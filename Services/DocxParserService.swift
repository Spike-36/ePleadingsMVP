//
//  DocxParserService.swift
//  ePleadingsMVP
//
//  Created by Pete on 03/10/2025.
//

import Foundation
import CoreData

/// Service that wraps DocxParser and writes extracted headings into Core Data.
final class DocxParserService {
    private let parser = DocxParser()
    
    /// Parse headings from the given DocumentEntity (must be a DOCX).
    /// Creates HeadingEntity objects linked to that document.
    func extractHeadings(for document: DocumentEntity, in context: NSManagedObjectContext) throws {
        guard let path = document.filePath else {
            throw NSError(domain: "DocxParserService", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Document has no filePath"])
        }
        let url = URL(fileURLWithPath: path)
        
        guard url.pathExtension.lowercased() == "docx" else {
            print("⚠️ Not a DOCX: \(url.lastPathComponent)")
            return
        }
        
        // 1. Parse headings → returns [ParsedHeading]
        let parsedHeadings = try parser.parseHeadings(at: url)
        if parsedHeadings.isEmpty {
            print("⚠️ No headings detected in \(url.lastPathComponent)")
            return
        }
        
        print("📑 Extracted \(parsedHeadings.count) heading(s) from \(url.lastPathComponent)")
        
        // 2. Remove any old headings linked to this document
        if let old = document.headings as? Set<HeadingEntity> {
            for h in old { context.delete(h) }
        }
        
        // 3. Create new HeadingEntity rows
        for parsed in parsedHeadings {
            let heading = HeadingEntity(context: context)
            heading.id = UUID()
            heading.text = parsed.text                  // ✅ Actual heading text
            heading.orderIndex = Int32(parsed.orderIndex) // ✅ Canonical order
            heading.level = 1
            heading.sourceFilename = document.filename
            heading.document = document
        }
        
        // 4. Save
        try context.save()
        print("✅ Saved \(parsedHeadings.count) headings into Core Data for \(document.filename ?? "?")")
    }
}

