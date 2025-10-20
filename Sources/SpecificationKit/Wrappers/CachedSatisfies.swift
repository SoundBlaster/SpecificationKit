//
//  CachedSatisfies.swift
//  SpecificationKit
//
//  Created by SpecificationKit on 2025.
//

import Foundation

#if canImport(SwiftUI)
    import SwiftUI
#endif

/// A property wrapper that caches specification evaluation results with configurable TTL.
///
/// `@CachedSatisfies` evaluates specifications lazily and caches results for a specified time-to-live (TTL).
/// This is particularly useful for expensive specifications that involve network calls, complex computations,
/// or database queries. The cache automatically expires after the TTL and handles memory pressure gracefully.
///
/// ## Usage
///
/// ```swift
/// @CachedSatisfies(using: ExpensiveAnalyticsSpec(), ttl: 300)
/// var analyticsEnabled: Bool
///
/// @CachedSatisfies(using: NetworkDependentSpec(), ttl: 60, provider: networkProvider)
/// var isNetworkFeatureAvailable: Bool
/// ```
///
/// ## Thread Safety
///
/// The implementation is thread-safe using internal locking mechanisms.
/// Multiple concurrent accesses will be properly synchronized.
///
/// ## Memory Management
///
/// The cache automatically handles memory pressure by clearing expired entries
/// and responding to system memory warnings on supported platforms.
@propertyWrapper
public struct CachedSatisfies<Context> {

    // MARK: - Properties

    private let contextFactory: () -> Context
    private let asyncContextFactory: (() async throws -> Context)?
    private let specification: AnySpecification<Context>
    private let ttl: TimeInterval
    private let cacheKey: String

    // MARK: - Property Wrapper Interface

    /// The wrapped value representing whether the specification is satisfied.
    /// Results are cached for the specified TTL duration.
    public var wrappedValue: Bool {
        // Check cache first
        if let cachedResult = GlobalCacheManager.shared.getValue(for: cacheKey) {
            return cachedResult
        }

        // Evaluate and cache result
        let context = contextFactory()
        let result = specification.isSatisfiedBy(context)
        GlobalCacheManager.shared.setValue(result, for: cacheKey, ttl: ttl)

        return result
    }

    // MARK: - Initializers

    /// Creates a CachedSatisfies property wrapper with a context provider and specification.
    /// - Parameters:
    ///   - provider: The context provider to use for evaluation
    ///   - specification: The specification to evaluate and cache
    ///   - ttl: Time-to-live for cached results in seconds (default: 60 seconds)
    ///   - cacheKey: Optional custom cache key (default: auto-generated)
    public init<Provider: ContextProviding, Spec: Specification>(
        provider: Provider,
        using specification: Spec,
        ttl: TimeInterval = 60.0,
        cacheKey: String? = nil
    ) where Provider.Context == Context, Spec.T == Context {
        self.contextFactory = provider.currentContext
        self.asyncContextFactory = provider.currentContextAsync
        self.specification = AnySpecification(specification)
        self.ttl = ttl
        self.cacheKey =
            cacheKey ?? "\(String(describing: Spec.self))_\(UUID().uuidString.prefix(8))"

        GlobalCacheManager.shared.setupMemoryPressureHandling()
    }

    /// Creates a CachedSatisfies property wrapper with a predicate function.
    /// - Parameters:
    ///   - provider: The context provider to use for evaluation
    ///   - predicate: A predicate function that takes the context and returns a Bool
    ///   - ttl: Time-to-live for cached results in seconds (default: 60 seconds)
    ///   - cacheKey: Optional custom cache key (default: auto-generated)
    public init<Provider: ContextProviding>(
        provider: Provider,
        predicate: @escaping (Context) -> Bool,
        ttl: TimeInterval = 60.0,
        cacheKey: String? = nil
    ) where Provider.Context == Context {
        self.contextFactory = provider.currentContext
        self.asyncContextFactory = provider.currentContextAsync
        self.specification = AnySpecification(predicate)
        self.ttl = ttl
        self.cacheKey = cacheKey ?? "predicate_\(UUID().uuidString.prefix(8))"

        GlobalCacheManager.shared.setupMemoryPressureHandling()
    }

    // MARK: - Projected Value & Advanced Features

    /// Projected value providing access to cache management and async evaluation
    public var projectedValue: CachedSatisfiesProjection<Context> {
        CachedSatisfiesProjection(
            cacheKey: cacheKey,
            contextFactory: contextFactory,
            asyncContextFactory: asyncContextFactory,
            specification: specification,
            ttl: ttl
        )
    }

    // MARK: - Cache Management

    /// Manually invalidate the cache for this specification
    public func invalidateCache() {
        GlobalCacheManager.shared.invalidate(key: cacheKey)
    }

    /// Get cache statistics for this specification
    public func getCacheStats() -> (isCached: Bool, accessCount: Int) {
        let accessCount = GlobalCacheManager.shared.getAccessCount(for: cacheKey)
        return (isCached: accessCount > 0, accessCount: accessCount)
    }
}

