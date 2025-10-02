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
    
    @State private var selectedPage: Int? = nil
    
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    // 👇 Fetch documents linked to this CaseEntity
    @FetchRequest private var documents: FetchedResults<DocumentEntity>
    
    init(caseEntity: CaseEntity) {
        self.caseEntity = caseEntity
        _documents = FetchRequest(
            entity: DocumentEntity.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \DocumentEntity.filename, ascending: true)],
            predicate: NSPredicate(format: "case == %@", caseEntity)   // ✅ Core Data key is "case"
        )
    }
    
    var body: some View {
        NavigationSplitView {
            // Sidebar: pleadings navigation
            if let document = documents.first {
                PleadingsNavPanel(
                    document: document,
                    selectedPage: $selectedPage
                )
            } else {
                Text("No pleadings document found")
                    .foregroundColor(.secondary)
            }
        } detail: {
            // Main panel: pleadings viewer
            PleadingsPanel(
                caseEntity: caseEntity,
                selectedPage: $selectedPage
            )
        }
        .onChange(of: selectedPage) { newPage in
            if let page = newPage {
                print("✅ CaseViewFrame observed selectedPage change →", page)
            }
        }
        // ✅ direct property access — no more KVC
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
}

