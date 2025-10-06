//
//  SentenceLookupService.swift
//  ePleadingsMVP
//
//  Created by Peter Milligan on 06/10/2025.
//
// Services/SentenceLookupService.swift

import CoreData
import Foundation
import CoreGraphics

struct SentenceLookupService {
    static func findNearestSentence(page: Int, point: CGPoint, in context: NSManagedObjectContext) -> SentenceEntity? {
        let fetchRequest: NSFetchRequest<SentenceEntity> = SentenceEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "pageNumber == %d", page)

        do {
            let sentences = try context.fetch(fetchRequest)
            guard !sentences.isEmpty else { return nil }

            var closest: SentenceEntity?
            var minDistance: CGFloat = .greatestFiniteMagnitude

            for s in sentences {
                let dx = CGFloat(s.mappedX - Double(point.x))
                let dy = CGFloat(s.mappedY - Double(point.y))
                let distance = sqrt(dx*dx + dy*dy)
                if distance < minDistance {
                    minDistance = distance
                    closest = s
                }
            }

            return closest
        } catch {
            print("❌ Core Data fetch error: \(error)")
            return nil
        }
    }
}

