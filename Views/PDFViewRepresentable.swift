//
//  PDFViewRepresentable.swift
//  ePleadingsMVP
//
//  Created by Peter Milligan on 26/09/2025.
//

import SwiftUI
import PDFKit

/// A SwiftUI wrapper around PDFKit’s PDFView (macOS version)
struct PDFViewRepresentable: NSViewRepresentable {
    let url: URL
    @Binding var selectedHeading: HeadingEntity?
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeNSView(context: Context) -> PDFContainerView {
        let container = PDFContainerView()
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.document = PDFDocument(url: url)
        
        container.pdfView = pdfView
        container.setupOverlay(with: context.coordinator)
        return container
    }

    func updateNSView(_ container: PDFContainerView, context: Context) {
        guard let pdfView = container.pdfView,
              let heading = selectedHeading,
              let doc = pdfView.document,
              heading.mappedPageNumber > 0 else { return }
        
        let pageIndex = Int(heading.mappedPageNumber - 1) // CoreData stores 1-based
        guard let page = doc.page(at: pageIndex) else { return }
        
        let bounds = CGRect(
            x: heading.mappedX,
            y: heading.mappedY,
            width: heading.mappedWidth,
            height: heading.mappedHeight
        )
        
        // 🔎 Scroll to region
        pdfView.go(to: bounds, on: page)
        
        // ✅ Remove old temp annotations first
        page.annotations
            .filter { $0.userName == "HeadingHighlight" }
            .forEach { page.removeAnnotation($0) }
        
        // ✅ Add a translucent yellow overlay box
        let highlight = PDFAnnotation(
            bounds: bounds,
            forType: .highlight,
            withProperties: nil
        )
        highlight.color = NSColor.systemYellow.withAlphaComponent(0.4)
        highlight.userName = "HeadingHighlight"
        page.addAnnotation(highlight)
        
        // ✅ Auto-remove after 2 seconds for a “flash” effect
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            page.removeAnnotation(highlight)
        }
    }

    // MARK: - Coordinator
    class Coordinator: NSObject {
        var parent: PDFViewRepresentable
        
        init(_ parent: PDFViewRepresentable) {
            self.parent = parent
        }
        
        @objc func handleClick(_ gesture: NSClickGestureRecognizer) {
            guard let overlay = gesture.view as? NSView,
                  let container = overlay.superview as? PDFContainerView,
                  let pdfView = container.pdfView else { return }
            
            let locationInOverlay = gesture.location(in: overlay)
            let locationInPDF = pdfView.convert(locationInOverlay, from: overlay)
            
            guard let page = pdfView.page(for: locationInPDF, nearest: true) else {
                print("🖱️ Click outside page area at \(locationInOverlay)")
                return
            }
            
            let locationOnPage = pdfView.convert(locationInOverlay, to: page)
            print("🖱️ Click detected → Page: \(page.label ?? "?"), Coordinates: \(locationOnPage)")
            
            // 🔶 Draw a short-lived highlight box at the click point
            let boxSize: CGFloat = 40
            let boxOrigin = CGPoint(
                x: locationOnPage.x - boxSize / 2,
                y: locationOnPage.y - boxSize / 2
            )
            let highlightRect = CGRect(origin: boxOrigin, size: CGSize(width: boxSize, height: boxSize))
            
            let clickHighlight = PDFAnnotation(bounds: highlightRect, forType: .square, withProperties: nil)
            clickHighlight.color = NSColor.systemBlue.withAlphaComponent(0.3)
            clickHighlight.border = PDFBorder()
            clickHighlight.border?.lineWidth = 1.5
            clickHighlight.userName = "ClickFlash"
            page.addAnnotation(clickHighlight)
            
            // Auto-remove after short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                page.removeAnnotation(clickHighlight)
            }
        }
        
        // 👉 handleRightClick for Phase 6.1
        @objc func handleRightClick(_ gesture: NSClickGestureRecognizer) {
            guard let container = gesture.view?.superview as? PDFContainerView,
                  let pdfView = container.pdfView else { return }
            
            let location = gesture.location(in: gesture.view)
            let pdfLocation = pdfView.convert(location, from: gesture.view)
            
            if let page = pdfView.page(for: pdfLocation, nearest: true) {
                let point = pdfView.convert(location, to: page)
                print("🖱️ Right-click → Page \(page.label ?? "?"), Coords \(point)")
            }
        }
    }
}

/// Container that hosts both PDFView and transparent overlay for click detection
final class PDFContainerView: NSView {
    var pdfView: PDFView?
    private var overlayView: NSView?
    
    func setupOverlay(with coordinator: PDFViewRepresentable.Coordinator) {
        guard let pdfView else { return }
        pdfView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(pdfView)
        
        // Fit PDFView to container
        NSLayoutConstraint.activate([
            pdfView.leadingAnchor.constraint(equalTo: leadingAnchor),
            pdfView.trailingAnchor.constraint(equalTo: trailingAnchor),
            pdfView.topAnchor.constraint(equalTo: topAnchor),
            pdfView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        // Add overlay on top
        let overlay = NSView()
        overlay.translatesAutoresizingMaskIntoConstraints = false
        overlay.wantsLayer = true
        overlay.layer?.backgroundColor = NSColor.clear.cgColor
        addSubview(overlay)
        self.overlayView = overlay
        
        NSLayoutConstraint.activate([
            overlay.leadingAnchor.constraint(equalTo: leadingAnchor),
            overlay.trailingAnchor.constraint(equalTo: trailingAnchor),
            overlay.topAnchor.constraint(equalTo: topAnchor),
            overlay.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        // 👉 Explicit left-click recognizer setup
        let clickRecognizer = NSClickGestureRecognizer(target: coordinator,
                                                       action: #selector(coordinator.handleClick(_:)))
        clickRecognizer.buttonMask = 0x1 // left button only
        overlay.addGestureRecognizer(clickRecognizer)
        
        // 👉 Explicit right-click recognizer setup
        let rightClick = NSClickGestureRecognizer(target: coordinator,
                                                  action: #selector(coordinator.handleRightClick(_:)))
        rightClick.numberOfClicksRequired = 1
        rightClick.buttonMask = 0x2 // right mouse button
        overlay.addGestureRecognizer(rightClick)
        
        print("✅ Overlay ready: left/right recognizers attached (\(overlay.gestureRecognizers.count) total).")
        
        // 🔄 Optional monitor for low-level events (uncomment for debugging)
        /*
        NSEvent.addLocalMonitorForEvents(matching: [.rightMouseDown]) { event in
            print("🧩 RightMouseDown monitor → location: \(event.locationInWindow)")
            return event
        }
        */
    }
}

