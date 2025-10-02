//  CaseDetailView.swift
//  ePleadingsMVP
//

import SwiftUI
import PDFKit
import CoreData

#if false   // 🔒 Disable CaseDetailView for now (kept for reference)

struct CaseDetailView: View {
    let caseInfo: CaseInfo   // 👈 passed in from StartupView
    
    @Environment(\.managedObjectContext) private var context
    @StateObject private var viewModel: CaseViewModel
    @State private var selectedSentenceID: String? = nil   // 👈 matches SentenceItem.id
    @State private var selectedPage: Int? = nil            // 👈 new binding for PDFView
    
    @StateObject private var importService = ImportService()
    
    // ✅ Single init – always use environment context
    init(caseInfo: CaseInfo) {
        self.caseInfo = caseInfo
        _viewModel = StateObject(
            wrappedValue: CaseViewModel(
                caseInfo: caseInfo,
                context: PersistenceController.shared.container.viewContext
            )
        )
    }
    
    var body: some View {
        NavigationSplitView {
            // LEFT PANE → sentence list with selection
            List(selection: $selectedSentenceID) {
                Section(header: Text("Parsed Sentences (debug)")
                    .font(.caption)
                    .foregroundColor(.secondary)) {
                        
                    ForEach(viewModel.sentences) { sentence in
                        VStack(alignment: .leading) {
                            Text(sentence.text)
                                .font(.body)
                            
                            Text("Page: \(sentence.pageNumber)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            if let filename = sentence.sourceFilename {
                                Text(filename)
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            }
                        }
                        .tag(sentence.id)   // 👈 tag with String
                    }
                }
            }
            .navigationTitle(caseInfo.displayName)
            
        } detail: {
            if let id = selectedSentenceID,
               let sentence = viewModel.sentences.first(where: { $0.id == id }),
               let url = sentence.resolvedURL(in: caseInfo.url) {
                
                // ✅ keep selectedPage in sync with selected sentence
                PDFViewRepresentable(
                    url: url,
                    selectedPage: Binding(
                        get: { selectedPage ?? sentence.pageNumber },
                        set: { selectedPage = $0 }
                    )
                )
                .onAppear {
                    selectedPage = sentence.pageNumber
                }
                
            } else {
                Text("Select a sentence to view its source PDF")
                    .foregroundColor(.secondary)
            }
        }
        .toolbar {
            // ✅ Import file into this case
            ToolbarItem(placement: .automatic) {
                Button {
                    if let result = importService.importFileAndReturn(into: caseInfo.displayName) {
                        print("✅ Imported file: \(result)")
                        viewModel.reloadCase()
                    }
                } label: {
                    Label("Import", systemImage: "square.and.arrow.down")
                }
            }
        }
    }
}

#endif

