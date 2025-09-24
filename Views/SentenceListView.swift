//
//  SentenceListView.swift
//  ePleadingsMVP
//
//  Created by Peter Milligan on 24/09/2025.
//

import SwiftUI
import CoreData

struct SentenceListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Sentence.pageNumber, ascending: true)],
        animation: .default
    )
    private var sentences: FetchedResults<Sentence>
    
    var body: some View {
        VStack {
            HStack {
                Button("Add Dummy") {
                    addDummySentence()
                }
                .padding(.trailing, 8)
                
                Button("Clear All", role: .destructive) {
                    clearAllSentences()
                }
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
                }
            }
        }
        .padding()
    }
    
    private func addDummySentence() {
        let newSentence = Sentence(context: viewContext)
        newSentence.id = UUID()
        newSentence.text = "Test sentence at \(Date())"
        newSentence.pageNumber = Int32(Int.random(in: 1...100))
        newSentence.sourceFilename = "Dummy.docx"
        
        do {
            try viewContext.save()
        } catch {
            print("❌ Error saving: \(error.localizedDescription)")
        }
    }
    
    private func clearAllSentences() {
        for sentence in sentences {
            viewContext.delete(sentence)
        }
        
        do {
            try viewContext.save()
        } catch {
            print("❌ Error clearing: \(error.localizedDescription)")
        }
    }
}

