//
//  StartupView.swift
//  ePleadingsMVP
//

import SwiftUI

struct StartupView: View {
    @ObservedObject var caseManager = CaseManager.shared
    private let importService = ImportService()   // ✅ no StateObject
    @State private var selectedCase: CaseInfo? = nil   // 👈 only used for delete
    
    var body: some View {
        NavigationStack {
            List(caseManager.cases, id: \.name) { caseInfo in
                HStack {
                    NavigationLink {
                        if caseInfo.hasDocx && caseInfo.hasPdf {
                            CaseDetailView(caseInfo: caseInfo)
                        } else {
                            MissingFilesView(caseInfo: caseInfo)
                        }
                    } label: {
                        HStack {
                            Text(caseInfo.displayName)
                            Spacer()
                            // ✅ status indicators
                            Image(systemName: caseInfo.hasDocx ? "doc.fill" : "doc")
                                .foregroundColor(caseInfo.hasDocx ? .green : .red)
                            Image(systemName: caseInfo.hasPdf ? "doc.richtext.fill" : "doc.richtext")
                                .foregroundColor(caseInfo.hasPdf ? .green : .red)
                        }
                    }
                    
                    // 👇 Select for delete
                    Button {
                        selectedCase = caseInfo
                    } label: {
                        Image(systemName: selectedCase == caseInfo ? "checkmark.circle.fill" : "circle")
                    }
                    .buttonStyle(.borderless)
                }
            }
            .navigationTitle("Cases")
            .toolbar {
                // ✅ New Case
                ToolbarItem(placement: .automatic) {
                    Button {
                        do {
                            let displayName = "NewCase-\(UUID().uuidString.prefix(4))"
                            try caseManager.createCase(named: displayName)
                            print("📂 Created new case: \(displayName)")
                        } catch {
                            print("❌ Failed to create new case: \(error)")
                        }
                    } label: {
                        Label("New Case", systemImage: "plus")
                    }
                }
                
                // ✅ Import Case (generic)
                ToolbarItem(placement: .automatic) {
                    Button {
                        if let result = importService.importFileAndReturn() {
                            print("✅ Imported file: \(result)")
                            caseManager.refreshCases()
                        }
                    } label: {
                        Label("Import", systemImage: "square.and.arrow.down")
                    }
                }
                
                // 🗑️ Delete Case
                ToolbarItem(placement: .automatic) {
                    Button(role: .destructive) {
                        if let caseToDelete = selectedCase {
                            do {
                                try caseManager.deleteCase(named: caseToDelete.name)
                                selectedCase = nil
                                print("🗑️ Deleted case: \(caseToDelete.displayName)")
                            } catch {
                                print("❌ Failed to delete case: \(error)")
                            }
                        }
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    .disabled(selectedCase == nil)
                }
            }
        }
    }
}

