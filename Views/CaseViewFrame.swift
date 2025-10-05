//
//  CaseViewFrame.swift
//  ePleadingsMVP
//
//  Created by Peter Milligan on 26/09/2025.
//

import SwiftUI
import CoreData

struct CaseViewFrame: View {
    let caseEntity: CaseEntity
    @State private var selectedHeading: HeadingEntity? = nil
    @State private var leftHeading: HeadingEntity? = nil     // 👉 new
    @State private var rightHeading: HeadingEntity? = nil    // 👉 new
    @State private var isSplitViewMode: Bool = false         // toggle state

    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @FetchRequest private var documents: FetchedResults<DocumentEntity>

    init(caseEntity: CaseEntity) {
        self.caseEntity = caseEntity
        _documents = FetchRequest(
            entity: DocumentEntity.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \DocumentEntity.filename, ascending: true)],
            predicate: NSPredicate(format: "caseEntity == %@", caseEntity)
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
            // 👉 Conditional main panel
            if isSplitViewMode {
                SplitPleadingsPanel(
                    caseEntity: caseEntity,
                    leftHeading: $leftHeading,
                    rightHeading: $rightHeading
                )
            } else {
                PleadingsPanel(
                    caseEntity: caseEntity,
                    selectedHeading: $selectedHeading
                )
            }
        }
        .onAppear { runHeadingMapperIfNeeded() }
        .onChange(of: selectedHeading) { newHeading in
            if let h = newHeading {
                print("✅ selectedHeading → \(h.text ?? "nil") [page \(h.mappedPageNumber)]")
            }
        }
        .navigationTitle(caseEntity.filename)
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button("Back") { dismiss() }
            }

            ToolbarItem(placement: .automatic) {
                Button(isSplitViewMode ? "Single View" : "Split View") {
                    isSplitViewMode.toggle()
                    print("🔁 Split view mode toggled → \(isSplitViewMode ? "ON" : "OFF")")
                }
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

        let pdfDocEntity = docs.first { ($0.filePath ?? "").lowercased().hasSuffix(".pdf") }
        let docxDocEntity = docs.first { ($0.filePath ?? "").lowercased().hasSuffix(".docx") }

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

        let headings: [HeadingEntity] =
            (docxDocEntity?.headings?.allObjects as? [HeadingEntity]) ??
            (pdfDocEntity?.headings?.allObjects as? [HeadingEntity]) ??
            []

        print("🧭 runHeadingMapperIfNeeded → Using PDF: \(pdfURL.lastPathComponent); headings=\(headings.count)")

        guard let mapper = HeadingToPageMapper(context: viewContext, pdfURL: pdfURL) else { return }
        mapper.mapHeadings(headings)
    }
}

