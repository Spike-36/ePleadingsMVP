//
//  DocxParser.swift
//  ePleadingsMVP
//
//  Created by Peter Milligan on 24/09/2025.
//

import Foundation
import ZIPFoundation

/// DOCX parser for MVP.
/// Unzips .docx → extracts /word/document.xml → walks with XMLParser → collects <w:t> runs into normalized paragraphs.
class DocxParser: NSObject {
    private var paragraphs: [String] = []
    private var currentParagraph: String = ""
    private var insideText: Bool = false

    /// Parse the DOCX at the given URL and return paragraphs of text.
    func parseDocx(at url: URL) throws -> [String] {
        // 1. Open as ZIP
        guard let archive = Archive(url: url, accessMode: .read) else {
            throw NSError(domain: "DocxParser", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Not a valid DOCX file"])
        }

        // 2. Extract document.xml to temp
        let tempDir = FileManager.default.temporaryDirectory
        let xmlURL = tempDir.appendingPathComponent(UUID().uuidString + ".xml")
        try archive.extract("word/document.xml", to: xmlURL)

        // Reset before parsing
        paragraphs = []

        // 3. Parse XML
        let parser = XMLParser(contentsOf: xmlURL)!
        parser.delegate = self
        parser.parse()

        return paragraphs
    }

    /// Scan parsed paragraphs for headings like "Statement 1" / "Answer 2" / "Cond. 3"
    /// Only captures the prefix (e.g. "Cond. 5", "Ans. 3"), not the trailing narrative.
    func parseHeadings(at url: URL) throws -> [String] {
        let paras = try parseDocx(at: url)

        // Regex captures only the prefix (group 0)
        let regex = try NSRegularExpression(
            pattern: "^(Statement|Stat\\.?|Answer|Ans\\.?|Condescendence|Cond\\.?)\\s*\\d+",
            options: [.caseInsensitive]
        )

        var found: [String] = []
        for para in paras {
            let range = NSRange(para.startIndex..<para.endIndex, in: para)
            if let match = regex.firstMatch(in: para, options: [], range: range),
               let swiftRange = Range(match.range, in: para) {
                let headingOnly = String(para[swiftRange])
                print("📑 Found heading: \(headingOnly) (from paragraph: '\(para)')")
                found.append(headingOnly)
            }
        }

        return found
    }

    /// Collapse all whitespace variants (space, tabs, NBSP, thin spaces) into a single " ".
    private func normalizeWhitespace(_ s: String) -> String {
        let ws = CharacterSet.whitespacesAndNewlines
            .union(.init(charactersIn: "\u{00A0}\u{2000}\u{2001}\u{2002}\u{2003}\u{2009}"))

        let mapped = s.unicodeScalars.map { ws.contains($0) ? " " : String($0) }.joined()
        return mapped.replacingOccurrences(of: " +", with: " ", options: .regularExpression)
                     .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - XMLParserDelegate
extension DocxParser: XMLParserDelegate {
    func parser(_ parser: XMLParser,
                didStartElement elementName: String,
                namespaceURI: String?,
                qualifiedName qName: String?,
                attributes attributeDict: [String : String] = [:]) {
        switch elementName {
        case "w:p":
            currentParagraph = ""   // start new paragraph
        case "w:t":
            insideText = true       // ✅ ignore style attrs, just take text
        case "w:tab":
            currentParagraph.append("\t")
        case "w:br":
            currentParagraph.append("\n")
        default:
            break
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if insideText {
            currentParagraph.append(string)
        }
    }

    func parser(_ parser: XMLParser,
                didEndElement elementName: String,
                namespaceURI: String?,
                qualifiedName qName: String?) {
        switch elementName {
        case "w:t":
            insideText = false
        case "w:p":
            let trimmed = currentParagraph.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                // ✅ normalize before saving
                paragraphs.append(normalizeWhitespace(trimmed))
            }
        default:
            break
        }
    }
}

// MARK: - Archive convenience
private extension Archive {
    /// Extract a single file inside the archive to a given destination URL
    func extract(_ path: String, to destURL: URL) throws {
        guard let entry = self[path] else {
            throw NSError(domain: "DocxParser", code: 2,
                          userInfo: [NSLocalizedDescriptionKey: "Missing \(path)"])
        }
        var collected = Data()
        _ = try self.extract(entry) { data in
            collected.append(data)
        }
        try collected.write(to: destURL, options: .atomic)
    }
}

