//
//  ePleadingsMVPApp.swift
//  ePleadingsMVP
//

import SwiftUI

@main
struct ePleadingsMVPApp: App {
    @StateObject private var caseManager = CaseManager.shared
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            StartupView()   // ✅ Always start here
                .environment(\.managedObjectContext,
                             persistenceController.container.viewContext)
                .onAppear {
                    #if DEBUG
                    // 🧩 Debug: confirm Core Data wiring is intact
                    print("🔍 Running Core Data integrity checks on launch...")
                    
                    // 🔄 Quick entity count summary
                    persistenceController.debugSummaryCounts()
                    
                    // 👉 Check for orphaned documents
                    persistenceController.debugCheckForOrphanDocuments()
                    
                    print("✅ Relationship and orphan checks complete.\n")
                    #endif
                }
        }
    }
}

