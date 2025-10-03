//
//  PleadingsPanel.swift
//  ePleadingsMVP
//

import SwiftUI
import PDFKit

struct PleadingsPanel: View {
    let caseEntity: CaseEntity   // ✅ Core Data entity
    @Binding var selectedHeading: HeadingEntity?   // 🔄 heading binding
    
    @State private var pdfURL: URL? = nil
    
    var body: some View {
        VStack {
            if let url = pdfURL {
                PDFViewRepresentable(url: url, selectedHeading: $selectedHeading)
            } else {
                Text("No pleadings PDF found for this case.")
                    .foregroundColor(.secondary)
            }
        }
        .onAppear { loadPleadings() }
    }
    
    private func loadPleadings() {
        guard let documents = caseEntity.documents as? Set<DocumentEntity> else {
            print("⚠️ No documents relationship for case \(caseEntity.filename)")
            return
        }
        
        for doc in documents {
            guard let path = doc.filePath else { continue }
            let url = URL(fileURLWithPath: path)
            
            if FileManager.default.fileExists(atPath: url.path),
               url.pathExtension.lowercased() == "pdf" {
                print("✅ Found PDF:", url.path)
                pdfURL = url
                return
            }
        }
        
        print("⚠️ No matching PDFs found for case:", caseEntity.filename)
    }
}

