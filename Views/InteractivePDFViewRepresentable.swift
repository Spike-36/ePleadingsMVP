import SwiftUI
import PDFKit

struct InteractivePDFViewRepresentable: NSViewRepresentable {
    let url: URL
    @Binding var selectedHeading: HeadingEntity?

    func makeNSView(context: Context) -> InteractivePDFView {
        let pdfView = InteractivePDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displaysAsBook = false
        pdfView.displayDirection = .vertical

        if let document = PDFDocument(url: url) {
            pdfView.document = document
        }

        // Attach click handlers
        pdfView.onLeftClick = { pageNumber, point in
            context.coordinator.handleLeftClick(pageNumber: pageNumber, point: point)
        }

        pdfView.onRightClick = { pageNumber, point in
            context.coordinator.handleRightClick(pageNumber: pageNumber, point: point)
        }

        return pdfView
    }

    func updateNSView(_ pdfView: InteractivePDFView, context: Context) {
        guard let heading = selectedHeading,
              let document = pdfView.document else { return }

        // Safely derive a name string from any known property
        let headingName =
            (heading.value(forKey: "text") as? String) ??
            (heading.value(forKey: "name") as? String) ??
            (heading.value(forKey: "heading") as? String) ??
            (heading.value(forKey: "id") as? String) ??
            ""

        guard !headingName.isEmpty else { return }

        for pageIndex in 0..<document.pageCount {
            guard let page = document.page(at: pageIndex) else { continue }

            for annotation in page.annotations {
                if annotation.fieldName == headingName {
                    pdfView.scrollTo(page: page, rect: annotation.bounds)
                    return
                }
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
            print("Left click on page \(pageNumber) at \(point)")
        }

        func handleRightClick(pageNumber: Int, point: CGPoint) {
            print("Right click on page \(pageNumber) at \(point)")
        }
    }
}

