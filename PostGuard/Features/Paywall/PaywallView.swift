import StoreKit
import SwiftUI

struct PaywallView: View {
    @EnvironmentObject private var store: StoreService
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        SubscriptionStoreView(productIDs: [StoreService.monthlyProductID]) {
            marketingHeader
        }
        .subscriptionStoreButtonLabel(.multiline)
        .storeButton(.visible, for: .restorePurchases)
        .subscriptionStorePolicyDestination(url: AccountView.termsURL, for: .termsOfService)
        .subscriptionStorePolicyDestination(url: AccountView.privacyPolicyURL, for: .privacyPolicy)
        .subscriptionStoreControlBackground(.gradientMaterial)
        .background(Color.pgBackground)
        .preferredColorScheme(.dark)
        .onInAppPurchaseCompletion { _, result in
            if case .success(.success) = result {
                await store.refreshEntitlements()
                dismiss()
            }
        }
    }

    private var marketingHeader: some View {
        VStack(spacing: 14) {
            Image(systemName: "crown.fill")
                .font(.system(size: 40))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.pgCaution, Color.pgAccent],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .neonGlow(color: .pgAccentGlow, radius: 12)

            Text("PostGuard Pro")
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(.pgTextPrimary)

            VStack(alignment: .leading, spacing: 10) {
                featureRow(icon: "infinity", text: "分析回数が無制限に")
                featureRow(icon: "keyboard", text: "キーボードからも制限なく分析")
                featureRow(icon: "sparkles", text: "今後のPro限定機能をすべて利用可能")
            }
            .padding(.top, 4)

            Text("無料プランでは月\(SharedStore.freeMonthlyLimit)回まで分析できます。\nサブスクリプションは期間終了の24時間前までに解約しない限り自動更新されます。")
                .font(.system(size: 11))
                .foregroundColor(.pgTextTertiary)
                .multilineTextAlignment(.center)
                .padding(.top, 6)
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .background(Color.pgBackground)
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.pgAccent)
                .frame(width: 22)
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.pgTextPrimary)
        }
    }
}
