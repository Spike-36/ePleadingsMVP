//
//  CaseViewFrame.swift
//  ePleadingsMVP
//
//  Created by Peter Milligan on 26/09/2025.
//

import SwiftUI

// ✅ CaseViewMode enum (only once)
enum CaseViewMode: String, CaseIterable, Identifiable {
    case issues = "Issues"
    case pleadings = "Pleadings"

    var id: String { rawValue }
}

// ✅ CaseViewFrame struct (only once)
struct CaseViewFrame: View {
    let caseInfo: CaseInfo   // accepts the case being passed in
    
    @State private var mode: CaseViewMode = .pleadings
    @State private var selectedPage: Int? = nil   // shared state
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack {
            // Picker to switch modes
            Picker("View", selection: $mode) {
                ForEach(CaseViewMode.allCases) { m in
                    Text(m.rawValue).tag(m)
                }
            }
            .pickerStyle(.menu)
            .padding(.horizontal)
            
            Divider()
            
            // SplitView with sidebar + detail
            NavigationSplitView {
                switch mode {
                case .issues:
                    Text("Sidebar: Issues")
                case .pleadings:
                    PleadingsNavPanel(
                        sourceFilename: caseInfo.sourceFilename ?? "unknown.docx",
                        selectedPage: $selectedPage   // ✅ binding passed here
                    )
                }
            } detail: {
                switch mode {
                case .issues:
                    Text("Main View: Issues")
                case .pleadings:
                    PleadingsPanel(
                        caseInfo: caseInfo,
                        selectedPage: $selectedPage   // ✅ binding passed here
                    )
                }
            }
        }
        // Debug print when selectedPage changes
        .onChange(of: selectedPage) { newPage in
            if let page = newPage {
                print("✅ CaseViewFrame observed selectedPage change →", page)
            }
        }
        .navigationTitle(caseInfo.displayName)
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

