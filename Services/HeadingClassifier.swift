//
//  HeadingClassifier.swift
//  ePleadingsMVP
//
//  Created by Peter Milligan on 29/09/2025.
//
//
//  HeadingClassifier.swift
//  ePleadingsMVP
//
//  Created by Peter Milligan on 28/09/2025.
//
import Foundation

enum PleadingHeadingType {
    case statement
    case answer
    case misc
}

struct HeadingClassifier {
    // 👇 You just add to these arrays as you discover more patterns
    private static let statementMarkers = ["Cond.", "Condition", "Stat.", "Statement"]
    private static let answerMarkers = ["Ans.", "Answer"]
    
    static func classify(_ text: String) -> PleadingHeadingType {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if statementMarkers.contains(where: { trimmed.hasPrefix($0) }) {
            return .statement
        }
        
        if answerMarkers.contains(where: { trimmed.hasPrefix($0) }) {
            return .answer
        }
        
        return .misc
    }
}

