import SwiftUI
import PDFKit

struct PleadingsPanel: View {
    let caseEntity: CaseEntity   // ✅ Core Data entity
    @Binding var selectedPage: Int?
    
    @State private var pdfURL: URL? = nil
    
    var body: some View {
        VStack {
            if let url = pdfURL {
                PDFViewRepresentable(url: url, selectedPage: $selectedPage)
            } else {
                Text("No pleadings PDF found for this case.")
                    .foregroundColor(.secondary)
            }
        }
        .onAppear { loadPleadings() }
        .onChange(of: selectedPage) { newValue in
            if let page = newValue {
                print("👉 PleadingsPanel received selectedPage = \(page)")
            }
        }
    }
    
    private func loadPleadings() {
        guard let documents = caseEntity.documents as? Set<DocumentEntity> else { return }
        let fm = FileManager.default
        
        // Case folder under Documents/Cases/{UUID}
        let caseFolder = PersistenceController.shared.casesFolder
            .appendingPathComponent(caseEntity.id.uuidString, isDirectory: true) // ✅ no optional chain
        
        for doc in documents {
            let filename = doc.filename   // ✅ non-optional String in DocumentEntity
            let fileURL = caseFolder.appendingPathComponent(filename)
            
            if fm.fileExists(atPath: fileURL.path),
               fileURL.pathExtension.lowercased() == "pdf" {
                pdfURL = fileURL
                return
            }
        }
    }
}

