//
//  CaseViewModel.swift
//  ePleadingsMVP
//

import Foundation
import SwiftUI
import CoreData

@MainActor
final class CaseViewModel: ObservableObject {
    // Existing single-pane plumbing (kept as-is)
    @Published var sentences: [SentenceItem] = []
    @Published var targetPage: Int? = nil

    // NEW — split-pane selections the UI can bind to (optional to use from views)
    @Published var activeLeftHeading: HeadingEntity? = nil
    @Published var activeRightHeading: HeadingEntity? = nil

    private let caseInfo: CaseInfo
    private let context: NSManagedObjectContext

    init(caseInfo: CaseInfo, context: NSManagedObjectContext) {
        self.caseInfo = caseInfo
        self.context = context
        loadFromCoreData()
    }

    /// Load sentences for this case ONLY from Core Data
    private func loadFromCoreData() {
        let fetch: NSFetchRequest<SentenceEntity> = SentenceEntity.fetchRequest()
        fetch.sortDescriptors = [
            NSSortDescriptor(keyPath: \SentenceEntity.pageNumber, ascending: true)
        ]

        do {
            let results = try context.fetch(fetch)

            self.sentences = results.map { sentence in
                SentenceItem(
                    id: (sentence.id ?? UUID()).uuidString,
                    text: sentence.text ?? "",
                    pageNumber: Int(sentence.pageNumber),
                    sourceFilename: sentence.sourceFilename
                )
            }

            print("📦 Loaded \(sentences.count) sentences from Core Data")
        } catch {
            print("⚠️ Failed to fetch sentences from Core Data: \(error.localizedDescription)")
            self.sentences = []
        }
    }

    /// Public method for views to refresh
    func reloadCase() {
        loadFromCoreData()
    }

    /// Set a target page for PDF navigation
    func jumpToPage(_ page: Int) {
        targetPage = page
    }

    // MARK: - Split selection helper (optional)
    /// Given a user-selected heading and the full heading list, compute left/right panes.
    func applySelection(selected: HeadingEntity?, allHeadings: [HeadingEntity]) {
        guard let selected else {
            activeLeftHeading = nil
            activeRightHeading = nil
            return
        }

        let text = (selected.text ?? "").lowercased()
        let isAnswer = text.contains("ans.") || text.contains("answer")

        // Find pair if available
        let pair = HeadingPairMatcher.findPair(for: selected, in: allHeadings)

        if isAnswer {
            // Right = the answer the user clicked; Left = its statement/cond (if any)
            activeRightHeading = selected
            activeLeftHeading = pair
        } else {
            // Left = the statement/cond the user clicked; Right = its answer (if any)
            activeLeftHeading = selected
            activeRightHeading = pair
        }

        if let l = activeLeftHeading?.text { print("🟩 Left = \(l)") }
        if let r = activeRightHeading?.text { print("🟦 Right = \(r)") }
    }
}

