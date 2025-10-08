//
//  HeadingToPageMapper.swift
//  ePleadingsMVP
//

import Foundation
import PDFKit
import CoreData

/// Maps DOCX headings (stored under the DOCX DocumentEntity) to page numbers + bounding boxes in the matching PDF.
final class HeadingToPageMapper {

    private let context: NSManagedObjectContext
    private let pdfDocument: PDFDocument

    /// Failable init to avoid crashing if the PDF can’t be opened.
    init?(context: NSManagedObjectContext, pdfURL: URL) {
        guard let doc = PDFDocument(url: pdfURL) else {
            print("❌ Failed to open PDF at \(pdfURL.path)")
            return nil
        }
        self.context = context
        self.pdfDocument = doc
    }

    /// Map the provided headings using the already-opened PDF.
    /// (These headings should usually be from the DOCX DocumentEntity.)
    func mapHeadings(_ headings: [HeadingEntity]) {
        print("📑 Mapping \(headings.count) heading(s) across \(pdfDocument.pageCount) page(s).")

        var mappedCount = 0
        var notFoundCount = 0

        for heading in headings {
            guard let text = heading.text, !text.isEmpty else { continue }

            if let (pageIndex, bounds) = find(text: text) {
                heading.mappedPageNumber = Int32(pageIndex + 1) // 0-based → 1-based
                heading.mappedX = Double(bounds.origin.x)
                heading.mappedY = Double(bounds.origin.y)
                heading.mappedWidth = Double(bounds.width)
                heading.mappedHeight = Double(bounds.height)
                mappedCount += 1
                // 🔇 Verbose log removed:
                // print("✅ '\(text)' → page \(pageIndex + 1) @ \(bounds.integral)")
            } else {
                notFoundCount += 1
                // 🔇 Verbose log removed:
                // print("⚠️ Not found in PDF: '\(text)'")
            }
        }

        do {
            try context.save()
            print("💾 Saved heading mappings. ✅ \(mappedCount) mapped, ⚠️ \(notFoundCount) not found.")
        } catch {
            print("❌ Failed to save heading mappings: \(error)")
        }
    }

    /// Find the first page+bounds for the given text (case-insensitive) using PDFKit text content.
    private func find(text raw: String) -> (Int, CGRect)? {
        let needle = normalizeWhitespace(raw)

        for i in 0..<pdfDocument.pageCount {
            guard let page = pdfDocument.page(at: i),
                  let pageString = page.string else { continue }

            let haystack = normalizeWhitespace(pageString)

            if let range = haystack.range(of: needle, options: [.caseInsensitive]) {
                let ns = NSRange(range, in: haystack)
                if let sel = page.selection(for: ns) {
                    return (i, sel.bounds(for: page))
                }
            } else {
                // 🔇 Suppressed verbose "searching" logs
                // let snippet = haystack.prefix(200).replacingOccurrences(of: "\n", with: "⏎")
                // print("   [p\(i+1)] Searching for '\(needle)' not found in first 200 chars: \(snippet)…")
            }
        }
        return nil
    }

    /// Collapse all whitespace (spaces, tabs, newlines, NBSP, thin spaces) into single spaces
    private func normalizeWhitespace(_ s: String) -> String {
        let ws = CharacterSet.whitespacesAndNewlines
            .union(.init(charactersIn: "\u{00A0}\u{2000}\u{2001}\u{2002}\u{2003}\u{2009}"))

        let collapsed = s.unicodeScalars.map { ws.contains($0) ? " " : String($0) }.joined()
        return collapsed
            .replacingOccurrences(of: " +", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

