//
//  PleadingsPanel.swift
//  ePleadingsMVP
//

import SwiftUI
import PDFKit

struct PleadingsPanel: View {
    let caseInfo: CaseInfo   // 👈 tells us which case folder to use
    @Binding var selectedPage: Int?   // ✅ must be Binding so it can sync with parent

    @State private var pdfURL: URL? = nil

    var body: some View {
        VStack {
            if let url = pdfURL {
                // ✅ Fixed call: correct labels + pass Binding
                PDFViewRepresentable(url: url, selectedPage: $selectedPage)
            } else {
                Text("No pleadings PDF found for this case.")
                    .foregroundColor(.secondary)
            }
        }
        .onAppear {
            loadPleadings()
        }
        .onChange(of: selectedPage) { newValue in
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

