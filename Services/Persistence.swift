//
//  Persistence.swift
//  ePleadingsMVP
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "ePleadingsMVP") // must match your .xcdatamodeld file name
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
    /// Saves a dummy test sentence into Core Data
    func saveTestSentence() {
        let context = container.viewContext
        
        let sentence = Sentence(context: context)
        sentence.id = UUID()
        sentence.text = "This is a test paragraph from Core Data."
        sentence.pageNumber = 1
        sentence.sourceFilename = "Dummy.docx"
        
        do {
            try context.save()
            print("✅ Test sentence saved to Core Data")
        } catch {
            print("❌ Failed to save test sentence: \(error)")
        }
    }
    
    /// Debug: print sentences currently stored in Core Data
    func debugPrintSentences(limit: Int? = nil) {
        let context = container.viewContext
        let fetchRequest: NSFetchRequest<Sentence> = Sentence.fetchRequest()
        
        do {
            let results = try context.fetch(fetchRequest)
            print("📦 Found \(results.count) sentences in Core Data")
            
            let slice: ArraySlice<Sentence>
            if let limit = limit {
                slice = results.prefix(limit)
            } else {
                slice = results[...]
            }
            
            for (index, s) in slice.enumerated() {
                let text = s.text ?? "nil"
                let page = s.pageNumber
                let source = s.sourceFilename ?? "unknown"
                print("(\(index + 1)) ➡️ \(text) (page \(page), source: \(source))")
            }
            
            if let limit = limit, results.count > limit {
                print("… ⚠️ \(results.count - limit) more sentences not shown")
            }
        } catch {
            print("⚠️ Failed to fetch sentences: \(error)")
        }
    }
    
    /// Debug: placeholder for headings (extend once Headings entity exists)
    func debugPrintHeadings(limit: Int? = nil) {
        print("ℹ️ Headings debug not yet implemented")
    }
}

