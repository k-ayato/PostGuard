import SwiftUI

@MainActor
final class AppRouter: ObservableObject {
    @Published var deepLinkRecord: AnalysisRecord?
    @Published var showHistory = false
    @Published var showKeyboardSetup = false
    @Published var showAccount = false
    @Published var showPlanSelection = false
    @Published var showLogin = false

    // postguard://result … キーボードの「詳細」
    // postguard://signin … キーボードの「アプリでログイン」（起動すればログインゲートが表示される）
    // postguard://paywall … キーボードの「プランを変更」
    func handle(_ url: URL) {
        guard url.scheme == "postguard" else { return }
        switch url.host {
        case "result":
            if let record = SharedStore.shared.consumePendingRecord() {
                deepLinkRecord = record
            }
        case "paywall":
            showPlanSelection = true
        case "signin":
            // ログインゲートがルートで表示されるため個別処理は不要
            break
        default:
            break
        }
    }
}
