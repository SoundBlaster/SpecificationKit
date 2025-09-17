//
//  ContextValue.swift
//  SpecificationKit
//
//  Created by SpecificationKit on 2025.
//

import CoreData
import Foundation

/// Core Data entity for storing context values with versioning and expiration support
@objc(ContextValue)
public class ContextValue: NSManagedObject {

    /// The unique key for this context value
    @NSManaged public var key: String

    /// The serialized value data
    @NSManaged public var valueData: Data

    /// The type of the stored value (for deserialization)
    @NSManaged public var valueType: String

    /// The category of the value (userData, counter, flag, event, segment)
    @NSManaged public var category: String

    /// The timestamp when this value was created/updated
    @NSManaged public var timestamp: Date

    /// Optional expiration date for this value
    @NSManaged public var expirationDate: Date?

    /// Version number for this value (for migration and conflict resolution)
    @NSManaged public var version: Int32

    /// Convenience computed property to check if the value has expired
    public var isExpired: Bool {
        guard let expirationDate = expirationDate else { return false }
        return Date() > expirationDate
    }
}

// MARK: - Category Constants

extension ContextValue {
    public enum Category: String, CaseIterable {
        case userData = "userData"
        case counter = "counter"
        case flag = "flag"
        case event = "event"
        case segment = "segment"
    }
}

// MARK: - Fetch Request

extension ContextValue {

    /// Creates a fetch request for ContextValue entities
    /// - Returns: A configured NSFetchRequest for ContextValue
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ContextValue> {
        return NSFetchRequest<ContextValue>(entityName: "ContextValue")
    }

    /// Creates a fetch request for a specific key and category
    /// - Parameters:
    ///   - key: The key to search for
    ///   - category: The category to filter by
    ///   - includeExpired: Whether to include expired values (default: false)
    /// - Returns: A configured NSFetchRequest
    public class func fetchRequest(
        key: String,
        category: Category,
        includeExpired: Bool = false
    ) -> NSFetchRequest<ContextValue> {
        let request = fetchRequest()

        var predicates: [NSPredicate] = [
            NSPredicate(format: "key == %@", key),
            NSPredicate(format: "category == %@", category.rawValue),
        ]

        if !includeExpired {
            predicates.append(
                NSPredicate(
                    format: "expirationDate == nil OR expirationDate > %@", Date() as NSDate)
            )
        }

        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \ContextValue.timestamp, ascending: false)
        ]
        request.fetchLimit = 1

        return request
    }

    /// Creates a fetch request for all values in a specific category
    /// - Parameters:
    ///   - category: The category to filter by
    ///   - includeExpired: Whether to include expired values (default: false)
    /// - Returns: A configured NSFetchRequest
    public class func fetchRequest(
        category: Category,
        includeExpired: Bool = false
    ) -> NSFetchRequest<ContextValue> {
        let request = fetchRequest()

        var predicates: [NSPredicate] = [
            NSPredicate(format: "category == %@", category.rawValue)
        ]

        if !includeExpired {
            predicates.append(
                NSPredicate(
                    format: "expirationDate == nil OR expirationDate > %@", Date() as NSDate)
            )
        }

        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ContextValue.key, ascending: true)]

        return request
    }

    /// Creates a fetch request for expired values
    /// - Returns: A configured NSFetchRequest for expired values
    public class func expiredValuesFetchRequest() -> NSFetchRequest<ContextValue> {
        let request = fetchRequest()
        request.predicate = NSPredicate(
            format: "expirationDate != nil AND expirationDate <= %@",
            Date() as NSDate
        )
        return request
    }
}
