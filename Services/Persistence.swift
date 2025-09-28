//
//  Persistence.swift
//  ePleadingsMVP
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "ePleadingsMVP") // must match .xcdatamodeld
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("❌ Unresolved Core Data error \(error), \(error.userInfo)")
            }
        }
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
}

// MARK: - Helpers
extension PersistenceController {
    /// Saves a dummy test heading + sentence into Core Data
    func saveTestSentence() {
        let context = container.viewContext

        let heading = HeadingEntity(context: context)
        heading.id = UUID()
        heading.text = "DUMMY HEADING"
        heading.level = 1
        heading.pageNumber = 1
        heading.sourceFilename = "Dummy.docx"

        let sentence = SentenceEntity(context: context)
        sentence.id = UUID()
        sentence.text = "This is a test paragraph linked to the dummy heading."
        sentence.pageNumber = 1
        sentence.sourceFilename = "Dummy.docx"
        sentence.heading = heading   // ✅ correct relationship

        do {
            try context.save()
            print("✅ Test heading + sentence saved to Core Data")
        } catch {
            print("❌ Failed to save test data: \(error)")
        }
    }

    /// Debug: print sentences currently stored in Core Data
    func debugPrintSentences(limit: Int? = nil) {
        let context = container.viewContext
        let fetchRequest: NSFetchRequest<SentenceEntity> = SentenceEntity.fetchRequest()

        do {
            let results = try context.fetch(fetchRequest)
            print("📦 Found \(results.count) sentences in Core Data")

            let slice = limit != nil ? results.prefix(limit!) : results[...]
            for (index, s) in slice.enumerated() {
                let text = s.text ?? "nil"
                let page = s.pageNumber
                let source = s.sourceFilename ?? "unknown"
                let headingText = s.heading?.text ?? "(no heading)"
                print("(\(index + 1)) ➡️ \(text) (page \(page), source: \(source), heading: \(headingText))")
            }

            if let limit = limit, results.count > limit {
                print("… ⚠️ \(results.count - limit) more sentences not shown")
            }
        } catch {
            print("⚠️ Failed to fetch sentences: \(error)")
        }
    }

    /// Debug: print headings currently stored in Core Data
    func debugPrintHeadings(limit: Int? = nil) {
        let context = container.viewContext
        let fetchRequest: NSFetchRequest<HeadingEntity> = HeadingEntity.fetchRequest()

        do {
            let results = try context.fetch(fetchRequest)
            print("📦 Found \(results.count) headings in Core Data")

            let slice = limit != nil ? results.prefix(limit!) : results[...]
            for (index, h) in slice.enumerated() {
                let text = h.text ?? "nil"
                let page = h.pageNumber
                let source = h.sourceFilename ?? "unknown"
                let level = h.level
                let sentenceCount = h.sentences?.count ?? 0
                print("(\(index + 1)) ➡️ \(text) (level \(level), page \(page), source: \(source), sentences: \(sentenceCount))")
            }

            if let limit = limit, results.count > limit {
                print("… ⚠️ \(results.count - limit) more headings not shown")
            }
        } catch {
            print("⚠️ Failed to fetch headings: \(error)")
        }
    }

    // MARK: - Relationship Test
    func runRelationshipTest() {
        let context = container.viewContext

        // 1. Create a dummy heading
        let heading = HeadingEntity(context: context)
        heading.id = UUID()
        heading.text = "RELATIONSHIP TEST HEADING"
        heading.level = 1
        heading.pageNumber = 1
        heading.sourceFilename = "Test.docx"

        // 2. Create multiple sentences and attach them
        for i in 1...3 {
            let sentence = SentenceEntity(context: context)
            sentence.id = UUID()
            sentence.text = "Sentence \(i) for relationship test"
            sentence.pageNumber = Int32(i)
            sentence.sourceFilename = "Test.docx"
            sentence.heading = heading   // ✅ attach sentence → heading
        }

        do {
            try context.save()
            print("✅ Relationship test data saved")
        } catch {
            print("❌ Failed to save relationship test data: \(error)")
        }

        // 3. Verify heading → sentences
        if let sentences = heading.sentences as? Set<SentenceEntity> {
            print("🔎 Heading '\(heading.text ?? "")' has \(sentences.count) sentences")
        }

        // 4. Verify each sentence → heading
        let fetch: NSFetchRequest<SentenceEntity> = SentenceEntity.fetchRequest()
        if let results = try? context.fetch(fetch) {
            for s in results {
                print("➡️ '\(s.text ?? "nil")' belongs to heading '\(s.heading?.text ?? "nil")'")
            }
        }
    }
}

