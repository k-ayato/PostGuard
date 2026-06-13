import SwiftUI

// プラン選択画面（仮実装）。現在は無料プランのみ選択可能で、
// Proは「準備中」表示。サブスク本実装時にProボタンをStoreKit購入
// （PaywallView / StoreService）へ接続する。
struct PlanSelectionView: View {
    @EnvironmentObject private var store: StoreService
    @Environment(\.dismiss) private var dismiss
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @AppStorage("hasSelectedPlan") private var hasSelectedPlan = false
    @EnvironmentObject private var router: AppRouter

    // 初回（ログイン直後）はプラン選択が必須なので閉じるボタンを出さない
    private var canClose: Bool { hasSelectedPlan }

    var body: some View {
        ZStack {
            Color.pgBackground.ignoresSafeArea()

            Circle()
                .fill(Color.pgAccent.opacity(0.08))
                .frame(width: 360, height: 360)
                .offset(x: 130, y: -280)
                .blur(radius: 90)
                .allowsHitTesting(false)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header
                    .padding(.horizontal, 24)
                    .padding(.top, 24)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        freePlanCard
                        proPlanCard
                        Text("プランはいつでもアカウント画面から変更できます。")
                            .font(.system(size: 11))
                            .foregroundColor(.pgTextTertiary)
                            .padding(.top, 4)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 40)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 8) {
                Text("プランを選択")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.pgTextPrimary)
                Text("あなたに合ったプランで分析をはじめましょう")
                    .font(.system(size: 13))
                    .foregroundColor(.pgTextSecondary)
            }
            Spacer()
            if canClose {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.pgTextSecondary)
                        .frame(width: 34, height: 34)
                        .background(Circle().fill(Color.pgSurface))
                }
            }
        }
    }

    // MARK: - Free plan

    private var freePlanCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("無料プラン")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.pgTextPrimary)
                Spacer()
                if hasSelectedPlan && !store.isPro {
                    Text("現在のプラン")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.pgSafe)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.pgSafeGlow))
                }
            }

            Text("¥0")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.pgTextPrimary)

            VStack(alignment: .leading, spacing: 8) {
                planFeature(icon: "checkmark.circle.fill", text: "月\(SharedStore.freeMonthlyLimit)回までAI分析", color: .pgSafe)
                planFeature(icon: "checkmark.circle.fill", text: "7軸リスク分析・修正提案", color: .pgSafe)
                planFeature(icon: "checkmark.circle.fill", text: "キーボードからの分析", color: .pgSafe)
            }

            Button {
                hasSelectedPlan = true
                dismiss()
                if !hasSeenOnboarding {
                    hasSeenOnboarding = true
                    router.showKeyboardSetup = true
                }
            } label: {
                Text(hasSelectedPlan ? "このプランを継続" : "無料で始める")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(
                        LinearGradient(
                            colors: [Color.pgAccent, Color(hex: "#9B5CFF")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .shadow(color: Color.pgAccent.opacity(0.4), radius: 14, y: 6)
            }
        }
        .padding(18)
        .glassCard()
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.pgAccent.opacity(0.5), lineWidth: 1.5)
        )
    }

    // MARK: - Pro plan (準備中)

    private var proPlanCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.pgCaution)
                    Text("PostGuard Pro")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.pgTextPrimary)
                }
                Spacer()
                Text("準備中")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.pgCaution)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.pgCautionGlow))
            }

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("¥480")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.pgTextPrimary)
                Text("/ 月（予定）")
                    .font(.system(size: 13))
                    .foregroundColor(.pgTextSecondary)
            }

            VStack(alignment: .leading, spacing: 8) {
                planFeature(icon: "infinity", text: "分析回数が無制限", color: .pgAccent)
                planFeature(icon: "keyboard", text: "キーボードからも制限なし", color: .pgAccent)
                planFeature(icon: "sparkles", text: "今後のPro限定機能", color: .pgAccent)
            }

            Button {
                // サブスク本実装時にStoreKit購入（PaywallView）へ接続する
            } label: {
                Text("近日提供予定")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.pgTextTertiary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.pgSurface)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.pgBorder, lineWidth: 1)
                            )
                    )
            }
            .disabled(true)
        }
        .padding(18)
        .glassCard()
        .opacity(0.85)
    }

    private func planFeature(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 20)
            Text(text)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.pgTextPrimary)
        }
    }
}
