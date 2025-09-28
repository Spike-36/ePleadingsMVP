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
                    // Debug: prove Core Data is live
                    persistenceController.runRelationshipTest()
                    persistenceController.debugPrintHeadings()
                    persistenceController.debugPrintSentences()
                }
        }
    }
}

