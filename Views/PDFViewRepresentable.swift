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
    @Binding var selectedHeading: HeadingEntity?
    
    func makeNSView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.document = PDFDocument(url: url)
        return pdfView
    }

    func updateNSView(_ pdfView: PDFView, context: Context) {
        guard let heading = selectedHeading,
              let doc = pdfView.document,
              heading.mappedPageNumber > 0 else { return }
        
        let pageIndex = Int(heading.mappedPageNumber - 1) // CoreData stores 1-based
        guard let page = doc.page(at: pageIndex) else { return }
        
        let bounds = CGRect(
            x: heading.mappedX,
            y: heading.mappedY,
            width: heading.mappedWidth,
            height: heading.mappedHeight
        )
        
        // 🔎 Scroll to region
        pdfView.go(to: bounds, on: page)
        
        // ✅ Remove old temp annotations first
        page.annotations
            .filter { $0.userName == "HeadingHighlight" }
            .forEach { page.removeAnnotation($0) }
        
        // ✅ Add a translucent yellow overlay box
        let highlight = PDFAnnotation(
            bounds: bounds,
            forType: .highlight,
            withProperties: nil
        )
        highlight.color = NSColor.systemYellow.withAlphaComponent(0.4)
        highlight.userName = "HeadingHighlight"
        page.addAnnotation(highlight)
        
        // ✅ Auto-remove after 2 seconds for a “flash” effect
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            page.removeAnnotation(highlight)
        }
    }
}

