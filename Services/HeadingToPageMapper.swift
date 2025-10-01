//
//  HeadingToPageMapper.swift
//  ePleadingsMVP
//
//  Created by Peter Milligan on 29/09/2025.
//

import Foundation
import PDFKit
import CoreData

/// Maps DOCX headings stored in Core Data to actual PDF page numbers and bounding boxes.
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

    /// Run once per case load: assign PDF page numbers + bounding boxes to all headings.
    func mapHeadingsToPages() {
        let fetchRequest: NSFetchRequest<HeadingEntity> = HeadingEntity.fetchRequest()

        do {
            let headings = try context.fetch(fetchRequest)
            print("🔎 Mapping \(headings.count) headings to PDF pages")

            for heading in headings {
                guard let text = heading.text else { continue }

                if let result = findPageAndBounds(for: text) {
                    let pdfPageNumber = result.pageIndex + 1 // PDFKit is 0-based
                    let bounds = result.bounds

                    // 👉 Store results into Core Data
                    heading.mappedPageNumber = Int32(pdfPageNumber)
                    heading.mappedX = bounds.origin.x
                    heading.mappedY = bounds.origin.y
                    heading.mappedWidth = bounds.width
                    heading.mappedHeight = bounds.height

                    print("✅ Mapped heading '\(text)' → page \(pdfPageNumber) @ \(bounds)")
                } else {
                    print("⚠️ No match for heading '\(text)' in PDF")
                }
            }

            try context.save()
            print("💾 Saved mapped page numbers + bounding boxes to Core Data")
        } catch {
            print("❌ Failed mapping headings: \(error)")
        }
    }

    /// Find the first PDF page containing `headingText` and return both page index + bounding box.
    private func findPageAndBounds(for headingText: String) -> (pageIndex: Int, bounds: CGRect)? {
        for pageIndex in 0..<pdfDocument.pageCount {
            guard let page = pdfDocument.page(at: pageIndex),
                  let content = page.string else { continue }

            // Case-insensitive match
            if let range = content.range(of: headingText, options: [.caseInsensitive]) {
                let nsRange = NSRange(range, in: content)

                if let selection = page.selection(for: nsRange) {
                    let bounds = selection.bounds(for: page)

                    // Warn if multiple matches on same page
                    let matches = content.components(separatedBy: headingText).count - 1
                    if matches > 1 {
                        print("⚠️ Multiple matches for '\(headingText)' on page \(pageIndex + 1)")
                    }

                    return (pageIndex, bounds)
                } else {
                    // Page contains text but no bounding box
                    return (pageIndex, .zero)
                }
            }
        }
        return nil
    }
}

