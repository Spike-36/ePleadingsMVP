//
//  Persistence.swift
//  ePleadingsMVP
//

import CoreData

final class PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    // 👉 Toggle this to true if you want a clean slate every launch
    private let resetOnLaunch: Bool = false

    private init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "ePleadingsMVP") // must match .xcdatamodeld
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                fatalError("❌ Unresolved Core Data error \(error), \(error.userInfo)")
            }

            // 💾 Show the live Core Data store location
            if let storeURL = storeDescription.url {
                print("💾 Core Data store path:", storeURL.path)
            } else {
                print("⚠️ No store URL found — using in-memory store?")
            }

            // 🔍 Debug: confirm entities Core Data has loaded
            for entity in self.container.managedObjectModel.entities {
                print("📦 Loaded entity:", entity.name ?? "nil")
            }

            // 👉 Reset store if flag is set
            if self.resetOnLaunch {
                let coordinator = self.container.persistentStoreCoordinator
                for store in coordinator.persistentStores {
                    if let url = store.url {
                        do {
                            try coordinator.destroyPersistentStore(at: url, ofType: store.type, options: nil)
                            try coordinator.addPersistentStore(ofType: store.type,
                                                               configurationName: nil,
                                                               at: url,
                                                               options: nil)
                            print("🧹 Core Data store reset on launch at:", url.path)
                        } catch {
                            print("⚠️ Failed to reset store:", error)
                        }
                    }
                }
            }
        }

        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
}

// MARK: - Helpers
extension PersistenceController {
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
        sentence.heading = heading
        sentence.state = "new" // 👉 Added: test state assignment

        do {
            try context.save()
            print("✅ Test heading + sentence saved to Core Data with state:", sentence.state ?? "nil") // 👉 Updated log
        } catch {
            print("❌ Failed to save test data:", error)
        }
    }

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
                let state = s.state ?? "(no state)" // 👉 Include state in logs
                print("(\(index + 1)) ➡️ \(text) (page \(page), source: \(source), heading: \(headingText), state: \(state))")
            }

            if let limit = limit, results.count > limit {
                print("… ⚠️ \(results.count - limit) more sentences not shown")
            }
        } catch {
            print("⚠️ Failed to fetch sentences:", error)
        }
    }

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

                print("(\(index + 1)) ➡️ \(text) [level \(level)] — page: \(page) @ \(source) — sentences: \(sentenceCount)")
            }

            if let limit = limit, results.count > limit {
                print("… ⚠️ \(results.count - limit) more headings not shown")
            }
        } catch {
            print("⚠️ Failed to fetch headings:", error)
        }
    }

    func runRelationshipTest() {
        let context = container.viewContext

        let heading = HeadingEntity(context: context)
        heading.id = UUID()
        heading.text = "RELATIONSHIP TEST HEADING"
        heading.level = 1
        heading.pageNumber = 1
        heading.sourceFilename = "Test.docx"

        for i in 1...3 {
            let sentence = SentenceEntity(context: context)
            sentence.id = UUID()
            sentence.text = "Sentence \(i) for relationship test"
            sentence.pageNumber = Int32(i)
            sentence.sourceFilename = "Test.docx"
            sentence.heading = heading
            sentence.state = "processed" // 👉 Added: set state explicitly for test
        }

        do {
            try context.save()
            print("✅ Relationship test data saved (state set to 'processed')") // 👉 Updated log
        } catch {
            print("❌ Failed to save relationship test data:", error)
        }

        if let sentences = heading.sentences as? Set<SentenceEntity> {
            print("🔎 Heading '\(heading.text ?? "")' has \(sentences.count) sentences")
        }

        let fetch: NSFetchRequest<SentenceEntity> = SentenceEntity.fetchRequest()
        if let results = try? context.fetch(fetch) {
            for s in results {
                print("➡️ '\(s.text ?? "nil")' belongs to heading '\(s.heading?.text ?? "nil")' [state: \(s.state ?? "nil")]") // 👉 include state
            }
        }
    }
}

// MARK: - File storage helpers
extension PersistenceController {
    var casesFolder: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let folder = docs.appendingPathComponent("Cases", isDirectory: true)

        if !FileManager.default.fileExists(atPath: folder.path) {
            do {
                try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
                print("📂 Created Cases folder at:", folder.path)
            } catch {
                print("⚠️ Failed to create Cases folder:", error)
            }
        }

        return folder
    }
}

