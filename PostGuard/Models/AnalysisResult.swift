import Foundation

struct AnalysisResult: Codable, Identifiable, Hashable {
    var id: String { "\(overallScore)-\(safe)" }
    let safe: Bool
    let overallScore: Int
    let dimensions: [RiskDimension]
    let factCheck: FactCheckResult
    let suggestion: String?

    enum CodingKeys: String, CodingKey {
        case safe
        case overallScore = "overall_score"
        case dimensions
        case factCheck = "fact_check"
        case suggestion
    }
}

struct RiskDimension: Codable, Identifiable, Hashable {
    let id: UUID
    let name: String
    let score: Int
    let reason: String

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = UUID()
        name = try container.decode(String.self, forKey: .name)
        score = try container.decode(Int.self, forKey: .score)
        reason = try container.decode(String.self, forKey: .reason)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(score, forKey: .score)
        try container.encode(reason, forKey: .reason)
    }

    enum CodingKeys: String, CodingKey {
        case name, score, reason
    }
}

struct FactCheckResult: Codable, Hashable {
    let claims: [String]
    let result: String
    let sourceUrl: String?

    enum CodingKeys: String, CodingKey {
        case claims, result, sourceUrl = "source_url"
    }
}

enum RiskLevel {
    case safe, caution, warning

    init(score: Int) {
        switch score {
        case 0...30: self = .safe
        case 31...60: self = .caution
        default: self = .warning
        }
    }

    var label: String {
        switch self {
        case .safe: return "安全"
        case .caution: return "注意"
        case .warning: return "警告"
        }
    }
}
