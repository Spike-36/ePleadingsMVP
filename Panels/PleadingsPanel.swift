//
//  PleadingsPanel.swift
//  ePleadingsMVP
//
//  Phase 6.2 — PDF discovery fix + verified path validation
//

import SwiftUI
import PDFKit
import CoreData

struct PleadingsPanel: View {
    let caseEntity: CaseEntity
    @Binding var selectedHeading: HeadingEntity?

    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest private var documents: FetchedResults<DocumentEntity>

    init(caseEntity: CaseEntity, selectedHeading: Binding<HeadingEntity?>) {
        self.caseEntity = caseEntity
        _selectedHeading = selectedHeading
        _documents = FetchRequest(
            entity: DocumentEntity.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \DocumentEntity.filename, ascending: true)],
            predicate: NSPredicate(format: "caseEntity == %@", caseEntity)
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            if let pdfURL = resolvedPDFURL() {
                // ✅ Match InteractivePDFViewRepresentable signature (no selectedHeading param)
                InteractivePDFViewRepresentable(
                    url: pdfURL,
                    context: viewContext,
                    caseEntity: caseEntity
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onAppear {
                    print("📄 PleadingsPanel using InteractivePDFView → \(pdfURL.lastPathComponent)")
                }

            } else {
                VStack {
                    Text("No PDF available for this case.")
                        .foregroundColor(.secondary)
                    Text("(Ensure a PDF or matching .docx/.pdf pair exists in the case folder.)")
                        .font(.footnote)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Color(NSColor.textBackgroundColor))
    }

    // MARK: - Resolve PDF path
    private func resolvedPDFURL() -> URL? {
        let docs = Array(documents)
        guard !docs.isEmpty else { return nil }

        // ✅ 1. Prefer actual PDFs first — and verify the file exists
        if let pdfDoc = docs.first(where: { ($0.filePath ?? "").lowercased().hasSuffix(".pdf") }),
           let path = pdfDoc.filePath,
           FileManager.default.fileExists(atPath: path) {
            print("🧭 Found actual PDF at: \(path)")
            return URL(fileURLWithPath: path)
        }

        // ✅ 2. Fallback to a derived PDF path based on DOCX location
        if let docxDoc = docs.first(where: { ($0.filePath ?? "").lowercased().hasSuffix(".docx") }),
           let docxPath = docxDoc.filePath {
            let candidate = URL(fileURLWithPath: docxPath)
                .deletingPathExtension()
                .appendingPathExtension("pdf")
            if FileManager.default.fileExists(atPath: candidate.path) {
                print("🧭 Derived PDF found at: \(candidate.path)")
                return candidate
            } else {
                print("⚠️ Derived PDF not found at: \(candidate.path)")
            }
        }

        // ✅ Fixed: UUID is non-optional, remove `?`
        print("⚠️ No matching PDF found for case \(caseEntity.id.uuidString)")
        return nil
    }
}

