//
//  ImportService.swift
//  ePleadingsMVP
//
//  Handles importing files into the app’s sandbox (macOS).
//

import Foundation
import AppKit
import UniformTypeIdentifiers
import CoreData

// Service to handle importing files into the app’s sandbox (macOS).
final class ImportService: ObservableObject {
    @Published var importedFiles: [CaseFile] = []
    
    func importFile(into caseEntity: CaseEntity) -> DocumentEntity? {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [
            .pdf,
            UTType(filenameExtension: "docx")!
        ]
        
        guard panel.runModal() == .OK, let pickedURL = panel.url else { return nil }
        
        do {
            // ✅ Always save files into UUID-based case folder
            let copiedURL = try FileHelper.copyFile(from: pickedURL, toCaseID: caseEntity.id)
            
            let context = caseEntity.managedObjectContext!
            let document = DocumentEntity(context: context)
            
            // ✅ Required fields
            document.id = UUID()
            document.createdAt = Date()
            document.filename = pickedURL.lastPathComponent
            document.filePath = copiedURL.path
            document.caseEntity = caseEntity   // link back to the case
            
            // 👉 If DOCX, parse headings right now
            if copiedURL.pathExtension.lowercased() == "docx" {
                let parserService = DocxParserService()
                do {
                    try parserService.extractHeadings(for: document, in: context)
                } catch {
                    print("⚠️ Failed to parse headings for \(document.filename ?? "?"): \(error)")
                }
            } else {
                // Otherwise, add a dummy heading so UI isn’t empty
                let heading = HeadingEntity(context: context)
                heading.id = UUID()
                heading.text = "Imported: \(document.filename ?? "Unknown")"
                heading.level = 1
                heading.pageNumber = 1
                heading.sourceFilename = document.filename
                heading.document = document
                try context.save()
            }
            
            print("✅ Imported \(document.filename ?? "?") into case: \(caseEntity.filename ?? "Unknown Case")")
            return document
        } catch {
            print("❌ Failed to import file: \(error)")
            return nil
        }
    }
}

