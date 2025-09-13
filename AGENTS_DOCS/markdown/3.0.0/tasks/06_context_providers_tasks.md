# Backend/Persistence Specialist Tasks

## Agent Profile
- **Primary Skills**: Network programming, Core Data, caching, concurrency, data persistence
- **Secondary Skills**: URLSession, async/await, thread safety, error handling
- **Complexity Level**: High (4/5)

## Task Overview

### Context Provider Infrastructure Enhancement
**Objective**: Implement NetworkContextProvider, PersistentContextProvider, and CompositeContextProvider
**Priority**: High
**Dependencies**: None for Network/Persistent, Advanced specs depend on Persistent
**Timeline**: 17 days total

---

## 3.3.1: NetworkContextProvider Implementation

### Timeline: 7 days

#### API Design Target
```swift
public final class NetworkContextProvider: ContextProviding {
    public struct Configuration {
        let endpoint: URL
        let refreshInterval: TimeInterval
        let cachePolicy: CachePolicy
        let fallbackValues: [String: Any]
        let requestTimeout: TimeInterval
        let retryPolicy: RetryPolicy
        
        public static let `default` = Configuration(
            endpoint: URL(string: "https://api.example.com/context")!,
            refreshInterval: 300, // 5 minutes
            cachePolicy: .returnCacheDataElseLoad,
            fallbackValues: [:],
            requestTimeout: 30,
            retryPolicy: .exponentialBackoff(maxAttempts: 3)
        )
    }
    
    public enum RetryPolicy {
        case none
        case fixedDelay(TimeInterval, maxAttempts: Int)
        case exponentialBackoff(maxAttempts: Int)
        case custom((Int, Error) -> TimeInterval?)
    }
    
    private let configuration: Configuration
    private let session: URLSession
    private let cache: NSCache<NSString, CachedResponse>
    private let queue: DispatchQueue
    
    public init(configuration: Configuration, session: URLSession = .shared) {
        self.configuration = configuration
        self.session = session
        self.cache = NSCache()
        self.queue = DispatchQueue(label: "network-context-provider", qos: .utility)
        
        setupPeriodicRefresh()
    }
}
```

#### Network Layer Implementation
```swift
extension NetworkContextProvider {
    public func getValue(for key: String) async throws -> Any? {
        // Check cache first
        if let cached = getCachedValue(for: key), !cached.isExpired {
            return cached.value
        }
        
        // Fetch from network with retry logic
        do {
            let data = try await fetchWithRetry(key: key)
            let value = try parseResponse(data, for: key)
            cacheValue(value, for: key)
            return value
        } catch {
            // Return fallback value if available
            return configuration.fallbackValues[key]
        }
    }
    
    private func fetchWithRetry(key: String) async throws -> Data {
        var lastError: Error?
        let maxAttempts = getMaxAttempts(for: configuration.retryPolicy)
        
        for attempt in 1...maxAttempts {
            do {
                return try await performNetworkRequest(key: key)
            } catch {
                lastError = error
                
                if attempt < maxAttempts {
                    let delay = getRetryDelay(for: configuration.retryPolicy, attempt: attempt, error: error)
                    if let delay = delay {
                        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    } else {
                        break // No retry policy
                    }
                }
            }
        }
        
        throw lastError ?? NetworkError.maxRetriesExceeded
    }
    
    private func performNetworkRequest(key: String) async throws -> Data {
        var request = URLRequest(url: configuration.endpoint.appendingPathComponent(key))
        request.timeoutInterval = configuration.requestTimeout
        request.cachePolicy = configuration.cachePolicy
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            throw NetworkError.httpError(httpResponse.statusCode)
        }
        
        return data
    }
}
```

#### Caching Strategy
```swift
private struct CachedResponse {
    let value: Any
    let timestamp: Date
    let ttl: TimeInterval
    
    var isExpired: Bool {
        Date().timeIntervalSince(timestamp) > ttl
    }
}

extension NetworkContextProvider {
    private func getCachedValue(for key: String) -> CachedResponse? {
        return cache.object(forKey: NSString(string: key))
    }
    
    private func cacheValue(_ value: Any, for key: String) {
        let cached = CachedResponse(
            value: value,
            timestamp: Date(),
            ttl: configuration.refreshInterval
        )
        cache.setObject(cached, forKey: NSString(string: key))
    }
    
    private func setupPeriodicRefresh() {
        Timer.scheduledTimer(withTimeInterval: configuration.refreshInterval, repeats: true) { _ in
            Task {
                await self.refreshCache()
            }
        }
    }
    
    private func refreshCache() async {
        // Background refresh of cached values
        let keys = getAllCachedKeys()
        await withTaskGroup(of: Void.self) { group in
            for key in keys {
                group.addTask {
                    try? await self.getValue(for: key)
                }
            }
        }
    }
}
```

