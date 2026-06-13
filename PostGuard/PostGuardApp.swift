import GoogleSignIn
import SwiftUI

@main
struct PostGuardApp: App {
    @StateObject private var router = AppRouter()
    @StateObject private var auth = AuthService.shared
    @StateObject private var usage = UsageService.shared
    @StateObject private var store = StoreService.shared

    init() {
        FirebaseBootstrap.configureIfAvailable()
    }

    var body: some Scene {
        WindowGroup {
            // sheet等のプレゼンテーションは必ずRootView内（環境オブジェクトの
            // スコープ内）で行う。ここに付けると環境が継承されずクラッシュする。
            RootView()
                .environmentObject(router)
                .environmentObject(auth)
                .environmentObject(usage)
                .environmentObject(store)
                .preferredColorScheme(.dark)
                .onOpenURL { url in
                    if GIDSignIn.sharedInstance.handle(url) { return }
                    router.handle(url)
                }
        }
    }
}
