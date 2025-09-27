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

/// Service to handle importing files into the app’s sandbox (macOS).
final class ImportService: ObservableObject {
    @Published var importedFiles: [CaseFile] = []

    // Existing async/published import (used by other screens)
    func importFile(into caseName: String = "DefaultCase") {
        if let result = importFileAndReturn(into: caseName) {
            // Keep published array in sync for any views that use it
            if let idx = importedFiles.firstIndex(where: { $0.caseName == result.caseName }) {
                importedFiles[idx] = result
            } else {
                importedFiles.append(result)
            }
        }
    }

    /// Synchronous import that RETURNS the CaseFile so callers can act immediately.
    func importFileAndReturn(into caseName: String = "DefaultCase") -> CaseFile? {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [
            .pdf,
            UTType(filenameExtension: "docx")!
        ]

        guard panel.runModal() == .OK, let pickedURL = panel.url else { return nil }

        let safeName = FileHelper.safeName(from: caseName)
        do {
            // ✅ Copy into case folder
            let copiedURL = try FileHelper.copyFile(from: pickedURL, toCase: safeName)

            // ✅ Resolve case folder paths
            let folder = try FileHelper.caseFolder(named: safeName)
            let pdf = folder.appendingPathComponent("\(safeName).pdf")
            let docx = folder.appendingPathComponent("\(safeName).docx")

            // 🔍 Debug prints for file presence
            print("✅ Saved \(pickedURL.lastPathComponent) → \(copiedURL.lastPathComponent)")
            print("   PDF exists? \(FileManager.default.fileExists(atPath: pdf.path))")
            print("   DOCX exists? \(FileManager.default.fileExists(atPath: docx.path))")

            // ✅ If DOCX exists, parse it for paragraphs + save to Core Data
            if FileManager.default.fileExists(atPath: docx.path) {
                let parser = DocxParser()
                do {
                    let paragraphs = try parser.parseDocx(at: docx)
                    print("📄 Parsed \(paragraphs.count) paragraphs from \(docx.lastPathComponent)")

                    let context = PersistenceController.shared.container.viewContext

                    for (idx, p) in paragraphs.enumerated() {
                        let sentence = Sentence(context: context)
                        sentence.id = UUID()
                        sentence.text = p
                        sentence.pageNumber = Int32(idx + 1) // crude order = “page”
                        sentence.sourceFilename = docx.lastPathComponent

                        // Simple heading flag (all caps heuristic)
                        if p.uppercased() == p && p.count > 3 {
                            print("🔖 HEADING detected: \(p)")

                            let heading = HeadingEntity(context: context)
                            heading.id = UUID()
                            heading.text = p
                            heading.level = 1 // TODO: refine heading levels later
                            heading.pageNumber = Int32(idx + 1)
                            heading.sourceFilename = docx.lastPathComponent

                            // Optionally link the sentence to the heading
                            sentence.parentHeading = heading
                        }
                    }

                    try context.save()
                    print("💾 Saved \(paragraphs.count) sentences into Core Data for case \(safeName)")

                } catch {
                    print("⚠️ Failed to parse DOCX: \(error)")
                }
            }

            let result = CaseFile(
                caseName: safeName,
                pdfURL: FileManager.default.fileExists(atPath: pdf.path) ? pdf : nil,
                docxURL: FileManager.default.fileExists(atPath: docx.path) ? docx : nil
            )
            return result
        } catch {
            print("❌ ImportService failed: \(error)")
            return nil
        }
    }

    /// Load existing files for a case from disk.
    func loadFiles(for caseName: String) {
        do {
            let folder = try FileHelper.caseFolder(named: caseName)
            let pdfURL = folder.appendingPathComponent("\(caseName).pdf")
            let docxURL = folder.appendingPathComponent("\(caseName).docx")

            let caseFile = CaseFile(
                caseName: caseName,
                pdfURL: FileManager.default.fileExists(atPath: pdfURL.path) ? pdfURL : nil,
                docxURL: FileManager.default.fileExists(atPath: docxURL.path) ? docxURL : nil
            )
            self.importedFiles = [caseFile]
        } catch {
            print("❌ loadFiles failed: \(error)")
            self.importedFiles = []
        }
    }
}

