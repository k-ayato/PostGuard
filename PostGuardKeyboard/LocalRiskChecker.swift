import Foundation

// 端末内で完結する簡易リスクチェック。ネットワークや App Group（フルアクセス）に
// 依存しないため、キーボードのフルアクセスがOFFでも動作する（App Store審査 4.4.1
// 対応）。AIによる詳細分析の代替ではなく、「明らかな注意点」を即時に知らせる用途。
enum LocalRiskChecker {
    struct Warning: Identifiable {
        let id = UUID()
        let icon: String     // SF Symbol 名
        let message: String
    }

    static func check(_ raw: String) -> [Warning] {
        let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return [] }

        var warnings: [Warning] = []

        // 個人情報: 電話番号らしき数字列
        if matches(text, #"0\d{1,4}[-－ ]?\d{1,4}[-－ ]?\d{3,4}"#) {
            warnings.append(.init(icon: "phone.fill",
                                  message: "電話番号らしき数字列が含まれています。公開前にご確認ください。"))
        }
        // 個人情報: メールアドレス
        if matches(text, #"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}"#) {
            warnings.append(.init(icon: "envelope.fill",
                                  message: "メールアドレスが含まれています。公開前にご確認ください。"))
        }
        // 攻撃的・不適切な可能性のある語（最小限のローカル辞書）
        if ngWords.contains(where: { text.localizedCaseInsensitiveContains($0) }) {
            warnings.append(.init(icon: "exclamationmark.bubble.fill",
                                  message: "攻撃的・不適切に受け取られうる語が含まれています。"))
        }
        // 過剰な感嘆符・疑問符（煽り・感情的に見えやすい）
        if matches(text, #"[!！]{3,}|[?？]{3,}"#) {
            warnings.append(.init(icon: "exclamationmark.2",
                                  message: "感嘆符・疑問符が多く、感情的・煽り口調に見える可能性があります。"))
        }
        // 文字数（SNS想定の目安）
        if text.count > 280 {
            warnings.append(.init(icon: "textformat.size",
                                  message: "280文字を超えています（\(text.count)字）。"))
        }

        return warnings
    }

    private static func matches(_ text: String, _ pattern: String) -> Bool {
        text.range(of: pattern, options: .regularExpression) != nil
    }

    // 明らかな語のみの小さな辞書。網羅性ではなく即時の注意喚起が目的。
    private static let ngWords: [String] = [
        "死ね", "殺す", "クズ", "ゴミ", "消えろ", "ブス", "キモい", "馬鹿野郎",
    ]
}
