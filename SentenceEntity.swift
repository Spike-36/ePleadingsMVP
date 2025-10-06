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
    @NSManaged public var id: UUID
    @NSManaged public var pageNumber: Int32
    @NSManaged public var sourceFilename: String?
    @NSManaged public var text: String

    // 🟨 Bounding box coordinates (added for Phase 6.2)
    @NSManaged public var mappedX: Double
    @NSManaged public var mappedY: Double
    @NSManaged public var mappedWidth: Double
    @NSManaged public var mappedHeight: Double

    // MARK: - Relationships
    /// Parent heading (inverse of HeadingEntity.sentences)
    @NSManaged public var heading: HeadingEntity?

    /// Parent document (inverse of DocumentEntity.sentences)
    @NSManaged public var document: DocumentEntity?
}

// MARK: - Identifiable
extension SentenceEntity: Identifiable {}

