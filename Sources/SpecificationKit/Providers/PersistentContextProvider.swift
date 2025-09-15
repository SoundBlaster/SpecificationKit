//
//  PersistentContextProvider.swift
//  SpecificationKit
//
//  Created by SpecificationKit on 2024.
//

import CoreData
import Foundation

#if canImport(Combine)
    import Combine
#endif

/// A context provider that persists data using Core Data with async/await support
@available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
public final class PersistentContextProvider: ContextProviding, @unchecked Sendable {

    // MARK: - Configuration

    /// Configuration for the persistent context provider
    public struct Configuration {
        /// Name of the Core Data model
        public let modelName: String

        /// Type of persistent store
        public let storeType: StoreType

        /// Migration policy for schema changes
        public let migrationPolicy: MigrationPolicy

        /// Whether to enable encryption for stored data
        public let encryptionEnabled: Bool

        /// Default configuration with recommended settings
        public static let `default` = Configuration(
            modelName: "SpecificationContext",
            storeType: .sqliteStoreType,
            migrationPolicy: .automatic,
            encryptionEnabled: true
        )

        public init(
            modelName: String,
            storeType: StoreType = .sqliteStoreType,
            migrationPolicy: MigrationPolicy = .automatic,
            encryptionEnabled: Bool = true
        ) {
            self.modelName = modelName
            self.storeType = storeType
            self.migrationPolicy = migrationPolicy
            self.encryptionEnabled = encryptionEnabled
        }
    }

    /// Persistent store types supported by the provider
    public enum StoreType {
        case sqliteStoreType
        case inMemoryStoreType
        case binaryStoreType

        var nsStoreType: String {
            switch self {
            case .sqliteStoreType:
                return NSSQLiteStoreType
            case .inMemoryStoreType:
                return NSInMemoryStoreType
            case .binaryStoreType:
                return NSBinaryStoreType
            }
        }
    }

    /// Migration policy for handling schema changes
    public enum MigrationPolicy {
        case automatic
        case manual(MigrationManager)
        case none
    }

    /// Protocol for custom migration managers
    public protocol MigrationManager: AnyObject {
        func performMigration(
            from sourceModel: NSManagedObjectModel,
            to destinationModel: NSManagedObjectModel,
            at storeURL: URL
        ) throws
    }

    /// Errors that can occur during persistence operations
    public enum PersistenceError: Error, LocalizedError {
        case modelNotFound(String)
        case storeLoadFailed(Error)
        case saveContextFailed(Error)
        case migrationFailed(Error)
        case serializationFailed(String)
        case deserializationFailed(String)

        public var errorDescription: String? {
            switch self {
            case .modelNotFound(let name):
                return "Core Data model '\(name)' not found"
            case .storeLoadFailed(let error):
                return "Failed to load persistent store: \(error.localizedDescription)"
            case .saveContextFailed(let error):
                return "Failed to save context: \(error.localizedDescription)"
            case .migrationFailed(let error):
                return "Migration failed: \(error.localizedDescription)"
            case .serializationFailed(let message):
                return "Serialization failed: \(message)"
            case .deserializationFailed(let message):
                return "Deserialization failed: \(message)"
            }
        }
    }

    // MARK: - Properties

    private let configuration: Configuration
    private let serialQueue: DispatchQueue

    #if canImport(Combine)
        private let changeSubject = PassthroughSubject<Void, Never>()
        private let changeStreamContinuation: AsyncStream<Void>.Continuation
        private let changeStream: AsyncStream<Void>
    #endif

    /// Lazy-loaded persistent container
    private lazy var persistentContainer: NSPersistentContainer = {
        // Create an in-memory model for testing
        if configuration.storeType == .inMemoryStoreType {
            let model = createInMemoryModel()
            let container = NSPersistentContainer(
                name: configuration.modelName, managedObjectModel: model)

            // Configure store description for in-memory
            let storeDescription = container.persistentStoreDescriptions.first!
            storeDescription.type = NSInMemoryStoreType

            var loadError: Error?
            container.loadPersistentStores { _, error in
                loadError = error
            }

            if let error = loadError {
                fatalError("Failed to load in-memory store: \(error)")
            }

            container.viewContext.automaticallyMergesChangesFromParent = true
            container.viewContext.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy

            return container
        }

        // Try to find the model in different bundle locations for file-based stores
        let bundles = [Bundle.module, Bundle.main, Bundle(for: type(of: self))]
        var modelURL: URL?

        for bundle in bundles {
            modelURL =
                bundle.url(forResource: configuration.modelName, withExtension: "momd")
                ?? bundle.url(forResource: configuration.modelName, withExtension: "xcdatamodeld")
            if modelURL != nil { break }
        }

        guard let foundModelURL = modelURL else {
            fatalError("Could not find Core Data model '\(configuration.modelName)' in any bundle")
        }

        guard let model = NSManagedObjectModel(contentsOf: foundModelURL) else {
            fatalError("Could not load Core Data model from '\(foundModelURL)'")
        }

        let container = NSPersistentContainer(
            name: configuration.modelName, managedObjectModel: model)

        // Configure store description
        let storeDescription = container.persistentStoreDescriptions.first!
        storeDescription.type = configuration.storeType.nsStoreType

        // Setup migration
        setupMigration(for: storeDescription)

        // Setup encryption if enabled
        if configuration.encryptionEnabled {
            setupEncryption(for: storeDescription)
        }

        var loadError: Error?
        container.loadPersistentStores { _, error in
            loadError = error
        }

        if let error = loadError {
            fatalError("Failed to load persistent store: \(error)")
        }

        // Configure context
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy

        return container
    }()

