//
//  StartupView.swift
//  ePleadingsMVP
//

import SwiftUI
import CoreData

struct StartupView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    // Selected Core Data entities
    @State private var selectedCase: CaseEntity? = nil
    @State private var navTarget: CaseEntity? = nil
    @State private var frameTarget: CaseEntity? = nil
    
    @State private var showingNewCaseSheet = false
    @State private var newCaseFilename: String = ""   // ✅ renamed for clarity
    
    // 👉 Fetch all saved cases
    @FetchRequest(
        entity: CaseEntity.entity(),
        sortDescriptors: []   // no sort for now
    ) private var cases: FetchedResults<CaseEntity>
    
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
        List(cases, id: \.id) { caseEntity in
            caseRow(for: caseEntity)
        }
    }
    
    private func caseRow(for caseEntity: CaseEntity) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(caseEntity.filename)   // ✅ now consistent everywhere
                    .foregroundColor(.primary)
                    .onTapGesture {
                        selectedCase = caseEntity
                    }
                
                // placeholder icons
                HStack {
                    Image(systemName: "doc")
                        .foregroundColor(.secondary)
                    Image(systemName: "doc.richtext")
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Image(systemName: selectedCase == caseEntity ? "checkmark.circle.fill" : "circle")
                .foregroundColor(.blue)
        }
    }
}

// MARK: - Toolbar
extension StartupView {
    private var toolbarContent: some ToolbarContent {
        Group {
            ToolbarItem(placement: .automatic) {
                Button {
                    showingNewCaseSheet = true
                } label: {
                    Label("New Case", systemImage: "plus")
                }
            }
            
            ToolbarItem(placement: .automatic) {
                Button(role: .destructive) {
                    if let caseToDelete = selectedCase {
                        viewContext.delete(caseToDelete)
                        try? viewContext.save()
                        selectedCase = nil
                    }
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                .disabled(selectedCase == nil)
            }
            
            ToolbarItem(placement: .automatic) {
                Button {
                    if let target = selectedCase {
                        frameTarget = target
                    }
                } label: {
                    Label("Frame Test", systemImage: "square.grid.2x2")
                }
            }
            
            ToolbarItem(placement: .automatic) {
                Button {
                    if let target = selectedCase {
                        navTarget = target
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
        if let _ = navTarget {
            // placeholder until CaseDetailView is restored
            Text("Detail view disabled (CaseDetailView removed)")
                .foregroundColor(.secondary)
        }
    }
    
    @ViewBuilder
    private func frameDestination() -> some View {
        if let caseEntity = frameTarget {
            CaseViewFrame(caseEntity: caseEntity)
        }
    }
}

// MARK: - New Case Sheet
extension StartupView {
    private var newCaseSheet: some View {
        VStack {
            Text("Enter new case filename:")
                .font(.headline)
            TextField("Case filename", text: $newCaseFilename)   // ✅ renamed binding
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            HStack {
                Button("Cancel") {
                    showingNewCaseSheet = false
                    newCaseFilename = ""
                }
                Spacer()
                Button("Create") {
                    let new = CaseEntity(context: viewContext)
                    new.id = UUID()
                    new.filename = newCaseFilename   // ✅ set filename not name
                    new.createdAt = Date()
                    try? viewContext.save()
                    showingNewCaseSheet = false
                    newCaseFilename = ""
                }
                .disabled(newCaseFilename.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
        }
        .padding()
        .frame(width: 350, height: 150)
    }
}

