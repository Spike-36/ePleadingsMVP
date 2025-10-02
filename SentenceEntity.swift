//
//  SentenceEntity.swift
//  ePleadingsMVP
//
//  Created by Peter Milligan on 28/09/2025.
//

import Foundation
import CoreData

@objc(SentenceEntity)
public class SentenceEntity: NSManagedObject {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SentenceEntity> {
        return NSFetchRequest<SentenceEntity>(entityName: "SentenceEntity")
    }

    // MARK: - Attributes
    @NSManaged public var id: UUID                // Consistent with other entities
    @NSManaged public var pageNumber: Int32
    @NSManaged public var sourceFilename: String?
    @NSManaged public var text: String

    // MARK: - Relationships
    /// Parent heading (inverse of HeadingEntity.sentences)
    @NSManaged public var heading: HeadingEntity?
}

// MARK: - Identifiable
extension SentenceEntity: Identifiable {}

