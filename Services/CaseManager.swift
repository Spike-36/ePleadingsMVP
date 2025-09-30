//
//  CaseManager.swift
//  ePleadingsMVP
//

import Foundation
import SwiftUI

/// Represents a single case folder.
struct CaseInfo: Identifiable, Hashable {
    let id = UUID()
    let name: String
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
/// These detect **any** .docx / .pdf file in the case folder.
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
    private let activeCaseKey = "ActiveCaseName"
    
    // MARK: - Init
    private init() {
        // Single source of truth for the Cases directory
        casesDirectory = FileHelper.casesDirectory
        
        // Ensure directory exists (FileHelper already does this, but harmless)
        try? FileManager.default.createDirectory(
            at: casesDirectory,
            withIntermediateDirectories: true
        )
        
        refreshCases()
        
        // 👉 Disabled auto-restore at startup
        // restoreActiveCase()
    }
    
    // MARK: - Case Management
    
    func createCase(named name: String) throws {
        let safeName = FileHelper.safeName(from: name)
        let newCaseURL = casesDirectory.appendingPathComponent(safeName, isDirectory: true)
        
        if FileManager.default.fileExists(atPath: newCaseURL.path) {
            throw NSError(domain: "CaseManager",
                          code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Case already exists"])
        }
        
        try FileManager.default.createDirectory(at: newCaseURL, withIntermediateDirectories: true)
        refreshCases()
    }
    
    func deleteCase(named name: String) throws {
        let caseURL = casesDirectory.appendingPathComponent(name, isDirectory: true)
        try FileManager.default.removeItem(at: caseURL)
        refreshCases()
        
        if activeCase?.name == name {
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
                .map { url in
                    let safe = url.lastPathComponent
                    return CaseInfo(name: safe, displayName: safe, url: url)
                }
                .sorted {
                    $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
                }
        } catch {
            // 🔄 Quietly handle failure without spamming logs
            cases = []
        }
    }
    
    // MARK: - Persistence
    
    private func persistActiveCase() {
        guard let activeCase else {
            UserDefaults.standard.removeObject(forKey: activeCaseKey)
            return
        }
        UserDefaults.standard.set(activeCase.name, forKey: activeCaseKey)
    }
    
    private func restoreActiveCase() {
        if let savedName = UserDefaults.standard.string(forKey: activeCaseKey),
           let match = cases.first(where: { $0.name == savedName }) {
            activeCase = match
        }
    }
}

