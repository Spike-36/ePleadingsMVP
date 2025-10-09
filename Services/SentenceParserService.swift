//
//  SentenceParserService.swift
//  ePleadingsMVP
//
//  Created by Peter Milligan on 09/10/2025.
//
//  Purpose:
//  Extract real sentences from DOCX paragraphs,
//  attach them to both the DocumentEntity and (when applicable) the current HeadingEntity.
//  Assign a document-wide continuous orderIndex. Skip heading lines & junk.
//

import Foundation
import CoreData

final class SentenceParserService {
    private let parser = DocxParser()

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

        // 0️⃣ Clean slate
        do {
            let fetch: NSFetchRequest<SentenceEntity> = SentenceEntity.fetchRequest()
            fetch.predicate = NSPredicate(format: "document == %@", document)
            for old in try context.fetch(fetch) { context.delete(old) }
        } catch {
            print("⚠️ [\(tag)] Failed to purge old sentences: \(error)")
        }

        // 1️⃣ Parse paragraphs
        let paragraphs = try parser.parseDocx(at: url)
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        guard !paragraphs.isEmpty else {
            print("⚠️ [\(tag)] No paragraphs found in \(url.lastPathComponent)")
            try context.save()
            return
        }

        // 2️⃣ Fetch headings
        let headingFetch: NSFetchRequest<HeadingEntity> = HeadingEntity.fetchRequest()
        headingFetch.predicate = NSPredicate(format: "document == %@", document)
        headingFetch.sortDescriptors = [NSSortDescriptor(keyPath: \HeadingEntity.orderIndex, ascending: true)]
        let headings = try context.fetch(headingFetch)

        var currentHeading: HeadingEntity?
        var globalOrder: Int32 = 0
        var createdCount = 0

        // 3️⃣ Iterate through paragraphs (split multi-line blocks)
        for para in paragraphs {
            // Split any multi-line paragraphs (common in DOCX exports)
            let lines = para.components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }

            for line in lines {
                let lower = line.lowercased()

                // --- Detect heading-like lines (regex catches “Statement 2”, “Ans 1:”, etc.)
                if lower.range(of: #"^(statement|answer|cond|admit)[\s\d:\-]*$"#,
                               options: .regularExpression) != nil {
                    if let label = HeadingClassifier.extractLabel(line),
                       let found = headings.first(where: {
                           ($0.text ?? "").caseInsensitiveCompare(label) == .orderedSame
                       }) {
                        currentHeading = found
                    } else {
                        currentHeading = nil
                    }
                    print("🧭 [\(tag)] Skipped heading-like line: '\(line)'")
                    continue
                }

                // --- Safety net classification
                switch HeadingClassifier.classify(line) {
                case .statement, .answer:
                    if let label = HeadingClassifier.extractLabel(line),
                       let found = headings.first(where: {
                           ($0.text ?? "").caseInsensitiveCompare(label) == .orderedSame
                       }) {
                        currentHeading = found
                    } else {
                        currentHeading = nil
                    }
                    continue // never create sentences for heading lines

                case .misc:
                    // --- Split into real sentences
                    let parts = Self.splitIntoSentences(line)
                    for raw in parts {
                        let clean = raw.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard Self.isValidSentence(clean) else {
                            print("🧹 [\(tag)] Skipping trivial fragment: '\(clean)'")
                            continue
                        }

                        let s = SentenceEntity(context: context)
                        s.id = UUID()
                        s.text = clean
                        s.document = document
                        s.heading = currentHeading
                        s.orderIndex = globalOrder
                        s.sourceFilename = document.filename
                        s.state = "new"

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
        }

        try context.save()
        print("✅ [\(tag)] SentenceParserService: Created \(createdCount) clean sentence(s) for \(document.filename ?? "?"), orderIndex 0...\(max(0, Int(globalOrder) - 1)).")
    }

    // MARK: - Validation helper
    private static func isValidSentence(_ text: String) -> Bool {
        guard text.count >= 6 else { return false }
        let trimmed = text.trimmingCharacters(in: .punctuationCharacters)
        if trimmed.rangeOfCharacter(from: .letters) == nil { return false }
        if trimmed.count <= 3 && trimmed.rangeOfCharacter(from: .decimalDigits) != nil { return false }
        return true
    }

    // MARK: - Minimal sentence splitter
    private static func splitIntoSentences(_ paragraph: String) -> [String] {
        var results: [String] = []
        var buffer = ""
        var prev: Character?

        for ch in paragraph {
            buffer.append(ch)
            if ch == "." || ch == "!" || ch == "?" {
                prev = ch
            } else if let p = prev, (p == "." || p == "!" || p == "?"), ch == " " {
                results.append(buffer.trimmingCharacters(in: .whitespacesAndNewlines))
                buffer = ""
                prev = nil
            } else {
                prev = nil
            }
        }

        let tail = buffer.trimmingCharacters(in: .whitespacesAndNewlines)
        if !tail.isEmpty { results.append(tail) }
        return results
    }
}

