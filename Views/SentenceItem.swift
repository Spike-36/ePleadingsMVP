import Foundation

struct SentenceItem: Identifiable, Hashable {
    let id: String
    let text: String
    let pageNumber: Int
    let sourceURL: URL?

    init(index: Int, text: String, pageNumber: Int, sourceURL: URL?) {
        // Stable ID: combine source path + paragraph index + hash of text
        let pathPart = sourceURL?.lastPathComponent ?? "unknown"
        let hashPart = text.hashValue
        self.id = "\(pathPart)-\(index)-\(hashPart)"
        
        self.text = text
        self.pageNumber = pageNumber
        self.sourceURL = sourceURL
    }
}

