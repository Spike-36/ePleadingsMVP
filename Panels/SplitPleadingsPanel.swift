//
//  SplitPleadingsPanel.swift
//  ePleadingsMVP
//
//  Created by Peter Milligan on 05/10/2025.
//

import SwiftUI
import PDFKit

struct SplitPleadingsPanel: View {
    let caseEntity: CaseEntity
    @Binding var leftHeading: HeadingEntity?
    @Binding var rightHeading: HeadingEntity?

    @State private var pdfURL: URL? = nil

    var body: some View {
        VStack(spacing: 8) {
            // Header bar
            VStack {
                Text("🧾 Split Pleadings Mode")
                    .font(.title2)
                Text("Left = Statement • Right = Response")
                    .foregroundColor(.secondary)
                    .font(.subheadline)
            }
            .padding(.bottom, 8)

            Divider()

            // Main two-pane layout
            if let url = pdfURL {
                HStack(spacing: 12) {
                    PDFViewRepresentable(url: url, selectedHeading: $leftHeading)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .border(Color.gray.opacity(0.4))

                    PDFViewRepresentable(url: url, selectedHeading: $rightHeading)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .border(Color.gray.opacity(0.4))
                }
                .padding(8)
            } else {
                Text("No pleadings PDF found for this case.")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear { loadPleadings() }
        .background(Color(NSColor.windowBackgroundColor))
    }

    private func loadPleadings() {
        guard let documents = caseEntity.documents as? Set<DocumentEntity> else {
            print("⚠️ No documents relationship for case \(caseEntity.filename ?? "nil")")
            return
        }

        for doc in documents {
            guard let path = doc.filePath else { continue }
            let url = URL(fileURLWithPath: path)
            if FileManager.default.fileExists(atPath: url.path),
               url.pathExtension.lowercased() == "pdf" {
                pdfURL = url
                print("✅ SplitPleadingsPanel using PDF:", url.lastPathComponent)
                return
            }
        }
        print("⚠️ No PDF found for SplitPleadingsPanel in case:", caseEntity.filename ?? "nil")
    }
}

