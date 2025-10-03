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
        let docs = Array(documents)
        guard !docs.isEmpty else { return }
        
        // Prefer a PDF doc
        let pdfDocEntity = docs.first { ($0.filePath ?? "").lowercased().hasSuffix(".pdf") }
        let docxDocEntity = docs.first { ($0.filePath ?? "").lowercased().hasSuffix(".docx") }
        
        // Resolve actual PDF URL
        var resolvedPDFURL: URL?
        if let pdfPath = pdfDocEntity?.filePath {
            resolvedPDFURL = URL(fileURLWithPath: pdfPath)
        } else if let docxPath = docxDocEntity?.filePath {
            let candidate = URL(fileURLWithPath: docxPath)
                .deletingPathExtension()
                .appendingPathExtension("pdf")
            if FileManager.default.fileExists(atPath: candidate.path) {
                resolvedPDFURL = candidate
            }
        }
        
        guard let pdfURL = resolvedPDFURL else {
            print("❌ No PDF available for mapping for case \(caseEntity.filename ?? "<no name>")")
            return
        }
        
        // Use headings from the DOCX (fallback: headings from the PDF doc entity)
        let headings: [HeadingEntity] =
            (docxDocEntity?.headings?.allObjects as? [HeadingEntity]) ??
            (pdfDocEntity?.headings?.allObjects as? [HeadingEntity]) ??
            []
        
        print("🧭 runHeadingMapperIfNeeded → Using PDF: \(pdfURL.lastPathComponent); headings=\(headings.count)")
        
        guard let mapper = HeadingToPageMapper(context: viewContext, pdfURL: pdfURL) else {
            return
        }
        mapper.mapHeadings(headings)
    }
}

