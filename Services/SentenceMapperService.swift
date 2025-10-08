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
        let docName = document.filename ?? "Unknown Document"
        print("📄 Starting SentenceMapper for \(docName)")

        // ✅ Open the PDF for this document
        guard let path = document.filePath,
              let pdfDoc = PDFDocument(url: URL(fileURLWithPath: path)) else {
            print("❌ SentenceMapper: Unable to open PDF for \(docName)")
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

            // ✅ For each sentence, attempt to locate its bounding boxes
            for sentenceText in sentences {
                guard let range = pageText.range(of: sentenceText) else { continue }
                let nsRange = NSRange(range, in: pageText)
                guard let selection = page.selection(for: nsRange) else { continue }

                // 🟩 Multi-line bounding boxes
                let lineSelections = selection.selectionsByLine()
                let rects = lineSelections.map { $0.bounds(for: page) }
                guard !rects.isEmpty else { continue }

                // ✅ Create and populate a new SentenceEntity
                let sentence = SentenceEntity(context: context)
                sentence.id = UUID()
                sentence.text = sentenceText
                sentence.pageNumber = Int32(pageIndex + 1)
                sentence.sourceFilename = document.filename
                sentence.document = document  // ← link only to the document

                // 🟢 Store all rectangles in Core Data
                sentence.rects = rects

                // 🧩 Keep first rect for legacy single-rect compatibility
                if let first = rects.first {
                    sentence.mappedX = Double(first.origin.x)
                    sentence.mappedY = Double(first.origin.y)
                    sentence.mappedWidth = Double(first.size.width)
                    sentence.mappedHeight = Double(first.size.height)
                }

                mappedCount += 1
                print("✅ Mapped sentence (\(rects.count) rects) on page \(sentence.pageNumber) in '\(docName)': \(sentenceText.prefix(40))…")
            }
        }

        // ✅ Save mapped sentences
        do {
            if context.hasChanges {
                try context.save()
            }
            let caseLabel = document.caseEntity?.filename ?? "—"
            print("💾 SentenceMapper: \(mappedCount) sentences saved for '\(docName)' (case: \(caseLabel)).")
        } catch {
            print("❌ SentenceMapper error: \(error)")
        }
    }
}

