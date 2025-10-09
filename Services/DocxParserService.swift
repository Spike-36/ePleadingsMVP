//
//  DocxParserService.swift
//  ePleadingsMVP
//
//  Created by Pete on 03/10/2025.
//  Updated 09/10/2025 — Stage 5: Parser De-duplication Pass
//

import Foundation
import CoreData

/// Service that wraps DocxParser and writes extracted headings into Core Data.
final class DocxParserService {
    private let parser = DocxParser()
    
    /// Parse headings from the given DocumentEntity (must be a DOCX).
    /// Creates HeadingEntity objects linked to that document.
    func extractHeadings(for document: DocumentEntity,
                         in context: NSManagedObjectContext,
                         callID: String? = nil) throws {
        guard let path = document.filePath else {
            throw NSError(domain: "DocxParserService", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Document has no filePath"])
        }
        let url = URL(fileURLWithPath: path)
        let tag = callID ?? "∅"
        
        guard url.pathExtension.lowercased() == "docx" else {
            print("⚠️ [\(tag)] Not a DOCX: \(url.lastPathComponent)")
            return
        }
        
        // 1. Parse headings → returns [ParsedHeading]
        let parsedHeadings = try parser.parseHeadings(at: url)
        if parsedHeadings.isEmpty {
            print("⚠️ [\(tag)] No headings detected in \(url.lastPathComponent)")
            return
        }
        
        print("📑 [\(tag)] Extracted \(parsedHeadings.count) heading(s) from \(url.lastPathComponent)")
        
        // 2. Remove any old headings linked to this document
        if let old = document.headings as? Set<HeadingEntity>, !old.isEmpty {
            print("🗑️ [\(tag)] Removing \(old.count) old heading(s) for \(document.filename ?? "?")")
            for h in old { context.delete(h) }
        }
        
        // 3. Create new HeadingEntity rows (deduplication guard)
        var seenHeadings = Set<String>()
        var savedCount = 0
        var skippedCount = 0
        
        for parsed in parsedHeadings {
            let normalized = parsed.text
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()
            
            guard !normalized.isEmpty else { continue }
            
            if seenHeadings.contains(normalized) {
                skippedCount += 1
                print("⚙️ [\(tag)] Skipped duplicate heading: '\(parsed.text)'")
                continue
            }
            
            seenHeadings.insert(normalized)
            
            let heading = HeadingEntity(context: context)
            heading.id = UUID()
            heading.text = parsed.text
            heading.orderIndex = Int32(savedCount)
            heading.level = 1
            heading.sourceFilename = document.filename
            heading.document = document
            
            savedCount += 1
        }
        
        // 4. Save
        try context.save()
        print("✅ [\(tag)] Saved \(savedCount) unique heading(s) (\(skippedCount) duplicate(s) skipped) for \(document.filename ?? "?")")
    }
}

