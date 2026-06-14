//
//  KeyboardViewController.swift
//  PostGuardKeyboard
//

import SwiftUI
import UIKit

final class KeyboardViewController: UIInputViewController {
    // Flip to true to scan the whole document across paragraph boundaries
    // (slower, moves the cursor) instead of reading the visible context only.
    private let useFullDocumentScan = false

    private let viewModel = KeyboardViewModel()
    private var heightConstraint: NSLayoutConstraint?

    override func viewDidLoad() {
        super.viewDidLoad()

        viewModel.controller = self

        let host = UIHostingController(rootView: KeyboardRootView(viewModel: viewModel))
        host.view.backgroundColor = UIColor(Color.pgBackground)
        addChild(host)
        view.addSubview(host.view)
        host.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            host.view.topAnchor.constraint(equalTo: view.topAnchor),
            host.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        host.didMove(toParent: self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if heightConstraint == nil {
            // priority 999: a required constraint conflicts with the system-
            // installed keyboard height constraint and can crash.
            let constraint = view.heightAnchor.constraint(equalToConstant: 300)
            constraint.priority = UILayoutPriority(999)
            constraint.isActive = true
            heightConstraint = constraint
        }
        viewModel.refresh(force: true)
    }

    override func textDidChange(_ textInput: UITextInput?) {
        super.textDidChange(textInput)
        viewModel.refresh()
    }

    var fullAccessGranted: Bool { hasFullAccess }

    func setKeyboardHeight(_ height: CGFloat) {
        heightConstraint?.constant = height
    }

    func capturedText() async -> String {
        if useFullDocumentScan {
            return await textDocumentProxy.readEntireDocument()
        }
        return textDocumentProxy.fullContext
    }

    // Replaces the host app's text with newText. Bails out if the text changed
    // since it was captured, to avoid destroying edits made meanwhile.
    func replaceAll(with newText: String, captured: String) async -> Bool {
        let proxy = textDocumentProxy
        await proxy.moveCursorToEnd()
        guard proxy.fullContext == captured else { return false }
        await proxy.deleteBackward(times: captured.count)
        proxy.insertText(newText)
        return true
    }

    // Keyboard extensions cannot use extensionContext.open(); walking the
    // responder chain to UIApplication and invoking its open URL method is the
    // known workaround. iOS 18 logs a "needs to migrate to the non-deprecated
    // UIApplication.open(_:options:completionHandler:)" warning for the legacy
    // openURL: selector and can fail to actually open the app, so we prefer the
    // non-deprecated selector and only fall back to openURL: when unavailable.
    @discardableResult
    func openMainApp(host: String) -> Bool {
        guard let url = URL(string: "postguard://\(host)") else { return false }

        // 1. Try to resolve the UIApplication via the responder chain's
        //    `application` accessor, then drive it directly. This is the most
        //    reliable target since UIApplication implements both open methods.
        if let application = responderChainApplication() {
            if open(url, on: application) { return true }
        }

        // 2. Fall back to invoking the open selectors on whichever responder in
        //    the chain implements them (the classic workaround).
        var responder: UIResponder? = self
        while let current = responder {
            if !(current is UIInputViewController), open(url, on: current) {
                return true
            }
            responder = current.next
        }
        return false
    }

    // Walks the responder chain looking for an object that exposes a UIApplication
    // through the `application` selector (UIApplication itself returns `self`).
    private func responderChainApplication() -> NSObject? {
        let applicationSelector = NSSelectorFromString("application")
        var responder: UIResponder? = self
        while let current = responder {
            if !(current is UIInputViewController),
               current.responds(to: applicationSelector),
               let application = current.perform(applicationSelector)?.takeUnretainedValue() as? NSObject {
                return application
            }
            responder = current.next
        }
        return nil
    }

    // Attempts to open `url` on `target`, preferring the non-deprecated
    // open(_:options:completionHandler:) selector over the deprecated openURL:.
    private func open(_ url: URL, on target: NSObject) -> Bool {
        let modernSelector = NSSelectorFromString("openURL:options:completionHandler:")
        if target.responds(to: modernSelector) {
            typealias OpenURLOptions = @convention(c)
                (NSObject, Selector, URL, [AnyHashable: Any], Any?) -> Void
            let method = target.method(for: modernSelector)
            let openURL = unsafeBitCast(method, to: OpenURLOptions.self)
            openURL(target, modernSelector, url, [:], nil)
            return true
        }

        let legacySelector = NSSelectorFromString("openURL:")
        if target.responds(to: legacySelector) {
            target.perform(legacySelector, with: url)
            return true
        }
        return false
    }

    func openMainApp(record: AnalysisRecord) -> Bool {
        SharedStore.shared.savePendingRecord(record)
        return openMainApp(host: "result")
    }

    func dismissToPreviousKeyboard() {
        advanceToNextInputMode()
    }
}
