//
//  ImportService.swift
//  ePleadingsMVP
//
//  Handles importing files into the app’s sandbox (macOS).
//

import Foundation
import AppKit
import UniformTypeIdentifiers

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
            // ✅ Correct argument order
            _ = try FileHelper.copyFile(from: pickedURL, toCase: safeName)

            // ✅ caseFolder is throwing, so call with try
            let folder = try FileHelper.caseFolder(named: safeName)
            let pdf = folder.appendingPathComponent("\(safeName).pdf")
            let docx = folder.appendingPathComponent("\(safeName).docx")

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

