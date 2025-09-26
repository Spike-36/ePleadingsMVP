//
//  StartupView.swift
//  ePleadingsMVP
//

import SwiftUI

struct StartupView: View {
    @ObservedObject var caseManager = CaseManager.shared
    private let importService = ImportService()
    
    @State private var selectedCase: CaseInfo? = nil   // 👉 used for delete
    @State private var navTarget: CaseInfo? = nil      // 👉 drives NavigationLink
    
    var body: some View {
        NavigationStack {
            List(caseManager.cases, id: \.name) { caseInfo in
                HStack {
                    VStack(alignment: .leading) {
                        Text(caseInfo.displayName)
                            .foregroundColor(.primary)
                            // ✅ Single tap = select for delete
                            .onTapGesture {
                                selectedCase = caseInfo
                            }
                            // ✅ Double tap = navigate to detail
                            .simultaneousGesture(
                                TapGesture(count: 2).onEnded {
                                    navTarget = caseInfo
                                }
                            )
                        
                        HStack {
                            Image(systemName: caseInfo.hasDocx ? "doc.fill" : "doc")
                                .foregroundColor(caseInfo.hasDocx ? .green : .red)
                            Image(systemName: caseInfo.hasPdf ? "doc.richtext.fill" : "doc.richtext")
                                .foregroundColor(caseInfo.hasPdf ? .green : .red)
                        }
                    }
                    
                    Spacer()
                    
                    // Selection indicator for delete
                    Image(systemName: selectedCase == caseInfo ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(.blue)
                }
            }
            .navigationTitle("Cases")
            .toolbar {
                // ➕ New Case
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
                
                // ⬇️ Import
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
                
                // 🗑️ Delete
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
            // ✅ NavigationLink driven by navTarget (using isActive form)
            .background(
                NavigationLink(
                    destination: navDestination(),
                    isActive: Binding(
                        get: { navTarget != nil },
                        set: { if !$0 { navTarget = nil } }
                    )
                ) { EmptyView() }
                .hidden()
            )
        }
    }
    
    @ViewBuilder
    private func navDestination() -> some View {
        if let caseInfo = navTarget {
            if caseInfo.hasDocx && caseInfo.hasPdf {
                CaseDetailView(caseInfo: caseInfo)
            } else {
                MissingFilesView(caseInfo: caseInfo)
            }
        } else {
            EmptyView()
        }
    }
}

