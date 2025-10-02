//
//  HeadingEntity.swift
//  ePleadingsMVP
//
//  Created by Peter Milligan on 28/09/2025.
//

import Foundation
import CoreData

@objc(HeadingEntity)
public class HeadingEntity: NSManagedObject {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<HeadingEntity> {
        return NSFetchRequest<HeadingEntity>(entityName: "HeadingEntity")
    }

    // MARK: - Attributes
    @NSManaged public var id: UUID
    @NSManaged public var text: String?
    @NSManaged public var level: Int16
    @NSManaged public var pageNumber: Int32
    @NSManaged public var sourceFilename: String?

    // MARK: - Mapped PDF positioning
    @NSManaged public var mappedPageNumber: Int32
    @NSManaged public var mappedX: Double
    @NSManaged public var mappedY: Double
    @NSManaged public var mappedWidth: Double
    @NSManaged public var mappedHeight: Double

    // MARK: - Relationships
    /// Parent document (inverse of DocumentEntity.headings)
    @NSManaged public var document: DocumentEntity?

    /// Sentences under this heading (inverse of SentenceEntity.heading)
    @NSManaged public var sentences: NSSet?
}

// MARK: - Generated accessors for sentences
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

// MARK: - Identifiable
extension HeadingEntity: Identifiable {}

