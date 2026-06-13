import SwiftUI

// MARK: - Color Palette
extension Color {
    static let pgBackground = Color(hex: "#0A0A0F")
    static let pgSurface = Color(hex: "#13131A")
    static let pgSurfaceElevated = Color(hex: "#1C1C26")
    static let pgBorder = Color(hex: "#2A2A3A")
    static let pgAccent = Color(hex: "#6C63FF")
    static let pgAccentGlow = Color(hex: "#6C63FF").opacity(0.3)

    static let pgSafe = Color(hex: "#00D084")
    static let pgSafeGlow = Color(hex: "#00D084").opacity(0.2)
    static let pgCaution = Color(hex: "#FFB800")
    static let pgCautionGlow = Color(hex: "#FFB800").opacity(0.2)
    static let pgWarning = Color(hex: "#FF4757")
    static let pgWarningGlow = Color(hex: "#FF4757").opacity(0.2)

    static let pgTextPrimary = Color.white
    static let pgTextSecondary = Color(hex: "#8B8BA0")
    static let pgTextTertiary = Color(hex: "#4A4A60")

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}

// MARK: - Risk Level Colors
extension RiskLevel {
    var color: Color {
        switch self {
        case .safe: return .pgSafe
        case .caution: return .pgCaution
        case .warning: return .pgWarning
        }
    }

    var glowColor: Color {
        switch self {
        case .safe: return .pgSafeGlow
        case .caution: return .pgCautionGlow
        case .warning: return .pgWarningGlow
        }
    }

    var icon: String {
        switch self {
        case .safe: return "checkmark.shield.fill"
        case .caution: return "exclamationmark.triangle.fill"
        case .warning: return "xmark.shield.fill"
        }
    }
}

// MARK: - View Modifiers
struct GlassCard: ViewModifier {
    var intensity: Double = 1.0

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.pgSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.pgBorder.opacity(intensity), lineWidth: 1)
                    )
            )
    }
}

struct NeonGlow: ViewModifier {
    let color: Color
    let radius: CGFloat

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.6), radius: radius / 2)
            .shadow(color: color.opacity(0.3), radius: radius)
    }
}

extension View {
    func glassCard(intensity: Double = 1.0) -> some View {
        modifier(GlassCard(intensity: intensity))
    }

    func neonGlow(color: Color, radius: CGFloat = 8) -> some View {
        modifier(NeonGlow(color: color, radius: radius))
    }
}
