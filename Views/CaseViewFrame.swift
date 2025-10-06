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

    // Single-mode selection (kept)
    @State private var selectedHeading: HeadingEntity? = nil

    // Split-mode derived selections
    @State private var pairedHeading: HeadingEntity? = nil     // from the NavPanel
    @State private var leftHeading: HeadingEntity? = nil       // drives left PDF
    @State private var rightHeading: HeadingEntity? = nil      // drives right PDF

    // Toggle state
    @State private var isSplitViewMode: Bool = false

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
            // Sidebar: pleadings navigation (reused)
            if let document = documents.first {
                PleadingsNavPanel(
                    document: document,
                    selectedHeading: $selectedHeading,
                    pairedHeading: $pairedHeading
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
        // When primary or paired updates, compute left/right placement
        .onChange(of: selectedHeading) { _ in
            recomputeSplitTargets()
        }
        .onChange(of: pairedHeading) { _ in
            recomputeSplitTargets()
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
                    // Keep current selections; no reset needed
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

    // Decide which side each heading should occupy
    private func recomputeSplitTargets() {
        guard let primary = selectedHeading else {
            leftHeading = nil
            rightHeading = nil
            return
        }

        let text = (primary.text ?? "").lowercased()
        let isAnswer = text.contains("ans.") || text.contains("answer")

        if isAnswer {
            // Right = the clicked Answer; Left = its Statement/Cond (if any)
            rightHeading = primary
            leftHeading = pairedHeading
        } else {
            // Left = the clicked Statement/Cond; Right = its Answer (if any)
            leftHeading = primary
            rightHeading = pairedHeading
        }

        if let l = leftHeading?.text { print("🟩 Left target → \(l)") }
        if let r = rightHeading?.text { print("🟦 Right target → \(r)") }
    }

    // Existing mapping bootstrap
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

