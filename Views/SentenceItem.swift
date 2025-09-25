import Foundation

struct SentenceItem: Identifiable, Hashable {
    let id: String
    let text: String
    let pageNumber: Int
    let sourceFilename: String?

    init(text: String, pageNumber: Int, sourceFilename: String?) {
        // Construct a stable ID from filename + page + text
        self.id = "\(sourceFilename ?? "unknown")-\(pageNumber)-\(text)"
        self.text = text
        self.pageNumber = pageNumber
        self.sourceFilename = sourceFilename
    }
}

