//
//  DefaultContextProvider.swift
//  SpecificationKit
//
//  Created by SpecificationKit on 2024.
//

import Foundation

/// A default context provider that supplies evaluation context from runtime state.
/// This provider can be configured with various data sources and maintains
/// application-wide state for specification evaluation.
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
    }

    /// Clears all counters
    public func clearCounters() {
        lock.lock()
        defer { lock.unlock() }
        _counters.removeAll()
    }

    /// Clears all events
    public func clearEvents() {
        lock.lock()
        defer { lock.unlock() }
        _events.removeAll()
    }

    /// Clears all flags
    public func clearFlags() {
        lock.lock()
        defer { lock.unlock() }
        _flags.removeAll()
    }

    /// Clears all user data
    public func clearUserData() {
        lock.lock()
        defer { lock.unlock() }
        _userData.removeAll()
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
    }

    /// Unregisters a custom context provider
    /// - Parameter contextKey: The key to unregister
    public func unregister(contextKey: String) {
        lock.lock()
        defer { lock.unlock() }
        _contextProviders.removeValue(forKey: contextKey)
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
