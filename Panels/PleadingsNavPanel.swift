//
//  PleadingsNavPanel.swift
//  ePleadingsMVP
//
//  Created by Peter Milligan on 28/09/2025.
//

import SwiftUI
import CoreData

struct PleadingsNavPanel: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    var sourceFilename: String
    @Binding var selectedPage: Int?   // 👉 Stage 4.1: binding
    
    @FetchRequest private var headings: FetchedResults<HeadingEntity>
    
    init(sourceFilename: String, selectedPage: Binding<Int?>) {
        self.sourceFilename = sourceFilename
        self._selectedPage = selectedPage
        _headings = FetchRequest(
            entity: HeadingEntity.entity(),
            sortDescriptors: [
                NSSortDescriptor(keyPath: \HeadingEntity.pageNumber, ascending: true),
                NSSortDescriptor(keyPath: \HeadingEntity.text, ascending: true)
            ],
            predicate: NSPredicate(format: "sourceFilename == %@", sourceFilename)
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Headings")
                .font(.headline)
                .padding(.bottom, 4)
            
            if headings.isEmpty {
                if sourceFilename == "unknown.docx" {
                    Text("No pleadings document found for this case")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                } else {
                    Text("No headings found in \(sourceFilename)")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                }
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(groupedHeadings().enumerated()), id: \.offset) { _, group in
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(group, id: \.objectID) { heading in
                                    if let text = heading.text {
                                        if text.localizedCaseInsensitiveContains("cond.") ||
                                            text.localizedCaseInsensitiveContains("condescendence") ||
                                            text.localizedCaseInsensitiveContains("statement") ||
                                            text.localizedCaseInsensitiveContains("stat.") {
                                            
                                            // Main Cond. heading
                                            Button(action: {
                                                let page = Int(heading.pageNumber)
                                                selectedPage = page
                                                print("➡️ NavPanel tapped, page =", page)
                                            }) {
                                                Text(text)
                                                    .font(.body.bold())
                                                    .padding(.vertical, 2)
                                            }
                                            .buttonStyle(.plain)
                                            
                                        } else if text.localizedCaseInsensitiveContains("ans.") ||
                                                    text.localizedCaseInsensitiveContains("answer") {
                                            
                                            // Indented Answer
                                            Button(action: {
                                                let page = Int(heading.pageNumber)
                                                selectedPage = page
                                                print("➡️ NavPanel tapped, page =", page)
                                            }) {
                                                HStack {
                                                    Spacer().frame(width: 20)
                                                    Text(text)
                                                        .font(.body)
                                                        .padding(.vertical, 2)
                                                }
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }
                            }
                            .padding(.bottom, 8) // gap between Cond./Ans. groups
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
        .padding()
    }
    
    // Group into blocks: each Cond. with following Ans.
    private func groupedHeadings() -> [[HeadingEntity]] {
        var groups: [[HeadingEntity]] = []
        var currentGroup: [HeadingEntity] = []
        
        for heading in headings {
            if let text = heading.text {
                if text.localizedCaseInsensitiveContains("cond.") ||
                    text.localizedCaseInsensitiveContains("condescendence") ||
                    text.localizedCaseInsensitiveContains("statement") ||
                    text.localizedCaseInsensitiveContains("stat.") {
                    // Start a new group when we hit a Cond.
                    if !currentGroup.isEmpty {
                        groups.append(currentGroup)
                        currentGroup = []
                    }
                }
                currentGroup.append(heading)
            }
        }
        if !currentGroup.isEmpty {
            groups.append(currentGroup)
        }
        return groups
    }
}

