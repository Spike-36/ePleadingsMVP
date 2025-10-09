//
//  SentenceParserService.swift
//  ePleadingsMVP
//
//  Created by Peter Milligan on 09/10/2025.
//
//  SentenceParserService.swift
//  ePleadingsMVP
//
//  Purpose: Extract real sentences from DOCX paragraphs, attach them to both
//  the DocumentEntity and (when applicable) the current HeadingEntity.
//  Assign a document-wide continuous orderIndex. Skip heading lines & junk.
//
//  Created by ChatGPT on request of Pete.
//

import Foundation
import CoreData

final class SentenceParserService {
    private let parser = DocxParser()

    /// Extract sentences for a DOCX-backed DocumentEntity.
    /// - Important: Assumes headings have already been created for this document
    ///   by DocxParserService.extractHeadings(...).
    func extractSentences(for document: DocumentEntity,
                          in context: NSManagedObjectContext,
                          callID: String? = nil) throws {
        let tag = callID ?? "∅"

        guard let path = document.filePath else {
            throw NSError(domain: "SentenceParserService", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Document has no filePath"])
        }
        let url = URL(fileURLWithPath: path)
        guard url.pathExtension.lowercased() == "docx" else {
            print("⚠️ [\(tag)] SentenceParserService: Not a DOCX: \(url.lastPathComponent)")
            return
        }

        // 0) Remove any old sentences for this document (clean re-import)
        do {
            let fetch: NSFetchRequest<SentenceEntity> = SentenceEntity.fetchRequest()
            fetch.predicate = NSPredicate(format: "document == %@", document)
            let old = try context.fetch(fetch)
            if !old.isEmpty {
                old.forEach { context.delete($0) }
                print("🗑️ [\(tag)] Deleted \(old.count) existing sentence(s) for \(document.filename ?? "?")")
            }
        } catch {
            print("⚠️ [\(tag)] Failed to purge old sentences: \(error)")
        }

        // 1) Load paragraphs from DOCX
        let paragraphs = try parser.parseDocx(at: url)
        if paragraphs.isEmpty {
            print("⚠️ [\(tag)] No paragraphs found in \(url.lastPathComponent)")
            try context.save()
            return
        }

        // 2) Fetch existing headings (created earlier by DocxParserService)
        let headingFetch: NSFetchRequest<HeadingEntity> = HeadingEntity.fetchRequest()
        headingFetch.predicate = NSPredicate(format: "document == %@", document)
        headingFetch.sortDescriptors = [NSSortDescriptor(keyPath: \HeadingEntity.orderIndex, ascending: true)]
        let headings = try context.fetch(headingFetch)

        // Index headings by their short label text (e.g., "Stat. 2", "Ans. 2") in order.
        var headingCursor = 0
        var currentHeading: HeadingEntity? = nil

        // 3) Walk paragraphs; when a heading line is seen, advance heading context;
        //    otherwise create sentence records for non-heading text.
        var globalOrder: Int32 = 0
        var createdCount = 0

        for para in paragraphs {
            switch HeadingClassifier.classify(para) {
            case .statement, .answer:
                // Advance heading context using detected label
                if let label = HeadingClassifier.extractLabel(para) {
                    // Prefer exact next heading in order if it matches label
                    if headingCursor < headings.count {
                        let candidate = headings[headingCursor]
                        if (candidate.text ?? "").caseInsensitiveCompare(label) == .orderedSame {
                            currentHeading = candidate
                            headingCursor += 1
                            continue
                        }
                    }
                    // Fallback: try to find by text match anywhere
                    if let found = headings.first(where: { ($0.text ?? "").caseInsensitiveCompare(label) == .orderedSame }) {
                        currentHeading = found
                    } else {
                        // If no heading exists (unexpected), clear context so we don't attach wrongly
                        print("⚠️ [\(tag)] Heading label '\(label)' not found among persisted headings.")
                        currentHeading = nil
                    }
                } else {
                    currentHeading = nil
                }

            case .misc:
                // Create one-or-more sentences from the paragraph text (basic split).
                // Keep it conservative: we split on terminal punctuation followed by space.
                // We deliberately avoid fancy NLP here to reduce false splits.
                let parts = Self.splitIntoSentences(para)
                for raw in parts {
                    let clean = raw.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard clean.count >= 5 else { continue } // skip trivial tokens

                    let s = SentenceEntity(context: context)
                    s.id = UUID()
                    s.text = clean
                    s.document = document
                    s.heading = currentHeading        // may be nil if outside any heading
                    s.orderIndex = globalOrder
                    s.sourceFilename = document.filename
                    s.state = "new"

                    // zero-init mapped geometry; mapper will fill later
                    s.mappedX = 0
                    s.mappedY = 0
                    s.mappedWidth = 0
                    s.mappedHeight = 0
                    s.rectsData = nil

                    globalOrder += 1
                    createdCount += 1
                }
            }
        }

        try context.save()
        print("✅ [\(tag)] SentenceParserService: Created \(createdCount) sentence(s) for \(document.filename ?? "?"), orderIndex 0...\(max(0, Int(globalOrder) - 1)).")
    }

    // MARK: - Minimal sentence splitter
    // Splits on . ? ! followed by space or end-of-string. Keeps abbreviations largely intact because we don't split on '.' when next char is a digit/letter without space.
    private static func splitIntoSentences(_ paragraph: String) -> [String] {
        var results: [String] = []
        var buffer = ""
        var prev: Character?

        for ch in paragraph {
            buffer.append(ch)
            if ch == "." || ch == "!" || ch == "?" {
                // Peek: if the next char is a space or we're at paragraph end, treat as boundary
                prev = ch
            } else if let p = prev, (p == "." || p == "!" || p == "?"), ch == " " {
                // boundary confirmed
                results.append(buffer.trimmingCharacters(in: .whitespacesAndNewlines))
                buffer = ""
                prev = nil
            } else {
                prev = nil
            }
        }
        if !buffer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            results.append(buffer.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        return results
    }
}

