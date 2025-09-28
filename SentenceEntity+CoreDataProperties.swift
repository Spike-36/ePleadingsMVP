//
//  SentenceEntity+CoreDataProperties.swift
//  ePleadingsMVP
//
//  Created by Peter Milligan on 28/09/2025.
//
//

import Foundation
import CoreData


extension SentenceEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SentenceEntity> {
        return NSFetchRequest<SentenceEntity>(entityName: "SentenceEntity")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var pageNumber: Int32
    @NSManaged public var sourceFilename: String?
    @NSManaged public var text: String?
    @NSManaged public var heading: HeadingEntity?

}

extension SentenceEntity : Identifiable {

}
