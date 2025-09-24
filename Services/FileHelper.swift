//
//  FileHelper.swift
//  ePleadingsMVP
//
//  Provides safe file system helpers for working inside the app sandbox.
//

import Foundation

enum FileHelper {
    
    /// Return the app’s Application Support directory, creating it if needed.
    static func applicationSupportDirectory() throws -> URL {
        try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
    }
    
    /// Return (and create if needed) a case folder inside Application Support.
    static func caseFolder(named safeName: String) throws -> URL {
        let base = try applicationSupportDirectory()
        let caseFolder = base.appendingPathComponent("CaseFiles").appendingPathComponent(safeName)
        
        if !FileManager.default.fileExists(atPath: caseFolder.path) {
            try FileManager.default.createDirectory(
                at: caseFolder,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }
        return caseFolder
    }
    
    /// Copy a file into a specific case folder, overwriting if necessary.
    static func copyFile(_ source: URL, toCaseFolder safeName: String) throws -> URL {
        let ext = source.pathExtension.lowercased()
        let destFolder = try caseFolder(named: safeName)
        let destURL = destFolder.appendingPathComponent("\(safeName).\(ext)")
        
        if FileManager.default.fileExists(atPath: destURL.path) {
            try FileManager.default.removeItem(at: destURL)
        }
        
        try FileManager.default.copyItem(at: source, to: destURL)
        return destURL
    }
    
    /// Normalize a base name for safe folder use (strip spaces, lowercase).
    static func safeName(from raw: String) -> String {
        raw.replacingOccurrences(of: " ", with: "_").lowercased()
    }
    
    /// Save a picked file into the app’s sandbox under its own case folder.
    static func saveToSandbox(originalURL: URL) throws -> URL {
        let name = originalURL.deletingPathExtension().lastPathComponent
        let safe = safeName(from: name)
        return try copyFile(originalURL, toCaseFolder: safe)
    }
}

