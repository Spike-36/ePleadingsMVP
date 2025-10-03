//
//  CaseManager.swift
//  ePleadingsMVP
//

import Foundation
import SwiftUI

/// Represents a single case folder.
struct CaseInfo: Identifiable, Hashable {
    let id: UUID
    let name: String       // UUID string (folder name)
    let displayName: String
    let url: URL

    /// Returns the first .docx filename in this case folder (if any)
    var sourceFilename: String? {
        let fm = FileManager.default
        if let items = try? fm.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) {
            if let docx = items.first(where: { $0.pathExtension.lowercased() == "docx" }) {
                return docx.lastPathComponent
            }
        }
        return nil
    }
}

/// File presence helpers used by StartupView status icons.
extension CaseInfo {
    var hasDocx: Bool {
        let fm = FileManager.default
        guard let items = try? fm.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) else { return false }
        return items.contains { $0.pathExtension.lowercased() == "docx" }
    }

    var hasPdf: Bool {
        let fm = FileManager.default
        guard let items = try? fm.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) else { return false }
        return items.contains { $0.pathExtension.lowercased() == "pdf" }
    }
}

/// Manages all cases and persistence of the active case.
class CaseManager: ObservableObject {
    static let shared = CaseManager()
    
    @Published var cases: [CaseInfo] = []
    @Published var activeCase: CaseInfo? = nil {
        didSet { persistActiveCase() }
    }
    
    private let casesDirectory: URL
    private let activeCaseKey = "ActiveCaseID"
    
    private init() {
        casesDirectory = FileHelper.casesDirectory
        try? FileManager.default.createDirectory(at: casesDirectory, withIntermediateDirectories: true)
        refreshCases()
        // Disabled auto-restore for now
        // restoreActiveCase()
    }
    
    // MARK: - Case Management
    
    /// Creates a case folder named after a new UUID. Stores displayName in a metadata file.
    func createCase(displayName: String) throws {
        let id = UUID()
        let newCaseURL = casesDirectory.appendingPathComponent(id.uuidString, isDirectory: true)
        
        try FileManager.default.createDirectory(at: newCaseURL, withIntermediateDirectories: true)
        
        // Store displayName in a simple metadata file
        let metaURL = newCaseURL.appendingPathComponent("case.meta")
        try displayName.data(using: .utf8)?.write(to: metaURL)
        
        refreshCases()
    }
    
    func deleteCase(id: UUID) throws {
        let caseURL = casesDirectory.appendingPathComponent(id.uuidString, isDirectory: true)
        try FileManager.default.removeItem(at: caseURL)
        refreshCases()
        
        if activeCase?.id == id {
            activeCase = nil
        }
    }
    
    func refreshCases() {
        do {
            let contents = try FileManager.default.contentsOfDirectory(
                at: casesDirectory,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            )
            cases = contents
                .filter { $0.hasDirectoryPath }
                .compactMap { url in
                    guard let id = UUID(uuidString: url.lastPathComponent) else { return nil }
                    
                    // Load displayName from metadata file, fallback to UUID
                    let metaURL = url.appendingPathComponent("case.meta")
                    let displayName = (try? String(contentsOf: metaURL)) ?? id.uuidString
                    
                    return CaseInfo(id: id, name: id.uuidString, displayName: displayName, url: url)
                }
                .sorted {
                    $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
                }
        } catch {
            cases = []
        }
    }
    
    // MARK: - Persistence
    
    private func persistActiveCase() {
        guard let activeCase else {
            UserDefaults.standard.removeObject(forKey: activeCaseKey)
            return
        }
        UserDefaults.standard.set(activeCase.id.uuidString, forKey: activeCaseKey)
    }
    
    private func restoreActiveCase() {
        if let savedID = UserDefaults.standard.string(forKey: activeCaseKey),
           let id = UUID(uuidString: savedID),
           let match = cases.first(where: { $0.id == id }) {
            activeCase = match
        }
    }
}

