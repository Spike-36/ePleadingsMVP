//
//  PleadingsPanel.swift
//  ePleadingsMVP
//

import SwiftUI
import PDFKit

struct PleadingsPanel: View {
    let caseEntity: CaseEntity   // ✅ Core Data entity
    @Binding var selectedPage: Int?
    
    @State private var pdfURL: URL? = nil
    
    var body: some View {
        VStack {
            if let url = pdfURL {
                PDFViewRepresentable(url: url, selectedPage: $selectedPage)
            } else {
                Text("No pleadings PDF found for this case.")
                    .foregroundColor(.secondary)
            }
        }
        .onAppear { loadPleadings() }
        .onChange(of: selectedPage) { newValue in
            if let page = newValue {
                print("👉 PleadingsPanel received selectedPage = \(page)")
            }
        }
    }
    
    private func loadPleadings() {
        guard let documents = caseEntity.documents as? Set<DocumentEntity> else {
            print("⚠️ No documents relationship for case \(caseEntity.filename)")
            return
        }
        
        for doc in documents {
            guard let path = doc.filePath else { continue }
            let url = URL(fileURLWithPath: path)
            
            print("🔎 Checking:", url.path)
            
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

