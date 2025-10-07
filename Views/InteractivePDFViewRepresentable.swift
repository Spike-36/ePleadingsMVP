import SwiftUI
import PDFKit
import CoreData // 👉 Needed for managedObjectContext

// 🧩 Helper view to pass mouse events through to PDFView
final class ClickPassthroughView: NSView {
    var targetView: NSView?

    override func hitTest(_ point: NSPoint) -> NSView? {
        guard let event = NSApp.currentEvent else { return targetView }
        switch event.type {
        case .leftMouseDown, .rightMouseDown, .otherMouseDown:
            // ✅ Forward clicks to PDFView
            return targetView
        default:
            // ✅ Allow scroll, drag, zoom, etc. to behave normally
            return super.hitTest(point)
        }
    }
}

struct InteractivePDFViewRepresentable: NSViewRepresentable {
    let url: URL
    @Binding var selectedHeading: HeadingEntity?
    @Environment(\.managedObjectContext) private var context // 🔄 Keep Core Data context injected

    func makeNSView(context: Context) -> ClickPassthroughView {
        let container = ClickPassthroughView(frame: .zero)

        // ✅ Create the PDF view
        let pdfView = InteractivePDFView(frame: .zero)
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displaysAsBook = false
        pdfView.displayDirection = .vertical

        // 👉 Inject Core Data context so right-click tagging works
        pdfView.managedObjectContext = self.context

        if let document = PDFDocument(url: url) {
            pdfView.document = document

            // 👉 Apply sentence highlights after loading
            let filename = url.lastPathComponent
            SentenceHighlightService.applyHighlights(
                to: pdfView,
                sourceFilename: filename,
                context: self.context
            )
        }

        // ✅ Attach click handlers
        pdfView.onRightClick = { pageNumber, point in
            context.coordinator.handleRightClick(pageNumber: pageNumber, point: point)
        }

        pdfView.onLeftClick = { pageNumber, point in
            context.coordinator.handleLeftClick(pageNumber: pageNumber, point: point)
        }

        // ✅ Embed the PDFView inside the container
        container.addSubview(pdfView)
        pdfView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            pdfView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            pdfView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            pdfView.topAnchor.constraint(equalTo: container.topAnchor),
            pdfView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        container.targetView = pdfView
        return container
    }

    func updateNSView(_ container: ClickPassthroughView, context: Context) {
        guard
            let pdfView = container.targetView as? InteractivePDFView,
            let heading = selectedHeading,
            let document = pdfView.document
        else { return }

        // Safely derive a name string from any known property
        let headingName =
            (heading.value(forKey: "text") as? String) ??
            (heading.value(forKey: "name") as? String) ??
            (heading.value(forKey: "heading") as? String) ??
            (heading.value(forKey: "id") as? String) ??
            ""

        guard !headingName.isEmpty else { return }

        // Scroll to the annotation matching the heading
        for pageIndex in 0..<document.pageCount {
            guard let page = document.page(at: pageIndex) else { continue }
            for annotation in page.annotations where annotation.fieldName == headingName {
                pdfView.scrollTo(page: page, rect: annotation.bounds)
                return
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    class Coordinator {
        var parent: InteractivePDFViewRepresentable

        init(parent: InteractivePDFViewRepresentable) {
            self.parent = parent
        }

        func handleLeftClick(pageNumber: Int, point: CGPoint) {
            Swift.print("🖱️ Left click on page \(pageNumber) at \(point)")
        }

        func handleRightClick(pageNumber: Int, point: CGPoint) {
            Swift.print("🖱️ Right click on page \(pageNumber) at \(point)")
        }
    }
}

