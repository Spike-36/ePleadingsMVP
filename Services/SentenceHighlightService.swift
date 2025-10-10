//
//  SentenceHighlightService.swift
//  ePleadingsMVP
//
//  Updated: 10/10/2025 — Fix: No more stacked highlights
//  ✅ Clears any existing ePleadings highlights before re-adding
//  ✅ Tags new annotations (userName="ePleadingsHighlight")
//  ✅ Runs on main thread
//

import Foundation
import PDFKit
import CoreData
import SwiftUI

final class SentenceHighlightService {

    private static let tag = "ePleadingsHighlight"

    static func applyHighlights(to pdfView: PDFView,
                                for document: DocumentEntity,
                                context: NSManagedObjectContext) {

        let name = document.filename ?? "Unknown"
        Swift.print("🟡 SentenceHighlightService: applying highlights for \(name)")

        guard let pdfDoc = pdfView.document else {
            Swift.print("⚠️ No active PDF document in pdfView – cannot apply highlights.")
            return
        }

        // Ensure UI-thread operations for PDFKit
        if !Thread.isMainThread {
            DispatchQueue.main.sync {
                applyHighlights(to: pdfView, for: document, context: context)
            }
            return
        }

        // Fetch just this document's sentences
        let fetch: NSFetchRequest<SentenceEntity> = SentenceEntity.fetchRequest()
        fetch.predicate = NSPredicate(format: "document == %@", document)

        guard let sentences = try? context.fetch(fetch), !sentences.isEmpty else {
            Swift.print("⚠️ No mapped sentences found for \(name)")
            // Still clear any leftovers to be safe
            clearAllEpleadingsHighlights(in: pdfDoc)
            return
        }

        // 1) Clear any previous ePleadings highlights (and any 'Highlight' subtype as a safety net)
        let removed = clearAllEpleadingsHighlights(in: pdfDoc)
        if removed > 0 { Swift.print("🧹 Cleared \(removed) old highlights (all pages)") }

        // 2) Re-add current highlights
        let grouped = Dictionary(grouping: sentences, by: { Int($0.pageNumber) })
        var totalApplied = 0
        var totalSkipped = 0

        for (pageNum, items) in grouped.sorted(by: { $0.key < $1.key }) {
            guard let page = pdfDoc.page(at: pageNum - 1) else { continue }
            var pageApplied = 0

            for sentence in items {
                let text = sentence.text.trimmingCharacters(in: .whitespacesAndNewlines)
                guard text.count >= 5 else { totalSkipped += 1; continue }

                if sentence.heading == nil,
                   text.range(of: #"^(statement|answer|cond|admit)[\s\d:\-]*$"#,
                              options: [.regularExpression, .caseInsensitive]) != nil {
                    totalSkipped += 1
                    continue
                }

                let rects = sentence.rects.isEmpty
                    ? [CGRect(x: sentence.mappedX, y: sentence.mappedY,
                              width: sentence.mappedWidth, height: sentence.mappedHeight)]
                    : sentence.rects

                for rect in rects {
                    guard rect.width > 1, rect.height > 1,
                          rect.origin.x >= 0, rect.origin.y >= 0 else {
                        totalSkipped += 1; continue
                    }

                    let ann = PDFAnnotation(bounds: rect, forType: .highlight, withProperties: nil)
                    ann.userName = tag                      // 🔖 tag it so we can find & remove next time
                    ann.color = color(for: sentence.sentenceState)
                    ann.contents = text
                    page.addAnnotation(ann)

                    totalApplied += 1
                    pageApplied += 1
                }
            }

            Swift.print("✅ Applied \(pageApplied) valid highlights on page \(pageNum)")
        }

        pdfView.setNeedsDisplay(pdfView.bounds)
        Swift.print("🔎 Highlight summary — applied: \(totalApplied), skipped: \(totalSkipped)")
    }

    // Hard clear everything we previously added (plus any 'Highlight' subtype to be extra safe)
    private static func clearAllEpleadingsHighlights(in pdfDoc: PDFDocument) -> Int {
        var removed = 0
        for i in 0..<pdfDoc.pageCount {
            guard let page = pdfDoc.page(at: i) else { continue }
            // Take a copy before removing
            let toRemove = page.annotations.filter {
                // remove anything we created OR any 'Highlight' subtype (in case old runs weren't tagged)
                ($0.userName == tag) || ($0.type == PDFAnnotationSubtype.highlight.rawValue)
            }
            toRemove.forEach { page.removeAnnotation($0) }
            removed += toRemove.count
        }
        return removed
    }

    // MARK: - Color Mapping
    private static func color(for state: SentenceEntity.SentenceState) -> NSColor {
        switch state {
        case .admitted:     return NSColor.systemGreen.withAlphaComponent(0.3)
        case .denied:       return NSColor.systemRed.withAlphaComponent(0.3)
        case .notKnown:     return NSColor.systemYellow.withAlphaComponent(0.3)
        case .unclassified: return .clear
        @unknown default:   return .clear
        }
    }
}

