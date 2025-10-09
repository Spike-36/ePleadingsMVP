//
//  SentenceHighlightService.swift
//  ePleadingsMVP
//
//  Updated: 09/10/2025 —
//  • Removed redundant case parameter (now uses document→case relationship)
//  • Keeps rect sanity + short-text filters
//

import Foundation
import PDFKit
import CoreData
import SwiftUI

final class SentenceHighlightService {

    // 🔄 Removed `for caseEntity` parameter — no longer needed
    static func applyHighlights(to pdfView: PDFView,
                                sourceFilename: String,
                                context: NSManagedObjectContext) {
        print("🟡 SentenceHighlightService: applying highlights for \(sourceFilename)")

        // ✅ Match by base filename (test.3.3.docx ↔ test.3.3.pdf)
        let baseName = (sourceFilename as NSString).deletingPathExtension
        let fetch: NSFetchRequest<SentenceEntity> = SentenceEntity.fetchRequest()

        // 🔄 Predicate simplified — we rely on document→caseEntity relationship now
        fetch.predicate = NSPredicate(
            format: "sourceFilename BEGINSWITH[cd] %@", baseName
        )

        guard let sentences = try? context.fetch(fetch), !sentences.isEmpty else {
            print("⚠️ No mapped sentences found for \(sourceFilename)")
            return
        }

        // ✅ Group by page for batch drawing
        let grouped = Dictionary(grouping: sentences, by: { Int($0.pageNumber) })
        var totalApplied = 0
        var totalSkipped = 0

        for (pageNum, items) in grouped.sorted(by: { $0.key < $1.key }) {
            guard let page = pdfView.document?.page(at: pageNum - 1) else { continue }
            var pageApplied = 0

            for sentence in items {
                let text = sentence.text.trimmingCharacters(in: .whitespacesAndNewlines)

                // 🟡 Skip junk or headings
                guard text.count >= 5 else {
                    totalSkipped += 1
                    continue
                }
                if sentence.heading == nil,
                   text.range(of: #"^(statement|answer|cond|admit)[\s\d:\-]*$"#,
                              options: [.regularExpression, .caseInsensitive]) != nil {
                    totalSkipped += 1
                    continue
                }

                // ✅ Use multi-rect support with sanity check
                let rects = sentence.rects.isEmpty
                    ? [CGRect(x: sentence.mappedX,
                              y: sentence.mappedY,
                              width: sentence.mappedWidth,
                              height: sentence.mappedHeight)]
                    : sentence.rects

                for rect in rects {
                    guard rect.width > 1, rect.height > 1,
                          rect.origin.x >= 0, rect.origin.y >= 0 else {
                        totalSkipped += 1
                        continue
                    }

                    let annotation = PDFAnnotation(bounds: rect,
                                                   forType: .highlight,
                                                   withProperties: nil)
                    annotation.color = color(for: sentence.sentenceState)
                    annotation.contents = text
                    page.addAnnotation(annotation)

                    totalApplied += 1
                    pageApplied += 1
                }
            }

            print("✅ Applied \(pageApplied) valid highlights on page \(pageNum)")
        }

        pdfView.setNeedsDisplay(pdfView.bounds)
        print("🔎 Highlight summary — applied: \(totalApplied), skipped: \(totalSkipped)")
    }

    // MARK: - Color Mapping
    private static func color(for state: SentenceEntity.SentenceState) -> NSColor {
        switch state {
        case .admitted:     return NSColor.systemGreen.withAlphaComponent(0.3)
        case .denied:       return NSColor.systemRed.withAlphaComponent(0.3)
        case .notKnown:     return NSColor.systemYellow.withAlphaComponent(0.3)
        case .unclassified: return .clear
        }
    }
}

