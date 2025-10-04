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
        let callID = UUID().uuidString.prefix(6)  // short unique tag for tracing
        print("🟢 importFile() called [\(callID)] for case: \(caseEntity.filename ?? "Unknown Case")")
        
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [
            .pdf,
            UTType(filenameExtension: "docx")!
        ]
        
        guard panel.runModal() == .OK, let pickedURL = panel.url else {
            print("🔴 [\(callID)] Import cancelled or no file selected")
            return nil
        }
        
        do {
            guard let context = caseEntity.managedObjectContext else {
                print("❌ [\(callID)] No managed object context found for case.")
                return nil
            }
            
            // ✅ Check using full file path and case ID (safe across contexts)
            let fetch: NSFetchRequest<DocumentEntity> = DocumentEntity.fetchRequest()
            fetch.predicate = NSPredicate(
                format: "filePath == %@ AND caseEntity.id == %@",
                pickedURL.path, caseEntity.id as CVarArg
            )
            
            if let existing = try? context.fetch(fetch).first {
                print("⚠️ [\(callID)] Document already imported (same path + case): \(existing.filename ?? "?")")
                return existing
            }
            
            // ✅ Always copy into the case’s own folder (unique destination)
            let copiedURL = try FileHelper.copyFile(from: pickedURL, toCaseID: caseEntity.id)
            
            let document = DocumentEntity(context: context)
            
            // 🔄 Required fields
            document.id = UUID()
            document.createdAt = Date()
            document.filename = pickedURL.lastPathComponent
            document.filePath = copiedURL.path
            document.caseEntity = caseEntity   // link back to the case
            
            // 👉 If DOCX, parse headings immediately
            if copiedURL.pathExtension.lowercased() == "docx" {
                let parserService = DocxParserService()
                do {
                    try parserService.extractHeadings(for: document, in: context, callID: String(callID))
                } catch {
                    print("⚠️ [\(callID)] Failed to parse headings for \(document.filename ?? "?"): \(error)")
                }
            } else {
                // 🧩 Fallback dummy heading for PDFs
                let heading = HeadingEntity(context: context)
                heading.id = UUID()
                heading.text = "Imported: \(document.filename ?? "Unknown")"
                heading.level = 1
                heading.pageNumber = 1
                heading.sourceFilename = document.filename
                heading.document = document
                try context.save()
            }
            
            print("✅ [\(callID)] Imported \(document.filename ?? "?") into case: \(caseEntity.filename ?? "Unknown Case")")
            return document
        } catch {
            print("❌ [\(callID)] Failed to import file: \(error)")
            return nil
        }
    }
}

