//
//  StartupView.swift
//  ePleadingsMVP
//

import SwiftUI

struct StartupView: View {
    @ObservedObject var caseManager = CaseManager.shared
    private let importService = ImportService()
    
    @State private var selectedCase: CaseInfo? = nil   // 👉 used for delete
    @State private var navTarget: CaseInfo? = nil      // 👉 drives CaseDetailView
    @State private var showingNewCaseSheet = false
    @State private var newCaseName: String = ""
    
    // 👉 New: toggle for launching CaseViewFrame
    @State private var frameTarget: CaseInfo? = nil
    
    var body: some View {
        NavigationStack {
            caseList
                .navigationTitle("Cases")
                .toolbar { toolbarContent }
                .background(detailNavigationLink)
                .background(frameNavigationLink)
                .sheet(isPresented: $showingNewCaseSheet) {
                    newCaseSheet
                }
        }
    }
}

// MARK: - Case List
extension StartupView {
    private var caseList: some View {
        List(caseManager.cases, id: \.name) { caseInfo in
            caseRow(for: caseInfo)
        }
    }
    
    private func caseRow(for caseInfo: CaseInfo) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(caseInfo.displayName)
                    .foregroundColor(.primary)
                    .onTapGesture {
                        selectedCase = caseInfo
                        caseManager.activeCase = caseInfo   // persist
                    }
                
                HStack {
                    Image(systemName: caseInfo.hasDocx ? "doc.fill" : "doc")
                        .foregroundColor(caseInfo.hasDocx ? .green : .red)
                    Image(systemName: caseInfo.hasPdf ? "doc.richtext.fill" : "doc.richtext")
                        .foregroundColor(caseInfo.hasPdf ? .green : .red)
                }
            }
            
            Spacer()
            
            Image(systemName: selectedCase == caseInfo ? "checkmark.circle.fill" : "circle")
                .foregroundColor(.blue)
        }
    }
}

// MARK: - Toolbar
extension StartupView {
    private var toolbarContent: some ToolbarContent {
        Group {
            // ➕ New Case
            ToolbarItem(placement: .automatic) {
                Button {
                    showingNewCaseSheet = true
                } label: {
                    Label("New Case", systemImage: "plus")
                }
            }
            
            // ⬇️ Import
            ToolbarItem(placement: .automatic) {
                Button {
                    if let target = selectedCase ?? caseManager.activeCase {
                        if let result = importService.importFileAndReturn(into: target.name) {
                            print("✅ Imported file: \(result)")
                            caseManager.refreshCases()
                            caseManager.activeCase = target
                            selectedCase = target
                        }
                    } else {
                        print("⚠️ No case selected for import")
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
            
            // 🧪 Frame Test → CaseViewFrame
            ToolbarItem(placement: .automatic) {
                Button {
                    if let target = selectedCase ?? caseManager.activeCase {
                        frameTarget = target   // 🔑 triggers navigation to CaseViewFrame
                    } else {
                        print("⚠️ No case selected to view frame")
                    }
                } label: {
                    Label("Frame Test", systemImage: "square.grid.2x2")
                }
            }
            
            // 📄 Detail Test → CaseDetailView
            ToolbarItem(placement: .automatic) {
                Button {
                    if let target = selectedCase ?? caseManager.activeCase {
                        navTarget = target   // 🔑 triggers navigation to CaseDetailView
                    } else {
                        print("⚠️ No case selected to view detail")
                    }
                } label: {
                    Label("Detail Test", systemImage: "doc.text.magnifyingglass")
                }
            }
        }
    }
}

// MARK: - Navigation
extension StartupView {
    private var detailNavigationLink: some View {
        NavigationLink(
            destination: navDestination(),
            isActive: Binding(
                get: { navTarget != nil },
                set: { if !$0 { navTarget = nil } }
            )
        ) { EmptyView() }
        .hidden()
    }
    
    private var frameNavigationLink: some View {
        NavigationLink(
            destination: frameDestination(),
            isActive: Binding(
                get: { frameTarget != nil },
                set: { if !$0 { frameTarget = nil } }
            )
        ) { EmptyView() }
        .hidden()
    }
    
    @ViewBuilder
    private func navDestination() -> some View {
        if let caseInfo = navTarget {
            if caseInfo.hasDocx && caseInfo.hasPdf {
                CaseDetailView(caseInfo: caseInfo)
            } else {
                MissingFilesView(caseInfo: caseInfo)
            }
        }
    }
    
    @ViewBuilder
    private func frameDestination() -> some View {
        if let caseInfo = frameTarget {
            CaseViewFrame(caseInfo: caseInfo)
        }
    }
}

// MARK: - New Case Sheet
extension StartupView {
    private var newCaseSheet: some View {
        VStack {
            Text("Enter new case name:")
                .font(.headline)
            TextField("Case name", text: $newCaseName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            HStack {
                Button("Cancel") {
                    showingNewCaseSheet = false
                    newCaseName = ""
                }
                Spacer()
                Button("Create") {
                    do {
                        try caseManager.createCase(named: newCaseName)
                        print("📂 Created new case: \(newCaseName)")
                    } catch {
                        print("❌ Failed to create new case: \(error)")
                    }
                    showingNewCaseSheet = false
                    newCaseName = ""
                }
                .disabled(newCaseName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
        }
        .padding()
        .frame(width: 350, height: 150)
    }
}

