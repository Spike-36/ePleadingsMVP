//
//  HeadingEntity+CoreDataProperties.swift
//  ePleadingsMVP
//
//  Created by Peter Milligan on 28/09/2025.
//
//

import Foundation
import CoreData


extension HeadingEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<HeadingEntity> {
        return NSFetchRequest<HeadingEntity>(entityName: "HeadingEntity")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var text: String?
    @NSManaged public var level: Int16
    @NSManaged public var pageNumber: Int32
    @NSManaged public var sourceFilename: String?
    @NSManaged public var sentences: NSSet?

}

// MARK: Generated accessors for sentences
extension HeadingEntity {

    @objc(addSentencesObject:)
    @NSManaged public func addToSentences(_ value: SentenceEntity)

    @objc(removeSentencesObject:)
    @NSManaged public func removeFromSentences(_ value: SentenceEntity)

    @objc(addSentences:)
    @NSManaged public func addToSentences(_ values: NSSet)

    @objc(removeSentences:)
    @NSManaged public func removeFromSentences(_ values: NSSet)

}

extension HeadingEntity : Identifiable {

}
