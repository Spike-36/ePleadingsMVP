//
//  HeadingClassifier.swift
//  ePleadingsMVP
//
//  Created by Peter Milligan on 29/09/2025.
//

import Foundation

enum PleadingHeadingType {
    case statement
    case answer
    case misc
}

struct HeadingClassifier {
    // Regular expressions for common heading patterns
    private static let statementPattern = #"^(Cond\.?|Condescendence|Statement|Stat\.?)\s*\d+"#
    private static let answerPattern = #"^(Ans\.?|Answer)\s*\d+"#

    /// Classify a block of text as statement/answer/misc
    static func classify(_ text: String) -> PleadingHeadingType {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.range(of: statementPattern, options: [.regularExpression, .caseInsensitive]) != nil {
            return .statement
        }

        if trimmed.range(of: answerPattern, options: [.regularExpression, .caseInsensitive]) != nil {
            return .answer
        }

        return .misc
    }

    /// Extracts the actual short heading string (e.g. "Cond. 1", "Ans. 3") if present.
    static func extractLabel(_ text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        if let match = trimmed.range(of: statementPattern, options: [.regularExpression, .caseInsensitive]) {
            return String(trimmed[match])
        }

        if let match = trimmed.range(of: answerPattern, options: [.regularExpression, .caseInsensitive]) {
            return String(trimmed[match])
        }

        return nil
    }
}