// MARK: - Projected Value Implementation

/// Projected value for CachedSatisfies providing advanced cache management features
public struct CachedSatisfiesProjection<Context> {
    private let cacheKey: String
    private let contextFactory: () -> Context
    private let asyncContextFactory: (() async throws -> Context)?
    private let specification: AnySpecification<Context>
    private let ttl: TimeInterval

    internal init(
        cacheKey: String,
        contextFactory: @escaping () -> Context,
        asyncContextFactory: (() async throws -> Context)?,
        specification: AnySpecification<Context>,
        ttl: TimeInterval
    ) {
        self.cacheKey = cacheKey
        self.contextFactory = contextFactory
        self.asyncContextFactory = asyncContextFactory
        self.specification = specification
        self.ttl = ttl
    }

    /// Async evaluation that respects caching
    public func evaluateAsync() async throws -> Bool {
        // Check cache first
        if let cachedResult = GlobalCacheManager.shared.getValue(for: cacheKey) {
            return cachedResult
        }

        // Use async context if available
        let context: Context
        if let asyncFactory = asyncContextFactory {
            context = try await asyncFactory()
        } else {
            context = contextFactory()
        }

        let result = specification.isSatisfiedBy(context)
        GlobalCacheManager.shared.setValue(result, for: cacheKey, ttl: ttl)
        return result
    }

    /// Force re-evaluation, bypassing cache
    public func forceEvaluate() -> Bool {
        GlobalCacheManager.shared.invalidate(key: cacheKey)
        let context = contextFactory()
        let result = specification.isSatisfiedBy(context)
        GlobalCacheManager.shared.setValue(result, for: cacheKey, ttl: ttl)
        return result
    }

    /// Check if result is currently cached
    public func isCached() -> Bool {
        let stats = GlobalCacheManager.shared.getAccessCount(for: cacheKey)
        return stats > 0
    }

    /// Manually invalidate the cache
    public func invalidate() {
        GlobalCacheManager.shared.invalidate(key: cacheKey)
    }

    /// Get access statistics
    public func getAccessCount() -> Int {
        return GlobalCacheManager.shared.getAccessCount(for: cacheKey)
    }
}

// MARK: - EvaluationContext Convenience

extension CachedSatisfies where Context == EvaluationContext {

    /// Creates a CachedSatisfies property wrapper using the shared default context provider.
    /// - Parameters:
    ///   - specification: The specification to evaluate and cache
    ///   - ttl: Time-to-live for cached results in seconds (default: 60 seconds)
    ///   - cacheKey: Optional custom cache key
    public init<Spec: Specification>(
        using specification: Spec,
        ttl: TimeInterval = 60.0,
        cacheKey: String? = nil
    ) where Spec.T == EvaluationContext {
        self.init(
            provider: DefaultContextProvider.shared,
            using: specification,
            ttl: ttl,
            cacheKey: cacheKey
        )
    }

    /// Creates a CachedSatisfies property wrapper with a predicate using the shared default context provider.
    /// - Parameters:
    ///   - predicate: A predicate function that takes EvaluationContext and returns Bool
    ///   - ttl: Time-to-live for cached results in seconds (default: 60 seconds)
    ///   - cacheKey: Optional custom cache key
    public init(
        predicate: @escaping (EvaluationContext) -> Bool,
        ttl: TimeInterval = 60.0,
        cacheKey: String? = nil
    ) {
        self.init(
            provider: DefaultContextProvider.shared,
            predicate: predicate,
            ttl: ttl,
            cacheKey: cacheKey
        )
    }

    /// Creates a cached specification for time-based conditions.
    /// - Parameters:
    ///   - minimumSeconds: Minimum seconds since launch
    ///   - ttl: Time-to-live for cached results in seconds (default: 60 seconds)
    /// - Returns: A CachedSatisfies wrapper for launch time checking
    public static func timeSinceLaunch(
        minimumSeconds: TimeInterval,
        ttl: TimeInterval = 60.0
    ) -> CachedSatisfies<EvaluationContext> {
        CachedSatisfies(
            predicate: { context in
                context.timeSinceLaunch >= minimumSeconds
            },
            ttl: ttl,
            cacheKey: "timeSinceLaunch_\(minimumSeconds)"
        )
    }

    /// Creates a cached specification for counter-based conditions.
    /// - Parameters:
    ///   - counterKey: The counter key to check
    ///   - maximum: The maximum allowed value (exclusive)
    ///   - ttl: Time-to-live for cached results in seconds (default: 60 seconds)
    /// - Returns: A CachedSatisfies wrapper for counter checking
    public static func counter(
        _ counterKey: String,
        lessThan maximum: Int,
        ttl: TimeInterval = 60.0
    ) -> CachedSatisfies<EvaluationContext> {
        CachedSatisfies(
            predicate: { context in
                context.counter(for: counterKey) < maximum
            },
            ttl: ttl,
            cacheKey: "counter_\(counterKey)_\(maximum)"
        )
    }

