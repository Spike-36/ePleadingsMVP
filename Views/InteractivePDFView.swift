import PDFKit
import SwiftUI

class InteractivePDFView: PDFView {
    var onRightClick: ((Int, CGPoint) -> Void)?
    var onLeftClick: ((Int, CGPoint) -> Void)?

    override func mouseDown(with event: NSEvent) {
        // Treat Control + Left Click as Right Click
        if event.modifierFlags.contains(.control) {
            self.rightMouseDown(with: event)
            return
        }

        guard let page = self.page(for: event.locationInWindow, nearest: true) else { return }
        let point = self.convert(event.locationInWindow, to: page)
        let pageNumber = page.label.flatMap { Int($0) } ?? 0
        onLeftClick?(pageNumber, point)
    }

    override func rightMouseDown(with event: NSEvent) {
        guard let page = self.page(for: event.locationInWindow, nearest: true) else { return }
        let point = self.convert(event.locationInWindow, to: page)
        let pageNumber = page.label.flatMap { Int($0) } ?? 0
        onRightClick?(pageNumber, point)
    }

    // 👉 explicit scroll helper
    func scrollTo(page: PDFPage, rect: CGRect) {
        self.go(to: rect, on: page)
    }
}

