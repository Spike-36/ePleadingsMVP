import SwiftUI
import CoreData

struct PleadingsNavPanel: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    var document: DocumentEntity
    @Binding var selectedHeading: HeadingEntity?
    
    @FetchRequest private var headings: FetchedResults<HeadingEntity>
    
    init(document: DocumentEntity, selectedHeading: Binding<HeadingEntity?>) {
        self.document = document
        self._selectedHeading = selectedHeading
        
        // ✅ Match by UUID, not object instance
        let request: NSFetchRequest<HeadingEntity> = HeadingEntity.fetchRequest()
        request.predicate = NSPredicate(
            format: "document.id == %@", document.id as CVarArg
        )
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \HeadingEntity.orderIndex, ascending: true)
        ]
        
        _headings = FetchRequest(fetchRequest: request)
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
                    LazyVStack(alignment: .leading, spacing: 0) {
                        // 👉 group statements + answers together visually
                        ForEach(groupedHeadings(), id: \.self) { group in
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(group, id: \.objectID) { heading in
                                    if let text = heading.text {
                                        headingButton(for: heading, text: text)
                                    }
                                }
                            }
                            .padding(.vertical, 6)
                            .background(Color(NSColor.windowBackgroundColor))
                            .cornerRadius(6)
                            .padding(.bottom, 8) // 🔄 adds the “gap” between groups
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
        .padding()
    }
    
    // MARK: - Grouping logic
    private func groupedHeadings() -> [[HeadingEntity]] {
        var groups: [[HeadingEntity]] = []
        var current: [HeadingEntity] = []
        
        for heading in headings {
            if let text = heading.text,
               text.localizedCaseInsensitiveContains("cond.") ||
               text.localizedCaseInsensitiveContains("condescendence") ||
               text.localizedCaseInsensitiveContains("statement") ||
               text.localizedCaseInsensitiveContains("stat.") {
                // start new group on every Statement-type heading
                if !current.isEmpty {
                    groups.append(current)
                    current.removeAll()
                }
            }
            current.append(heading)
        }
        
        if !current.isEmpty {
            groups.append(current)
        }
        return groups
    }
    
    // MARK: - Button rendering
    @ViewBuilder
    private func headingButton(for heading: HeadingEntity, text: String) -> some View {
        let isStatementOrCond =
            text.localizedCaseInsensitiveContains("cond.") ||
            text.localizedCaseInsensitiveContains("condescendence") ||
            text.localizedCaseInsensitiveContains("statement") ||
            text.localizedCaseInsensitiveContains("stat.")
        
        let isAnswer =
            text.localizedCaseInsensitiveContains("ans.") ||
            text.localizedCaseInsensitiveContains("answer")
        
        Button {
            selectedHeading = heading
        } label: {
            HStack {
                if isAnswer {
                    Spacer().frame(width: 20) // indent answers
                }
                Text(text)
                    .font(isStatementOrCond ? .body.bold() : .body)
                    .padding(.vertical, 2)
            }
        }
        .buttonStyle(.plain)
    }
}

