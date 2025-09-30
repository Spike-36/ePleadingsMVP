//
//  HeadingToPageMapper.swift
//  ePleadingsMVP
//
//  Created by Peter Milligan on 29/09/2025.
//

import Foundation
import PDFKit
import CoreData

/// Maps DOCX headings stored in Core Data to actual PDF page numbers.
final class HeadingToPageMapper {

    private let context: NSManagedObjectContext
    private let pdfDocument: PDFDocument

    init(context: NSManagedObjectContext, pdfURL: URL) {
        self.context = context
        guard let doc = PDFDocument(url: pdfURL) else {
            fatalError("❌ Failed to load PDF at \(pdfURL)")
        }
        self.pdfDocument = doc
    }

    /// Run once per case load: try to assign real PDF page numbers to all headings.
    func mapHeadingsToPages() {
        let fetchRequest: NSFetchRequest<HeadingEntity> = HeadingEntity.fetchRequest()

        do {
            let headings = try context.fetch(fetchRequest)
            print("🔎 Mapping \(headings.count) headings to PDF pages")

            for heading in headings {
                guard let text = heading.text else { continue }

                // 🧪 Stage 1 sanity check — confirm new Core Data fields are accessible
                print("🧪 Bounding box fields for '\(text)' →",
                      heading.mappedX,
                      heading.mappedY,
                      heading.mappedWidth,
                      heading.mappedHeight)

                if let pageIndex = findPageIndex(for: text) {
                    let pdfPageNumber = pageIndex + 1 // PDFKit is 0-based

                    // 👉 Actually store the mapped page number into Core Data
                    heading.mappedPageNumber = Int32(pdfPageNumber)

                    print("✅ Mapped heading '\(text)' → PDF page \(pdfPageNumber)")
                } else {
                    print("⚠️ No match for heading '\(text)' in PDF")
                }
            }

            try context.save()
            print("💾 Saved mapped page numbers to Core Data")
        } catch {
            print("❌ Failed mapping headings: \(error)")
        }
    }

    /// Search the PDF text for the first occurrence of a heading.
    private func findPageIndex(for headingText: String) -> Int? {
        for pageIndex in 0..<pdfDocument.pageCount {
            guard let page = pdfDocument.page(at: pageIndex),
                  let content = page.string else { continue }

            // Case-insensitive match to handle "Answer 4" vs "ANSWER 4"
            if let _ = content.range(of: headingText, options: [.caseInsensitive]) {
                // Count matches on this page for logging
                let matches = content.components(separatedBy: headingText).count - 1
                if matches > 1 {
                    print("⚠️ Multiple matches for '\(headingText)' on page \(pageIndex + 1)")
                }
                return pageIndex
            }
        }
        return nil
    }
}

