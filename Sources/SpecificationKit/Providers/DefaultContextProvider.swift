//
//  DefaultContextProvider.swift
//  SpecificationKit
//
//  Created by SpecificationKit on 2024.
//

import Foundation

#if canImport(Combine)
    import Combine
#endif

/// A thread-safe context provider that maintains application-wide state for specification evaluation.
///
/// `DefaultContextProvider` is the primary context provider in SpecificationKit, designed to manage
/// counters, feature flags, events, and user data that specifications use for evaluation. It provides
/// a shared singleton instance and supports reactive updates through Combine publishers.
///
/// ## Key Features
///
/// - **Thread-Safe**: All operations are protected by locks for concurrent access
/// - **Reactive Updates**: Publishes changes via Combine when state mutates
/// - **Flexible Storage**: Supports counters, flags, events, and arbitrary user data
/// - **Singleton Pattern**: Provides a shared instance for application-wide state
/// - **Async Support**: Provides both sync and async context access methods
///
/// ## Usage Examples
///
/// ### Basic Usage with Shared Instance
/// ```swift
/// let provider = DefaultContextProvider.shared
///
/// // Set up some initial state
/// provider.setFlag("premium_features", value: true)
/// provider.setCounter("app_launches", value: 1)
/// provider.recordEvent("first_launch")
///
/// // Use with specifications
/// @Satisfies(using: FeatureFlagSpec(flagKey: "premium_features"))
/// var showPremiumFeatures: Bool
/// ```
///
/// ### Counter Management
/// ```swift
/// let provider = DefaultContextProvider.shared
///
/// // Track user actions
/// provider.incrementCounter("button_clicks")
/// provider.incrementCounter("page_views", by: 1)
///
/// // Check limits with specifications
/// @Satisfies(using: MaxCountSpec(counterKey: "daily_api_calls", maximumCount: 1000))
/// var canMakeAPICall: Bool
///
/// if canMakeAPICall {
///     makeAPICall()
///     provider.incrementCounter("daily_api_calls")
/// }
/// ```
///
/// ### Event Tracking for Cooldowns
/// ```swift
/// // Record events for time-based specifications
/// provider.recordEvent("last_notification_shown")
/// provider.recordEvent("user_tutorial_completed")
///
/// // Use with time-based specs
/// @Satisfies(using: CooldownIntervalSpec(eventKey: "last_notification_shown", interval: 3600))
/// var canShowNotification: Bool
/// ```
///
/// ### Feature Flag Management
/// ```swift
/// // Configure feature flags
/// provider.setFlag("dark_mode_enabled", value: true)
/// provider.setFlag("experimental_ui", value: false)
/// provider.setFlag("analytics_enabled", value: true)
///
/// // Use throughout the app
/// @Satisfies(using: FeatureFlagSpec(flagKey: "dark_mode_enabled"))
/// var shouldUseDarkMode: Bool
/// ```
///
/// ### User Data Storage
/// ```swift
/// // Store user-specific data
/// provider.setUserData("subscription_tier", value: "premium")
/// provider.setUserData("user_segment", value: UserSegment.beta)
/// provider.setUserData("onboarding_completed", value: true)
///
/// // Access in custom specifications
/// struct CustomUserSpec: Specification {
///     typealias T = EvaluationContext
///
///     func isSatisfiedBy(_ context: EvaluationContext) -> Bool {
///         let tier = context.userData["subscription_tier"] as? String
///         return tier == "premium"
///     }
/// }
/// ```
///
/// ### Custom Context Provider Instance
/// ```swift
/// // Create isolated provider for testing or specific modules
/// let testProvider = DefaultContextProvider()
/// testProvider.setFlag("test_mode", value: true)
///
/// @Satisfies(provider: testProvider, using: FeatureFlagSpec(flagKey: "test_mode"))
/// var isInTestMode: Bool
/// ```
///
/// ### SwiftUI Integration with Updates
/// ```swift
/// struct ContentView: View {
///     @ObservedSatisfies(using: MaxCountSpec(counterKey: "banner_shown", maximumCount: 3))
///     var shouldShowBanner: Bool
///
///     var body: some View {
///         VStack {
///             if shouldShowBanner {
///                 PromoBanner()
///                     .onTapGesture {
///                         DefaultContextProvider.shared.incrementCounter("banner_shown")
///                         // View automatically updates due to reactive binding
///                     }
///             }
///             MainContent()
///         }
///     }
/// }
/// ```
///
/// ## Thread Safety
///
/// All methods are thread-safe and can be called from any queue:
///
/// ```swift
/// DispatchQueue.global().async {
///     provider.incrementCounter("background_task")
/// }
///
/// DispatchQueue.main.async {
///     provider.setFlag("ui_ready", value: true)
/// }
/// ```
///
/// ## State Management
///
/// The provider maintains several types of state:
/// - **Counters**: Integer values that can be incremented/decremented
/// - **Flags**: Boolean values for feature toggles
/// - **Events**: Date timestamps for time-based specifications
/// - **User Data**: Arbitrary key-value storage for custom data
/// - **Context Providers**: Custom data source factories
public class DefaultContextProvider: ContextProviding {

