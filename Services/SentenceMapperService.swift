//
//  SentenceMapperService.swift
//  ePleadingsMVP
//
//  Updated: 10/10/2025 — Diagnostic logging added
//  • Logs every mapped rect’s coordinates for each sentence
//  • Prints PDF page coordinate ranges for quick sanity checks
//

import Foundation
import PDFKit
import CoreData
import CoreGraphics

final class SentenceMapperService {

    func mapSentences(in document: DocumentEntity, using context: NSManagedObjectContext) {
        let docName = document.filename ?? "Unknown Document"
        print("📄 Starting SentenceMapper for \(docName)")

        guard let path = document.filePath,
              let pdfDoc = PDFDocument(url: URL(fileURLWithPath: path)) else {
            print("❌ SentenceMapper: Unable to open PDF for \(docName)")
            return
        }

        let baseName = (document.filename as NSString?)?.deletingPathExtension ?? (document.filename ?? "")
        let fetchRequest: NSFetchRequest<SentenceEntity> = SentenceEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "sourceFilename BEGINSWITH[cd] %@", baseName)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "orderIndex", ascending: true)]

        guard let existingSentences = try? context.fetch(fetchRequest), !existingSentences.isEmpty else {
            print("⚠️ No existing sentences found to map for \(docName)")
            return
        }

        print("🔎 Loaded \(existingSentences.count) existing sentences to map for \(docName).")

        var mappedCount = 0

        for pageIndex in 0..<pdfDoc.pageCount {
            guard let page = pdfDoc.page(at: pageIndex),
                  let pageText = page.string, !pageText.isEmpty else { continue }

            let pageBounds = page.bounds(for: .mediaBox)
            print("📏 Page \(pageIndex + 1) bounds: \(pageBounds)")

            for sentence in existingSentences {
                let text = sentence.text.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !text.isEmpty else { continue }

                // 🧩 Skip headings and fragments
                guard text.count > 4 else {
                    print("⚙️ Skipped too-short text: '\(text)'")
                    continue
                }
                if text.range(of: #"^(statement|answer|cond|admit)[\s\d:\-]*$"#,
                              options: [.regularExpression, .caseInsensitive]) != nil {
                    print("⚙️ Skipped heading-like text: '\(text)'")
                    continue
                }

                if let range = pageText.range(of: text) {
                    let nsRange = NSRange(range, in: pageText)
                    if let selection = page.selection(for: nsRange) {
                        let rects = selection.selectionsByLine().map { $0.bounds(for: page) }
                        guard !rects.isEmpty else { continue }

                        sentence.pageNumber = Int32(pageIndex + 1)
                        sentence.rects = rects

                        if let first = rects.first {
                            sentence.mappedX = Double(first.origin.x)
                            sentence.mappedY = Double(first.origin.y)
                            sentence.mappedWidth = Double(first.size.width)
                            sentence.mappedHeight = Double(first.size.height)
                        }

                        sentence.document = document
                        mappedCount += 1

                        // 🧾 Diagnostic printout
                        for (i, r) in rects.enumerated() {
                            print("🧩 [Page \(pageIndex + 1)] '\(text.prefix(30))…' rect[\(i)]: x=\(r.origin.x.rounded()), y=\(r.origin.y.rounded()), w=\(r.width.rounded()), h=\(r.height.rounded())")
                        }
                    }
                }
            }
        }

        do {
            if context.hasChanges { try context.save() }
            let caseLabel = document.caseEntity?.filename ?? "—"
            print("💾 SentenceMapper: \(mappedCount) sentences updated for '\(docName)' (case: \(caseLabel)).")
        } catch {
            print("❌ SentenceMapper error: \(error)")
        }
    }
}

