import SwiftUI

struct ContentView: View {
    @StateObject private var importService = ImportService()
    
    var body: some View {
        VStack {
            List {
                ForEach(importService.importedFiles) { file in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(file.caseName)
                            .font(.headline)
                        
                        if file.isPDFMissing {
                            Text("⚠ Missing PDF")
                                .foregroundColor(.orange)
                                .font(.subheadline)
                        }
                        if file.isDOCXMissing {
                            Text("⚠ Missing DOCX")
                                .foregroundColor(.orange)
                                .font(.subheadline)
                        }
                    }
                }
            }
            
            Button("Import File") {
                importService.importFile()
            }
            .padding()
        }
        .frame(minWidth: 400, minHeight: 300)
    }
}

