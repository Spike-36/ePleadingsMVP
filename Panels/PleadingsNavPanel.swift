import SwiftUI
import CoreData

struct PleadingsNavPanel: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    var document: DocumentEntity
    @Binding var selectedHeading: HeadingEntity?   // 🔄 switch from page to heading
    
    @FetchRequest private var headings: FetchedResults<HeadingEntity>
    
    init(document: DocumentEntity, selectedHeading: Binding<HeadingEntity?>) {
        self.document = document
        self._selectedHeading = selectedHeading
        _headings = FetchRequest(
            entity: HeadingEntity.entity(),
            sortDescriptors: [
                NSSortDescriptor(keyPath: \HeadingEntity.mappedPageNumber, ascending: true),
                NSSortDescriptor(keyPath: \HeadingEntity.text, ascending: true)
            ],
            predicate: NSPredicate(format: "document == %@", document)
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Headings")
                .font(.headline)
                .padding(.bottom, 4)
            
            if headings.isEmpty {
                Text("No headings found in \(document.filename)")
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
        if text.localizedCaseInsensitiveContains("cond.") ||
            text.localizedCaseInsensitiveContains("condescendence") ||
            text.localizedCaseInsensitiveContains("statement") ||
            text.localizedCaseInsensitiveContains("stat.") {
            
            Button {
                selectedHeading = heading   // 🔄 now sets heading
            } label: {
                Text(text)
                    .font(.body.bold())
                    .padding(.vertical, 2)
            }
            .buttonStyle(.plain)
            
        } else if text.localizedCaseInsensitiveContains("ans.") ||
                    text.localizedCaseInsensitiveContains("answer") {
            
            Button {
                selectedHeading = heading   // 🔄 now sets heading
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

