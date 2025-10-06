//
//  SentenceMapper.swift
//  ePleadingsMVP
//
//  Created by Peter Milligan on 06/10/2025.
//

import Foundation
import PDFKit
import CoreData
import CoreGraphics

/// Responsible for mapping sentence bounding boxes from a PDF into Core Data
final class SentenceMapper {

    /// Maps sentence regions into Core Data by extracting bounding boxes from PDF text selections
    func mapSentences(in document: DocumentEntity, using context: NSManagedObjectContext) {
        print("📄 Starting SentenceMapper for \(document.filename)")

        // ✅ Use existing filePath and filename attributes
        guard let path = document.filePath,
              let pdfDoc = PDFDocument(url: URL(fileURLWithPath: path)) else {
            print("❌ SentenceMapper: Unable to open PDF for \(document.filename)")
            return
        }

        var mappedCount = 0

        // Iterate over all pages
        for pageIndex in 0..<pdfDoc.pageCount {
            guard let page = pdfDoc.page(at: pageIndex),
                  let pageText = page.string, !pageText.isEmpty else { continue }

            // Split text into sentences by punctuation
            let sentences = pageText
                .split(whereSeparator: { [".", "!", "?"].contains($0) })
                .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }

            for sentenceText in sentences {
                // ✅ Use PDFDocument.findString instead of non-existent page.selection(for:)
                guard let selection = pdfDoc.findString(sentenceText, withOptions: [.caseInsensitive])
                        .first(where: { $0.pages.contains(page) }) else {
                    continue
                }

                // Combine all bounding boxes of the selection for this page
                let unionRect = selection.bounds(for: page)

                let sentence = SentenceEntity(context: context)
                sentence.id = UUID()
                sentence.text = sentenceText
                sentence.pageNumber = Int32(pageIndex + 1)
                sentence.mappedX = Double(unionRect.origin.x)
                sentence.mappedY = Double(unionRect.origin.y)
                sentence.mappedWidth = Double(unionRect.size.width)
                sentence.mappedHeight = Double(unionRect.size.height)
                sentence.sourceFilename = document.filename
                sentence.document = document

                mappedCount += 1
                print("✅ Mapped sentence @ page \(sentence.pageNumber) rect \(unionRect)")
            }
        }

        do {
            try context.save()
            print("💾 SentenceMapper: \(mappedCount) sentences mapped and saved.")
        } catch {
            print("❌ SentenceMapper error: \(error)")
        }
    }
}

