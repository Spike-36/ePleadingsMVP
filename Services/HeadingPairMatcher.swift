//
//  HeadingPairMatcher.swift
//  ePleadingsMVP
//
//  Created by Peter Milligan on 05/10/2025.
//
//
//  HeadingPairMatcher.swift
//  ePleadingsMVP
//
//  Created by Peter Milligan on 05/10/2025.
//

import Foundation

/// Utility to find a paired heading — e.g. "Statement 4" ↔ "Answer 4"
struct HeadingPairMatcher {
    
    /// Attempts to locate the corresponding paired heading.
    /// - Parameters:
    ///   - heading: The currently selected heading (Statement / Cond / Answer).
    ///   - headings: All available headings in the document.
    /// - Returns: The paired heading if found, or nil if none detected.
    static func findPair(for heading: HeadingEntity, in headings: [HeadingEntity]) -> HeadingEntity? {
        
        // Ensure text exists
        guard let text = heading.text?.lowercased() else { return nil }
        
        // Extract a number (e.g. 3 in "Statement 3", "Ans 3", "Cond 3")
        let pattern = #"(?i)(?:sta(?:tement)?|ans(?:wer)?|cond(?:escendence)?)\.?\s*(\d+)"#
        guard
            let match = text.range(of: pattern, options: .regularExpression),
            let numStr = String(text[match]).components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
                as String?,
            let num = Int(numStr)
        else {
            print("⚠️ HeadingPairMatcher: No number found in '\(text)'")
            return nil
        }
        
        // Determine whether this is a Statement/Cond or Answer
        let isStatementLike = text.contains("stat") || text.contains("cond")
        let targetPrefix = isStatementLike ? "ans" : "stat"
        
        // Search for the complementary heading
        let pair = headings.first { h in
            guard let t = h.text?.lowercased() else { return false }
            return t.contains(targetPrefix) && t.contains("\(num)")
        }
        
        if let p = pair {
            print("🟦 Pair found: \(heading.text ?? "?") ↔ \(p.text ?? "?")")
        } else {
            print("🟨 No matching pair found for \(heading.text ?? "?")")
        }
        
        return pair
    }
}

