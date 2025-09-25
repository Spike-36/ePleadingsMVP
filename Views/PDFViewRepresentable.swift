//
//  PDFViewRepresentable.swift
//  ePleadingsMVP
//

import SwiftUI
import PDFKit

struct PDFViewRepresentable: NSViewRepresentable {
    let fileURL: URL
    let targetPage: Int

    func makeNSView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical

        if let doc = PDFDocument(url: fileURL) {
            pdfView.document = doc
        } else {
            print("⚠️ Could not load PDF at \(fileURL.path)")
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

