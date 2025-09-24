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
    
    /// Import a file into a specific case (defaults to "DefaultCase").
    func importFile(into caseName: String = "DefaultCase") {
        DispatchQueue.main.async {
            let panel = NSOpenPanel()
            panel.allowsMultipleSelection = false
            panel.canChooseDirectories = false
            panel.canChooseFiles = true
            panel.allowedContentTypes = [
                .pdf,
                UTType(filenameExtension: "docx")!
            ]
            
            if panel.runModal() == .OK, let pickedURL = panel.url {
                let ext = pickedURL.pathExtension.lowercased()
                let safeName = FileHelper.safeName(from: caseName)
                
                do {
                    // Copy file into the chosen case folder
                    let destination = try FileHelper.copyFile(pickedURL, toCaseFolder: safeName)
                    
                    // See if we already have a CaseFile for this case
                    if let index = self.importedFiles.firstIndex(where: { $0.caseName == safeName }) {
                        var existing = self.importedFiles[index]
                        if ext == "pdf" {
                            existing = CaseFile(
                                caseName: safeName,
                                pdfURL: destination,
                                docxURL: existing.docxURL
                            )
                        } else if ext == "docx" {
                            existing = CaseFile(
                                caseName: safeName,
                                pdfURL: existing.pdfURL,
                                docxURL: destination
                            )
                        }
                        self.importedFiles[index] = existing
                    } else {
                        // Create new CaseFile
                        let newFile = CaseFile(
                            caseName: safeName,
                            pdfURL: ext == "pdf" ? destination : nil,
                            docxURL: ext == "docx" ? destination : nil
                        )
                        self.importedFiles.append(newFile)
                    }
                    
                } catch {
                    print("❌ ImportService failed: \(error)")
                }
            }
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

