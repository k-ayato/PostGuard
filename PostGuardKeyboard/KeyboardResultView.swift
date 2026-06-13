import SwiftUI

struct KeyboardResultView: View {
    let record: AnalysisRecord
    @ObservedObject var viewModel: KeyboardViewModel

    private var riskLevel: RiskLevel { record.riskLevel }

    var body: some View {
        VStack(spacing: 10) {
            scoreHeader

            if let suggestion = record.result.suggestion {
                suggestionCard(suggestion)
                actionButtons
            } else {
                safeBody
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }

    // MARK: - Score header

    private var scoreHeader: some View {
        HStack(spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: riskLevel.icon)
                    .font(.system(size: 13, weight: .bold))
                Text(riskLevel.label)
                    .font(.system(size: 13, weight: .bold))
            }
            .foregroundStyle(riskLevel.color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule().fill(riskLevel.glowColor)
            )

            Text("スコア \(record.result.overallScore)")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.pgTextPrimary)

            Spacer()

            Button {
                viewModel.openDetail()
            } label: {
                HStack(spacing: 4) {
                    Text("詳細")
                    Image(systemName: "arrow.up.forward.app")
                }
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.pgAccent)
            }
        }
    }

    // MARK: - Suggestion (non-safe)

    private func suggestionCard(_ suggestion: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("修正案")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.pgTextSecondary)
            ScrollView {
                Text(suggestion)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.pgTextPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .glassCard()
    }

    private var actionButtons: some View {
        HStack(spacing: 10) {
            Button {
                viewModel.applySuggestion()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("修正する")
                }
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 42)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.pgSafe)
                )
            }

            Button {
                viewModel.cancel()
            } label: {
                Text("キャンセル")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.pgTextSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.pgSurface)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.pgBorder, lineWidth: 1)
                            )
                    )
            }
        }
    }

    // MARK: - Safe (no suggestion)

    private var safeBody: some View {
        VStack(spacing: 10) {
            Spacer()
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 30))
                .foregroundStyle(Color.pgSafe)
                .neonGlow(color: .pgSafeGlow, radius: 10)
            Text("この投稿に問題は見つかりませんでした")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.pgTextPrimary)
            Spacer()
            Button {
                viewModel.cancel()
            } label: {
                Text("閉じる")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.pgAccent)
                    )
            }
        }
    }
}