    // MARK: - Shared Instance

    /// Shared singleton instance for convenient access across the application
    public static let shared = DefaultContextProvider()

    // MARK: - Private Properties

    private let launchDate: Date
    private var _counters: [String: Int] = [:]
    private var _events: [String: Date] = [:]
    private var _flags: [String: Bool] = [:]
    private var _userData: [String: Any] = [:]
    private var _contextProviders: [String: () -> Any] = [:]

    private let lock = NSLock()

    #if canImport(Combine)
        public let objectWillChange = PassthroughSubject<Void, Never>()
    #endif

    // MARK: - Initialization

    /// Creates a new default context provider
    /// - Parameter launchDate: The application launch date (defaults to current date)
    public init(launchDate: Date = Date()) {
        self.launchDate = launchDate
    }

    // MARK: - ContextProviding

    public func currentContext() -> EvaluationContext {
        lock.lock()
        defer { lock.unlock() }

        // Incorporate any registered context providers
        var mergedUserData = _userData

        // Add any dynamic context data
        for (key, provider) in _contextProviders {
            mergedUserData[key] = provider()
        }

        return EvaluationContext(
            currentDate: Date(),
            launchDate: launchDate,
            userData: mergedUserData,
            counters: _counters,
            events: _events,
            flags: _flags
        )
    }

    // MARK: - Counter Management

    /// Sets a counter value
    /// - Parameters:
    ///   - key: The counter key
    ///   - value: The counter value
    public func setCounter(_ key: String, to value: Int) {
        lock.lock()
        defer { lock.unlock() }
        _counters[key] = value
        #if canImport(Combine)
            objectWillChange.send()
        #endif
    }

    /// Increments a counter by the specified amount
    /// - Parameters:
    ///   - key: The counter key
    ///   - amount: The amount to increment (defaults to 1)
    /// - Returns: The new counter value
    @discardableResult
    public func incrementCounter(_ key: String, by amount: Int = 1) -> Int {
        lock.lock()
        defer { lock.unlock() }
        let newValue = (_counters[key] ?? 0) + amount
        _counters[key] = newValue
        #if canImport(Combine)
            objectWillChange.send()
        #endif
        return newValue
    }

    /// Decrements a counter by the specified amount
    /// - Parameters:
    ///   - key: The counter key
    ///   - amount: The amount to decrement (defaults to 1)
    /// - Returns: The new counter value
    @discardableResult
    public func decrementCounter(_ key: String, by amount: Int = 1) -> Int {
        lock.lock()
        defer { lock.unlock() }
        let newValue = max(0, (_counters[key] ?? 0) - amount)
        _counters[key] = newValue
        #if canImport(Combine)
            objectWillChange.send()
        #endif
        return newValue
    }

    /// Gets the current value of a counter
    /// - Parameter key: The counter key
    /// - Returns: The current counter value, or 0 if not found
    public func getCounter(_ key: String) -> Int {
        lock.lock()
        defer { lock.unlock() }
        return _counters[key] ?? 0
    }

    /// Resets a counter to zero
    /// - Parameter key: The counter key
    public func resetCounter(_ key: String) {
        lock.lock()
        defer { lock.unlock() }
        _counters[key] = 0
        #if canImport(Combine)
            objectWillChange.send()
        #endif
    }

    // MARK: - Event Management

    /// Records an event with the current timestamp
    /// - Parameter key: The event key
    public func recordEvent(_ key: String) {
        recordEvent(key, at: Date())
    }

    /// Records an event with a specific timestamp
    /// - Parameters:
    ///   - key: The event key
    ///   - date: The event timestamp
    public func recordEvent(_ key: String, at date: Date) {
        lock.lock()
        defer { lock.unlock() }
        _events[key] = date
        #if canImport(Combine)
            objectWillChange.send()
        #endif
    }

    /// Gets the timestamp of an event
    /// - Parameter key: The event key
    /// - Returns: The event timestamp, or nil if not found
    public func getEvent(_ key: String) -> Date? {
        lock.lock()
        defer { lock.unlock() }
        return _events[key]
    }

    /// Removes an event record
    /// - Parameter key: The event key
    public func removeEvent(_ key: String) {
        lock.lock()
        defer { lock.unlock() }
        _events.removeValue(forKey: key)
        #if canImport(Combine)
            objectWillChange.send()
        #endif
    }

    // MARK: - Flag Management

    /// Sets a boolean flag
    /// - Parameters:
    ///   - key: The flag key
    ///   - value: The flag value
    public func setFlag(_ key: String, to value: Bool) {
        lock.lock()
        defer { lock.unlock() }
        _flags[key] = value
        #if canImport(Combine)
            objectWillChange.send()
        #endif
    }

