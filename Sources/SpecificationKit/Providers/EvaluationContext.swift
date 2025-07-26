//
//  EvaluationContext.swift
//  SpecificationKit
//
//  Created by SpecificationKit on 2024.
//

import Foundation

/// A context object that holds data needed for specification evaluation.
/// This serves as a container for all the information that specifications might need
/// to make their decisions, such as timestamps, counters, user state, etc.
public struct EvaluationContext {

    /// The current date and time for time-based evaluations
    public let currentDate: Date

    /// Application launch time for calculating time since launch
    public let launchDate: Date

    /// A dictionary for storing arbitrary key-value data
    public let userData: [String: Any]

    /// A dictionary for storing counters and numeric values
    public let counters: [String: Int]

    /// A dictionary for storing date-based events
    public let events: [String: Date]

    /// A dictionary for storing boolean flags
    public let flags: [String: Bool]

    /// Creates a new evaluation context with the specified parameters
    /// - Parameters:
    ///   - currentDate: The current date and time (defaults to now)
    ///   - launchDate: The application launch date (defaults to now)
    ///   - userData: Custom user data dictionary
    ///   - counters: Numeric counters dictionary
    ///   - events: Event timestamps dictionary
    ///   - flags: Boolean flags dictionary
    public init(
        currentDate: Date = Date(),
        launchDate: Date = Date(),
        userData: [String: Any] = [:],
        counters: [String: Int] = [:],
        events: [String: Date] = [:],
        flags: [String: Bool] = [:]
    ) {
        self.currentDate = currentDate
        self.launchDate = launchDate
        self.userData = userData
        self.counters = counters
        self.events = events
        self.flags = flags
    }
}

// MARK: - Convenience Properties

extension EvaluationContext {

    /// Time interval since application launch in seconds
    public var timeSinceLaunch: TimeInterval {
        currentDate.timeIntervalSince(launchDate)
    }

    /// Current calendar components for date-based logic
    public var calendar: Calendar {
        Calendar.current
    }

    /// Current time zone
    public var timeZone: TimeZone {
        TimeZone.current
    }
}

// MARK: - Data Access Methods

extension EvaluationContext {

    /// Gets a counter value for the given key
    /// - Parameter key: The counter key
    /// - Returns: The counter value, or 0 if not found
    public func counter(for key: String) -> Int {
        counters[key] ?? 0
    }

    /// Gets an event date for the given key
    /// - Parameter key: The event key
    /// - Returns: The event date, or nil if not found
    public func event(for key: String) -> Date? {
        events[key]
    }

    /// Gets a flag value for the given key
    /// - Parameter key: The flag key
    /// - Returns: The flag value, or false if not found
    public func flag(for key: String) -> Bool {
        flags[key] ?? false
    }

    /// Gets user data for the given key
    /// - Parameter key: The data key
    /// - Returns: The user data value, or nil if not found
    public func userData<T>(for key: String, as type: T.Type = T.self) -> T? {
        userData[key] as? T
    }

    /// Calculates time since an event occurred
    /// - Parameter eventKey: The event key
    /// - Returns: Time interval since the event, or nil if event not found
    public func timeSinceEvent(_ eventKey: String) -> TimeInterval? {
        guard let eventDate = event(for: eventKey) else { return nil }
        return currentDate.timeIntervalSince(eventDate)
    }
}

// MARK: - Builder Pattern

extension EvaluationContext {

    /// Creates a new context with updated user data
    /// - Parameter userData: The new user data dictionary
    /// - Returns: A new EvaluationContext with the updated user data
    public func withUserData(_ userData: [String: Any]) -> EvaluationContext {
        EvaluationContext(
            currentDate: currentDate,
            launchDate: launchDate,
            userData: userData,
            counters: counters,
            events: events,
            flags: flags
        )
    }

    /// Creates a new context with updated counters
    /// - Parameter counters: The new counters dictionary
    /// - Returns: A new EvaluationContext with the updated counters
    public func withCounters(_ counters: [String: Int]) -> EvaluationContext {
        EvaluationContext(
            currentDate: currentDate,
            launchDate: launchDate,
            userData: userData,
            counters: counters,
            events: events,
            flags: flags
        )
    }

    /// Creates a new context with updated events
    /// - Parameter events: The new events dictionary
    /// - Returns: A new EvaluationContext with the updated events
    public func withEvents(_ events: [String: Date]) -> EvaluationContext {
        EvaluationContext(
            currentDate: currentDate,
            launchDate: launchDate,
            userData: userData,
            counters: counters,
            events: events,
            flags: flags
        )
    }

    /// Creates a new context with updated flags
    /// - Parameter flags: The new flags dictionary
    /// - Returns: A new EvaluationContext with the updated flags
    public func withFlags(_ flags: [String: Bool]) -> EvaluationContext {
        EvaluationContext(
            currentDate: currentDate,
            launchDate: launchDate,
            userData: userData,
            counters: counters,
            events: events,
            flags: flags
        )
    }

    /// Creates a new context with an updated current date
    /// - Parameter currentDate: The new current date
    /// - Returns: A new EvaluationContext with the updated current date
    public func withCurrentDate(_ currentDate: Date) -> EvaluationContext {
        EvaluationContext(
            currentDate: currentDate,
            launchDate: launchDate,
            userData: userData,
            counters: counters,
            events: events,
            flags: flags
        )
    }
}
