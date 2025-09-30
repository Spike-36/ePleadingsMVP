//
//  PDFViewRepresentable.swift
//  ePleadingsMVP
//
//  Created by Peter Milligan on 26/09/2025.
//

import SwiftUI
import PDFKit

/// A SwiftUI wrapper around PDFKit’s PDFView (macOS version)
struct PDFViewRepresentable: NSViewRepresentable {
    let url: URL
    @Binding var selectedPage: Int?

    func makeNSView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.document = PDFDocument(url: url)
        return pdfView
    }

    func updateNSView(_ pdfView: PDFView, context: Context) {
        // 🔄 Apply 1-based → 0-based fix for Core Data page numbers
        if let pageIndex = selectedPage,
           pageIndex > 0,  // ✅ guard against negative indexes
           let page = pdfView.document?.page(at: pageIndex - 1) {
            pdfView.go(to: page)
        }
    }
}

