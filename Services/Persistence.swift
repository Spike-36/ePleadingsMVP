//
//  Persistence.swift
//  ePleadingsMVP
//

import CoreData
import SQLite3   // ✅ for manual VACUUM compaction

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

    // 🔄 Updated — now cleans orphaned DocumentEntity + SentenceEntity safely
    func debugCheckForOrphanDocuments() {
        let context = container.viewContext
        print("🔍 Running Core Data integrity checks on launch...")

        // --- Summary counts (for context) ---
        let entities = ["CaseEntity", "DocumentEntity", "HeadingEntity", "SentenceEntity"]
        for e in entities {
            let req = NSFetchRequest<NSFetchRequestResult>(entityName: e)
            let count = (try? context.count(for: req)) ?? 0
            print("📦 \(e.replacingOccurrences(of: "Entity", with: "")): \(count)")
        }

        var didDeleteSomething = false

        // --- Orphan Document cleanup ---
        let fetchDocs: NSFetchRequest<DocumentEntity> = DocumentEntity.fetchRequest()
        fetchDocs.predicate = NSPredicate(format: "caseEntity == nil")

        do {
            let orphans = try context.fetch(fetchDocs)
            if orphans.isEmpty {
                print("✅ No orphaned DocumentEntity records found.")
            } else {
                print("⚠️ Found \(orphans.count) unlinked (orphan) documents:")
                for doc in orphans {
                    print("   • \(doc.filename ?? "(unknown)") — path: \(doc.filePath ?? "nil")")
                    context.delete(doc)
                }
                try context.save()
                didDeleteSomething = true
                print("🧹 Deleted \(orphans.count) orphaned documents and saved context.")
            }
        } catch {
            print("❌ Failed to scan or clean orphaned documents: \(error)")
        }

        // --- Orphan Sentence cleanup ---
        let fetchSentences: NSFetchRequest<SentenceEntity> = SentenceEntity.fetchRequest()
        fetchSentences.predicate = NSPredicate(format: "document == nil")
        do {
            let orphans = try context.fetch(fetchSentences)
            if orphans.isEmpty {
                print("✅ No orphaned SentenceEntity records found.")
            } else {
                print("⚠️ Found \(orphans.count) orphaned sentences (no linked document):")
                for s in orphans.prefix(10) {
                    print("   • '\(s.text ?? "(no text)")' — page: \(s.pageNumber)")
                    context.delete(s)
                }
                try context.save()
                didDeleteSomething = true
                print("🧹 Deleted \(orphans.count) orphaned SentenceEntity records.")
            }
        } catch {
            print("❌ Failed to scan or clean orphaned sentences: \(error)")
        }

        // --- Compact only if we actually deleted data ---
        if didDeleteSomething {
            self.compactStore()
        }

        // --- Store file size diagnostics ---
        if let storeURL = container.persistentStoreDescriptions.first?.url {
            if let attrs = try? FileManager.default.attributesOfItem(atPath: storeURL.path),
               let size = attrs[.size] as? NSNumber {
                let kb = Double(truncating: size) / 1024.0
                print(String(format: "💽 SQLite store size: %.1f KB", kb))
            }
        }

        print("✅ Relationship and orphan checks complete.")
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

// MARK: - Store maintenance
extension PersistenceController {
    /// Physically compacts the SQLite store after deletions.
    func compactStore() {
        guard let storeURL = container.persistentStoreDescriptions.first?.url else {
            print("⚠️ compactStore: No store URL found.")
            return
        }

        var db: OpaquePointer?
        if sqlite3_open(storeURL.path, &db) == SQLITE_OK {
            if sqlite3_exec(db, "VACUUM;", nil, nil, nil) == SQLITE_OK {
                print("🧩 SQLite store compacted successfully.")
            } else {
                print("⚠️ SQLite VACUUM command failed.")
            }
            sqlite3_close(db)
        } else {
            print("⚠️ Unable to open database for compaction.")
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

