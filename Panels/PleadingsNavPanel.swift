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
    
    /// Groups so each Cond/Stat has exactly one Answer after it
    func groupedHeadings() -> [[HeadingEntity]] {
        var groups: [[HeadingEntity]] = []
        var currentGroup: [HeadingEntity] = []
        var expectingAnswer = false
        
        func flushGroup() {
            if !currentGroup.isEmpty {
                print("📦 Flushing group: \(currentGroup.compactMap { $0.text })")
                groups.append(currentGroup)
                currentGroup = []
            }
            expectingAnswer = false
        }
        
        // 🔎 DEBUG: dump raw order before grouping
        print("🔎 Raw heading order from Core Data (\(headings.count)):")
        for (i, h) in headings.enumerated() {
            let text = h.text ?? "<nil>"
            let page = h.mappedPageNumber    // Int32, safe default is 0
            print("(\(i+1)) ➡️ '\(text)' @ page \(page)")
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
                print("➡️ New Statement: \(text)")
                flushGroup()
                currentGroup.append(heading)
                expectingAnswer = true
            } else if isAnswer, expectingAnswer {
                print("✅ Pairing Answer '\(text)' with \(currentGroup.first?.text ?? "<none>")")
                currentGroup.append(heading)
                flushGroup() // only allow one Answer per Cond/Stat
            } else if isAnswer {
                print("⚠️ Orphan Answer: \(text) → standalone group")
                flushGroup()
                currentGroup.append(heading)
                flushGroup()
            } else {
                // ignore extras (no grouping for unmatched items)
                continue
            }
        }
        
        flushGroup()
        
        print("🔎 Grouping complete. Total groups: \(groups.count)")
        for (i, g) in groups.enumerated() {
            print("(\(i+1)) \(g.compactMap { $0.text })")
        }
        
        return groups
    }
}

