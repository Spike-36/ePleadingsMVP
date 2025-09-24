import Foundation
import AppKit
import UniformTypeIdentifiers

struct CaseFile: Identifiable {
    let id = UUID()
    let name: String        // Base name without extension
    let fileExtension: String
    let localURL: URL       // Location in app’s sandbox
}

/// Service to handle importing files into the app’s sandbox (macOS).
final class ImportService: ObservableObject {
    @Published var importedFiles: [CaseFile] = []
    
    func importFile() {
        DispatchQueue.main.async {
            let panel = NSOpenPanel()
            panel.allowsMultipleSelection = false
            panel.canChooseDirectories = false
            panel.canChooseFiles = true
            panel.allowedContentTypes = [
                .pdf,
                UTType(filenameExtension: "docx")!
            ]
            
            if panel.runModal() == .OK, let pickedURL = panel.url {
                let ext = pickedURL.pathExtension.lowercased()
                let name = pickedURL.deletingPathExtension().lastPathComponent
                
                do {
                    // Delegate actual file copy into sandbox to FileHelper
                    let destination = try FileHelper.saveToSandbox(originalURL: pickedURL)
                    
                    // Record it in our model
                    let newFile = CaseFile(
                        name: name,
                        fileExtension: ext,
                        localURL: destination
                    )
                    self.importedFiles.append(newFile)
                } catch {
                    print("❌ ImportService failed: \(error)")
                }
            }
        }
    }
}

