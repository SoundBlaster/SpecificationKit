//
//  PredicateSpec.swift
//  SpecificationKit
//
//  Created by SpecificationKit on 2024.
//

import Foundation

/// A specification that accepts a closure for arbitrary logic.
/// This provides maximum flexibility for custom business rules that don't fit
/// into the standard specification patterns.
public struct PredicateSpec<T>: Specification {

    /// The predicate function that determines if the specification is satisfied
    private let predicate: (T) -> Bool

    /// An optional description of what this predicate checks
    public let description: String?

    /// Creates a new PredicateSpec with the given predicate
    /// - Parameters:
    ///   - description: An optional description of what this predicate checks
    ///   - predicate: The closure that evaluates the candidate
    public init(description: String? = nil, _ predicate: @escaping (T) -> Bool) {
        self.description = description
        self.predicate = predicate
    }

    public func isSatisfiedBy(_ candidate: T) -> Bool {
        predicate(candidate)
    }
}

// MARK: - Convenience Factory Methods

extension PredicateSpec {

    /// Creates a predicate specification that always returns true
    /// - Returns: A PredicateSpec that is always satisfied
    public static func alwaysTrue() -> PredicateSpec<T> {
        PredicateSpec(description: "Always true") { _ in true }
    }

    /// Creates a predicate specification that always returns false
    /// - Returns: A PredicateSpec that is never satisfied
    public static func alwaysFalse() -> PredicateSpec<T> {
        PredicateSpec(description: "Always false") { _ in false }
    }

    /// Creates a predicate specification from a KeyPath that returns a Bool
    /// - Parameters:
    ///   - keyPath: The KeyPath to a Boolean property
    ///   - description: An optional description
    /// - Returns: A PredicateSpec that checks the Boolean property
    public static func keyPath(
        _ keyPath: KeyPath<T, Bool>,
        description: String? = nil
    ) -> PredicateSpec<T> {
        PredicateSpec(description: description) { candidate in
            candidate[keyPath: keyPath]
        }
    }

    /// Creates a predicate specification that checks if a property equals a value
    /// - Parameters:
    ///   - keyPath: The KeyPath to the property to check
    ///   - value: The value to compare against
    ///   - description: An optional description
    /// - Returns: A PredicateSpec that checks for equality
    public static func keyPath<Value: Equatable>(
        _ keyPath: KeyPath<T, Value>,
        equals value: Value,
        description: String? = nil
    ) -> PredicateSpec<T> {
        PredicateSpec(description: description) { candidate in
            candidate[keyPath: keyPath] == value
        }
    }

    /// Creates a predicate specification that checks if a comparable property is greater than a value
    /// - Parameters:
    ///   - keyPath: The KeyPath to the property to check
    ///   - value: The value to compare against
    ///   - description: An optional description
    /// - Returns: A PredicateSpec that checks if the property is greater than the value
    public static func keyPath<Value: Comparable>(
        _ keyPath: KeyPath<T, Value>,
        greaterThan value: Value,
        description: String? = nil
    ) -> PredicateSpec<T> {
        PredicateSpec(description: description) { candidate in
            candidate[keyPath: keyPath] > value
        }
    }

    /// Creates a predicate specification that checks if a comparable property is less than a value
    /// - Parameters:
    ///   - keyPath: The KeyPath to the property to check
    ///   - value: The value to compare against
    ///   - description: An optional description
    /// - Returns: A PredicateSpec that checks if the property is less than the value
    public static func keyPath<Value: Comparable>(
        _ keyPath: KeyPath<T, Value>,
        lessThan value: Value,
        description: String? = nil
    ) -> PredicateSpec<T> {
        PredicateSpec(description: description) { candidate in
            candidate[keyPath: keyPath] < value
        }
    }

    /// Creates a predicate specification that checks if a comparable property is within a range
    /// - Parameters:
    ///   - keyPath: The KeyPath to the property to check
    ///   - range: The range to check against
    ///   - description: An optional description
    /// - Returns: A PredicateSpec that checks if the property is within the range
    public static func keyPath<Value: Comparable>(
        _ keyPath: KeyPath<T, Value>,
        in range: ClosedRange<Value>,
        description: String? = nil
    ) -> PredicateSpec<T> {
        PredicateSpec(description: description) { candidate in
            range.contains(candidate[keyPath: keyPath])
        }
    }
}

