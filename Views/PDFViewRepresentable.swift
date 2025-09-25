//
//  PDFViewRepresentable.swift
//  ePleadingsMVP
//

import SwiftUI
import PDFKit

struct PDFViewRepresentable: NSViewRepresentable {
    let filename: String
    let targetPage: Int

    func makeNSView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical

        if let url = Bundle.main.url(forResource: filename.replacingOccurrences(of: ".pdf", with: ""), withExtension: "pdf"),
           let doc = PDFDocument(url: url) {
            pdfView.document = doc
        }

        return pdfView
    }

    func updateNSView(_ nsView: PDFView, context: Context) {
        guard let doc = nsView.document,
              targetPage > 0,
              targetPage <= doc.pageCount,
              let page = doc.page(at: targetPage - 1) else { return }

        nsView.go(to: page)
    }
}

