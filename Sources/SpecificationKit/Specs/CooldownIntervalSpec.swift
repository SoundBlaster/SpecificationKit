//
//  CooldownIntervalSpec.swift
//  SpecificationKit
//
//  Created by SpecificationKit on 2025.
//

import Foundation

/// A specification that ensures enough time has passed since the last occurrence of an event.
/// This is particularly useful for implementing cooldown periods for actions like showing banners,
/// notifications, or any other time-sensitive operations that shouldn't happen too frequently.
public struct CooldownIntervalSpec: Specification {
    public typealias T = EvaluationContext

    /// The key identifying the last occurrence event in the context
    public let eventKey: String

    /// The minimum time interval that must pass between occurrences
    public let cooldownInterval: TimeInterval

    /// Creates a new CooldownIntervalSpec
    /// - Parameters:
    ///   - eventKey: The key identifying the last occurrence event in the evaluation context
    ///   - cooldownInterval: The minimum time interval that must pass between occurrences
    public init(eventKey: String, cooldownInterval: TimeInterval) {
        self.eventKey = eventKey
        self.cooldownInterval = cooldownInterval
    }

    /// Creates a new CooldownIntervalSpec with interval in seconds
    /// - Parameters:
    ///   - eventKey: The key identifying the last occurrence event
    ///   - seconds: The cooldown period in seconds
    public init(eventKey: String, seconds: TimeInterval) {
        self.init(eventKey: eventKey, cooldownInterval: seconds)
    }

    /// Creates a new CooldownIntervalSpec with interval in minutes
    /// - Parameters:
    ///   - eventKey: The key identifying the last occurrence event
    ///   - minutes: The cooldown period in minutes
    public init(eventKey: String, minutes: TimeInterval) {
        self.init(eventKey: eventKey, cooldownInterval: minutes * 60)
    }

    /// Creates a new CooldownIntervalSpec with interval in hours
    /// - Parameters:
    ///   - eventKey: The key identifying the last occurrence event
    ///   - hours: The cooldown period in hours
    public init(eventKey: String, hours: TimeInterval) {
        self.init(eventKey: eventKey, cooldownInterval: hours * 3600)
    }

    /// Creates a new CooldownIntervalSpec with interval in days
    /// - Parameters:
    ///   - eventKey: The key identifying the last occurrence event
    ///   - days: The cooldown period in days
    public init(eventKey: String, days: TimeInterval) {
        self.init(eventKey: eventKey, cooldownInterval: days * 86400)
    }

    public func isSatisfiedBy(_ context: EvaluationContext) -> Bool {
        guard let lastOccurrence = context.event(for: eventKey) else {
            // If the event has never occurred, the cooldown is satisfied
            return true
        }

        let timeSinceLastOccurrence = context.currentDate.timeIntervalSince(lastOccurrence)
        return timeSinceLastOccurrence >= cooldownInterval
    }
}

// MARK: - Convenience Factory Methods

extension CooldownIntervalSpec {

    /// Creates a cooldown specification for daily restrictions
    /// - Parameter eventKey: The event key to track
    /// - Returns: A CooldownIntervalSpec with a 24-hour cooldown
    public static func daily(_ eventKey: String) -> CooldownIntervalSpec {
        CooldownIntervalSpec(eventKey: eventKey, days: 1)
    }

    /// Creates a cooldown specification for weekly restrictions
    /// - Parameter eventKey: The event key to track
    /// - Returns: A CooldownIntervalSpec with a 7-day cooldown
    public static func weekly(_ eventKey: String) -> CooldownIntervalSpec {
        CooldownIntervalSpec(eventKey: eventKey, days: 7)
    }

    /// Creates a cooldown specification for monthly restrictions (30 days)
    /// - Parameter eventKey: The event key to track
    /// - Returns: A CooldownIntervalSpec with a 30-day cooldown
    public static func monthly(_ eventKey: String) -> CooldownIntervalSpec {
        CooldownIntervalSpec(eventKey: eventKey, days: 30)
    }

    /// Creates a cooldown specification for hourly restrictions
    /// - Parameter eventKey: The event key to track
    /// - Returns: A CooldownIntervalSpec with a 1-hour cooldown
    public static func hourly(_ eventKey: String) -> CooldownIntervalSpec {
        CooldownIntervalSpec(eventKey: eventKey, hours: 1)
    }

    /// Creates a cooldown specification with a custom time interval
    /// - Parameters:
    ///   - eventKey: The event key to track
    ///   - interval: The custom cooldown interval
    /// - Returns: A CooldownIntervalSpec with the specified interval
    public static func custom(_ eventKey: String, interval: TimeInterval) -> CooldownIntervalSpec {
        CooldownIntervalSpec(eventKey: eventKey, cooldownInterval: interval)
    }
}

// MARK: - Time Remaining Utilities

extension CooldownIntervalSpec {

