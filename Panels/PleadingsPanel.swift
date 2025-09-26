//
//  PleadingsPanel.swift
//  ePleadingsMVP
//

import SwiftUI
import PDFKit

struct PleadingsPanel: View {
    let caseInfo: CaseInfo   // 👈 so we know which case folder to look in

    @State private var pdfURL: URL? = nil

    var body: some View {
        Group {
            if let url = pdfURL {
                PDFViewRepresentable(fileURL: url, targetPage: 0)
            } else {
                Text("No pleadings PDF found for this case.")
                    .foregroundColor(.secondary)
            }
        }
        .onAppear {
            loadPleadingsPDF()
        }
    }

    private func loadPleadingsPDF() {
        let fm = FileManager.default
        let caseFolder = caseInfo.url

        // 1️⃣ Preferred file name convention
        let preferred = caseFolder.appendingPathComponent("pleadings.pdf")
        if fm.fileExists(atPath: preferred.path) {
            pdfURL = preferred
            return
        }

        // 2️⃣ Fallback: first .pdf file in case folder
        if let files = try? fm.contentsOfDirectory(at: caseFolder, includingPropertiesForKeys: nil) {
            if let firstPDF = files.first(where: { $0.pathExtension.lowercased() == "pdf" }) {
                pdfURL = firstPDF
                return
            }
        }

        // 3️⃣ Nothing found
        pdfURL = nil
    }
}

