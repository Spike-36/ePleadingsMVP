//
//  ContentView.swift
//  ePleadingsMVP
//

import SwiftUI

struct ContentView: View {
    @StateObject private var importService = ImportService()
    @StateObject private var caseManager = CaseManager.shared
    
    var body: some View {
        VStack {
            // Active case selector
            HStack {
                Text("Active Case:")
                if let active = caseManager.activeCase {
                    Text(active.displayName)
                        .fontWeight(.bold)
                } else {
                    Text("None")
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button("New Case") {
                    do {
                        try caseManager.createCase(named: "defaultcase")
                        if let newCase = caseManager.cases.last {
                            caseManager.openCase(newCase)
                            importService.loadFiles(for: newCase.name)
                        }
                    } catch {
                        print("❌ Failed to create case: \(error)")
                    }
                }
            }
            .padding()
            
            Divider()
            
            // List of imported files for the active case
            List {
                ForEach(importService.importedFiles) { file in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(file.caseName)
                            .font(.headline)
                        
                        if file.isPDFMissing {
                            Text("⚠ Missing PDF")
                                .foregroundColor(.orange)
                                .font(.subheadline)
                        }
                        if file.isDOCXMissing {
                            Text("⚠ Missing DOCX")
                                .foregroundColor(.orange)
                                .font(.subheadline)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            
            // Import button (requires an active case)
            Button(action: {
                if let active = caseManager.activeCase {
                    importService.importFile(into: active.name)
                } else {
                    print("⚠ No active case selected")
                }
            }) {
                Text("Import File")
                    .frame(maxWidth: .infinity)
            }
            .padding()
        }
        .frame(minWidth: 400, minHeight: 300)
        .onAppear {
            // When the app opens, reload files for the active case (if any)
            if let active = caseManager.activeCase {
                importService.loadFiles(for: active.name)
            }
        }
    }
}

