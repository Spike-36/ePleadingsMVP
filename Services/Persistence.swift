//
//  Persistence.swift
//  ePleadingsMVP
//

import CoreData

final class PersistenceController {
    static let shared = PersistenceController()
    let container: NSPersistentContainer

    // 🧹 TEMP: Reset Core Data store on every launch (set to false after testing)
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

            // 💾 Show where the store is located
            if let storeURL = storeDescription.url {
                print("💾 Active Core Data store:", storeURL.path)
            } else {
                print("⚠️ No store URL found — using in-memory store?")
            }

            // 🔍 Debug: confirm entities loaded
            for entity in self.container.managedObjectModel.entities {
                print("📦 Loaded entity:", entity.name ?? "nil")
            }

            // 👉 Reset store on launch (for dev testing only)
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

// MARK: - Debug helpers
extension PersistenceController {
    func saveTestSentence() { print("🚫 saveTestSentence() disabled in production.") }
    func runRelationshipTest() { print("🚫 runRelationshipTest() disabled in production.") }

    func debugPrintSentences(limit: Int? = nil) {
        let context = container.viewContext
        let fetchRequest: NSFetchRequest<SentenceEntity> = SentenceEntity.fetchRequest()
        do {
            let results = try context.fetch(fetchRequest)
            print("📦 Found \(results.count) sentences in Core Data")
            let slice = limit != nil ? results.prefix(limit!) : results[...]
            for (index, s) in slice.enumerated() {
                let text = s.text
                let page = s.pageNumber
                let source = s.sourceFilename ?? "unknown"
                let headingText = s.heading?.text ?? "(no heading)"
                let state = s.state ?? "(no state)"
                print("(\(index + 1)) ➡️ \(text) (page \(page), source: \(source), heading: \(headingText), state: \(state))")
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
        } catch {
            print("⚠️ Failed to fetch headings:", error)
        }
    }

    func debugCheckForOrphanDocuments() {
        let context = container.viewContext
        let fetchRequest: NSFetchRequest<DocumentEntity> = DocumentEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "caseEntity == nil")
        do {
            let orphans = try context.fetch(fetchRequest)
            if orphans.isEmpty {
                print("✅ Sanity Check: No orphan documents found — all are linked to cases.")
            } else {
                print("⚠️ Found \(orphans.count) unlinked (orphan) documents:")
                for doc in orphans {
                    print("   • \(doc.filename ?? "Unnamed") — path: \(doc.filePath ?? "unknown")")
                }
            }
        } catch {
            print("❌ Failed to run orphan document check:", error)
        }
    }

    func debugSummaryCounts() {
        let context = container.viewContext
        let entities = ["CaseEntity", "DocumentEntity", "HeadingEntity", "SentenceEntity"]
        print("📊 Core Data summary:")
        for entityName in entities {
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            do {
                let count = try context.count(for: request)
                print("   • \(entityName.replacingOccurrences(of: "Entity", with: "")): \(count)")
            } catch {
                print("   ⚠️ Failed to count \(entityName): \(error)")
            }
        }

        if let storeURL = container.persistentStoreDescriptions.first?.url {
            do {
                let attrs = try FileManager.default.attributesOfItem(atPath: storeURL.path)
                if let size = attrs[.size] as? NSNumber {
                    let kb = Double(truncating: size) / 1024.0
                    print(String(format: "💽 SQLite store size: %.1f KB", kb))
                }
            } catch {
                print("⚠️ Unable to get SQLite file size:", error)
            }
        }
        print("")
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

