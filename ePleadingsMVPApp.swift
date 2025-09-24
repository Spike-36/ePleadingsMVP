import SwiftUI

@main
struct ePleadingsMVPApp: App {
    @StateObject private var importService = ImportService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(importService)
        }
    }
}

