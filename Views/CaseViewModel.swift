//
//  CaseViewModel.swift
//  ePleadingsMVP
//

import Foundation
import SwiftUI
import CoreData

@MainActor
final class CaseViewModel: ObservableObject {
    @Published var sentences: [SentenceItem] = []
    @Published var targetPage: Int? = nil
    
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
}

