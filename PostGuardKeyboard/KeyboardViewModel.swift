import Combine
import SwiftUI
import UIKit

@MainActor
final class KeyboardViewModel: ObservableObject {
    enum Phase {
        case needsFullAccess
        case needsSignIn
        case quotaExceeded
        case empty
        case ready(text: String)
        case loading
        case result(AnalysisRecord)
        case replacing
        case error(String)
    }

    @Published private(set) var phase: Phase = .empty

    weak var controller: KeyboardViewController?

    // Called on appear and whenever the host text changes. Does not clobber
    // in-flight or presented states unless forced.
    func refresh(force: Bool = false) {
        guard let controller else { return }
        if !force {
            switch phase {
            case .loading, .result, .replacing, .error:
                return
            default:
                break
            }
        }
        guard controller.fullAccessGranted else {
            phase = .needsFullAccess
            return
        }
        // ログイン状態・Pro状態は本体アプリがApp Groupへ書き込んだキャッシュを参照する
        guard SharedStore.shared.uid != nil else {
            phase = .needsSignIn
            return
        }
        controller.setKeyboardHeight(300)
        Task {
            let text = await controller.capturedText()
            if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                phase = .empty
            } else {
                phase = .ready(text: text)
            }
        }
    }

    func analyze() {
        guard case .ready(let text) = phase else { return }
        let store = SharedStore.shared
        guard store.isPro || store.freeRemaining > 0 else {
            phase = .quotaExceeded
            return
        }
        phase = .loading
        Task {
            do {
                let result = try await GeminiService.shared.analyze(text: text)
                let record = AnalysisRecord(sourceText: text, result: result, origin: .keyboard)
                store.appendHistory(record)
                // Firestoreへは本体アプリ起動時に UsageService.sync() が反映する
                store.pendingKeyboardCount += 1
                phase = .result(record)
                controller?.setKeyboardHeight(340)
            } catch {
                phase = .error(error.localizedDescription)
            }
        }
    }

    func openAppForSignIn() {
        controller?.openMainApp(host: "signin")
    }

    func openAppForPaywall() {
        controller?.openMainApp(host: "paywall")
    }

    func applySuggestion() {
        guard case .result(let record) = phase,
              let suggestion = record.result.suggestion,
              let controller else { return }
        phase = .replacing
        Task {
            let replaced = await controller.replaceAll(with: suggestion, captured: record.sourceText)
            if replaced {
                controller.dismissToPreviousKeyboard()
            } else {
                phase = .error("入力内容が分析時から変更されたため、置換を中止しました。")
            }
        }
    }

    func cancel() {
        controller?.dismissToPreviousKeyboard()
    }

    func openDetail() {
        guard case .result(let record) = phase, let controller else { return }
        if !controller.openMainApp(record: record) {
            phase = .error("自動で開けませんでした。PostGuardアプリを起動すると詳細が表示されます。")
        }
    }

    func retry() {
        refresh(force: true)
    }
}
