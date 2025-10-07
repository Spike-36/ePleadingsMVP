//
//  SentenceHighlightService.swift
//  ePleadingsMVP
//
//  Created by Peter Milligan on 07/10/2025.
//
//
//  SentenceHighlightService.swift
//  ePleadingsMVP
//
//  Created by Peter Milligan on 07/10/2025.
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
        print("🟡 SentenceHighlightService: applying highlights for \(sourceFilename)")

        // ✅ Fetch all mapped sentences for this file
        let fetch: NSFetchRequest<SentenceEntity> = SentenceEntity.fetchRequest()
        fetch.predicate = NSPredicate(format: "sourceFilename == %@", sourceFilename)

        guard let sentences = try? context.fetch(fetch), !sentences.isEmpty else {
            print("⚠️ No mapped sentences found for \(sourceFilename)")
            return
        }

        // ✅ Group by page for efficiency
        let grouped = Dictionary(grouping: sentences, by: { Int($0.pageNumber) })

        for (pageNum, items) in grouped {
            guard let page = pdfView.document?.page(at: pageNum - 1) else { continue }

            for sentence in items {
                let rect = CGRect(
                    x: sentence.mappedX,
                    y: sentence.mappedY,
                    width: sentence.mappedWidth,
                    height: sentence.mappedHeight
                )

                let annotation = PDFAnnotation(bounds: rect,
                                               forType: .highlight,
                                               withProperties: nil)
                annotation.color = color(for: sentence.sentenceState)
                annotation.contents = sentence.text

                page.addAnnotation(annotation)
            }

            print("✅ Applied \(items.count) highlights on page \(pageNum)")
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
            return NSColor.systemGray.withAlphaComponent(0.2)
        }
    }
}

