import Foundation
import CoreData

struct HeadingFetchService {
    static func fetchRequest(for document: DocumentEntity) -> NSFetchRequest<HeadingEntity> {
        let request = HeadingEntity.fetchRequest()
        request.predicate = NSPredicate(format: "document == %@", document)
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \HeadingEntity.orderIndex, ascending: true),
            NSSortDescriptor(keyPath: \HeadingEntity.pageNumber, ascending: true)
        ]
        return request
    }
}

