import SwiftUI

struct ContentView: View {
    @StateObject private var importService = ImportService()
    
    var body: some View {
        VStack(spacing: 20) {
            Button(action: {
                importService.importFile()
            }) {
                Text("Import File")
                    .padding()
            }
            
            if importService.importedFiles.isEmpty {
                Text("No files imported yet")
                    .foregroundColor(.secondary)
            } else {
                List(importService.importedFiles) { file in
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(file.name).\(file.fileExtension)")
                            .font(.headline)
                        Text(file.localURL.path)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .frame(minWidth: 400, minHeight: 300)
        .padding()
    }
}