    // MARK: - Initialization

    public init(configuration: Configuration = .default) {
        self.configuration = configuration
        self.serialQueue = DispatchQueue(label: "persistent-context-provider", qos: .utility)

        #if canImport(Combine)
            let (stream, continuation) = AsyncStream.makeStream(of: Void.self)
            self.changeStream = stream
            self.changeStreamContinuation = continuation
        #endif

        setupChangeNotifications()
    }

    deinit {
        #if canImport(Combine)
            changeStreamContinuation.finish()
        #endif
    }

    // MARK: - ContextProviding

    public func currentContext() -> EvaluationContext {
        // Return a basic context for synchronous access
        return EvaluationContext()
    }

    public func currentContextAsync() async throws -> EvaluationContext {
        return try await withCheckedThrowingContinuation { continuation in
            serialQueue.async {
                do {
                    let context = try self.loadPersistedContext()
                    continuation.resume(returning: context)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    // MARK: - Data Management Methods

    /// Sets a value for the given key with optional expiration
    public func setValue(_ value: Any, for key: String, expirationDate: Date? = nil) async {
        await performAsyncOperation {
            try self.storeValue(
                value, for: key, category: .userData, expirationDate: expirationDate)
        }
    }

    /// Sets a counter value for the given key
    public func setCounter(_ value: Int, for key: String, expirationDate: Date? = nil) async {
        await performAsyncOperation {
            try self.storeValue(value, for: key, category: .counter, expirationDate: expirationDate)
        }
    }

    /// Increments a counter by the specified amount
    public func incrementCounter(for key: String, by amount: Int = 1) async {
        await performAsyncOperation {
            let currentValue = try self.getValue(for: key, category: .counter) as? Int ?? 0
            let newValue = currentValue + amount
            try self.storeValue(newValue, for: key, category: .counter, expirationDate: nil)
        }
    }

    /// Sets a flag value for the given key
    public func setFlag(_ value: Bool, for key: String, expirationDate: Date? = nil) async {
        await performAsyncOperation {
            try self.storeValue(value, for: key, category: .flag, expirationDate: expirationDate)
        }
    }

    /// Sets an event timestamp for the given key
    public func setEvent(_ date: Date, for key: String, expirationDate: Date? = nil) async {
        await performAsyncOperation {
            try self.storeValue(date, for: key, category: .event, expirationDate: expirationDate)
        }
    }

    /// Adds a segment to the user's segments
    public func addSegment(_ segment: String) async {
        await performAsyncOperation {
            try self.storeValue(true, for: segment, category: .segment, expirationDate: nil)
        }
    }

    /// Removes a segment from the user's segments
    public func removeSegment(_ segment: String) async {
        await performAsyncOperation {
            try self.removeValue(for: segment, category: .segment)
        }
    }

    /// Clears all stored data
    public func clearAllData() async {
        await performAsyncOperation {
            try self.clearAllStoredData()
        }
    }

    /// Removes expired data from the store
    public func removeExpiredData() async {
        await performAsyncOperation {
            try self.removeExpiredValues()
        }
    }

    // MARK: - Private Implementation

    private func createInMemoryModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        // Create ContextValue entity
        let entity = NSEntityDescription()
        entity.name = "ContextValue"
        entity.managedObjectClassName = "SpecificationKit.ContextValue"

        // Create attributes
        let keyAttribute = NSAttributeDescription()
        keyAttribute.name = "key"
        keyAttribute.attributeType = .stringAttributeType
        keyAttribute.isOptional = false

        let valueDataAttribute = NSAttributeDescription()
        valueDataAttribute.name = "valueData"
        valueDataAttribute.attributeType = .binaryDataAttributeType
        valueDataAttribute.isOptional = false

        let valueTypeAttribute = NSAttributeDescription()
        valueTypeAttribute.name = "valueType"
        valueTypeAttribute.attributeType = .stringAttributeType
        valueTypeAttribute.isOptional = false

        let categoryAttribute = NSAttributeDescription()
        categoryAttribute.name = "category"
        categoryAttribute.attributeType = .stringAttributeType
        categoryAttribute.isOptional = false

        let timestampAttribute = NSAttributeDescription()
        timestampAttribute.name = "timestamp"
        timestampAttribute.attributeType = .dateAttributeType
        timestampAttribute.isOptional = false

        let expirationDateAttribute = NSAttributeDescription()
        expirationDateAttribute.name = "expirationDate"
        expirationDateAttribute.attributeType = .dateAttributeType
        expirationDateAttribute.isOptional = true

        let versionAttribute = NSAttributeDescription()
        versionAttribute.name = "version"
        versionAttribute.attributeType = .integer32AttributeType
        versionAttribute.isOptional = false
        versionAttribute.defaultValue = 1

        entity.properties = [
            keyAttribute, valueDataAttribute, valueTypeAttribute, categoryAttribute,
            timestampAttribute, expirationDateAttribute, versionAttribute,
        ]

        model.entities = [entity]
        return model
    }

    private func setupMigration(for storeDescription: NSPersistentStoreDescription) {
        switch configuration.migrationPolicy {
        case .automatic:
            storeDescription.shouldMigrateStoreAutomatically = true
            storeDescription.shouldInferMappingModelAutomatically = true
        case .manual:
            storeDescription.shouldMigrateStoreAutomatically = false
            storeDescription.shouldInferMappingModelAutomatically = false
        case .none:
            storeDescription.shouldMigrateStoreAutomatically = false
            storeDescription.shouldInferMappingModelAutomatically = false
        }
    }

    private func setupEncryption(for storeDescription: NSPersistentStoreDescription) {
        // Enable file protection for enhanced security on supported platforms
        #if os(iOS) || os(watchOS) || os(tvOS)
            storeDescription.setOption(
                FileProtectionType.complete as NSObject, forKey: "NSFileProtectionKey")
        #endif
    }

    private func setupChangeNotifications() {
        NotificationCenter.default.addObserver(
            forName: .NSManagedObjectContextDidSave,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self,
                let context = notification.object as? NSManagedObjectContext,
                context.persistentStoreCoordinator
                    == self.persistentContainer.persistentStoreCoordinator
            else {
                return
            }

            // Merge changes to view context
            self.persistentContainer.viewContext.mergeChanges(fromContextDidSave: notification)

            // Notify observers
            #if canImport(Combine)
                self.changeSubject.send()
                self.changeStreamContinuation.yield()
            #endif
        }
    }

    private func loadPersistedContext() throws -> EvaluationContext {
        let context = persistentContainer.newBackgroundContext()

        return try context.performAndWait {
            let userData = try self.loadCategory(.userData, in: context)
            let counters = try self.loadCounters(in: context)
            let flags = try self.loadFlags(in: context)
            let events = try self.loadEvents(in: context)
            let segments = try self.loadSegments(in: context)

            return EvaluationContext(
                userData: userData,
                counters: counters,
                events: events,
                flags: flags,
                segments: segments
            )
        }
    }

    private func loadCategory(_ category: ContextValue.Category, in context: NSManagedObjectContext)
        throws -> [String: Any]
    {
        let request = ContextValue.fetchRequest(category: category)
        let results = try context.fetch(request)

        var values: [String: Any] = [:]
        for contextValue in results {
            if let value = try? deserializeValue(
                contextValue.valueData, type: contextValue.valueType)
            {
                values[contextValue.key] = value
            }
        }

        return values
    }

    private func loadCounters(in context: NSManagedObjectContext) throws -> [String: Int] {
        let request = ContextValue.fetchRequest(category: .counter)
        let results = try context.fetch(request)

        var counters: [String: Int] = [:]
        for contextValue in results {
            if let value = try? deserializeValue(
                contextValue.valueData, type: contextValue.valueType) as? Int
            {
                counters[contextValue.key] = value
            }
        }

        return counters
    }

    private func loadFlags(in context: NSManagedObjectContext) throws -> [String: Bool] {
        let request = ContextValue.fetchRequest(category: .flag)
        let results = try context.fetch(request)

        var flags: [String: Bool] = [:]
        for contextValue in results {
            if let value = try? deserializeValue(
                contextValue.valueData, type: contextValue.valueType) as? Bool
            {
                flags[contextValue.key] = value
            }
        }

        return flags
    }

    private func loadEvents(in context: NSManagedObjectContext) throws -> [String: Date] {
        let request = ContextValue.fetchRequest(category: .event)
        let results = try context.fetch(request)

        var events: [String: Date] = [:]
        for contextValue in results {
            if let value = try? deserializeValue(
                contextValue.valueData, type: contextValue.valueType) as? Date
            {
                events[contextValue.key] = value
            }
        }

        return events
    }

    private func loadSegments(in context: NSManagedObjectContext) throws -> Set<String> {
        let request = ContextValue.fetchRequest(category: .segment)
        let results = try context.fetch(request)

        return Set(results.map { $0.key })
    }

    private func storeValue(
        _ value: Any, for key: String, category: ContextValue.Category, expirationDate: Date?
    ) throws {
        let context = persistentContainer.newBackgroundContext()

        try context.performAndWait {
            // Remove existing value
            let deleteRequest = ContextValue.fetchRequest(
                key: key, category: category, includeExpired: true)
            let existingValues = try context.fetch(deleteRequest)
            existingValues.forEach(context.delete)

            // Create new value
            let contextValue = ContextValue(context: context)
            contextValue.key = key
            contextValue.valueData = try self.serializeValue(value)
            contextValue.valueType = String(describing: type(of: value))
            contextValue.category = category.rawValue
            contextValue.timestamp = Date()
            contextValue.expirationDate = expirationDate
            contextValue.version = 1

            try context.save()
        }
    }

    private func getValue(for key: String, category: ContextValue.Category) throws -> Any? {
        let context = persistentContainer.newBackgroundContext()

        return try context.performAndWait {
            let request = ContextValue.fetchRequest(key: key, category: category)
            let results = try context.fetch(request)

            guard let contextValue = results.first else { return nil }
            return try self.deserializeValue(contextValue.valueData, type: contextValue.valueType)
        }
    }

    private func removeValue(for key: String, category: ContextValue.Category) throws {
        let context = persistentContainer.newBackgroundContext()

        try context.performAndWait {
            let request = ContextValue.fetchRequest(
                key: key, category: category, includeExpired: true)
            let results = try context.fetch(request)
            results.forEach(context.delete)
            try context.save()
        }
    }

    private func clearAllStoredData() throws {
        let context = persistentContainer.newBackgroundContext()

        try context.performAndWait {
            let request = ContextValue.fetchRequest()
            let results = try context.fetch(request)
            results.forEach(context.delete)
            try context.save()
        }
    }

    private func removeExpiredValues() throws {
        let context = persistentContainer.newBackgroundContext()

        try context.performAndWait {
            let request = ContextValue.expiredValuesFetchRequest()
            let results = try context.fetch(request)
            results.forEach(context.delete)
            try context.save()
        }
    }

    private func serializeValue(_ value: Any) throws -> Data {
        do {
            return try NSKeyedArchiver.archivedData(
                withRootObject: value, requiringSecureCoding: false)
        } catch {
            throw PersistenceError.serializationFailed(error.localizedDescription)
        }
    }

    private func deserializeValue(_ data: Data, type: String) throws -> Any {
        do {
            // Use the modern secure unarchiving API
            let allowedClasses: [AnyClass] = [
                NSString.self, NSNumber.self, NSDate.self, NSData.self,
                NSArray.self, NSDictionary.self, NSSet.self, NSNull.self,
            ]
            let unarchiver = try NSKeyedUnarchiver(forReadingFrom: data)
            unarchiver.requiresSecureCoding = false
            let result = try unarchiver.decodeTopLevelObject(
                of: allowedClasses,
                forKey: NSKeyedArchiveRootObjectKey
            )
            unarchiver.finishDecoding()
            return result ?? NSNull()
        } catch {
            throw PersistenceError.deserializationFailed(error.localizedDescription)
        }
    }

    private func performAsyncOperation(_ operation: @escaping () throws -> Void) async {
        await withCheckedContinuation { continuation in
            serialQueue.async {
                do {
                    try operation()
                    continuation.resume()
                } catch {
                    // Log error but don't crash - operations should be resilient
                    print("PersistentContextProvider error: \(error)")
                    continuation.resume()
                }
            }
        }
    }
}

// MARK: - ContextUpdatesProviding

#if canImport(Combine)
    @available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
    extension PersistentContextProvider: ContextUpdatesProviding {

        public var contextUpdates: AnyPublisher<Void, Never> {
            changeSubject.eraseToAnyPublisher()
        }

        public var contextStream: AsyncStream<Void> {
            changeStream
        }
    }
#endif
