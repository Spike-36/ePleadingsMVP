//
//  PleadingsPanel.swift
//  ePleadingsMVP
//

import SwiftUI
import PDFKit

enum PleadingsMode: String, CaseIterable, Identifiable {
    case pdf = "PDF"
    case docx = "DOCX"

    var id: String { rawValue }
}

struct PleadingsPanel: View {
    let caseInfo: CaseInfo   // 👈 tells us which case folder to use

    @State private var mode: PleadingsMode = .pdf
    @State private var pdfURL: URL? = nil
    @State private var docxParagraphs: [String] = []

    var body: some View {
        VStack {
            // Segmented toggle to switch between PDF and DOCX
            Picker("Format", selection: $mode) {
                ForEach(PleadingsMode.allCases) { m in
                    Text(m.rawValue).tag(m)
                }
            }
            .pickerStyle(.segmented)
            .padding()

            Divider()

            Group {
                switch mode {
                case .pdf:
                    if let url = pdfURL {
                        PDFViewRepresentable(fileURL: url, targetPage: 0)
                    } else {
                        Text("No pleadings PDF found for this case.")
                            .foregroundColor(.secondary)
                    }

                case .docx:
                    if docxParagraphs.isEmpty {
                        Text("No DOCX paragraphs loaded.")
                            .foregroundColor(.secondary)
                    } else {
                        List(docxParagraphs, id: \.self) { p in
                            Text(p)
                                .font(.body)
                                .padding(.vertical, 2)
                        }
                    }
                }
            }
        }
        .onAppear {
            loadPleadings()
        }
    }

    private func loadPleadings() {
        let fm = FileManager.default
        let caseFolder = caseInfo.url

        // 1️⃣ Preferred PDF name
        let preferredPDF = caseFolder.appendingPathComponent("pleadings.pdf")
        if fm.fileExists(atPath: preferredPDF.path) {
            pdfURL = preferredPDF
        } else if let files = try? fm.contentsOfDirectory(at: caseFolder, includingPropertiesForKeys: nil) {
            if let firstPDF = files.first(where: { $0.pathExtension.lowercased() == "pdf" }) {
                pdfURL = firstPDF
            }
        }

        // 2️⃣ DOCX load: grab the first .docx in the folder
        if let files = try? fm.contentsOfDirectory(at: caseFolder, includingPropertiesForKeys: nil) {
            if let firstDocx = files.first(where: { $0.pathExtension.lowercased() == "docx" }) {
                let parser = DocxParser()
                do {
                    docxParagraphs = try parser.parseDocx(at: firstDocx)
                    print("📄 Loaded \(docxParagraphs.count) DOCX paragraphs from \(firstDocx.lastPathComponent)")
                } catch {
                    print("⚠️ Failed to parse DOCX: \(error)")
                    docxParagraphs = []
                }
            }
        }
    }
}

