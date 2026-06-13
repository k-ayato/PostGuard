import Foundation

struct AnalysisRecord: Codable, Identifiable, Hashable {
    enum Origin: String, Codable {
        case app
        case keyboard

        var label: String {
            switch self {
            case .app: return "アプリ"
            case .keyboard: return "キーボード"
            }
        }
    }

    let id: UUID
    let date: Date
    let sourceText: String
    let result: AnalysisResult
    let origin: Origin

    init(id: UUID = UUID(), date: Date = Date(), sourceText: String, result: AnalysisResult, origin: Origin) {
        self.id = id
        self.date = date
        self.sourceText = sourceText
        self.result = result
        self.origin = origin
    }

    var riskLevel: RiskLevel {
        RiskLevel(score: result.overallScore)
    }
}