    /// Creates a cached specification for flag-based conditions.
    /// - Parameters:
    ///   - flagKey: The flag key to check
    ///   - expectedValue: The expected flag value
    ///   - ttl: Time-to-live for cached results in seconds (default: 60 seconds)
    /// - Returns: A CachedSatisfies wrapper for flag checking
    public static func flag(
        _ flagKey: String,
        equals expectedValue: Bool = true,
        ttl: TimeInterval = 60.0
    ) -> CachedSatisfies<EvaluationContext> {
        CachedSatisfies(
            predicate: { context in
                context.flag(for: flagKey) == expectedValue
            },
            ttl: ttl,
            cacheKey: "flag_\(flagKey)_\(expectedValue)"
        )
    }
}

// MARK: - Global Cache Management

/// Thread-safe global cache manager singleton
final class GlobalCacheManager: @unchecked Sendable {
    static let shared = GlobalCacheManager()

    private var cache: [String: CachedValue] = [:]
    private var accessCount: [String: Int] = [:]
    private let lock = NSLock()
    private var memoryPressureSetup = false

    private init() {}

    /// A cached value with timestamp and TTL information
    private struct CachedValue {
        let value: Bool
        let timestamp: Date
        let ttl: TimeInterval

        var isExpired: Bool {
            Date().timeIntervalSince(timestamp) > ttl
        }
    }

    func getValue(for key: String) -> Bool? {
        lock.lock()
        defer { lock.unlock() }

        if let cached = cache[key] {
            if !cached.isExpired && cached.ttl > 0 {
                accessCount[key, default: 0] += 1
                return cached.value
            } else {
                // Remove expired value or zero TTL value
                cache.removeValue(forKey: key)
                accessCount.removeValue(forKey: key)
            }
        }
        return nil
    }

    func setValue(_ value: Bool, for key: String, ttl: TimeInterval) {
        lock.lock()
        defer { lock.unlock() }

        cache[key] = CachedValue(value: value, timestamp: Date(), ttl: ttl)
        accessCount[key] = (accessCount[key] ?? 0) + 1
    }

    func invalidate(key: String) {
        lock.lock()
        defer { lock.unlock() }

        cache.removeValue(forKey: key)
        accessCount.removeValue(forKey: key)
    }

    func clearExpired() {
        lock.lock()
        defer { lock.unlock() }

        let now = Date()
        let expiredKeys = cache.compactMap { (key, value) in
            value.timestamp.addingTimeInterval(value.ttl) < now ? key : nil
        }

        for key in expiredKeys {
            cache.removeValue(forKey: key)
            accessCount.removeValue(forKey: key)
        }
    }

    func clearAll() {
        lock.lock()
        defer { lock.unlock() }

        cache.removeAll()
        accessCount.removeAll()
    }

    func getCacheStats() -> (totalSize: Int, totalAccesses: Int) {
        lock.lock()
        defer { lock.unlock() }

        let size = cache.count
        let totalAccesses = accessCount.values.reduce(0, +)
        return (totalSize: size, totalAccesses: totalAccesses)
    }

    func getAccessCount(for key: String) -> Int {
        lock.lock()
        defer { lock.unlock() }

        return accessCount[key] ?? 0
    }

    func setupMemoryPressureHandling() {
        lock.lock()
        defer { lock.unlock() }

        guard !memoryPressureSetup else { return }
        memoryPressureSetup = true

        #if os(iOS) || os(tvOS)
            NotificationCenter.default.addObserver(
                forName: UIApplication.didReceiveMemoryWarningNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.clearExpired()
            }

            // Also handle app state changes
            NotificationCenter.default.addObserver(
                forName: UIApplication.didEnterBackgroundNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.clearExpired()
            }
        #endif

        // Set up periodic cache cleanup every 5 minutes
        Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            self?.clearExpired()
        }
    }
}

// MARK: - Global Cache Extensions

extension CachedSatisfies {

    /// Clear all cached values across all CachedSatisfies instances
    public static func clearAllCaches() {
        GlobalCacheManager.shared.clearAll()
    }

    /// Clear expired cached values across all CachedSatisfies instances
    public static func clearExpiredCaches() {
        GlobalCacheManager.shared.clearExpired()
    }

    /// Get global cache statistics
    public static func getGlobalCacheStats() -> (totalSize: Int, totalAccesses: Int) {
        GlobalCacheManager.shared.getCacheStats()
    }
}

#if canImport(SwiftUI)
    // MARK: - SwiftUI Integration

    extension CachedSatisfies: DynamicProperty where Context == EvaluationContext {

        /// SwiftUI integration that updates when cache values change
        public mutating func update() {
            // SwiftUI will call this when the view needs updating
            // The actual caching logic handles the rest
        }
    }
#endif