// MARK: - EvaluationContext Specific Extensions

extension PredicateSpec where T == EvaluationContext {

    /// Creates a predicate that checks if enough time has passed since launch
    /// - Parameters:
    ///   - minimumTime: The minimum time since launch in seconds
    ///   - description: An optional description
    /// - Returns: A PredicateSpec for launch time checking
    public static func timeSinceLaunch(
        greaterThan minimumTime: TimeInterval,
        description: String? = nil
    ) -> PredicateSpec<EvaluationContext> {
        PredicateSpec(description: description ?? "Time since launch > \(minimumTime)s") {
            context in
            context.timeSinceLaunch > minimumTime
        }
    }

    /// Creates a predicate that checks a counter value
    /// - Parameters:
    ///   - counterKey: The counter key to check
    ///   - comparison: The comparison to perform
    ///   - value: The value to compare against
    ///   - description: An optional description
    /// - Returns: A PredicateSpec for counter checking
    public static func counter(
        _ counterKey: String,
        _ comparison: CounterComparison,
        _ value: Int,
        description: String? = nil
    ) -> PredicateSpec<EvaluationContext> {
        PredicateSpec(description: description ?? "Counter \(counterKey) \(comparison) \(value)") {
            context in
            let counterValue = context.counter(for: counterKey)
            return comparison.evaluate(counterValue, against: value)
        }
    }

    /// Creates a predicate that checks if a flag is set
    /// - Parameters:
    ///   - flagKey: The flag key to check
    ///   - expectedValue: The expected flag value (defaults to true)
    ///   - description: An optional description
    /// - Returns: A PredicateSpec for flag checking
    public static func flag(
        _ flagKey: String,
        equals expectedValue: Bool = true,
        description: String? = nil
    ) -> PredicateSpec<EvaluationContext> {
        PredicateSpec(description: description ?? "Flag \(flagKey) = \(expectedValue)") { context in
            context.flag(for: flagKey) == expectedValue
        }
    }

    /// Creates a predicate that checks if an event exists
    /// - Parameters:
    ///   - eventKey: The event key to check
    ///   - description: An optional description
    /// - Returns: A PredicateSpec that checks for event existence
    public static func eventExists(
        _ eventKey: String,
        description: String? = nil
    ) -> PredicateSpec<EvaluationContext> {
        PredicateSpec(description: description ?? "Event \(eventKey) exists") { context in
            context.event(for: eventKey) != nil
        }
    }

    /// Creates a predicate that checks the current time against a specific hour range
    /// - Parameters:
    ///   - hourRange: The range of hours (0-23) when this should be satisfied
    ///   - description: An optional description
    /// - Returns: A PredicateSpec for time-of-day checking
    public static func currentHour(
        in hourRange: ClosedRange<Int>,
        description: String? = nil
    ) -> PredicateSpec<EvaluationContext> {
        PredicateSpec(description: description ?? "Current hour in \(hourRange)") { context in
            let currentHour = context.calendar.component(.hour, from: context.currentDate)
            return hourRange.contains(currentHour)
        }
    }

    /// Creates a predicate that checks if it's currently a weekday
    /// - Parameter description: An optional description
    /// - Returns: A PredicateSpec that is satisfied on weekdays (Monday-Friday)
    public static func isWeekday(description: String? = nil) -> PredicateSpec<EvaluationContext> {
        PredicateSpec(description: description ?? "Is weekday") { context in
            let weekday = context.calendar.component(.weekday, from: context.currentDate)
            return (2...6).contains(weekday)  // Monday = 2, Friday = 6
        }
    }

