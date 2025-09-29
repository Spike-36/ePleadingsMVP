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

    // Async/published import (used by other screens)
    func importFile(into caseName: String = "DefaultCase") {
        if let result = importFileAndReturn(into: caseName) {
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
            let copiedURL = try FileHelper.copyFile(from: pickedURL, toCase: safeName)
            let folder = try FileHelper.caseFolder(named: safeName)
            let pdf = folder.appendingPathComponent("\(safeName).pdf")
            let docx = folder.appendingPathComponent("\(safeName).docx")

            print("✅ Saved \(pickedURL.lastPathComponent) → \(copiedURL.lastPathComponent)")

            if FileManager.default.fileExists(atPath: docx.path) {
                let parser = DocxParser()
                do {
                    let paragraphs = try parser.parseDocx(at: docx)
                    print("📄 Parsed \(paragraphs.count) paragraphs from \(docx.lastPathComponent)")

                    let context = PersistenceController.shared.container.viewContext

                    for (idx, p) in paragraphs.enumerated() {
                        print("🔍 Paragraph \(idx): \(p.prefix(100))")

                        // Always store sentence
                        let sentence = SentenceEntity(context: context)
                        sentence.id = UUID()
                        sentence.text = p
                        sentence.pageNumber = Int32(idx + 1)
                        sentence.sourceFilename = docx.lastPathComponent

                        // Classify + extract label
                        let headingType = HeadingClassifier.classify(p)
                        if headingType != .misc,
                           let label = HeadingClassifier.extractLabel(p) {
                            print("🔖 HEADING detected: \(headingType) → \(label)")

                            let heading = HeadingEntity(context: context)
                            heading.id = UUID()
                            heading.text = label   // ✅ store only clean label, not whole paragraph
                            heading.level = 1
                            heading.pageNumber = Int32(idx + 1)
                            heading.sourceFilename = docx.lastPathComponent

                            sentence.heading = heading
                        }
                    }

                    try context.save()
                    print("💾 Saved \(paragraphs.count) sentences into Core Data for case \(safeName)")
                } catch {
                    print("⚠️ Failed to parse DOCX: \(error)")
                }
            }

            return CaseFile(
                caseName: safeName,
                pdfURL: FileManager.default.fileExists(atPath: pdf.path) ? pdf : nil,
                docxURL: FileManager.default.fileExists(atPath: docx.path) ? docx : nil
            )
        } catch {
            print("❌ ImportService failed: \(error)")
            return nil
        }
    }

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

