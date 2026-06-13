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
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            if auth.isSignedIn {
                NavigationStack {
                    InputView()
                }
            } else {
                LoginView()
            }
        }
        .onAppear {
            auth.start()
            store.start()
            Task { await usage.sync() }
            if auth.isSignedIn {
                presentPostSignInFlowIfNeeded()
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
        .sheet(isPresented: $router.showKeyboardSetup) {
            KeyboardSetupView()
        }
        .sheet(isPresented: $router.showHistory) {
            HistoryView()
        }
        .sheet(isPresented: $router.showAccount) {
            AccountView()
        }
    }

    // ログイン直後（または既ログインでの初回起動時）のフロー:
    // プラン未選択ならプラン選択 → 初回はキーボード設定ガイド
    private func presentPostSignInFlowIfNeeded() {
        if !hasSelectedPlan {
            router.showPlanSelection = true
        } else if !hasSeenOnboarding {
            hasSeenOnboarding = true
            router.showKeyboardSetup = true
        }
    }
}
