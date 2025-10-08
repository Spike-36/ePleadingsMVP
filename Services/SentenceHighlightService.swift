//
//  SentenceHighlightService.swift
//  ePleadingsMVP
//
//  Created by Peter Milligan on 07/10/2025.
//  Updated 08/10/2025: multi-rect support for precise sentence highlights.
//

import Foundation
import PDFKit
import CoreData
import SwiftUI

/// Applies colored highlights to PDF pages based on SentenceEntity mappings.
final class SentenceHighlightService {

    /// Adds highlights to the given PDFView for a specific document filename.
    static func applyHighlights(to pdfView: PDFView,
                                sourceFilename: String,
                                context: NSManagedObjectContext) {
        Swift.print("🟡 SentenceHighlightService: applying highlights for \(sourceFilename)")

        // ✅ Fetch all mapped sentences for this file
        let fetch: NSFetchRequest<SentenceEntity> = SentenceEntity.fetchRequest()
        fetch.predicate = NSPredicate(format: "sourceFilename == %@", sourceFilename)

        guard let sentences = try? context.fetch(fetch), !sentences.isEmpty else {
            Swift.print("⚠️ No mapped sentences found for \(sourceFilename)")
            return
        }

        // ✅ Group by page for efficiency
        let grouped = Dictionary(grouping: sentences, by: { Int($0.pageNumber) })

        for (pageNum, items) in grouped {
            guard let page = pdfView.document?.page(at: pageNum - 1) else { continue }

            for sentence in items {
                // Skip unclassified (no gray boxes)
                if sentence.sentenceState == .unclassified { continue }

                // 👉 Use multiple rects if available, fallback to single
                let rects = sentence.rects.isEmpty
                    ? [CGRect(x: sentence.mappedX,
                              y: sentence.mappedY,
                              width: sentence.mappedWidth,
                              height: sentence.mappedHeight)]
                    : sentence.rects

                for rect in rects {
                    let annotation = PDFAnnotation(bounds: rect,
                                                   forType: .highlight,
                                                   withProperties: nil)
                    annotation.color = color(for: sentence.sentenceState)
                    annotation.contents = sentence.text
                    page.addAnnotation(annotation)
                }
            }

            Swift.print("✅ Applied \(items.count) sentence highlights on page \(pageNum)")
        }

        pdfView.setNeedsDisplay(pdfView.bounds)
    }

    // MARK: - Color Mapping
    private static func color(for state: SentenceEntity.SentenceState) -> NSColor {
        switch state {
        case .admitted:
            return NSColor.systemGreen.withAlphaComponent(0.3)
        case .denied:
            return NSColor.systemRed.withAlphaComponent(0.3)
        case .notKnown:
            return NSColor.systemYellow.withAlphaComponent(0.3)
        case .unclassified:
            return .clear // ✅ no gray debug boxes
        }
    }
}

// MARK: - PDFView Extension for Live Refresh
extension PDFView {

    /// Removes all old highlights and reapplies new ones from Core Data.
    func refreshHighlights(for sourceFilename: String, context: NSManagedObjectContext) {
        guard let document = self.document else { return }

        // 🔄 Remove existing highlight annotations
        for i in 0 ..< document.pageCount {
            guard let page = document.page(at: i) else { continue }
            let oldHighlights = page.annotations.filter {
                $0.type == PDFAnnotationSubtype.highlight.rawValue
            }
            oldHighlights.forEach { page.removeAnnotation($0) }
        }

        // 🟢 Reapply highlights
        SentenceHighlightService.applyHighlights(to: self,
                                                 sourceFilename: sourceFilename,
                                                 context: context)

        Swift.print("🔁 PDFView highlights refreshed for \(sourceFilename)")
    }
}