    /// Creates a predicate that checks if it's currently a weekend
    /// - Parameter description: An optional description
    /// - Returns: A PredicateSpec that is satisfied on weekends (Saturday-Sunday)
    public static func isWeekend(description: String? = nil) -> PredicateSpec<EvaluationContext> {
        PredicateSpec(description: description ?? "Is weekend") { context in
            let weekday = context.calendar.component(.weekday, from: context.currentDate)
            return weekday == 1 || weekday == 7  // Sunday = 1, Saturday = 7
        }
    }
}

// MARK: - Counter Comparison Helper

/// Enumeration of comparison operations for counter values
public enum CounterComparison {
    case lessThan
    case lessThanOrEqual
    case equal
    case greaterThanOrEqual
    case greaterThan
    case notEqual

    /// Evaluates the comparison between two integers
    /// - Parameters:
    ///   - lhs: The left-hand side value (actual counter value)
    ///   - rhs: The right-hand side value (comparison value)
    /// - Returns: The result of the comparison
    func evaluate(_ lhs: Int, against rhs: Int) -> Bool {
        switch self {
        case .lessThan:
            return lhs < rhs
        case .lessThanOrEqual:
            return lhs <= rhs
        case .equal:
            return lhs == rhs
        case .greaterThanOrEqual:
            return lhs >= rhs
        case .greaterThan:
            return lhs > rhs
        case .notEqual:
            return lhs != rhs
        }
    }
}

// MARK: - Collection Extensions

extension Collection where Element: Specification {

    /// Creates a PredicateSpec that is satisfied when all specifications in the collection are satisfied
    /// - Returns: A PredicateSpec representing the AND of all specifications
    public func allSatisfiedPredicate() -> PredicateSpec<Element.T> {
        PredicateSpec(description: "All \(count) specifications satisfied") { candidate in
            self.allSatisfy { spec in
                spec.isSatisfiedBy(candidate)
            }
        }
    }

    /// Creates a PredicateSpec that is satisfied when any specification in the collection is satisfied
    /// - Returns: A PredicateSpec representing the OR of all specifications
    public func anySatisfiedPredicate() -> PredicateSpec<Element.T> {
        PredicateSpec(description: "Any of \(count) specifications satisfied") { candidate in
            self.contains { spec in
                spec.isSatisfiedBy(candidate)
            }
        }
    }
}

// MARK: - Functional Composition

extension PredicateSpec {

    /// Maps the input type of the predicate specification using a transform function
    /// - Parameter transform: A function that transforms the new input type to this spec's input type
    /// - Returns: A new PredicateSpec that works with the transformed input type
    public func contramap<U>(_ transform: @escaping (U) -> T) -> PredicateSpec<U> {
        PredicateSpec<U>(description: self.description) { input in
            self.isSatisfiedBy(transform(input))
        }
    }

    /// Combines this predicate with another using logical AND
    /// - Parameter other: Another predicate to combine with
    /// - Returns: A new PredicateSpec that requires both predicates to be satisfied
    public func and(_ other: PredicateSpec<T>) -> PredicateSpec<T> {
        let combinedDescription = [self.description, other.description]
            .compactMap { $0 }
            .joined(separator: " AND ")

        return PredicateSpec(description: combinedDescription.isEmpty ? nil : combinedDescription) {
            candidate in
            self.isSatisfiedBy(candidate) && other.isSatisfiedBy(candidate)
        }
    }

    /// Combines this predicate with another using logical OR
    /// - Parameter other: Another predicate to combine with
    /// - Returns: A new PredicateSpec that requires either predicate to be satisfied
    public func or(_ other: PredicateSpec<T>) -> PredicateSpec<T> {
        let combinedDescription = [self.description, other.description]
            .compactMap { $0 }
            .joined(separator: " OR ")

        return PredicateSpec(description: combinedDescription.isEmpty ? nil : combinedDescription) {
            candidate in
            self.isSatisfiedBy(candidate) || other.isSatisfiedBy(candidate)
        }
    }

    /// Negates this predicate specification
    /// - Returns: A new PredicateSpec that is satisfied when this one is not
    public func not() -> PredicateSpec<T> {
        let negatedDescription = description.map { "NOT (\($0))" }
        return PredicateSpec(description: negatedDescription) { candidate in
            !self.isSatisfiedBy(candidate)
        }
    }
}
