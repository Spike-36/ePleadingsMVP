//
//  CaseViewFrame.swift
//  ePleadingsMVP
//
//  Created by Peter Milligan on 26/09/2025.
//

import SwiftUI
import CoreData

struct CaseViewFrame: View {
    let caseEntity: CaseEntity   // 👈 Core Data entity
    
    @State private var selectedHeading: HeadingEntity? = nil   // 🔄 track heading
    
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    // 👇 Fetch documents linked to this CaseEntity
    @FetchRequest private var documents: FetchedResults<DocumentEntity>
    
    init(caseEntity: CaseEntity) {
        self.caseEntity = caseEntity
        _documents = FetchRequest(
            entity: DocumentEntity.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \DocumentEntity.filename, ascending: true)],
            predicate: NSPredicate(format: "caseEntity == %@", caseEntity) // ✅ filter by relationship
        )
    }
    
    var body: some View {
        NavigationSplitView {
            // Sidebar: pleadings navigation
            if let document = documents.first {
                PleadingsNavPanel(
                    document: document,
                    selectedHeading: $selectedHeading
                )
            } else {
                Text("No pleadings document found")
                    .foregroundColor(.secondary)
            }
        } detail: {
            // Main panel: pleadings viewer
            PleadingsPanel(
                caseEntity: caseEntity,
                selectedHeading: $selectedHeading
            )
        }
        .onAppear {
            runHeadingMapperIfNeeded()
        }
        .onChange(of: selectedHeading) { newHeading in
            if let h = newHeading {
                print("✅ CaseViewFrame observed selectedHeading change → \(h.text ?? "nil") [page \(h.mappedPageNumber)]")
            }
        }
        .navigationTitle(caseEntity.filename)
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button("Back") { dismiss() }
            }
            
            ToolbarItem(placement: .automatic) {
                Button("Debug DB") {
                    let persistence = PersistenceController.shared
                    persistence.debugPrintSentences(limit: 20)
                    persistence.debugPrintHeadings(limit: 20)
                    persistence.runRelationshipTest()
                }
            }
        }
    }
    
    private func runHeadingMapperIfNeeded() {
        guard let document = documents.first,
              let path = document.filePath else { return }
        
        let pdfURL = URL(fileURLWithPath: path)
        let mapper = HeadingToPageMapper(context: viewContext, pdfURL: pdfURL)
        mapper.mapHeadingsToPages()
    }
}

