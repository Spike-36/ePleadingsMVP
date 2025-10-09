//
//  SentenceHighlightService.swift
//  ePleadingsMVP
//
//  Updated: 09/10/2025 —
//  • Added filters for short / heading text (Stage 4 ghost prevention)
//  • Added rect sanity checks
//  • Fixed filename predicate to match DOCX/PDF by base name
//

import Foundation
import PDFKit
import CoreData
import SwiftUI

final class SentenceHighlightService {

    static func applyHighlights(to pdfView: PDFView,
                                sourceFilename: String,
                                context: NSManagedObjectContext) {
        print("🟡 SentenceHighlightService: applying highlights for \(sourceFilename)")

        // ✅ Match by base filename (test.3.3.docx ↔ test.3.3.pdf)
        let baseName = (sourceFilename as NSString).deletingPathExtension
        let fetch: NSFetchRequest<SentenceEntity> = SentenceEntity.fetchRequest()
        fetch.predicate = NSPredicate(format: "sourceFilename BEGINSWITH[cd] %@", baseName)

        guard let sentences = try? context.fetch(fetch), !sentences.isEmpty else {
            print("⚠️ No mapped sentences found for \(sourceFilename)")
            return
        }

        let grouped = Dictionary(grouping: sentences, by: { Int($0.pageNumber) })
        var applied = 0
        var skipped = 0

        for (pageNum, items) in grouped {
            guard let page = pdfView.document?.page(at: pageNum - 1) else { continue }

            for sentence in items {
                let text = sentence.text.trimmingCharacters(in: .whitespacesAndNewlines)

                // 🟡 Skip junk or headings
                guard text.count >= 5 else {
                    skipped += 1
                    print("⚙️ Ignored short text: '\(text)'")
                    continue
                }

                if sentence.heading == nil,
                   text.range(of: #"^(statement|answer|cond|admit)[\s\d:\-]*$"#,
                              options: [.regularExpression, .caseInsensitive]) != nil {
                    skipped += 1
                    print("⚙️ Ignored heading-like text: '\(text)'")
                    continue
                }

                // ✅ Use multi-rect support
                let rects = sentence.rects.isEmpty
                    ? [CGRect(x: sentence.mappedX,
                              y: sentence.mappedY,
                              width: sentence.mappedWidth,
                              height: sentence.mappedHeight)]
                    : sentence.rects

                for rect in rects {
                    guard rect.width > 1, rect.height > 1,
                          rect.origin.x >= 0, rect.origin.y >= 0 else {
                        print("⚙️ Ignored invalid rect:", rect)
                        skipped += 1
                        continue
                    }

                    let annotation = PDFAnnotation(bounds: rect,
                                                   forType: .highlight,
                                                   withProperties: nil)
                    annotation.color = color(for: sentence.sentenceState)
                    annotation.contents = text
                    page.addAnnotation(annotation)
                    applied += 1
                }
            }

            print("✅ Applied \(applied) valid highlights on page \(pageNum)")
        }

        pdfView.setNeedsDisplay(pdfView.bounds)
        print("🔎 Highlight summary — applied: \(applied), skipped: \(skipped)")
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

