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
    
    @FetchRequest private var headings: FetchedResults<HeadingEntity>
    
    init(sourceFilename: String) {
        self.sourceFilename = sourceFilename
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
                List {
                    ForEach(Array(groupedHeadings().enumerated()), id: \.offset) { _, group in
                        Section {
                            ForEach(group, id: \.objectID) { heading in
                                if let text = heading.text {
                                    if text.localizedCaseInsensitiveContains("cond.") ||
                                        text.localizedCaseInsensitiveContains("condescendence") ||
                                        text.localizedCaseInsensitiveContains("statement") ||
                                        text.localizedCaseInsensitiveContains("stat.") {
                                        // Main Cond. heading
                                        Text(text)
                                            .font(.body.bold())
                                            .padding(.vertical, 2)
                                    } else if text.localizedCaseInsensitiveContains("ans.") ||
                                                text.localizedCaseInsensitiveContains("answer") {
                                        // Indented Answer
                                        HStack {
                                            Spacer().frame(width: 20)
                                            Text(text)
                                                .font(.body)
                                                .padding(.vertical, 2)
                                        }
                                    }
                                }
                            }
                        } footer: {
                            // Add gap after each Cond./Ans. group
                            Color.clear.frame(height: 8)
                        }
                    }
                }
                .listStyle(PlainListStyle())
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

