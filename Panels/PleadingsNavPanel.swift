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
        // ✅ Now use the helper for consistent ordering
        _headings = FetchRequest(fetchRequest: HeadingFetchService.fetchRequest(for: document))
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
        let isAnswer = text.localizedCaseInsensitiveContains("ans.")
            || text.localizedCaseInsensitiveContains("answer")
        
        Button {
            selectedHeading = heading
        } label: {
            HStack {
                if isAnswer {
                    Spacer().frame(width: 20) // indent answers
                }
                Text(text)
                    .font(isAnswer ? .body : .body.bold())
                    .padding(.vertical, 2)
            }
        }
        .buttonStyle(.plain)
    }
    
    /// Groups so each Statement/Cond has at most one Answer after it.
    /// Assumes `headings` are already sorted by orderIndex.
    func groupedHeadings() -> [[HeadingEntity]] {
        var groups: [[HeadingEntity]] = []
        var currentGroup: [HeadingEntity] = []
        var expectingAnswer = false
        
        func flushGroup() {
            if !currentGroup.isEmpty {
                groups.append(currentGroup)
                currentGroup = []
            }
            expectingAnswer = false
        }
        
        for heading in headings {
            guard let text = heading.text else { continue }
            
            let isStatementOrCond =
                text.localizedCaseInsensitiveContains("cond.") ||
                text.localizedCaseInsensitiveContains("condescendence") ||
                text.localizedCaseInsensitiveContains("statement") ||
                text.localizedCaseInsensitiveContains("stat.")
            
            let isAnswer =
                text.localizedCaseInsensitiveContains("ans.") ||
                text.localizedCaseInsensitiveContains("answer")
            
            if isStatementOrCond {
                flushGroup()
                currentGroup.append(heading)
                expectingAnswer = true
            } else if isAnswer, expectingAnswer {
                currentGroup.append(heading)
                flushGroup()   // only one Answer allowed
            } else if isAnswer {
                // Orphan answer: put in its own group
                flushGroup()
                groups.append([heading])
            }
        }
        
        flushGroup()
        return groups
    }
}

