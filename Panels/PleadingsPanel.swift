//
//  PleadingsPanel.swift
//  ePleadingsMVP
//

import SwiftUI
import PDFKit

struct PleadingsPanel: View {
    let caseInfo: CaseInfo   // 👈 tells us which case folder to use
    let selectedPage: Int?   // 👉 Stage 4.1: accept selectedPage
    
    @State private var pdfURL: URL? = nil

    var body: some View {
        VStack {
            if let url = pdfURL {
                PDFViewRepresentable(fileURL: url, targetPage: 0)
                // 🔄 Stage 4.2 will switch to using selectedPage instead of 0
            } else {
                Text("No pleadings PDF found for this case.")
                    .foregroundColor(.secondary)
            }
        }
        .onAppear {
            loadPleadings()
        }
        .onChange(of: selectedPage) { newValue in
            // 🔄 Stage 4.1: just log it for now
            if let page = newValue {
                print("👉 PleadingsPanel received selectedPage = \(page)")
            } else {
                print("👉 PleadingsPanel received nil selectedPage")
            }
        }
    }

    private func loadPleadings() {
        let fm = FileManager.default
        let caseFolder = caseInfo.url

        // Preferred PDF name
        let preferredPDF = caseFolder.appendingPathComponent("pleadings.pdf")
        if fm.fileExists(atPath: preferredPDF.path) {
            pdfURL = preferredPDF
        } else if let files = try? fm.contentsOfDirectory(at: caseFolder, includingPropertiesForKeys: nil) {
            if let firstPDF = files.first(where: { $0.pathExtension.lowercased() == "pdf" }) {
                pdfURL = firstPDF
            }
        }
    }
}

