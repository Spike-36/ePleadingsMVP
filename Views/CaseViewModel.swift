//  CaseViewModel.swift
//  ePleadingsMVP

import Foundation
import SwiftUI

@MainActor
class CaseViewModel: ObservableObject {
    @Published var sentences: [SentenceItem] = [
        SentenceItem(
            text: "This is page 1 argument.",
            pageNumber: 1,
            sourceFilename: "pleadingsShort.pdf"
        ),
        SentenceItem(
            text: "This is page 2 evidence.",
            pageNumber: 2,
            sourceFilename: "pleadingsShort.pdf"
        ),
        SentenceItem(
            text: "This is page 3 conclusion.",
            pageNumber: 3,
            sourceFilename: "pleadingsShort.pdf"
        )
    ]

    @Published var targetPage: Int? = nil

    func jumpToPage(_ page: Int) {
        targetPage = page
    }
}

