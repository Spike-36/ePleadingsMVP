//
//  InteractivePDFView.swift
//  ePleadingsMVP
//
//  Updated: 10/10/2025 — PDF coordinate alignment + diagnostic logging (corrected for PDFKit API)
//  ✅ Uses PDFView coordinate conversion correctly (no PDFPage.convert)
//  ✅ Converts click location into PDF-space
//  ✅ Prefixed all print statements with Swift.print
//  ✅ Added rect containment diagnostic
//

import PDFKit
import SwiftUI
import CoreData

final class InteractivePDFView: PDFView {
    var onRightClick: ((Int, CGPoint) -> Void)?
    var onLeftClick: ((Int, CGPoint) -> Void)?
    var managedObjectContext: NSManagedObjectContext?

    private var lastClickedSentence: SentenceEntity?

    // MARK: - Mouse Handling

    override func menu(for event: NSEvent) -> NSMenu? {
        return nil
    }

    override func mouseDown(with event: NSEvent) {
        if event.modifierFlags.contains(.control) {
            self.rightMouseDown(with: event)
            return
        }

        guard let page = self.page(for: event.locationInWindow, nearest: true) else { return }

        // ✅ Correct coordinate conversion using PDFView only
        let pointInView = self.convert(event.locationInWindow, from: nil)
        let pdfPoint = self.convert(pointInView, to: page)

        let pageNumber = page.label.flatMap { Int($0) } ?? 0
        Swift.print("🖱️ Left click on page \(pageNumber) at \(pdfPoint)")
        onLeftClick?(pageNumber, pdfPoint)
    }

    override func rightMouseDown(with event: NSEvent) {
        guard let page = self.page(for: event.locationInWindow, nearest: true) else { return }

        // ✅ Correct coordinate conversion using PDFView only
        let pointInView = self.convert(event.locationInWindow, from: nil)
        let pdfPoint = self.convert(pointInView, to: page)

        let pageNumber = page.label.flatMap { Int($0) } ?? 0
        Swift.print("🖱️ Right click on page \(pageNumber) at \(pdfPoint)")
        onRightClick?(pageNumber, pdfPoint)

        if let s = findNearestSentence(pageNumber: pageNumber, point: pdfPoint) {
            lastClickedSentence = s
            Swift.print("🎯 Matched to sentence: '\(s.text.prefix(50))…'  rect=(\(s.mappedX.rounded()), \(s.mappedY.rounded()), \(s.mappedWidth.rounded()), \(s.mappedHeight.rounded()))")
        } else {
            Swift.print("⚠️ No nearby sentence found.")
            return
        }

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
            if let document = s.document {
                self.refreshHighlights(for: document, context: context)
            } else {
                Swift.print("⚠️ No DocumentEntity linked to sentence.")
            }
        } catch {
            Swift.print("❌ Failed to save state: \(error)")
        }
    }

    // MARK: - Diagnostic nearest-sentence finder
    private func findNearestSentence(pageNumber: Int, point: CGPoint) -> SentenceEntity? {
        guard let context = managedObjectContext else { return nil }
        let request: NSFetchRequest<SentenceEntity> = SentenceEntity.fetchRequest()
        request.predicate = NSPredicate(format: "pageNumber == %d", pageNumber)

        do {
            let candidates = try context.fetch(request)
            guard !candidates.isEmpty else {
                Swift.print("⚠️ No sentence candidates found for page \(pageNumber)")
                return nil
            }

            var best: SentenceEntity?
            var bestDist = CGFloat.greatestFiniteMagnitude
            for s in candidates {
                let cx = CGFloat(s.mappedX) + CGFloat(s.mappedWidth) / 2
                let cy = CGFloat(s.mappedY) + CGFloat(s.mappedHeight) / 2
                let dx = point.x - cx
                let dy = point.y - cy
                let dist = sqrt(dx*dx + dy*dy)
                Swift.print("📍 Distance from click → “\(s.text.prefix(20))…” = \(dist.rounded())")
                if dist < bestDist {
                    best = s
                    bestDist = dist
                }
            }

            if let best = best {
                Swift.print("🏁 Nearest sentence selected: “\(best.text.prefix(40))…” (dist=\(bestDist.rounded()))")

                // 🧩 Check click containment within mapped rect
                let rect = CGRect(
                    x: best.mappedX,
                    y: best.mappedY,
                    width: best.mappedWidth,
                    height: best.mappedHeight
                )
                let inside = rect.contains(point)
                Swift.print("🧩 Click position relative to rect: \(inside ? "✅ inside" : "❌ outside") — click=\(point), rect=\(rect.debugDescription)")
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

