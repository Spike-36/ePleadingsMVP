//
//  CaseViewFrame.swift
//  ePleadingsMVP
//
//  Created by Peter Milligan on 26/09/2025.
//

import SwiftUI

enum CaseViewMode: String, CaseIterable, Identifiable {
    case issues = "Issues"
    case pleadings = "Pleadings"
    
    var id: String { rawValue }
}

struct CaseViewFrame: View {
    let caseInfo: CaseInfo   // ✅ now accepts the case being passed in
    
    @State private var mode: CaseViewMode = .pleadings
    @State private var selectedPage: Int? = nil   // 👉 shared state
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack {
            // Dropdown picker
            Picker("View", selection: $mode) {
                ForEach(CaseViewMode.allCases) { m in
                    Text(m.rawValue).tag(m)
                }
            }
            .pickerStyle(.menu)
            .padding(.horizontal)
            
            Divider()
            
            // Sidebar + main view skeleton
            NavigationSplitView {
                switch mode {
                case .issues:
                    Text("Sidebar: Issues")
                case .pleadings:
                    // ✅ Pass binding into PleadingsNavPanel
                    PleadingsNavPanel(
                        sourceFilename: caseInfo.sourceFilename ?? "unknown.docx",
                        selectedPage: $selectedPage
                    )
                }
            } detail: {
                switch mode {
                case .issues:
                    Text("Main View: Issues")
                case .pleadings:
                    // ✅ Pass plain value into PleadingsPanel
                    PleadingsPanel(
                        caseInfo: caseInfo,
                        selectedPage: selectedPage
                    )
                }
            }
        }
        .navigationTitle(caseInfo.displayName)  // ✅ show the case name here
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button("Back") { dismiss() }
            }
            
            ToolbarItem(placement: .automatic) {
                Button("Debug DB") {
                    let persistence = PersistenceController.shared
                    persistence.debugPrintSentences(limit: 20)   // ✅ show sentences
                    persistence.debugPrintHeadings(limit: 20)    // ✅ show headings
                    persistence.runRelationshipTest()            // ✅ check relationships
                }
            }
        }
    }
}

