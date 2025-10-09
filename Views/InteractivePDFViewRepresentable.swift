//
//  InteractivePDFViewRepresentable.swift
//  ePleadingsMVP
//
//  Created by Peter Milligan on 07/10/2025.
//  Updated: 09/10/2025 — Fixed compile errors, removed redundant case parameter, and ensured safe AppKit color usage.
//

import SwiftUI
import PDFKit
import CoreData

struct InteractivePDFViewRepresentable: NSViewRepresentable {
    let url: URL?
    let context: NSManagedObjectContext
    let caseEntity: CaseEntity   // ✅ active case reference (kept for future use if needed)

    func makeNSView(context: Context) -> PDFView {
        let pdfView = InteractivePDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displaysAsBook = false
        pdfView.displayDirection = .vertical

        // ✅ AppKit-safe background color
        pdfView.backgroundColor = NSColor.controlBackgroundColor

        // Inject Core Data context
        pdfView.managedObjectContext = self.context

        // Load PDF if available
        if let url = self.url {
            pdfView.document = PDFDocument(url: url)
            let filename = url.lastPathComponent

            // 🔄 Updated — removed obsolete `for:` argument
            SentenceHighlightService.applyHighlights(
                to: pdfView,
                sourceFilename: filename,
                context: self.context
            )
        }

        // Attach click handlers
        pdfView.onRightClick = { pageNumber, point in
            context.coordinator.handleRightClick(pageNumber: pageNumber, point: point)
        }

        pdfView.onLeftClick = { pageNumber, point in
            context.coordinator.handleLeftClick(pageNumber: pageNumber, point: point)
        }

        return pdfView
    }

    func updateNSView(_ nsView: PDFView, context: Context) {
        // No dynamic updates required yet
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // MARK: - Coordinator
    class Coordinator {
        var parent: InteractivePDFViewRepresentable

        init(_ parent: InteractivePDFViewRepresentable) {
            self.parent = parent
        }

        func handleRightClick(pageNumber: Int, point: CGPoint) {
            Swift.print("🖱️ Right click on page \(pageNumber) at \(point)")
        }

        func handleLeftClick(pageNumber: Int, point: CGPoint) {
            Swift.print("🖱️ Left click on page \(pageNumber) at \(point)")
        }
    }
}

