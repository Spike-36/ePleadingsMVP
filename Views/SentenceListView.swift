//
//  SentenceListView.swift
//  ePleadingsMVP
//

import SwiftUI
import CoreData

struct SentenceListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var importService = ImportService()

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Sentence.pageNumber, ascending: true)],
        animation: .default
    )
    private var sentences: FetchedResults<Sentence>

    var body: some View {
        VStack {
            HStack {
                Button("Add Dummy") { addDummySentence() }
                    .padding(.trailing, 8)

                Button("Import DOCX") { importDocx() }
                    .padding(.trailing, 8)

                Button("Clear All", role: .destructive) { clearAllSentences() }
            }
            .padding(.top, 12)

            Text("Sentences in DB")
                .font(.headline)
                .padding(.bottom, 8)

            List(sentences, id: \.id) { sentence in
                VStack(alignment: .leading) {
                    Text(sentence.text ?? "")
                        .font(.body)
                    Text("Page: \(sentence.pageNumber)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(sentence.sourceFilename ?? "")
                               .font(.caption2)
                               .foregroundColor(.gray)
                }
            }
        }
        .padding()
    }

    // MARK: - Helpers

    private func addDummySentence() {
        let s = Sentence(context: viewContext)
        s.id = UUID()
        s.text = "Test sentence at \(Date())"
        s.pageNumber = Int32(Int.random(in: 1...100))
        s.sourceFilename = "Dummy.docx"
        try? viewContext.save()
    }

    private func importDocx() {
        // ✅ Parse immediately from the picker result to avoid duplicate runs
        guard let caseFile = importService.importFileAndReturn(into: "defaultcase"),
              let docxURL = caseFile.docxURL else {
            print("⚠️ No DOCX selected")
            return
        }

        do {
            let parser = DocxParser()
            let paragraphs = try parser.parseDocx(at: docxURL)

            for (idx, para) in paragraphs.enumerated() {
                let s = Sentence(context: viewContext)
                s.id = UUID()
                s.text = para
                s.pageNumber = Int32(idx + 1)   // 1-based for readability
                s.sourceFilename = docxURL.lastPathComponent
            }

            try viewContext.save()
            print("✅ Imported \(paragraphs.count) paragraphs")
        } catch {
            print("❌ Import failed: \(error.localizedDescription)")
        }
    }

    private func clearAllSentences() {
        for s in sentences { viewContext.delete(s) }
        try? viewContext.save()
    }
}

