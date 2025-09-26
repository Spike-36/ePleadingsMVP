//
//  CaseViewFrame.swift
//  ePleadingsMVP
//
//  Created by Peter Milligan on 26/09/2025.
//
//
//  CaseViewFrame.swift
//  ePleadingsMVP
//

import SwiftUI

enum CaseViewMode: String, CaseIterable, Identifiable {
    case issues = "Issues"
    case pleadings = "Pleadings"
    
    var id: String { rawValue }
}

struct CaseViewFrame: View {
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
                    Text("Main View: Pleadings")
                }
            }
        }
        .navigationTitle("Case View Frame")
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button("Back") {
                    dismiss()
                }
            }
        }
    }
}

