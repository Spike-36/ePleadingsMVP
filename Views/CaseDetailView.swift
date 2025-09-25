//
//  CaseDetailView.swift
//  ePleadingsMVP
//

import SwiftUI
import PDFKit

struct CaseDetailView: View {
    let caseInfo: CaseInfo   // 👈 passed in from StartupView
    
    @StateObject private var viewModel: CaseViewModel
    @State private var selectedSentence: SentenceItem? = nil
    @ObservedObject private var caseManager = CaseManager.shared
    @StateObject private var importService = ImportService()
    
    // Custom init so we can inject CaseInfo into the view model
    init(caseInfo: CaseInfo) {
        self.caseInfo = caseInfo
        _viewModel = StateObject(wrappedValue: CaseViewModel(caseInfo: caseInfo))
    }
    
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
                        
                        if let url = sentence.sourceURL {
                            Text(url.lastPathComponent)
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                    }
                    .tag(sentence)
                }
            }
            .navigationTitle(caseInfo.displayName)
            
        } detail: {
            if let sentence = selectedSentence,
               let url = sentence.sourceURL {
                PDFViewRepresentable(
                    fileURL: url,
                    targetPage: sentence.pageNumber
                )
            } else {
                Text("Select a sentence to view its source PDF")
                    .foregroundColor(.secondary)
            }
        }
        .toolbar {
            // ✅ Back to cases
            ToolbarItem(placement: .automatic) {
                Button {
                    caseManager.closeCase()
                } label: {
                    Label("Cases", systemImage: "folder")
                }
            }
            
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

