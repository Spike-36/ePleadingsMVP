//
//  ePleadingsMVPApp.swift
//  ePleadingsMVP
//

import SwiftUI

@main
struct ePleadingsMVPApp: App {
    @StateObject private var caseManager = CaseManager.shared

    var body: some Scene {
        WindowGroup {
            StartupView()   // ✅ Always start here
        }
    }
}

