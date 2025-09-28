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
        sortDescriptors: [NSSortDescriptor(keyPath: \SentenceEntity.pageNumber, ascending: true)],
        animation: .default
    )
    private var sentences: FetchedResults<SentenceEntity>

    var body: some View {
        VStack {
            HStack {
                Button("Add Dummy") {
                    addDummySentence()
                }
                .padding(.trailing, 8)

                Button("Import DOCX") {
                    importDocx()
                }
                .padding(.trailing, 8)

                Button("Clear All", role: .destructive) {
                    clearAllSentences()
                }
            }
            .padding()

            List {
                ForEach(sentences) { sentence in
                    Text(sentence.text ?? "Untitled")
                }
                .onDelete(perform: deleteSentences)
            }
        }
        .navigationTitle("Sentences")
    }

    // MARK: - Actions

    private func addDummySentence() {
        let newSentence = SentenceEntity(context: viewContext)
        newSentence.text = "This is a dummy sentence."

        // Use count of current fetch for pageNumber
        let nextPage = sentences.count + 1
        newSentence.pageNumber = Int32(nextPage)

        saveContext()
    }

    private func importDocx() {
        importService.importFileAndReturn()
    }

    private func clearAllSentences() {
        for sentence in sentences {
            viewContext.delete(sentence)
        }
        saveContext()
    }

    private func deleteSentences(offsets: IndexSet) {
        for index in offsets {
            let sentence = sentences[index]
            viewContext.delete(sentence)
        }
        saveContext()
    }

    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            print("❌ Failed to save context: \(error)")
        }
    }
}

