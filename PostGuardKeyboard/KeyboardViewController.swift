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
    // responder chain to UIApplication's openURL: is the known workaround.
    @discardableResult
    func openMainApp(host: String) -> Bool {
        guard let url = URL(string: "postguard://\(host)") else { return false }
        let selector = NSSelectorFromString("openURL:")
        var responder: UIResponder? = self
        while let current = responder {
            if current.responds(to: selector), !(current is UIInputViewController) {
                current.perform(selector, with: url)
                return true
            }
            responder = current.next
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
