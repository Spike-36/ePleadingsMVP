//
//  DocxParser.swift
//  ePleadingsMVP
//
//  Created by Peter Milligan on 24/09/2025.
//
import Foundation
import ZIPFoundation

/// Simple DOCX parser for MVP.
/// Extracts <w:t> text runs from document.xml and groups them into paragraphs.
class DocxParser: NSObject {
    private var currentElement = ""
    private var currentText = ""
    private var paragraphs: [String] = []
    
    func parseDocx(at url: URL) throws -> [String] {
        // 1. Unzip DOCX (it's a zip archive)
        guard let archive = Archive(url: url, accessMode: .read) else {
            throw NSError(domain: "DocxParser", code: 1, userInfo: [NSLocalizedDescriptionKey: "Not a valid DOCX file"])
        }
        
        // 2. Extract document.xml from /word/document.xml
        let tempDir = FileManager.default.temporaryDirectory
        let xmlURL = tempDir.appendingPathComponent(UUID().uuidString + ".xml")
        
        try archive.extract("word/document.xml", to: xmlURL)
        
        // 3. Parse XML
        let parser = XMLParser(contentsOf: xmlURL)!
        parser.delegate = self
        parser.parse()
        
        return paragraphs
    }
}

extension DocxParser: XMLParserDelegate {
    func parser(_ parser: XMLParser, didStartElement elementName: String,
                namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        if elementName == "w:p" { // start of paragraph
            currentText = ""
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if currentElement == "w:t" {
            currentText.append(string)
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String,
                namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "w:p" { // end of paragraph
            let trimmed = currentText.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                paragraphs.append(trimmed)
            }
        }
        currentElement = ""
    }
}

private extension Archive {
    /// Extract a single file to a URL
    func extract(_ path: String, to destURL: URL) throws {
        guard let entry = self[path] else {
            throw NSError(domain: "DocxParser", code: 2, userInfo: [NSLocalizedDescriptionKey: "Missing \(path)"])
        }
        _ = try self.extract(entry, consumer: { data in
            try? data.write(to: destURL, options: .atomic)
        })
    }
}