    /// Calculates the remaining cooldown time for the specified context
    /// - Parameter context: The evaluation context
    /// - Returns: The remaining cooldown time in seconds, or 0 if cooldown is complete
    public func remainingCooldownTime(in context: EvaluationContext) -> TimeInterval {
        guard let lastOccurrence = context.event(for: eventKey) else {
            return 0  // No previous occurrence, no cooldown remaining
        }

        let timeSinceLastOccurrence = context.currentDate.timeIntervalSince(lastOccurrence)
        let remainingTime = cooldownInterval - timeSinceLastOccurrence
        return max(0, remainingTime)
    }

    /// Checks if the cooldown is currently active
    /// - Parameter context: The evaluation context
    /// - Returns: True if the cooldown is still active, false otherwise
    public func isCooldownActive(in context: EvaluationContext) -> Bool {
        return !isSatisfiedBy(context)
    }

    /// Gets the next allowed time for the event
    /// - Parameter context: The evaluation context
    /// - Returns: The date when the cooldown will expire, or nil if already expired
    public func nextAllowedTime(in context: EvaluationContext) -> Date? {
        guard let lastOccurrence = context.event(for: eventKey) else {
            return nil  // No previous occurrence, already allowed
        }

        let nextAllowed = lastOccurrence.addingTimeInterval(cooldownInterval)
        return nextAllowed > context.currentDate ? nextAllowed : nil
    }
}

// MARK: - Combinable with Other Cooldowns

extension CooldownIntervalSpec {

    /// Combines this cooldown with another cooldown using AND logic
    /// Both cooldowns must be satisfied for the combined specification to be satisfied
    /// - Parameter other: Another CooldownIntervalSpec to combine with
    /// - Returns: An AndSpecification requiring both cooldowns to be satisfied
    public func and(_ other: CooldownIntervalSpec) -> AndSpecification<
        CooldownIntervalSpec, CooldownIntervalSpec
    > {
        AndSpecification(left: self, right: other)
    }

    /// Combines this cooldown with another cooldown using OR logic
    /// Either cooldown being satisfied will satisfy the combined specification
    /// - Parameter other: Another CooldownIntervalSpec to combine with
    /// - Returns: An OrSpecification requiring either cooldown to be satisfied
    public func or(_ other: CooldownIntervalSpec) -> OrSpecification<
        CooldownIntervalSpec, CooldownIntervalSpec
    > {
        OrSpecification(left: self, right: other)
    }
}

// MARK: - Advanced Cooldown Patterns

extension CooldownIntervalSpec {

    /// Creates a specification that implements exponential backoff cooldowns
    /// The cooldown time increases exponentially with each occurrence
    /// - Parameters:
    ///   - eventKey: The event key to track
    ///   - baseInterval: The base cooldown interval
    ///   - counterKey: The key for tracking occurrence count
    ///   - maxInterval: The maximum cooldown interval (optional)
    /// - Returns: An AnySpecification implementing exponential backoff
    public static func exponentialBackoff(
        eventKey: String,
        baseInterval: TimeInterval,
        counterKey: String,
        maxInterval: TimeInterval? = nil
    ) -> AnySpecification<EvaluationContext> {
        AnySpecification { context in
            guard let lastOccurrence = context.event(for: eventKey) else {
                return true  // No previous occurrence
            }

            let occurrenceCount = context.counter(for: counterKey)
            let multiplier = pow(2.0, Double(occurrenceCount - 1))
            var actualInterval = baseInterval * multiplier

            if let maxInterval = maxInterval {
                actualInterval = min(actualInterval, maxInterval)
            }

            let timeSinceLastOccurrence = context.currentDate.timeIntervalSince(lastOccurrence)
            return timeSinceLastOccurrence >= actualInterval
        }
    }

    /// Creates a specification with different cooldown intervals based on the time of day
    /// - Parameters:
    ///   - eventKey: The event key to track
    ///   - daytimeInterval: Cooldown interval during daytime hours
    ///   - nighttimeInterval: Cooldown interval during nighttime hours
    ///   - daytimeHours: The range of hours considered daytime (default: 6-22)
    /// - Returns: An AnySpecification with time-of-day based cooldowns
    public static func timeOfDayBased(
        eventKey: String,
        daytimeInterval: TimeInterval,
        nighttimeInterval: TimeInterval,
        daytimeHours: ClosedRange<Int> = 6...22
    ) -> AnySpecification<EvaluationContext> {
        AnySpecification { context in
            guard let lastOccurrence = context.event(for: eventKey) else {
                return true  // No previous occurrence
            }

            let currentHour = context.calendar.component(.hour, from: context.currentDate)
            let isDaytime = daytimeHours.contains(currentHour)
            let requiredInterval = isDaytime ? daytimeInterval : nighttimeInterval

            let timeSinceLastOccurrence = context.currentDate.timeIntervalSince(lastOccurrence)
            return timeSinceLastOccurrence >= requiredInterval
        }
    }
}
