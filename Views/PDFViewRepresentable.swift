import SwiftUI
import PDFKit

struct PDFViewRepresentable: NSViewRepresentable {
    let pdfDocument: PDFDocument?
    @Binding var pageNumber: Int?

    init(filename: String, pageNumber: Binding<Int?>) {
        if let url = Bundle.main.url(forResource: filename, withExtension: "pdf") {
            self.pdfDocument = PDFDocument(url: url)
        } else {
            self.pdfDocument = nil
            print("⚠️ Could not find \(filename).pdf in bundle")
        }
        self._pageNumber = pageNumber
    }

    func makeNSView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.document = pdfDocument
        return pdfView
    }

    func updateNSView(_ nsView: PDFView, context: Context) {
        if let pageNum = pageNumber,
           let doc = pdfDocument,
           pageNum > 0, pageNum <= doc.pageCount,
           let page = doc.page(at: pageNum - 1) {
            nsView.go(to: page)
        }
    }
}

