//
//  MockContextProvider.swift
//  SpecificationKit
//
//  Created by SpecificationKit on 2024.
//

import Foundation

/// A mock context provider designed for unit testing.
/// This provider allows you to set up specific context scenarios
/// and verify that specifications behave correctly under controlled conditions.
public class MockContextProvider: ContextProviding {

    // MARK: - Properties

    /// The context that will be returned by `currentContext()`
    public var mockContext: EvaluationContext

    /// Track how many times `currentContext()` was called
    public private(set) var contextRequestCount = 0

    /// Closure that will be called each time `currentContext()` is invoked
    public var onContextRequested: (() -> Void)?

    // MARK: - Initialization

    /// Creates a mock context provider with a default context
    public init() {
        self.mockContext = EvaluationContext()
    }

    /// Creates a mock context provider with the specified context
    /// - Parameter context: The context to return from `currentContext()`
    public init(context: EvaluationContext) {
        self.mockContext = context
    }

    /// Creates a mock context provider with builder-style configuration
    /// - Parameters:
    ///   - currentDate: The current date for the mock context
    ///   - launchDate: The launch date for the mock context
    ///   - userData: User data dictionary
    ///   - counters: Counters dictionary
    ///   - events: Events dictionary
    ///   - flags: Flags dictionary
    public convenience init(
        currentDate: Date = Date(),
        launchDate: Date = Date(),
        userData: [String: Any] = [:],
        counters: [String: Int] = [:],
        events: [String: Date] = [:],
        flags: [String: Bool] = [:]
    ) {
        let context = EvaluationContext(
            currentDate: currentDate,
            launchDate: launchDate,
            userData: userData,
            counters: counters,
            events: events,
            flags: flags
        )
        self.init(context: context)
    }

    // MARK: - ContextProviding

    public func currentContext() -> EvaluationContext {
        contextRequestCount += 1
        onContextRequested?()
        return mockContext
    }

    // MARK: - Mock Control Methods

    /// Updates the mock context
    /// - Parameter context: The new context to return
    public func setContext(_ context: EvaluationContext) {
        mockContext = context
    }

    /// Resets the context request count to zero
    public func resetRequestCount() {
        contextRequestCount = 0
    }

    /// Verifies that `currentContext()` was called the expected number of times
    /// - Parameter expectedCount: The expected number of calls
    /// - Returns: True if the count matches, false otherwise
    public func verifyContextRequestCount(_ expectedCount: Int) -> Bool {
        return contextRequestCount == expectedCount
    }
}

// MARK: - Builder Pattern

extension MockContextProvider {

    /// Updates the current date in the mock context
    /// - Parameter date: The new current date
    /// - Returns: Self for method chaining
    @discardableResult
    public func withCurrentDate(_ date: Date) -> MockContextProvider {
        mockContext = mockContext.withCurrentDate(date)
        return self
    }

    /// Updates the counters in the mock context
    /// - Parameter counters: The new counters dictionary
    /// - Returns: Self for method chaining
    @discardableResult
    public func withCounters(_ counters: [String: Int]) -> MockContextProvider {
        mockContext = mockContext.withCounters(counters)
        return self
    }

    /// Updates the events in the mock context
    /// - Parameter events: The new events dictionary
    /// - Returns: Self for method chaining
    @discardableResult
    public func withEvents(_ events: [String: Date]) -> MockContextProvider {
        mockContext = mockContext.withEvents(events)
        return self
    }

    /// Updates the flags in the mock context
    /// - Parameter flags: The new flags dictionary
    /// - Returns: Self for method chaining
    @discardableResult
    public func withFlags(_ flags: [String: Bool]) -> MockContextProvider {
        mockContext = mockContext.withFlags(flags)
        return self
    }

    /// Updates the user data in the mock context
    /// - Parameter userData: The new user data dictionary
    /// - Returns: Self for method chaining
    @discardableResult
    public func withUserData(_ userData: [String: Any]) -> MockContextProvider {
        mockContext = mockContext.withUserData(userData)
        return self
    }

    /// Adds a single counter to the mock context
    /// - Parameters:
    ///   - key: The counter key
    ///   - value: The counter value
    /// - Returns: Self for method chaining
    @discardableResult
    public func withCounter(_ key: String, value: Int) -> MockContextProvider {
        var counters = mockContext.counters
        counters[key] = value
        return withCounters(counters)
    }

    /// Adds a single event to the mock context
    /// - Parameters:
    ///   - key: The event key
    ///   - date: The event date
    /// - Returns: Self for method chaining
    @discardableResult
    public func withEvent(_ key: String, date: Date) -> MockContextProvider {
        var events = mockContext.events
        events[key] = date
        return withEvents(events)
    }

    /// Adds a single flag to the mock context
    /// - Parameters:
    ///   - key: The flag key
    ///   - value: The flag value
    /// - Returns: Self for method chaining
    @discardableResult
    public func withFlag(_ key: String, value: Bool) -> MockContextProvider {
        var flags = mockContext.flags
        flags[key] = value
        return withFlags(flags)
    }
}

// MARK: - Test Scenario Helpers

extension MockContextProvider {

    /// Creates a mock provider for testing launch delay scenarios
    /// - Parameters:
    ///   - timeSinceLaunch: The time since launch in seconds
    ///   - currentDate: The current date (defaults to now)
    /// - Returns: A configured MockContextProvider
    public static func launchDelayScenario(
        timeSinceLaunch: TimeInterval,
        currentDate: Date = Date()
    ) -> MockContextProvider {
        let launchDate = currentDate.addingTimeInterval(-timeSinceLaunch)
        return MockContextProvider(
            currentDate: currentDate,
            launchDate: launchDate
        )
    }

    /// Creates a mock provider for testing counter scenarios
    /// - Parameters:
    ///   - counterKey: The counter key
    ///   - counterValue: The counter value
    /// - Returns: A configured MockContextProvider
    public static func counterScenario(
        counterKey: String,
        counterValue: Int
    ) -> MockContextProvider {
        return MockContextProvider()
            .withCounter(counterKey, value: counterValue)
    }

    /// Creates a mock provider for testing event cooldown scenarios
    /// - Parameters:
    ///   - eventKey: The event key
    ///   - timeSinceEvent: Time since the event occurred in seconds
    ///   - currentDate: The current date (defaults to now)
    /// - Returns: A configured MockContextProvider
    public static func cooldownScenario(
        eventKey: String,
        timeSinceEvent: TimeInterval,
        currentDate: Date = Date()
    ) -> MockContextProvider {
        let eventDate = currentDate.addingTimeInterval(-timeSinceEvent)
        return MockContextProvider()
            .withCurrentDate(currentDate)
            .withEvent(eventKey, date: eventDate)
    }
}
