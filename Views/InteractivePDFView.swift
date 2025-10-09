//
//  InteractivePDFView.swift
//  ePleadingsMVP
//
//  Created by Peter Milligan on 07/10/2025.
//  Updated 10/10/2025 — fully object-based highlight refresh
//  ✅ Replaced filename-based refresh with DocumentEntity reference
//  ✅ Consistent Core Data predicate use (document == %@)
//  ✅ Disabled PDFKit’s default context menu
//

import PDFKit
import SwiftUI
import CoreData

final class InteractivePDFView: PDFView {
    var onRightClick: ((Int, CGPoint) -> Void)?
    var onLeftClick: ((Int, CGPoint) -> Void)?

    // 👉 Injected Core Data context (set by Representable on creation)
    var managedObjectContext: NSManagedObjectContext?

    // Keep track of the last clicked sentence
    private var lastClickedSentence: SentenceEntity?

    // MARK: - Mouse Handling

    override func menu(for event: NSEvent) -> NSMenu? {
        // 🧩 Returning nil suppresses PDFKit’s built-in menu entirely
        return nil
    }

    override func mouseDown(with event: NSEvent) {
        // Treat Control + Left Click as Right Click
        if event.modifierFlags.contains(.control) {
            self.rightMouseDown(with: event)   // 🔄 synthesize right-click
            return
        }

        guard let page = self.page(for: event.locationInWindow, nearest: true) else { return }
        let point = self.convert(event.locationInWindow, to: page)
        let pageNumber = page.label.flatMap { Int($0) } ?? 0
        onLeftClick?(pageNumber, point)
    }

    override func rightMouseDown(with event: NSEvent) {
        guard let page = self.page(for: event.locationInWindow, nearest: true) else { return }
        let point = self.convert(event.locationInWindow, to: page)
        let pageNumber = page.label.flatMap { Int($0) } ?? 0
        onRightClick?(pageNumber, point)

        if let s = findNearestSentence(pageNumber: pageNumber, point: point) {
            lastClickedSentence = s
        } else {
            Swift.print("⚠️ No nearby sentence found.")
            return
        }

        // 👉 Build custom context menu
        let menu = NSMenu(title: "Tag Sentence")
        menu.addItem(withTitle: "Admitted", action: #selector(markAdmitted), keyEquivalent: "")
        menu.addItem(withTitle: "Denied", action: #selector(markDenied), keyEquivalent: "")
        menu.addItem(withTitle: "Not Known", action: #selector(markNotKnown), keyEquivalent: "")
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "Cancel", action: nil, keyEquivalent: "")
        NSMenu.popUpContextMenu(menu, with: event, for: self)
    }

    // MARK: - Tagging Handlers

    @objc private func markAdmitted() { updateSentenceState("Admitted") }
    @objc private func markDenied() { updateSentenceState("Denied") }
    @objc private func markNotKnown() { updateSentenceState("Not Known") }

    private func updateSentenceState(_ newState: String) {
        guard let s = lastClickedSentence,
              let context = managedObjectContext else {
            Swift.print("⚠️ No sentence/context available for tagging.")
            return
        }

        s.state = newState
        do {
            try context.save()
            Swift.print("✅ Marked “\(s.text ?? "(unknown)")” as \(newState)")

            // ✅ NEW — trigger highlight refresh using linked DocumentEntity
            if let document = s.document {
                self.refreshHighlights(for: document, context: context)
            } else {
                Swift.print("⚠️ No DocumentEntity linked to sentence.")
            }

        } catch {
            Swift.print("❌ Failed to save state: \(error)")
        }
    }

    // MARK: - Simple nearest-sentence finder (replace with SentenceLookupService later)
    private func findNearestSentence(pageNumber: Int, point: CGPoint) -> SentenceEntity? {
        guard let context = managedObjectContext else { return nil }
        let request: NSFetchRequest<SentenceEntity> = SentenceEntity.fetchRequest()
        request.predicate = NSPredicate(format: "pageNumber == %d", pageNumber)

        do {
            let candidates = try context.fetch(request)
            guard !candidates.isEmpty else { return nil }

            var best: SentenceEntity?
            var bestDist = CGFloat.greatestFiniteMagnitude
            for s in candidates {
                let cx = CGFloat(s.mappedX) + CGFloat(s.mappedWidth) / 2
                let cy = CGFloat(s.mappedY) + CGFloat(s.mappedHeight) / 2
                let dx = point.x - cx
                let dy = point.y - cy
                let dist = sqrt(dx*dx + dy*dy)
                if dist < bestDist {
                    best = s
                    bestDist = dist
                }
            }
            return best
        } catch {
            Swift.print("⚠️ Lookup failed: \(error)")
            return nil
        }
    }

    func scrollTo(page: PDFPage, rect: CGRect) {
        self.go(to: rect, on: page)
    }
}

// MARK: - Live Highlight Refresh (object-based)
extension InteractivePDFView {

    /// Removes all existing highlights and reapplies updated ones from Core Data.
    func refreshHighlights(for document: DocumentEntity,
                           context: NSManagedObjectContext) {
        guard let pdfDocument = self.document else {
            Swift.print("⚠️ refreshHighlights: No PDF document loaded.")
            return
        }

        // 🧹 Remove all existing highlight annotations
        for i in 0..<pdfDocument.pageCount {
            guard let page = pdfDocument.page(at: i) else { continue }
            let oldHighlights = page.annotations.filter {
                $0.type == PDFAnnotationSubtype.highlight.rawValue
            }
            oldHighlights.forEach { page.removeAnnotation($0) }
        }

        // 🔄 Reapply updated highlights via SentenceHighlightService
        SentenceHighlightService.applyHighlights(
            to: self,
            for: document,
            context: context
        )

        Swift.print("🔁 InteractivePDFView: highlights refreshed for \(document.filename ?? "(unknown)")")
    }
}

