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
    
    @State private var mode: CaseViewMode = .issues
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
                    Text("Sidebar: Pleadings")
                }
            } detail: {
                switch mode {
                case .issues:
                    Text("Main View: Issues")
                case .pleadings:
                    PleadingsPanel(caseInfo: caseInfo)   // ✅ swapped in
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
                    persistence.debugPrintSentences(limit: 20)
                    // (Optional) add a similar call for headings later
                    // persistence.debugPrintHeadings(limit: 20)
                }
            }
        }
    }
}

