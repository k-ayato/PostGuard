import FirebaseAILogic
import FirebaseCore
import Foundation

enum GeminiError: LocalizedError {
    case notConfigured
    case invalidResponse
    case rateLimitExceeded(detail: String)
    case noAvailableModel
    case decodingError(String)
    case generationFailed(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "サービスのセットアップが完了していません。\nアプリを最新版に更新するか、時間をおいて再度お試しください。"
        case .invalidResponse:
            return "無効なレスポンスです"
        case .rateLimitExceeded(let detail):
            return "アクセスが集中しています。しばらくしてから再度お試しください。\n\n\(detail)"
        case .noAvailableModel:
            return "利用可能なモデルがありません。しばらくしてから再度お試しください。"
        case .decodingError(let msg):
            return "デコードエラー: \(msg)"
        case .generationFailed(let msg):
            return "分析に失敗しました: \(msg)"
        }
    }
}

final class GeminiService {
    static let shared = GeminiService()
    private init() {}

    // Fallback order: latest stable → lighter model on quota exhaustion.
    private let modelCandidates = [
        "gemini-2.5-flash",
        "gemini-2.5-flash-lite",
    ]

    private let systemPrompt = """
あなたはSNS投稿の炎上リスクと虚偽情報リスクを分析する専門家です。
以下の投稿文を分析し、必ず指定されたJSON形式のみで回答してください。
余計なテキストは一切含めないでください。

## 分析の指示

以下の7つの軸でそれぞれ0〜100のスコアをつけてください。
スコアが高いほどリスクが高いことを意味します。

1. 感情・攻撃性（挑発的・攻撃的な表現）
2. 差別・ハラスメント（属性への差別的言及）
3. 政治・宗教（対立を煽る表現）
4. 法的リスク（名誉毀損・プライバシー侵害の疑い）
5. ブランド整合性（企業・人物イメージを損なう表現）
6. TPO・文脈リスク（社会状況との文脈的ズレ）
7. 虚偽情報リスク（Google Searchで確認できない主張）

- 総合スコア（overall_score）は7軸の加重平均として算出してください
- 総合スコアが30以下の場合はsafeをtrueにしてください
- safeがtrueの場合、suggestionはnullにしてください
- 虚偽情報の判定は断定せず、確認できた/できなかったという形式にしてください
- 修正提案は原文の意図を極力保ちつつ、リスクを低減した日本語文章にしてください

## 出力形式（JSON）

{
  "safe": true or false,
  "overall_score": 0〜100の整数,
  "dimensions": [
    {
      "name": "分析軸名",
      "score": 0〜100の整数,
      "reason": "根拠の説明（日本語、1〜2文）"
    }
  ],
  "fact_check": {
    "claims": ["文中の主張1", "文中の主張2"],
    "result": "confirmed" or "unconfirmed" or "caution",
    "source_url": "参照URLまたはnull"
  },
  "suggestion": "修正後の文章またはnull"
}
"""

    func analyze(text: String) async throws -> AnalysisResult {
        await MainActor.run { FirebaseBootstrap.configureIfAvailable() }
        guard FirebaseBootstrap.isConfigured else { throw GeminiError.notConfigured }

        let ai = FirebaseAI.firebaseAI(backend: .googleAI())

        var sawQuotaError = false
        var lastError: Error = GeminiError.invalidResponse
        for modelName in modelCandidates {
            do {
                let result = try await callModel(ai: ai, modelName: modelName, text: text)
                print("[GeminiService] Success with model: \(modelName)")
                return result
            } catch let error as GeminiError {
                throw error
            } catch where isQuotaError(error) {
                // Quota exhausted on this model — try the lighter fallback.
                print("[GeminiService] model \(modelName) quota exhausted, trying fallback...")
                sawQuotaError = true
                lastError = error
                continue
            } catch {
                throw GeminiError.generationFailed(error.localizedDescription)
            }
        }
        if sawQuotaError {
            throw GeminiError.rateLimitExceeded(detail: lastError.localizedDescription)
        }
        throw GeminiError.generationFailed(lastError.localizedDescription)
    }

    private func callModel(ai: FirebaseAI, modelName: String, text: String) async throws -> AnalysisResult {
        // NOTE: structured JSON output is incompatible with Google Search
        // grounding, so JSON is extracted from the text response instead.
        let model = ai.generativeModel(
            modelName: modelName,
            generationConfig: GenerationConfig(temperature: 0.1),
            tools: [.googleSearch()],
            systemInstruction: ModelContent(role: "system", parts: systemPrompt)
        )

        let response = try await model.generateContent("投稿文: \(text)")

        guard let replyText = response.text, !replyText.isEmpty else {
            throw GeminiError.decodingError("モデルからテキスト応答が得られませんでした")
        }

        print("[GeminiService] replyText:\n\(replyText)")

        let jsonString = extractJSON(from: replyText)
        guard !jsonString.isEmpty, let jsonData = jsonString.data(using: .utf8) else {
            throw GeminiError.decodingError("JSONブロックの抽出に失敗しました。応答: \(replyText.prefix(200))")
        }

        do {
            return try JSONDecoder().decode(AnalysisResult.self, from: jsonData)
        } catch {
            print("[GeminiService] decode failed. jsonString:\n\(jsonString)")
            throw GeminiError.decodingError(error.localizedDescription)
        }
    }

    // The SDK does not expose HTTP status codes directly; quota errors are
    // identified from the underlying error description.
    private func isQuotaError(_ error: Error) -> Bool {
        let description = String(describing: error) + (error as NSError).localizedDescription
        return description.contains("429")
            || description.contains("RESOURCE_EXHAUSTED")
            || description.lowercased().contains("quota")
    }

    // Extracts the first {...} JSON block from a text that may contain markdown fences or prose.
    private func extractJSON(from text: String) -> String {
        // Strip ```json ... ``` fences if present
        if let fenceStart = text.range(of: "```json"),
           let fenceEnd = text.range(of: "```", range: fenceStart.upperBound..<text.endIndex) {
            return String(text[fenceStart.upperBound..<fenceEnd.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if let fenceStart = text.range(of: "```"),
           let fenceEnd = text.range(of: "```", range: fenceStart.upperBound..<text.endIndex) {
            return String(text[fenceStart.upperBound..<fenceEnd.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        // Find outermost { ... }
        guard let start = text.firstIndex(of: "{"),
              let end = text.lastIndex(of: "}") else {
            return text
        }
        return String(text[start...end])
    }
}
