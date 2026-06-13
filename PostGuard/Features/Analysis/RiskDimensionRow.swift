import SwiftUI

struct RiskDimensionRow: View {
    let dimension: RiskDimension
    let isExpanded: Bool
    var animationDelay: Double = 0
    let onTap: () -> Void

    private var level: RiskLevel { RiskLevel(score: dimension.score) }
    @State private var appeared = false

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                mainRow
                if isExpanded {
                    expandedReason
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .buttonStyle(.plain)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(isExpanded ? Color.pgSurfaceElevated : Color.pgSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(
                            isExpanded ? level.color.opacity(0.35) : Color.pgBorder,
                            lineWidth: isExpanded ? 1.5 : 1
                        )
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .onAppear {
            withAnimation(.spring(response: 0.5).delay(animationDelay)) {
                appeared = true
            }
        }
    }

    // MARK: - Main row
    private var mainRow: some View {
        HStack(spacing: 12) {
            // Score ring
            scoreRing

            // Name + progress bar
            VStack(alignment: .leading, spacing: 6) {
                Text(dimension.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.pgTextPrimary)
                    .lineLimit(1)

                // Progress bar — GeometryReader-free using frame + overlay
                progressBar
            }

            // Chevron
            Image(systemName: "chevron.down")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.pgTextTertiary)
                .rotationEffect(.degrees(isExpanded ? 180 : 0))
                .animation(.spring(response: 0.3), value: isExpanded)
                .frame(width: 16)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
    }

    // MARK: - Score ring
    private var scoreRing: some View {
        ZStack {
            Circle()
                .fill(level.color.opacity(0.10))
                .frame(width: 42, height: 42)
            Circle()
                .trim(from: 0, to: appeared ? CGFloat(dimension.score) / 100 : 0)
                .stroke(level.color, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                .frame(width: 36, height: 36)
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.8).delay(animationDelay), value: appeared)
            Text("\(dimension.score)")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(level.color)
        }
    }

    // MARK: - Progress bar (no GeometryReader)
    // Uses a proportional overlay so the bar fills relative to its own width.
    private var progressBar: some View {
        ZStack(alignment: .leading) {
            Capsule()
                .fill(Color.pgBorder)
                .frame(height: 3)
            GeometryReader { geo in
                Capsule()
                    .fill(level.color.opacity(0.8))
                    .frame(
                        width: appeared ? geo.size.width * CGFloat(dimension.score) / 100 : 0,
                        height: 3
                    )
                    .animation(.spring(response: 0.8).delay(animationDelay + 0.1), value: appeared)
            }
            .frame(height: 3)
        }
        .frame(height: 3)
    }

    // MARK: - Expanded reason
    private var expandedReason: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.pgBorder)
                .padding(.horizontal, 14)

            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "quote.opening")
                    .font(.system(size: 11))
                    .foregroundColor(level.color.opacity(0.6))
                    .padding(.top, 2)
                Text(dimension.reason)
                    .font(.system(size: 13))
                    .foregroundColor(.pgTextSecondary)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
    }
}
