//
//  DocxParser.swift
//  ePleadingsMVP
//
//  Created by Peter Milligan on 24/09/2025.
//

import Foundation
import ZIPFoundation

/// DOCX parser for MVP.
/// Unzips .docx → extracts /word/document.xml → walks with XMLParser → collects <w:t> runs into paragraphs.
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

    /// Stage 3.2 stub:
    /// Scan parsed paragraphs for headings like "Statement 1" / "Answer 2" / "Cond. 3"
    func parseHeadings(at url: URL) throws -> [String] {
        let paras = try parseDocx(at: url)

        // Regex: heading if starts with Statement/Answer/Cond variants + number (+ trailing text allowed)
        let regex = try NSRegularExpression(
            pattern: "^(Statement|Stat\\.?|Answer|Ans\\.?|Condescendence|Cond\\.?)\\s+\\d+\\b.*",
            options: [.caseInsensitive]
        )

        var found: [String] = []
        for para in paras {
            let range = NSRange(para.startIndex..<para.endIndex, in: para)
            if regex.firstMatch(in: para, options: [], range: range) != nil {
                print("📑 Found heading: \(para)")
                found.append(para)
            }
        }

        return found
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
            insideText = true
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
                paragraphs.append(trimmed)
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

