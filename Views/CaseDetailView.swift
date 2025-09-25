//
//  CaseDetailView.swift
//  ePleadingsMVP
//
//  Created by Pete on 25/09/2025.
//

import SwiftUI
import PDFKit

// MARK: - Dummy Sentence Model (to avoid Core Data conflict)
struct DummySentence: Identifiable {
    let id = UUID()
    let text: String
    let pageNumber: Int
    let sourceFilename: String
}

// MARK: - ViewModel
final class CaseViewModel: ObservableObject {
    @Published var sentences: [DummySentence] = []

    init() {
        loadDummyData()
    }

    private func loadDummyData() {
        sentences = [
            DummySentence(text: "This is page 1 argument.", pageNumber: 1, sourceFilename: "pleadingsShort.pdf"),
            DummySentence(text: "This is page 2 evidence.", pageNumber: 2, sourceFilename: "pleadingsShort.pdf"),
            DummySentence(text: "This is page 3 conclusion.", pageNumber: 3, sourceFilename: "pleadingsShort.pdf")
        ]
    }
}

// MARK: - View
struct CaseDetailView: View {
    @ObservedObject var viewModel = CaseViewModel()

    var body: some View {
        VStack(alignment: .leading) {
            Text("Case Detail (Dummy Data)")
                .font(.headline)
                .padding(.bottom, 8)

            List(viewModel.sentences) { sentence in
                VStack(alignment: .leading, spacing: 4) {
                    Text(sentence.text)
                        .font(.body)
                    Text("Page \(sentence.pageNumber)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(sentence.sourceFilename)
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
    }
}

