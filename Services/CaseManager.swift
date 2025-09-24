//
//  CaseManager.swift
//  ePleadingsMVP
//
//  Created by Peter Milligan on 24/09/2025.
////
//  CaseManager.swift
//  ePleadingsMVP
//
//  Central manager for creating, opening, and listing cases.
//

import Foundation

/// Represents a single case folder.
struct CaseInfo: Identifiable, Equatable {
    let id = UUID()
    let name: String   // Safe name (filesystem friendly)
    let displayName: String // What the user typed
    let url: URL
}

/// Case manager handles all case-level operations.
final class CaseManager: ObservableObject {
    static let shared = CaseManager()
    
    @Published private(set) var cases: [CaseInfo] = []
    @Published var activeCase: CaseInfo?
    
    private init() {
        refreshCases()
    }
    
    /// Returns the base folder where all case folders live.
    private func baseFolder() throws -> URL {
        let support = try FileHelper.applicationSupportDirectory()
        let caseRoot = support.appendingPathComponent("CaseFiles")
        if !FileManager.default.fileExists(atPath: caseRoot.path) {
            try FileManager.default.createDirectory(at: caseRoot,
                                                    withIntermediateDirectories: true,
                                                    attributes: nil)
        }
        return caseRoot
    }
    
    /// Scan disk and refresh the list of known cases.
    func refreshCases() {
        do {
            let root = try baseFolder()
            let dirs = try FileManager.default.contentsOfDirectory(at: root,
                                                                  includingPropertiesForKeys: nil,
                                                                  options: [.skipsHiddenFiles])
            self.cases = dirs.filter { $0.hasDirectoryPath }.map { url in
                let safeName = url.lastPathComponent
                let displayName = safeName.replacingOccurrences(of: "_", with: " ")
                return CaseInfo(name: safeName, displayName: displayName, url: url)
            }.sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
        } catch {
            print("❌ Failed to refresh cases: \(error)")
            self.cases = []
        }
    }
    
    /// Create a new case folder.
    func createCase(named displayName: String) throws {
        let safeName = FileHelper.safeName(from: displayName)
        let root = try baseFolder()
        let url = root.appendingPathComponent(safeName)
        if FileManager.default.fileExists(atPath: url.path) {
            throw NSError(domain: "CaseManager", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Case already exists."])
        }
        try FileManager.default.createDirectory(at: url,
                                                withIntermediateDirectories: true,
                                                attributes: nil)
        refreshCases()
    }
    
    /// Open an existing case (by picking from the list).
    func openCase(_ caseInfo: CaseInfo) {
        self.activeCase = caseInfo
    }
    
    /// Close the active case.
    func closeCase() {
        self.activeCase = nil
    }
}


