import SwiftUI

@main
struct ePleadingsMVPApp: App {
    @StateObject private var importService = ImportService()
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            // Swap ContentView for SentenceListView to sanity-check Core Data
            SentenceListView()
                .environmentObject(importService)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}

