import UIKit

extension UITextDocumentProxy {
    // Text visible to the proxy around the cursor. For single-paragraph posts
    // (the common case on SNS) this is the entire document; the proxy cuts
    // context at paragraph boundaries, so multi-paragraph text is truncated.
    var fullContext: String {
        (documentContextBeforeInput ?? "")
            + (selectedText ?? "")
            + (documentContextAfterInput ?? "")
    }

    // The proxy updates asynchronously after adjustTextPosition/deleteBackward,
    // so each step waits briefly for the host app to catch up.
    @MainActor
    func moveCursorToEnd() async {
        var iterations = 0
        while let after = documentContextAfterInput, !after.isEmpty, iterations < 40 {
            adjustTextPosition(byCharacterOffset: after.count)
            try? await Task.sleep(nanoseconds: 40_000_000)
            iterations += 1
        }
    }

    @MainActor
    func deleteBackward(times count: Int) async {
        for i in 0..<count {
            deleteBackward()
            if (i + 1) % 50 == 0 {
                try? await Task.sleep(nanoseconds: 20_000_000)
            }
        }
        try? await Task.sleep(nanoseconds: 40_000_000)
    }

    // v2: walks the whole document across paragraph boundaries. Slower and
    // moves the cursor; kept behind KeyboardViewController.useFullDocumentScan.
    @MainActor
    func readEntireDocument() async -> String {
        // Walk back to the beginning of the document.
        var iterations = 0
        while let before = documentContextBeforeInput, !before.isEmpty, iterations < 40 {
            adjustTextPosition(byCharacterOffset: -before.count)
            try? await Task.sleep(nanoseconds: 40_000_000)
            iterations += 1
        }
        // Accumulate forward. An empty "after" with a non-empty document means
        // the cursor sits on a paragraph boundary: step over the newline.
        var text = ""
        iterations = 0
        while iterations < 80 {
            if let after = documentContextAfterInput, !after.isEmpty {
                text += after
                adjustTextPosition(byCharacterOffset: after.count)
            } else if documentContextAfterInput != nil, hasText {
                let beforeLength = (documentContextBeforeInput ?? "").count
                adjustTextPosition(byCharacterOffset: 1)
                try? await Task.sleep(nanoseconds: 40_000_000)
                let movedLength = (documentContextBeforeInput ?? "").count
                // No progress: reached the real end of the document.
                if movedLength <= beforeLength { break }
                text += "\n"
                iterations += 1
                continue
            } else {
                break
            }
            try? await Task.sleep(nanoseconds: 40_000_000)
            iterations += 1
        }
        return text
    }
}
