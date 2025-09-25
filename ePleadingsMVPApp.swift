import SwiftUI

@main
struct ePleadingsMVPApp: App {
    @StateObject private var caseManager = CaseManager.shared

    var body: some Scene {
        WindowGroup {
            if let active = caseManager.activeCase {
                // ✅ Pass the active case into CaseDetailView
                CaseDetailView(caseInfo: active)
            } else {
                StartupView()
            }
        }
    }
}

