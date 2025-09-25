//
//  CaseDetailView.swift
//  ePleadingsMVP
//

import SwiftUI
import PDFKit

struct CaseDetailView: View {
    @StateObject private var viewModel = CaseViewModel()
    @State private var selectedSentence: SentenceItem? = nil

    var body: some View {
        NavigationSplitView {
            // LEFT PANE → sentence list with selection
            List(selection: $selectedSentence) {
                ForEach(viewModel.sentences) { sentence in
                    VStack(alignment: .leading) {
                        Text(sentence.text)
                            .font(.body)

                        Text("Page: \(sentence.pageNumber)")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text(sentence.sourceFilename ?? "")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                    .tag(sentence) // ✅ link row to selection
                }
            }
            .navigationTitle("Sentences")

        } detail: {
            if let sentence = selectedSentence {
                PDFViewRepresentable(
                    filename: sentence.sourceFilename ?? "",
                    targetPage: sentence.pageNumber
                )
            } else {
                Text("Select a sentence to view its source PDF")
                    .foregroundColor(.secondary)
            }
        }
    }
}

