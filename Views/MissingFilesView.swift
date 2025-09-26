//
//  MissingFilesView.swift
//  ePleadingsMVP
//
//  Created by Peter Milligan on 26/09/2025.
//

import SwiftUI

struct MissingFilesView: View {
    let caseInfo: CaseInfo
    @ObservedObject var caseManager = CaseManager.shared
    private let importService = ImportService()   // ✅ no StateObject

    var body: some View {
        VStack(spacing: 20) {
            Text("Files Missing for \(caseInfo.displayName)")
                .font(.headline)
                .multilineTextAlignment(.center)

            Text("This case requires both a DOCX and a PDF file before details can be viewed.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            // Status indicators
            HStack(spacing: 30) {
                VStack {
                    Image(systemName: caseInfo.hasDocx ? "doc.fill" : "doc")
                        .font(.system(size: 32))
                        .foregroundColor(caseInfo.hasDocx ? .green : .red)
                    Text("DOCX")
                        .font(.caption)
                }

                VStack {
                    Image(systemName: caseInfo.hasPdf ? "doc.richtext.fill" : "doc.richtext")
                        .font(.system(size: 32))
                        .foregroundColor(caseInfo.hasPdf ? .green : .red)
                    Text("PDF")
                        .font(.caption)
                }
            }

            // Import buttons (generic)
            VStack(spacing: 12) {
                Button {
                    if let result = importService.importFileAndReturn() {
                        print("✅ Imported file: \(result)")
                        caseManager.refreshCases()
                    }
                } label: {
                    Label("Import File", systemImage: "square.and.arrow.down")
                }
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Missing Files")
    }
}

