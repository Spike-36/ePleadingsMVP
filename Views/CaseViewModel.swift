//
//  CaseViewModel.swift
//  ePleadingsMVP
//

import Foundation
import SwiftUI

@MainActor
final class CaseViewModel: ObservableObject {
    @Published var sentences: [SentenceItem] = []
    @Published var targetPage: Int? = nil
    
    private let caseInfo: CaseInfo
    
    init(caseInfo: CaseInfo) {
        self.caseInfo = caseInfo
        loadCase()
    }
    
    /// Load sentences for this case
    private func loadCase() {
        let fm = FileManager.default
        let caseURL = caseInfo.url
        
        var pdfURL: URL? = nil
        var docxURL: URL? = nil
        
        if let files = try? fm.contentsOfDirectory(at: caseURL, includingPropertiesForKeys: nil) {
            pdfURL = files.first(where: { $0.pathExtension.lowercased() == "pdf" })
            docxURL = files.first(where: { $0.pathExtension.lowercased() == "docx" })
        }
        
        // Default fallback PDF
        let resolvedPDFURL = pdfURL ?? caseURL.appendingPathComponent("pleadingsShort.pdf")
        print("🔍 Using PDF path:", resolvedPDFURL.path)
        
        // Parse DOCX into paragraphs
        if let docxURL = docxURL {
            do {
                let parser = DocxParser()
                let paragraphs = try parser.parseDocx(at: docxURL)
                
                self.sentences = paragraphs.enumerated().map { (idx, text) in
                    SentenceItem(
                        index: idx,
                        text: text,
                        pageNumber: 1, // stub for now
                        sourceURL: resolvedPDFURL
                    )
                }
                return
            } catch {
                print("⚠️ Failed to parse DOCX at \(docxURL.path): \(error.localizedDescription)")
            }
        }
        
        // Fallback if no DOCX or parse error
        self.sentences = [
            SentenceItem(index: 0,
                         text: "⚠️ No DOCX found or failed to parse",
                         pageNumber: 1,
                         sourceURL: resolvedPDFURL)
        ]
    }
    
    /// 🔄 Public reload method so the view can refresh its data
    func reloadCase() {
        loadCase()
    }
    
    func jumpToPage(_ page: Int) {
        targetPage = page
    }
}