#### Error Handling & Offline Mode
```swift
public enum NetworkError: Error, LocalizedError {
    case invalidResponse
    case httpError(Int)
    case maxRetriesExceeded
    case networkUnavailable
    case parseError(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid network response"
        case .httpError(let code):
            return "HTTP error \(code)"
        case .maxRetriesExceeded:
            return "Maximum retry attempts exceeded"
        case .networkUnavailable:
            return "Network is unavailable"
        case .parseError(let message):
            return "Parse error: \(message)"
        }
    }
}

extension NetworkContextProvider {
    public func setOfflineMode(_ enabled: Bool) {
        if enabled {
            // Use only cached values and fallbacks
            session.configuration.requestCachePolicy = .returnCacheDataDontLoad
        } else {
            session.configuration.requestCachePolicy = configuration.cachePolicy
        }
    }
    
    public var isOnline: Bool {
        // Check network reachability
        return true // Simplified for example
    }
}
```

---

## 3.3.2: PersistentContextProvider Implementation

### Timeline: 8 days

#### Core Data Integration
```swift
public final class PersistentContextProvider: ContextProviding {
    public struct Configuration {
        let modelName: String
        let storeType: NSPersistentStoreType
        let migrationPolicy: MigrationPolicy
        let encryptionEnabled: Bool
        
        public static let `default` = Configuration(
            modelName: "SpecificationContext",
            storeType: .sqliteStoreType,
            migrationPolicy: .automatic,
            encryptionEnabled: true
        )
    }
    
    public enum MigrationPolicy {
        case automatic
        case manual(MigrationManager)
        case none
    }
    
    private let configuration: Configuration
    private lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: configuration.modelName)
        
        if configuration.encryptionEnabled {
            setupEncryption(for: container)
        }
        
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Failed to load store: \(error)")
            }
        }
        
        return container
    }()
    
    private var changePublisher = PassthroughSubject<String, Never>()
    
    public init(configuration: Configuration = .default) {
        self.configuration = configuration
        setupChangeNotification()
    }
}
```

#### Data Model Design
```swift
// Core Data Entity: ContextValue
@objc(ContextValue)
public class ContextValue: NSManagedObject {
    @NSManaged public var key: String
    @NSManaged public var value: Data
    @NSManaged public var type: String
    @NSManaged public var timestamp: Date
    @NSManaged public var expirationDate: Date?
    @NSManaged public var version: Int32
}

extension PersistentContextProvider {
    public func getValue(for key: String) async -> Any? {
        return await withCheckedContinuation { continuation in
            let context = persistentContainer.newBackgroundContext()
            context.perform {
                let request: NSFetchRequest<ContextValue> = ContextValue.fetchRequest()
                request.predicate = NSPredicate(format: "key == %@ AND (expirationDate == nil OR expirationDate > %@)", 
                                              key, Date())
                request.sortDescriptors = [NSSortDescriptor(keyPath: \ContextValue.timestamp, ascending: false)]
                request.fetchLimit = 1
                
                do {
                    let results = try context.fetch(request)
                    if let contextValue = results.first {
                        let value = try self.deserializeValue(contextValue.value, type: contextValue.type)
                        continuation.resume(returning: value)
                    } else {
                        continuation.resume(returning: nil)
                    }
                } catch {
                    continuation.resume(returning: nil)
                }
            }
        }
    }
    
    public func setValue(_ value: Any, for key: String, expirationDate: Date? = nil) async {
        await withCheckedContinuation { continuation in
            let context = persistentContainer.newBackgroundContext()
            context.perform {
                // Delete existing value
                let deleteRequest: NSFetchRequest<ContextValue> = ContextValue.fetchRequest()
                deleteRequest.predicate = NSPredicate(format: "key == %@", key)
                
                do {
                    let existingValues = try context.fetch(deleteRequest)
                    existingValues.forEach(context.delete)
                    
                    // Create new value
                    let contextValue = ContextValue(context: context)
                    contextValue.key = key
                    contextValue.value = try self.serializeValue(value)
                    contextValue.type = String(describing: type(of: value))
                    contextValue.timestamp = Date()
                    contextValue.expirationDate = expirationDate
                    contextValue.version = 1
                    
                    try context.save()
                    
                    // Notify observers
                    DispatchQueue.main.async {
                        self.changePublisher.send(key)
                    }
                    
                    continuation.resume()
                } catch {
                    continuation.resume()
                }
            }
        }
    }
}
```

#### Schema Migration Support
```swift
extension PersistentContextProvider {
    private func setupMigration() {
        switch configuration.migrationPolicy {
        case .automatic:
            persistentContainer.persistentStoreDescriptions.forEach {
                $0.shouldMigrateStoreAutomatically = true
                $0.shouldInferMappingModelAutomatically = true
            }
        case .manual(let manager):
            // Custom migration logic
            performManualMigration(using: manager)
        case .none:
            break
        }
    }
    
    private func performManualMigration(using manager: MigrationManager) {
        // Implement custom migration logic
    }
}
```

