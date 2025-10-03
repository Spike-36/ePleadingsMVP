//
//  FileHelper.swift
//  ePleadingsMVP
//

import Foundation

/// Provides helper functions for accessing the app’s file system directories.
enum FileHelper {
    
    /// Returns the Cases directory (creates it if missing).
    static var casesDirectory: URL {
        let fm = FileManager.default
        let base = fm.urls(for: .documentDirectory, in: .userDomainMask).first!
        let casesURL = base.appendingPathComponent("Cases", isDirectory: true)
        if !fm.fileExists(atPath: casesURL.path) {
            try? fm.createDirectory(at: casesURL, withIntermediateDirectories: true)
        }
        return casesURL
    }
    
    /// Builds a URL for a specific case folder.
    static func caseDirectory(for caseID: UUID) -> URL {
        return casesDirectory.appendingPathComponent(caseID.uuidString, isDirectory: true)
    }
    
    /// Sanitizes a string into a safe folder name (removes illegal characters).
    static func safeName(from raw: String) -> String {
        let invalid = CharacterSet(charactersIn: "/\\:?%*|\"<>")
        let cleaned = raw
            .components(separatedBy: invalid)
            .joined(separator: "_")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        return cleaned.isEmpty ? "UntitledCase" : cleaned
    }
    
    /// Copies a file into the given case folder (using UUID). Returns the new URL.
    static func copyFile(from sourceURL: URL, toCaseID caseID: UUID) throws -> URL {
        let fm = FileManager.default
        let caseFolder = caseDirectory(for: caseID)
        
        if !fm.fileExists(atPath: caseFolder.path) {
            try fm.createDirectory(at: caseFolder, withIntermediateDirectories: true)
        }
        
        let destURL = caseFolder.appendingPathComponent(sourceURL.lastPathComponent)
        
        // Overwrite if exists
        if fm.fileExists(atPath: destURL.path) {
            try fm.removeItem(at: destURL)
        }
        
        try fm.copyItem(at: sourceURL, to: destURL)
        return destURL
    }
}

