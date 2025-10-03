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

        for heading in headings {
            guard let text = heading.text, !text.isEmpty else { continue }

            if let (pageIndex, bounds) = find(text: text) {
                heading.mappedPageNumber = Int32(pageIndex + 1) // 0-based → 1-based
                heading.mappedX = Double(bounds.origin.x)
                heading.mappedY = Double(bounds.origin.y)
                heading.mappedWidth = Double(bounds.width)
                heading.mappedHeight = Double(bounds.height)
                print("✅ '\(text)' → page \(pageIndex + 1) @ \(bounds.integral)")
            } else {
                // Leave existing values; just log not found
                print("⚠️ Not found in PDF: '\(text)'")
            }
        }

        do {
            try context.save()
            print("💾 Saved heading mappings.")
        } catch {
            print("❌ Failed to save heading mappings: \(error)")
        }
    }

    /// Find the first page+bounds for the given text (case-insensitive) using PDFKit text content.
    private func find(text raw: String) -> (Int, CGRect)? {
        // Normalize a little (helps with trailing spaces etc.)
        let needle = raw.trimmingCharacters(in: .whitespacesAndNewlines)

        for i in 0..<pdfDocument.pageCount {
            guard let page = pdfDocument.page(at: i),
                  let pageString = page.string else { continue }

            if let range = pageString.range(of: needle, options: [.caseInsensitive]) {
                let ns = NSRange(range, in: pageString)
                if let sel = page.selection(for: ns) {
                    return (i, sel.bounds(for: page))
                }
            }
        }
        return nil
    }
}

