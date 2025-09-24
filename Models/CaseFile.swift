//
//  CaseFile.swift
//  ePleadingsMVP
//
//  Created by Peter Milligan on 24/09/2025.
//

//
//  CaseFile.swift
//  ePleadingsMVP
//
//  Represents a pair of documents (DOCX + PDF) in a case folder.
//  Tracks missing counterparts for UI warnings.
//

import Foundation

struct CaseFile: Identifiable, Hashable {
    let id = UUID()
    
    /// The safe folder name under Application Support/CaseFiles/
    let caseName: String
    
    /// Path to the PDF if present
    let pdfURL: URL?
    
    /// Path to the DOCX if present
    let docxURL: URL?
    
    /// Flags to show in the UI
    var isPDFMissing: Bool {
        docxURL != nil && pdfURL == nil
    }
    
    var isDOCXMissing: Bool {
        pdfURL != nil && docxURL == nil
    }
}
