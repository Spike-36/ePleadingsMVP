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

            // Simple contains check; later can improve with regex for line breaks etc.
            if content.contains(headingText) {
                return pageIndex
            }
        }
        return nil
    }
}

