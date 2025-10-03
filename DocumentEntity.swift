//
//  DocumentEntity.swift
//  ePleadingsMVP
//
//  Created by Peter Milligan on 02/10/2025.
//

import Foundation
import CoreData

@objc(DocumentEntity)
public class DocumentEntity: NSManagedObject {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<DocumentEntity> {
        return NSFetchRequest<DocumentEntity>(entityName: "DocumentEntity")
    }

    // MARK: - Attributes
    @NSManaged public var id: UUID
    @NSManaged public var filename: String
    @NSManaged public var createdAt: Date
    @NSManaged public var filePath: String?   // 👉 new attribute for storing the copied file path

    // MARK: - Relationships
    /// Parent case for this document (inverse of CaseEntity.documents)
    @NSManaged public var caseEntity: CaseEntity?

    /// All headings that belong to this document (inverse of HeadingEntity.document)
    @NSManaged public var headings: NSSet?

    /// All sentences that belong directly to this document (inverse of SentenceEntity.document)
    @NSManaged public var sentences: NSSet?
}

// MARK: - Generated accessors for headings
extension DocumentEntity {
    @objc(addHeadingsObject:)
    @NSManaged public func addToHeadings(_ value: HeadingEntity)

    @objc(removeHeadingsObject:)
    @NSManaged public func removeFromHeadings(_ value: HeadingEntity)

    @objc(addHeadings:)
    @NSManaged public func addToHeadings(_ values: NSSet)

    @objc(removeHeadings:)
    @NSManaged public func removeFromHeadings(_ values: NSSet)
}

// MARK: - Generated accessors for sentences
extension DocumentEntity {
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
extension DocumentEntity: Identifiable {}

