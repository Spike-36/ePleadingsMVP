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
            document.caseEntity = caseEntity   // ✅ critical: link back to the case
            
            // 👉 Diagnostic: confirm linkage before parsing
            let caseName = caseEntity.filename ?? "Unnamed Case"
            print("🧭 [\(callID)] Document \(document.filename ?? "?") correctly linked to case '\(caseName)'")
            
            // 👉 Handle DOCX or PDF
            if copiedURL.pathExtension.lowercased() == "docx" {
                // 🧩 Parse headings for DOCX
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
                
                // 👉 Defensive check: ensure linkage before mapping
                if document.caseEntity == nil {
                    document.caseEntity = caseEntity
                    print("🩹 [\(callID)] Repaired missing caseEntity link before mapping sentences.")
                }
                
                // 👉 Immediately map sentence bounding boxes (PDF only)
                let mapper = SentenceMapperService()
                mapper.mapSentences(in: document, using: context)
                
                // 👉 Post-mapping diagnostic
                if document.caseEntity == nil {
                    print("⚠️ [\(callID)] Document \(document.filename ?? "?") missing caseEntity link before sentence mapping.")
                } else {
                    print("🧭 [\(callID)] Sentences will map to case: \(document.caseEntity?.filename ?? "Unknown Case")")
                }
                
                // 👉 Verify sentence count for this document
                let fetch: NSFetchRequest<SentenceEntity> = SentenceEntity.fetchRequest()
                fetch.predicate = NSPredicate(format: "document == %@", document)
                if let sentences = try? context.fetch(fetch) {
                    let caseName = document.caseEntity?.filename ?? "Unknown"
                    print("🧩 [\(callID)] \(sentences.count) sentences now indirectly linked to case '\(caseName)'")
                }
                
                // 👉 Tag all sentences created for this document as "new"
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

            // 👉 Post-import sanity check
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

