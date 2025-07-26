//
//  TimeSinceEventSpec.swift
//  SpecificationKit
//
//  Created by SpecificationKit on 2024.
//

import Foundation

/// A specification that checks if a minimum duration has passed since a specific event.
/// This is useful for implementing cooldown periods, delays, or time-based restrictions.
public struct TimeSinceEventSpec: Specification {
    public typealias T = EvaluationContext

    /// The key identifying the event in the context
    public let eventKey: String

    /// The minimum time interval that must have passed since the event
    public let minimumInterval: TimeInterval

    /// Creates a new TimeSinceEventSpec
    /// - Parameters:
    ///   - eventKey: The key identifying the event in the evaluation context
    ///   - minimumInterval: The minimum time interval that must have passed
    public init(eventKey: String, minimumInterval: TimeInterval) {
        self.eventKey = eventKey
        self.minimumInterval = minimumInterval
    }

    /// Creates a new TimeSinceEventSpec with a minimum interval in seconds
    /// - Parameters:
    ///   - eventKey: The key identifying the event in the evaluation context
    ///   - seconds: The minimum number of seconds that must have passed
    public init(eventKey: String, seconds: TimeInterval) {
        self.init(eventKey: eventKey, minimumInterval: seconds)
    }

    /// Creates a new TimeSinceEventSpec with a minimum interval in minutes
    /// - Parameters:
    ///   - eventKey: The key identifying the event in the evaluation context
    ///   - minutes: The minimum number of minutes that must have passed
    public init(eventKey: String, minutes: TimeInterval) {
        self.init(eventKey: eventKey, minimumInterval: minutes * 60)
    }

    /// Creates a new TimeSinceEventSpec with a minimum interval in hours
    /// - Parameters:
    ///   - eventKey: The key identifying the event in the evaluation context
    ///   - hours: The minimum number of hours that must have passed
    public init(eventKey: String, hours: TimeInterval) {
        self.init(eventKey: eventKey, minimumInterval: hours * 3600)
    }

    /// Creates a new TimeSinceEventSpec with a minimum interval in days
    /// - Parameters:
    ///   - eventKey: The key identifying the event in the evaluation context
    ///   - days: The minimum number of days that must have passed
    public init(eventKey: String, days: TimeInterval) {
        self.init(eventKey: eventKey, minimumInterval: days * 86400)
    }

    public func isSatisfiedBy(_ context: EvaluationContext) -> Bool {
        guard let eventDate = context.event(for: eventKey) else {
            // If the event hasn't occurred yet, the specification is satisfied
            // (no cooldown is needed for something that never happened)
            return true
        }

        let timeSinceEvent = context.currentDate.timeIntervalSince(eventDate)
        return timeSinceEvent >= minimumInterval
    }
}

// MARK: - Convenience Extensions

extension TimeSinceEventSpec {

    /// Creates a specification that checks if enough time has passed since app launch
    /// - Parameter minimumInterval: The minimum time interval since launch
    /// - Returns: A TimeSinceEventSpec configured for launch time checking
    public static func sinceAppLaunch(minimumInterval: TimeInterval) -> AnySpecification<
        EvaluationContext
    > {
        AnySpecification { context in
            let timeSinceLaunch = context.timeSinceLaunch
            return timeSinceLaunch >= minimumInterval
        }
    }

    /// Creates a specification that checks if enough seconds have passed since app launch
    /// - Parameter seconds: The minimum number of seconds since launch
    /// - Returns: A TimeSinceEventSpec configured for launch time checking
    public static func sinceAppLaunch(seconds: TimeInterval) -> AnySpecification<EvaluationContext>
    {
        sinceAppLaunch(minimumInterval: seconds)
    }

    /// Creates a specification that checks if enough minutes have passed since app launch
    /// - Parameter minutes: The minimum number of minutes since launch
    /// - Returns: A TimeSinceEventSpec configured for launch time checking
    public static func sinceAppLaunch(minutes: TimeInterval) -> AnySpecification<EvaluationContext>
    {
        sinceAppLaunch(minimumInterval: minutes * 60)
    }

    /// Creates a specification that checks if enough hours have passed since app launch
    /// - Parameter hours: The minimum number of hours since launch
    /// - Returns: A TimeSinceEventSpec configured for launch time checking
    public static func sinceAppLaunch(hours: TimeInterval) -> AnySpecification<EvaluationContext> {
        sinceAppLaunch(minimumInterval: hours * 3600)
    }

    /// Creates a specification that checks if enough days have passed since app launch
    /// - Parameter days: The minimum number of days since launch
    /// - Returns: A TimeSinceEventSpec configured for launch time checking
    public static func sinceAppLaunch(days: TimeInterval) -> AnySpecification<EvaluationContext> {
        sinceAppLaunch(minimumInterval: days * 86400)
    }
}

// MARK: - TimeInterval Extensions for Readability

extension TimeInterval {
    /// Converts seconds to TimeInterval (identity function for readability)
    public static func seconds(_ value: Double) -> TimeInterval {
        value
    }

    /// Converts minutes to TimeInterval
    public static func minutes(_ value: Double) -> TimeInterval {
        value * 60
    }

    /// Converts hours to TimeInterval
    public static func hours(_ value: Double) -> TimeInterval {
        value * 3600
    }

    /// Converts days to TimeInterval
    public static func days(_ value: Double) -> TimeInterval {
        value * 86400
    }

    /// Converts weeks to TimeInterval
    public static func weeks(_ value: Double) -> TimeInterval {
        value * 604800
    }
}
