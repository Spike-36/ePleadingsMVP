//
//  CaseManager.swift
//  ePleadingsMVP
//
//  Central manager for creating, opening, and listing cases.
//

import Foundation

/// Represents a single case folder.
struct CaseInfo: Identifiable, Hashable {
    let id = UUID()             // unique identifier
    let name: String            // Safe name (filesystem friendly)
    let displayName: String     // What the user typed
    let url: URL
}

/// Extra helpers for checking required files.
extension CaseInfo {
    var hasDocx: Bool {
        let docxURL = url.appendingPathComponent("defaultcase.docx")
        return FileManager.default.fileExists(atPath: docxURL.path)
    }
    
    var hasPdf: Bool {
        let pdfURL = url.appendingPathComponent("defaultcase.pdf")
        return FileManager.default.fileExists(atPath: pdfURL.path)
    }
}

/// Case manager handles all case-level operations.
final class CaseManager: ObservableObject {
    static let shared = CaseManager()
    
    @Published private(set) var cases: [CaseInfo] = []
    
    private init() {
        refreshCases()
    }
    
    /// Scan disk and refresh the list of known cases.
    func refreshCases() {
        let root = FileHelper.casesDirectory
        do {
            let dirs = try FileManager.default.contentsOfDirectory(
                at: root,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            )
            self.cases = dirs.filter { $0.hasDirectoryPath }.map { url in
                let safeName = url.lastPathComponent
                let displayName = safeName.replacingOccurrences(of: "_", with: " ")
                return CaseInfo(name: safeName, displayName: displayName, url: url)
            }.sorted {
                $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
            }
        } catch {
            print("❌ Failed to refresh cases: \(error)")
            self.cases = []
        }
    }
    
    /// Create a new case folder.
    func createCase(named displayName: String) throws {
        let safeName = FileHelper.safeName(from: displayName)
        _ = try FileHelper.caseFolder(named: safeName)
        refreshCases()
    }
    
    /// Delete a case folder permanently.
    func deleteCase(named safeName: String) throws {
        try FileHelper.deleteCaseFolder(named: safeName)
        refreshCases()
    }
}

