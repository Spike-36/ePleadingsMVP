//
//  SentenceMapperService.swift
//  ePleadingsMVP
//
//  Created by Peter Milligan on 06/10/2025.
//

import Foundation
import PDFKit
import CoreData
import CoreGraphics

/// Maps sentence regions into Core Data by extracting bounding boxes from the PDF.
final class SentenceMapperService {

    /// Finds and records bounding boxes for each sentence belonging to a given document.
    func mapSentences(in document: DocumentEntity, using context: NSManagedObjectContext) {
        print("📄 Starting SentenceMapper for \(document.filename)")

        // ✅ Open the PDF for this document
        guard let path = document.filePath,
              let pdfDoc = PDFDocument(url: URL(fileURLWithPath: path)) else {
            print("❌ SentenceMapper: Unable to open PDF for \(document.filename)")
            return
        }

        var mappedCount = 0

        // ✅ Iterate through each page
        for pageIndex in 0..<pdfDoc.pageCount {
            guard let page = pdfDoc.page(at: pageIndex),
                  let pageText = page.string, !pageText.isEmpty else {
                continue
            }

            // ✅ Split text into sentences by punctuation
            let sentences = pageText
                .split(whereSeparator: { [".", "!", "?"].contains($0) })
                .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }

            // ✅ For each sentence, attempt to locate its bounding box
            for sentenceText in sentences {
                guard let range = pageText.range(of: sentenceText) else { continue }

                // Create a PDFSelection for this text range
                let nsRange = NSRange(range, in: pageText)
                guard let selection = page.selection(for: nsRange) else { continue }

                // Get the bounding box for the selection on this page
                let rect = selection.bounds(for: page)

                // ✅ Create and populate a new SentenceEntity
                let sentence = SentenceEntity(context: context)
                sentence.id = UUID()
                sentence.text = sentenceText
                sentence.pageNumber = Int32(pageIndex + 1)
                sentence.mappedX = Double(rect.origin.x)
                sentence.mappedY = Double(rect.origin.y)
                sentence.mappedWidth = Double(rect.size.width)
                sentence.mappedHeight = Double(rect.size.height)
                sentence.sourceFilename = document.filename
                sentence.document = document

                mappedCount += 1
                print("✅ Mapped sentence on page \(sentence.pageNumber): \(sentenceText.prefix(40))…")
            }
        }

        // ✅ Save mapped sentences
        do {
            try context.save()
            print("💾 SentenceMapper: \(mappedCount) sentences mapped and saved.")
        } catch {
            print("❌ SentenceMapper error: \(error)")
        }
    }
}

