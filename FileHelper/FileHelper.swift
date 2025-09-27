//
//  FileHelper.swift
//  ePleadingsMVP
//

import Foundation

enum FileHelper {
    // MARK: - Base directory
    static var casesDirectory: URL {
        guard let base = FileManager.default.urls(for: .documentDirectory,
                                                  in: .userDomainMask).first else {
            fatalError("❌ Could not locate Documents directory")
        }
        let dir = base.appendingPathComponent("Cases", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            do {
                try FileManager.default.createDirectory(
                    at: dir,
                    withIntermediateDirectories: true,
                    attributes: nil
                )
            } catch {
                fatalError("❌ Failed to create Cases directory: \(error)")
            }
        }
        return dir
    }

    // MARK: - Safe case name
    static func safeName(from displayName: String) -> String {
        // Replace spaces with underscores and strip unsafe characters
        let allowed = CharacterSet.alphanumerics.union(.init(charactersIn: "_-"))
        return displayName
            .map { allowed.contains($0.unicodeScalars.first!) ? $0 : "_" }
            .reduce("") { $0 + String($1) }
    }

    // MARK: - Case folder lookup
    static func caseFolder(named safeName: String) throws -> URL {
        let folder = casesDirectory.appendingPathComponent(safeName, isDirectory: true)
        if !FileManager.default.fileExists(atPath: folder.path) {
            try FileManager.default.createDirectory(
                at: folder,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }
        return folder
    }

    // MARK: - File copy (with normalization)
    static func copyFile(from source: URL, toCase caseName: String) throws -> URL {
        let folder = try caseFolder(named: caseName)

        // Normalize name if PDF or DOCX
        let ext = source.pathExtension.lowercased()
        let destFileName: String
        if ext == "pdf" {
            destFileName = "\(caseName).pdf"
        } else if ext == "docx" {
            destFileName = "\(caseName).docx"
        } else {
            destFileName = source.lastPathComponent // keep original name
        }

        let dest = folder.appendingPathComponent(destFileName)

        // Avoid overwriting an existing file
        if FileManager.default.fileExists(atPath: dest.path) {
            try FileManager.default.removeItem(at: dest)
        }

        try FileManager.default.copyItem(at: source, to: dest)
        return dest
    }

    // MARK: - Delete entire case
    static func deleteCaseFolder(named safeName: String) throws {
        let folder = casesDirectory.appendingPathComponent(safeName, isDirectory: true)
        if FileManager.default.fileExists(atPath: folder.path) {
            try FileManager.default.removeItem(at: folder)
        }
    }
}

