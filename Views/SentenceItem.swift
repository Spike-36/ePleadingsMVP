//
//  SentenceItem.swift
//  ePleadingsMVP
//

import Foundation

struct SentenceItem: Identifiable, Hashable {
    let id: String
    let text: String
    let pageNumber: Int
    let sourceFilename: String?
    
    /// Computed property: full URL if base folder is known
    func resolvedURL(in caseFolder: URL) -> URL? {
        guard let sourceFilename else { return nil }
        let candidateURL = caseFolder.appendingPathComponent(sourceFilename)
        
        // ✅ If it's a DOCX, try swapping to PDF in same folder
        if candidateURL.pathExtension.lowercased() == "docx" {
            let pdfURL = candidateURL.deletingPathExtension().appendingPathExtension("pdf")
            if FileManager.default.fileExists(atPath: pdfURL.path) {
                return pdfURL
            } else {
                print("⚠️ PDF not found for DOCX: \(pdfURL.path)")
            }
        }
        
        return candidateURL
    }
}

