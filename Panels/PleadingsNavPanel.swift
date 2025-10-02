import SwiftUI
import CoreData

struct PleadingsNavPanel: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    var document: DocumentEntity
    @Binding var selectedPage: Int?
    
    @FetchRequest private var headings: FetchedResults<HeadingEntity>
    
    init(document: DocumentEntity, selectedPage: Binding<Int?>) {
        self.document = document
        self._selectedPage = selectedPage
        _headings = FetchRequest(
            entity: HeadingEntity.entity(),
            sortDescriptors: [
                NSSortDescriptor(keyPath: \HeadingEntity.mappedPageNumber, ascending: true),
                NSSortDescriptor(keyPath: \HeadingEntity.text, ascending: true)
            ],
            predicate: NSPredicate(format: "document == %@", document) // ✅ filter by relationship
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Headings")
                .font(.headline)
                .padding(.bottom, 4)
            
            if headings.isEmpty {
                Text("No headings found in \(document.filename)") // ✅ no optional unwrap
                    .foregroundColor(.secondary)
                    .font(.subheadline)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(groupedHeadings().enumerated()), id: \.offset) { _, group in
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(group, id: \.objectID) { heading in
                                    if let text = heading.text {
                                        headingButton(for: heading, text: text)
                                    }
                                }
                            }
                            .padding(.bottom, 8)
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
        .padding()
    }
    
    @ViewBuilder
    private func headingButton(for heading: HeadingEntity, text: String) -> some View {
        let mapped = heading.mappedPageNumber
        if text.localizedCaseInsensitiveContains("cond.") ||
            text.localizedCaseInsensitiveContains("condescendence") ||
            text.localizedCaseInsensitiveContains("statement") ||
            text.localizedCaseInsensitiveContains("stat.") {
            
            Button {
                if mapped > 0 { selectedPage = Int(mapped) }
            } label: {
                Text(text)
                    .font(.body.bold())
                    .padding(.vertical, 2)
            }
            .buttonStyle(.plain)
            
        } else if text.localizedCaseInsensitiveContains("ans.") ||
                    text.localizedCaseInsensitiveContains("answer") {
            
            Button {
                if mapped > 0 { selectedPage = Int(mapped) }
            } label: {
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
    
    private func groupedHeadings() -> [[HeadingEntity]] {
        var groups: [[HeadingEntity]] = []
        var currentGroup: [HeadingEntity] = []
        
        for heading in headings {
            if let text = heading.text {
                if text.localizedCaseInsensitiveContains("cond.") ||
                    text.localizedCaseInsensitiveContains("condescendence") ||
                    text.localizedCaseInsensitiveContains("statement") ||
                    text.localizedCaseInsensitiveContains("stat.") {
                    if !currentGroup.isEmpty {
                        groups.append(currentGroup)
                        currentGroup = []
                    }
                }
                currentGroup.append(heading)
            }
        }
        if !currentGroup.isEmpty { groups.append(currentGroup) }
        return groups
    }
}

