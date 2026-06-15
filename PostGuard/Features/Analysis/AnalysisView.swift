import SwiftUI

struct AnalysisView: View {
    let result: AnalysisResult
    var originalText: String = ""
    let onReset: () -> Void
    @State private var expandedIds: Set<UUID> = []
    @State private var showSuggestion = false
    @State private var appearAnimation = false
    @Environment(\.dismiss) private var dismiss

    private var riskLevel: RiskLevel { RiskLevel(score: result.overallScore) }

    var body: some View {
        ZStack {
            Color.pgBackground.ignoresSafeArea()

            // Ambient glow — fixed size, no layout impact
            Circle()
                .fill(riskLevel.color.opacity(0.06))
                .frame(width: 400, height: 400)
                .offset(x: 120, y: -220)
                .blur(radius: 90)
                .allowsHitTesting(false)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // ── Custom nav header ──────────────────────────
                navHeader
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 8)

                // ── Scrollable content ─────────────────────────
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        scoreHeroCard
                        factCheckCard
                        dimensionsSection
                        if result.suggestion != nil {
                            suggestionCTA
                        }
                        newAnalysisButton
                            .padding(.bottom, 40)
                    }
                    // Single horizontal padding on the container — prevents overflow
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }
            }
        }
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $showSuggestion) {
            if let suggestion = result.suggestion {
                SuggestionView(
                    originalText: originalText,
                    suggestedText: suggestion,
                    onReset: onReset
                )
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                appearAnimation = true
            }
        }
    }

    // MARK: - Nav Header
    private var navHeader: some View {
        HStack(spacing: 12) {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.pgTextSecondary)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(Color.pgSurface)
                            .overlay(Circle().stroke(Color.pgBorder, lineWidth: 1))
                    )
            }
            Text("分析結果")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.pgTextPrimary)
            Spacer()
            // Risk level badge
            HStack(spacing: 5) {
                Image(systemName: riskLevel.icon)
                    .font(.system(size: 11, weight: .bold))
                Text(riskLevel.label)
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.0)
            }
            .foregroundColor(riskLevel.color)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(riskLevel.color.opacity(0.12))
                    .overlay(Capsule().stroke(riskLevel.color.opacity(0.4), lineWidth: 1))
            )
            .neonGlow(color: riskLevel.color, radius: 4)
        }
    }

    // MARK: - Score Hero
    private var scoreHeroCard: some View {
        VStack(spacing: 18) {
            // Label row
            HStack {
                Text("総合リスクスコア")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.pgTextTertiary)
                    .tracking(1.0)
                    .textCase(.uppercase)
                Spacer()
            }

            // Score number — monospaced for data/analytical precision
            HStack(alignment: .lastTextBaseline, spacing: 8) {
                Text("\(result.overallScore)")
                    .font(.system(size: 72, weight: .bold, design: .monospaced))
                    .foregroundColor(riskLevel.color)
                    .neonGlow(color: riskLevel.color, radius: 10)
                    .scaleEffect(appearAnimation ? 1.0 : 0.5, anchor: .leading)
                    .opacity(appearAnimation ? 1.0 : 0.0)
                Text("/ 100")
                    .font(.system(size: 16, weight: .regular, design: .monospaced))
                    .foregroundColor(.pgTextTertiary)
                    .padding(.bottom, 6)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Score bar
            ScoreBar(score: result.overallScore, color: riskLevel.color)
                .opacity(appearAnimation ? 1.0 : 0.0)

            // Tick marks
            HStack(spacing: 0) {
                Text("0")
                Spacer()
                Text("30")
                Spacer()
                Text("60")
                Spacer()
                Text("100")
            }
            .font(.system(size: 10, design: .monospaced))
            .foregroundColor(.pgTextTertiary)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.pgSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(riskLevel.color.opacity(0.3), lineWidth: 1.5)
                )
        )
    }

    // MARK: - Fact Check
    private var factCheckCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass.circle.fill")
                    .font(.system(size: 15))
                    .foregroundColor(.pgAccent)
                Text("ファクトチェック")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.pgTextPrimary)
                Spacer()
                factCheckBadge
            }

            if !result.factCheck.claims.isEmpty {
                VStack(alignment: .leading, spacing: 5) {
                    ForEach(result.factCheck.claims, id: \.self) { claim in
                        HStack(alignment: .top, spacing: 6) {
                            Text("·")
                                .foregroundColor(.pgTextTertiary)
                                .padding(.top, 1)
                            Text(claim)
                                .font(.system(size: 13))
                                .foregroundColor(.pgTextSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }

            // 出典: タップで既定ブラウザに遷移（Linkはユーザーの既定ブラウザでURLを開く）。
            // 未確認(unconfirmed)の場合は出典欄を控えめに表示する。
            if let urlString = result.factCheck.sourceUrl,
               let url = URL(string: urlString) {
                let isUnconfirmed = result.factCheck.result == "unconfirmed"
                Link(destination: url) {
                    HStack(spacing: 5) {
                        Image(systemName: "link")
                            .font(.system(size: 10))
                        Text("出典")
                            .font(.system(size: 11, weight: .semibold))
                        Text(urlString)
                            .font(.system(size: 11))
                            .lineLimit(1)
                            .truncationMode(.middle)
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 9))
                    }
                    .foregroundColor(isUnconfirmed ? .pgTextTertiary : .pgAccent.opacity(0.9))
                }
            } else if result.factCheck.result == "unconfirmed" {
                // 出典が得られなかった場合は控えめに
                Text("出典は確認できませんでした")
                    .font(.system(size: 11))
                    .foregroundColor(.pgTextTertiary)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.pgSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.pgBorder, lineWidth: 1)
                )
        )
    }

    private var factCheckBadge: some View {
        let config: (String, Color) = {
            switch result.factCheck.result {
            case "confirmed": return ("確認済み", .pgSafe)
            case "unconfirmed": return ("未確認", .pgCaution)
            default: return ("要注意", .pgWarning)
            }
        }()
        return Text(config.0)
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(config.1)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(config.1.opacity(0.12))
                    .overlay(Capsule().stroke(config.1.opacity(0.4), lineWidth: 1))
            )
    }

    // MARK: - Dimensions
    private var dimensionsSection: some View {
        VStack(spacing: 0) {
            HStack {
                Text("リスク軸の詳細")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.pgTextSecondary)
                    .tracking(0.8)
                    .textCase(.uppercase)
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "hand.tap")
                        .font(.system(size: 10))
                    Text("タップで展開")
                        .font(.system(size: 11))
                }
                .foregroundColor(.pgTextTertiary)
            }
            .padding(.bottom, 10)

            VStack(spacing: 8) {
                ForEach(Array(result.dimensions.enumerated()), id: \.element.id) { index, dim in
                    RiskDimensionRow(
                        dimension: dim,
                        isExpanded: expandedIds.contains(dim.id),
                        animationDelay: Double(index) * 0.05
                    ) {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            if expandedIds.contains(dim.id) {
                                expandedIds.remove(dim.id)
                            } else {
                                expandedIds.insert(dim.id)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Suggestion CTA
    private var suggestionCTA: some View {
        Button(action: { showSuggestion = true }) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.pgAccent.opacity(0.2), Color(hex: "#9B5CFF").opacity(0.15)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.pgAccent)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("修正提案を見る")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.pgTextPrimary)
                    Text("リスクを低減した文章を提案します")
                        .font(.system(size: 12))
                        .foregroundColor(.pgTextSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.pgTextTertiary)
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.pgSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.pgAccent.opacity(0.5), Color(hex: "#9B5CFF").opacity(0.3)],
                                    startPoint: .leading, endPoint: .trailing
                                ),
                                lineWidth: 1.5
                            )
                    )
            )
            .shadow(color: Color.pgAccent.opacity(0.12), radius: 12, y: 4)
        }
    }

    // MARK: - New Analysis Button
    private var newAnalysisButton: some View {
        Button(action: onReset) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 13, weight: .semibold))
                Text("新しい投稿を分析する")
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundColor(.pgTextSecondary)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.pgSurface)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.pgBorder, lineWidth: 1))
            )
        }
    }
}

// MARK: - Score Bar
struct ScoreBar: View {
    let score: Int
    let color: Color
    @State private var progress: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.pgBorder)
                    .frame(height: 8)
                // Safe zone tint (0–30%)
                Capsule()
                    .fill(Color.pgSafe.opacity(0.15))
                    .frame(width: geo.size.width * 0.30, height: 8)
                // Progress fill
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.7), color],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geo.size.width * progress, height: 8)
                    .shadow(color: color.opacity(0.45), radius: 4)
            }
        }
        .frame(height: 8)
        .onAppear {
            withAnimation(.spring(response: 1.0, dampingFraction: 0.8).delay(0.3)) {
                progress = CGFloat(score) / 100.0
            }
        }
    }
}
