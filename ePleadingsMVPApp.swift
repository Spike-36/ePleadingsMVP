//
//  ePleadingsMVPApp.swift
//  ePleadingsMVP
//
//  Created by Peter Milligan on 24/09/2025.
//

import SwiftUI

@main
struct ePleadingsMVPApp: App {
    @StateObject private var importService = ImportService()
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            // 🔹 Swap this to SentenceListView() for pipeline testing
            SentenceListView()
                .environmentObject(importService)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}

