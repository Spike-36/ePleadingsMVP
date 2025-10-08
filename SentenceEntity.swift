//
//  SentenceEntity.swift
//  ePleadingsMVP
//
//  Created by Peter Milligan on 28/09/2025.
//  Updated 08/10/2025: added multi-rect support (rectsData + rects)
//

import Foundation
import CoreData
import CoreGraphics

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

    // 🟨 Bounding box coordinates (Phase 6.2)
    @NSManaged public var mappedX: Double
    @NSManaged public var mappedY: Double
    @NSManaged public var mappedWidth: Double
    @NSManaged public var mappedHeight: Double

    // 🟩 Tagging state (Phase 6.4)
    @NSManaged public var state: String?

    // 🟦 Phase 6.6: multiple rect support
    @NSManaged public var rectsData: Data?

    /// Convenience computed property for decoded rects
    var rects: [CGRect] {
        get {
            guard let data = rectsData else { return [] }
            return (try? NSKeyedUnarchiver
                .unarchivedArrayOfObjects(ofClass: NSValue.self, from: data))?
                .map { $0.rectValue } ?? []
        }
        set {
            let nsValues = newValue.map { NSValue(rect: $0) }
            rectsData = try? NSKeyedArchiver
                .archivedData(withRootObject: nsValues, requiringSecureCoding: false)
        }
    }

    // MARK: - Relationships
    /// Parent heading (inverse of HeadingEntity.sentences)
    @NSManaged public var heading: HeadingEntity?

    /// Parent document (inverse of DocumentEntity.sentences)
    @NSManaged public var document: DocumentEntity?
}

// MARK: - Identifiable
extension SentenceEntity: Identifiable {}

// MARK: - Convenience Enum
extension SentenceEntity {
    enum SentenceState: String {
        case admitted = "Admitted"
        case denied = "Denied"
        case notKnown = "Not Known"
        case unclassified = "Unclassified"
    }

    var sentenceState: SentenceState {
        get { SentenceState(rawValue: state ?? "") ?? .unclassified }
        set { state = newValue.rawValue }
    }
}

