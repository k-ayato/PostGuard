import SwiftUI

// 環境オブジェクトのスコープ内で全てのプレゼンテーション（sheet/fullScreenCover）を
// 行うルート。App構造体側でsheetを付けると環境が継承されずクラッシュするため、
// 必ずここに集約する。
struct RootView: View {
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var auth: AuthService
    @EnvironmentObject private var usage: UsageService
    @EnvironmentObject private var store: StoreService
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @AppStorage("hasSelectedPlan") private var hasSelectedPlan = false
    @AppStorage("hasAgreedToTerms") private var hasAgreedToTerms = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            if !hasAgreedToTerms {
                ConsentView()
            } else if auth.isSignedIn {
                NavigationStack {
                    InputView()
                }
            } else {
                // 同意後〜匿名サインイン完了までの短いローディング（5.1.1対応で
                // ログインゲートは廃止。ログインは任意でAccountから行う）。
                signingInView
            }
        }
        .onAppear {
            auth.start()
            store.start()
            if hasAgreedToTerms {
                Task {
                    await auth.signInAnonymouslyIfNeeded()
                    await usage.sync()
                }
            }
            if auth.isSignedIn {
                presentPostSignInFlowIfNeeded()
            }
        }
        .onChange(of: hasAgreedToTerms) { _, agreed in
            // 利用規約に同意したタイミングで匿名サインインを開始する。
            if agreed {
                Task {
                    await auth.signInAnonymouslyIfNeeded()
                    await usage.sync()
                }
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                Task {
                    await store.refreshEntitlements()
                    await usage.sync()
                }
            }
        }
        .onChange(of: auth.isSignedIn) { _, signedIn in
            if signedIn {
                Task { await usage.sync() }
                presentPostSignInFlowIfNeeded()
            } else {
                // 次回ログイン時に再度プラン選択から始める
                hasSelectedPlan = false
                router.showPlanSelection = false
                router.showAccount = false
                router.showHistory = false
                router.showLogin = false
                // 本会員ログアウト/退会後もアプリを使い続けられるよう匿名に戻す。
                if hasAgreedToTerms {
                    Task { await auth.signInAnonymouslyIfNeeded() }
                }
            }
        }
        .fullScreenCover(isPresented: $router.showPlanSelection) {
            PlanSelectionView()
        }
        .fullScreenCover(item: $router.deepLinkRecord) { record in
            NavigationStack {
                AnalysisView(
                    result: record.result,
                    originalText: record.sourceText,
                    onReset: { router.deepLinkRecord = nil }
                )
            }
            .preferredColorScheme(.dark)
        }
        .sheet(isPresented: $router.showHistory) {
            HistoryView()
        }
        .sheet(isPresented: $router.showAccount) {
            AccountView()
        }
        .sheet(isPresented: $router.showLogin) {
            LoginView()
        }
    }

    // 匿名サインイン中の軽量ローディング
    private var signingInView: some View {
        ZStack {
            Color.pgBackground.ignoresSafeArea()
            ProgressView()
                .tint(.pgAccent)
                .scaleEffect(1.3)
        }
        .preferredColorScheme(.dark)
    }

    // ログイン直後（または既ログインでの初回起動時）のフロー:
    // プラン未選択ならプラン選択（有料プラン解放時のみ）。キーボード拡張は本バージョンで
    // 同梱しないため、初回のキーボード設定ガイドは表示しない。
    private func presentPostSignInFlowIfNeeded() {
        if FeatureFlags.paidPlansEnabled, !hasSelectedPlan {
            router.showPlanSelection = true
        }
    }
}
