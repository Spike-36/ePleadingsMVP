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
        let callID = UUID().uuidString.prefix(6)
        print("🟢 importFile() called [\(callID)] for case: \(caseEntity.filename ?? "Unknown Case")")
        
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.pdf, UTType(filenameExtension: "docx")!]
        
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
            document.id = UUID()
            document.createdAt = Date()
            document.filename = pickedURL.lastPathComponent
            document.filePath = copiedURL.path
            document.caseEntity = caseEntity   // initial link
            
            // 🩹 Defensive repair for cross-context mismatch
            if document.caseEntity == nil {
                document.caseEntity = context.object(with: caseEntity.objectID) as? CaseEntity
                print("🩹 [\(callID)] Repaired missing caseEntity link (initial assignment).")
            }
            
            let caseName = caseEntity.filename ?? "Unnamed Case"
            print("🧭 [\(callID)] Document \(document.filename ?? "?") linked to case '\(caseName)'")
            
            // Handle DOCX vs PDF
            if copiedURL.pathExtension.lowercased() == "docx" {
                let parserService = DocxParserService()
                do {
                    try parserService.extractHeadings(for: document, in: context, callID: String(callID))
                } catch {
                    print("⚠️ [\(callID)] Failed to parse headings for \(document.filename ?? "?"): \(error)")
                }

                let sentenceService = SentenceParserService()
                do {
                    try sentenceService.extractSentences(for: document, in: context, callID: String(callID))
                } catch {
                    print("⚠️ [\(callID)] Failed to parse sentences for \(document.filename ?? "?"): \(error)")
                }

                // 🩹 Ensure linkage persisted
                if document.caseEntity == nil {
                    document.caseEntity = context.object(with: caseEntity.objectID) as? CaseEntity
                    print("🩹 [\(callID)] Repaired missing caseEntity link after DOCX parsing.")
                }
                try context.save()
                
            } else {
                // --- PDF path ---
                let heading = HeadingEntity(context: context)
                heading.id = UUID()
                heading.text = "Imported: \(document.filename ?? "Unknown")"
                heading.level = 1
                heading.pageNumber = 1
                heading.sourceFilename = document.filename
                heading.document = document
                try context.save()
                
                if document.caseEntity == nil {
                    document.caseEntity = context.object(with: caseEntity.objectID) as? CaseEntity
                    print("🩹 [\(callID)] Repaired missing caseEntity link before sentence mapping.")
                }
                
                let mapper = SentenceMapperService()
                mapper.mapSentences(in: document, using: context)
                
                if document.caseEntity == nil {
                    print("⚠️ [\(callID)] Document \(document.filename ?? "?") still missing caseEntity link.")
                } else {
                    print("🧭 [\(callID)] Sentences will map to case: \(document.caseEntity?.filename ?? "Unknown Case")")
                }
                
                let fetch: NSFetchRequest<SentenceEntity> = SentenceEntity.fetchRequest()
                fetch.predicate = NSPredicate(format: "document == %@", document)
                if let sentences = try? context.fetch(fetch) {
                    print("🧩 [\(callID)] \(sentences.count) sentences now linked to case '\(document.caseEntity?.filename ?? "Unknown")'")
                }
                
                let updateRequest = NSBatchUpdateRequest(entityName: "SentenceEntity")
                updateRequest.predicate = NSPredicate(format: "document == %@", document)
                updateRequest.propertiesToUpdate = ["state": "new"]
                updateRequest.resultType = .updatedObjectsCountResultType
                if let result = try? context.execute(updateRequest) as? NSBatchUpdateResult {
                    print("🟢 [\(callID)] Tagged \(result.result ?? 0) sentences as 'new' for \(document.filename ?? "?")")
                }
                try context.save()
            }
            
            print("✅ [\(callID)] Imported \(document.filename ?? "?") into case: \(caseEntity.filename ?? "Unknown Case")")

            #if DEBUG
            print("🧩 [\(callID)] Running orphan document check after import...")
            PersistenceController.shared.debugCheckForOrphanDocuments()
            #endif
            
            return document
        } catch {
            print("❌ [\(callID)] Failed to import file: \(error)")
            return nil
        }
    }
}