#### Thread Safety & Change Notifications
```swift
extension PersistentContextProvider {
    private func setupChangeNotification() {
        NotificationCenter.default.addObserver(
            forName: .NSManagedObjectContextDidSave,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let context = notification.object as? NSManagedObjectContext,
                  context.persistentStoreCoordinator == self?.persistentContainer.persistentStoreCoordinator else {
                return
            }
            
            self?.persistentContainer.viewContext.mergeChanges(fromContextDidSave: notification)
        }
    }
    
    public var contextChanges: AnyPublisher<String, Never> {
        changePublisher.eraseToAnyPublisher()
    }
}
```

---

## 3.3.3: CompositeContextProvider Implementation

### Timeline: 2 days

#### Provider Composition Strategy
```swift
public final class CompositeContextProvider: ContextProviding {
    public enum FallbackStrategy {
        case firstAvailable    // Use first provider that has the value
        case prioritized([ContextProviding])  // Try providers in order
        case consensus(threshold: Double)     // Require agreement from multiple providers
        case weighted([(ContextProviding, Double)]) // Weighted average/selection
    }
    
    private let providers: [ContextProviding]
    private let strategy: FallbackStrategy
    private let cache: NSCache<NSString, Any>
    
    public init(providers: [ContextProviding], strategy: FallbackStrategy = .firstAvailable) {
        precondition(!providers.isEmpty, "CompositeContextProvider requires at least one provider")
        self.providers = providers
        self.strategy = strategy
        self.cache = NSCache()
    }
    
    public func getValue(for key: String) async -> Any? {
        switch strategy {
        case .firstAvailable:
            return await getFirstAvailableValue(for: key)
        case .prioritized(let orderedProviders):
            return await getPrioritizedValue(for: key, from: orderedProviders)
        case .consensus(let threshold):
            return await getConsensusValue(for: key, threshold: threshold)
        case .weighted(let weightedProviders):
            return await getWeightedValue(for: key, from: weightedProviders)
        }
    }
}
```

#### Advanced Composition Logic
```swift
extension CompositeContextProvider {
    private func getFirstAvailableValue(for key: String) async -> Any? {
        for provider in providers {
            if let value = await provider.getValue(for: key) {
                cache.setObject(value, forKey: NSString(string: key))
                return value
            }
        }
        return nil
    }
    
    private func getPrioritizedValue(for key: String, from orderedProviders: [ContextProviding]) async -> Any? {
        for provider in orderedProviders {
            if let value = await provider.getValue(for: key) {
                return value
            }
        }
        return nil
    }
    
    private func getConsensusValue(for key: String, threshold: Double) async -> Any? {
        let results = await withTaskGroup(of: (ContextProviding, Any?).self) { group in
            for provider in providers {
                group.addTask {
                    return (provider, await provider.getValue(for: key))
                }
            }
            
            var values: [Any?] = []
            for await (_, value) in group {
                values.append(value)
            }
            return values
        }
        
        let nonNilResults = results.compactMap { $0 }
        let agreementRatio = Double(nonNilResults.count) / Double(providers.count)
        
        if agreementRatio >= threshold, let mostCommonValue = findMostCommon(in: nonNilResults) {
            return mostCommonValue
        }
        
        return nil
    }
    
    private func findMostCommon<T: Equatable>(in values: [T]) -> T? {
        guard !values.isEmpty else { return nil }
        
        var counts: [T: Int] = [:]
        for value in values {
            counts[value, default: 0] += 1
        }
        
        return counts.max(by: { $0.value < $1.value })?.key
    }
}
```

---

## Implementation Guidelines

### Performance Requirements
- **Network Provider**: <100ms for cached values, <5s for network requests
- **Persistent Provider**: <10ms for database queries, <100ms for writes  
- **Composite Provider**: <50ms additional overhead for composition logic
- **Thread Safety**: All operations must be thread-safe and non-blocking

### Error Handling Standards
```swift
public enum ContextProviderError: Error, LocalizedError {
    case providerUnavailable(String)
    case dataCorruption(String)
    case networkFailure(URLError)
    case persistenceError(NSError)
    case compositionFailure(String)
    
    public var errorDescription: String? {
        // Comprehensive error descriptions
    }
}
```

### Testing Strategy
```swift
class ContextProviderTests: XCTestCase {
    func testNetworkProviderCaching() {
        // Test caching behavior and TTL
    }
    
    func testPersistentProviderMigration() {
        // Test database schema migration
    }
    
    func testCompositeProviderFallback() {
        // Test fallback strategy execution
    }
    
    func testConcurrentAccess() {
        // Test thread safety under concurrent load
    }
}
```

## Dependencies & Coordination

### External Dependencies
- Foundation for networking and persistence
- Core Data for database management
- Combine for reactive updates
- CryptoKit for data encryption (optional)

### Coordination Points
- **Advanced Specs Team**: Historical data requirements for HistoricalSpec
- **Performance Team**: Caching and query optimization
- **Testing Team**: Integration test infrastructure
- **Platform Team**: Platform-specific storage locations

## Success Metrics
- **Reliability**: 99.9% uptime for context value retrieval
- **Performance**: Meet all latency requirements under load
- **Data Integrity**: Zero data corruption incidents
- **Thread Safety**: Pass all concurrency stress tests