    /// Toggles a boolean flag
    /// - Parameter key: The flag key
    /// - Returns: The new flag value
    @discardableResult
    public func toggleFlag(_ key: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        let newValue = !(_flags[key] ?? false)
        _flags[key] = newValue
        #if canImport(Combine)
            objectWillChange.send()
        #endif
        return newValue
    }

    /// Gets the value of a boolean flag
    /// - Parameter key: The flag key
    /// - Returns: The flag value, or false if not found
    public func getFlag(_ key: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return _flags[key] ?? false
    }

    // MARK: - User Data Management

    /// Sets user data for a key
    /// - Parameters:
    ///   - key: The data key
    ///   - value: The data value
    public func setUserData<T>(_ key: String, to value: T) {
        lock.lock()
        defer { lock.unlock() }
        _userData[key] = value
        #if canImport(Combine)
            objectWillChange.send()
        #endif
    }

    /// Gets user data for a key
    /// - Parameters:
    ///   - key: The data key
    ///   - type: The expected type of the data
    /// - Returns: The data value cast to the specified type, or nil if not found or wrong type
    public func getUserData<T>(_ key: String, as type: T.Type = T.self) -> T? {
        lock.lock()
        defer { lock.unlock() }
        return _userData[key] as? T
    }

    /// Removes user data for a key
    /// - Parameter key: The data key
    public func removeUserData(_ key: String) {
        lock.lock()
        defer { lock.unlock() }
        _userData.removeValue(forKey: key)
        #if canImport(Combine)
            objectWillChange.send()
        #endif
    }

    // MARK: - Bulk Operations

    /// Clears all stored data
    public func clearAll() {
        lock.lock()
        defer { lock.unlock() }
        _counters.removeAll()
        _events.removeAll()
        _flags.removeAll()
        _userData.removeAll()
        #if canImport(Combine)
            objectWillChange.send()
        #endif
    }

    /// Clears all counters
    public func clearCounters() {
        lock.lock()
        defer { lock.unlock() }
        _counters.removeAll()
        #if canImport(Combine)
            objectWillChange.send()
        #endif
    }

    /// Clears all events
    public func clearEvents() {
        lock.lock()
        defer { lock.unlock() }
        _events.removeAll()
        #if canImport(Combine)
            objectWillChange.send()
        #endif
    }

    /// Clears all flags
    public func clearFlags() {
        lock.lock()
        defer { lock.unlock() }
        _flags.removeAll()
        #if canImport(Combine)
            objectWillChange.send()
        #endif
    }

    /// Clears all user data
    public func clearUserData() {
        lock.lock()
        defer { lock.unlock() }
        _userData.removeAll()
        #if canImport(Combine)
            objectWillChange.send()
        #endif
    }

    // MARK: - Context Registration

    /// Registers a custom context provider for a specific key
    /// - Parameters:
    ///   - contextKey: The key to associate with the provided context
    ///   - provider: A closure that provides the context
    public func register<T>(contextKey: String, provider: @escaping () -> T) {
        lock.lock()
        defer { lock.unlock() }
        _contextProviders[contextKey] = provider
        #if canImport(Combine)
            objectWillChange.send()
        #endif
    }

    /// Unregisters a custom context provider
    /// - Parameter contextKey: The key to unregister
    public func unregister(contextKey: String) {
        lock.lock()
        defer { lock.unlock() }
        _contextProviders.removeValue(forKey: contextKey)
        #if canImport(Combine)
            objectWillChange.send()
        #endif
    }
}

// MARK: - Convenience Extensions

extension DefaultContextProvider {

    /// Creates a specification that uses this provider's context
    /// - Parameter predicate: A predicate function that takes an EvaluationContext
    /// - Returns: An AnySpecification that evaluates using this provider's context
    public func specification<T>(_ predicate: @escaping (EvaluationContext) -> (T) -> Bool)
        -> AnySpecification<T>
    {
        AnySpecification { candidate in
            let context = self.currentContext()
            return predicate(context)(candidate)
        }
    }

    /// Creates a context-aware predicate specification
    /// - Parameter predicate: A predicate that takes both context and candidate
    /// - Returns: An AnySpecification that evaluates the predicate with this provider's context
    public func contextualPredicate<T>(_ predicate: @escaping (EvaluationContext, T) -> Bool)
        -> AnySpecification<T>
    {
        AnySpecification { candidate in
            let context = self.currentContext()
            return predicate(context, candidate)
        }
    }
}

#if canImport(Combine)
    // MARK: - Observation bridging
    extension DefaultContextProvider: ContextUpdatesProviding {
        /// Emits a signal when internal state changes.
        public var contextUpdates: AnyPublisher<Void, Never> {
            objectWillChange.eraseToAnyPublisher()
        }

        /// Async bridge of updates; yields whenever `objectWillChange` fires.
        public var contextStream: AsyncStream<Void> {
            AsyncStream { continuation in
                let subscription = objectWillChange.sink { _ in
                    continuation.yield(())
                }
                continuation.onTermination = { _ in
                    _ = subscription
                }
            }
        }
    }
#endif
