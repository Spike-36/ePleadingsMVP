//
//  HeadingToPageMapper.swift
//  ePleadingsMVP
//
//  Created by Peter Milligan on 28/09/2025.
//

import Foundation
import CoreData
import PDFKit

struct HeadingToPageMapper {
    let context: NSManagedObjectContext
    let pdfURL: URL
    
    func mapHeadingsToPages() {
        // ✅ Only process PDFs
        guard pdfURL.pathExtension.lowercased() == "pdf" else {
            print("⚠️ Skipping non-PDF file: \(pdfURL.lastPathComponent)")
            return
        }
        
        // Load PDF
        guard let pdfDoc = PDFDocument(url: pdfURL) else {
            print("❌ Failed to load PDF at \(pdfURL)")
            return
        }
        
        // Fetch all headings linked to this document
        let fetchRequest: NSFetchRequest<HeadingEntity> = HeadingEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "document.filePath == %@", pdfURL.path)
        
        guard let headings = try? context.fetch(fetchRequest) else {
            print("⚠️ Could not fetch headings for PDF: \(pdfURL.lastPathComponent)")
            return
        }
        
        print("📑 Running HeadingToPageMapper on \(headings.count) heading(s) for \(pdfURL.lastPathComponent)")
        
        for heading in headings {
            guard let text = heading.text, !text.isEmpty else { continue }
            
            var foundBox: CGRect? = nil
            var foundPage: Int = 0
            
            // 🔍 Search the document for the heading text
            if let selection = pdfDoc.findString(text, withOptions: .caseInsensitive),
               let page = selection.page {
                
                let box = selection.bounds(for: page)
                foundBox = box
                foundPage = pdfDoc.index(for: page) + 1 // 0-based → 1-based
                
                print("➡️ Mapped heading '\(text)' → page \(foundPage) @ (\(Int(box.origin.x)), \(Int(box.origin.y)), \(Int(box.width))×\(Int(box.height)))")
            }
            
            // Save mapping
            if let box = foundBox {
                heading.mappedPageNumber = Int32(foundPage)
                heading.mappedX = Double(box.origin.x)
                heading.mappedY = Double(box.origin.y)
                heading.mappedWidth = Double(box.width)
                heading.mappedHeight = Double(box.height)
            } else {
                // Fallback if not found in PDF
                heading.mappedPageNumber = 1
                heading.mappedX = 0
                heading.mappedY = 0
                heading.mappedWidth = 0
                heading.mappedHeight = 0
                
                print("⚠️ Could not locate heading '\(text)' in PDF → defaulted to page 1")
            }
        }
        
        do {
            try context.save()
            print("✅ Saved heading mappings into Core Data")
        } catch {
            print("❌ Failed to save heading mappings: \(error)")
        }
    }
}

