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
                // ✅ Show nicer message if we’re in the fallback case
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
                    ForEach(headings, id: \.objectID) { heading in
                        Text(heading.text ?? "")
                            .lineLimit(1)
                            .font(.body)
                            .padding(.vertical, 2)
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
        .padding()
    }
}

