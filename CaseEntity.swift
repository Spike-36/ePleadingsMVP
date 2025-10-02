//
//  CaseEntity.swift
//  ePleadingsMVP
//
//  Created by Pete on 2025-10-02.
//

import Foundation
import CoreData

@objc(CaseEntity)
public class CaseEntity: NSManagedObject {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CaseEntity> {
        return NSFetchRequest<CaseEntity>(entityName: "CaseEntity")
    }

    // MARK: - Attributes
    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var createdAt: Date

    // MARK: - Relationships
    /// All documents belonging to this case (inverse of DocumentEntity.caseRef)
    @NSManaged public var documents: NSSet?
}

// MARK: - Generated accessors for documents
extension CaseEntity {
    @objc(addDocumentsObject:)
    @NSManaged public func addToDocuments(_ value: DocumentEntity)

    @objc(removeDocumentsObject:)
    @NSManaged public func removeFromDocuments(_ value: DocumentEntity)

    @objc(addDocuments:)
    @NSManaged public func addToDocuments(_ values: NSSet)

    @objc(removeDocuments:)
    @NSManaged public func removeFromDocuments(_ values: NSSet)
}

// MARK: - Identifiable
extension CaseEntity: Identifiable {}

