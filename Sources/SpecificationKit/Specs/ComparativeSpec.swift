//
//  ComparativeSpec.swift
//  SpecificationKit
//
//  Created by SpecificationKit on 2024.
//

import Foundation

/// A specification that performs comparisons against baseline values or other specifications.
///
/// `ComparativeSpec` enables decision making based on relative comparisons rather than absolute
/// values. This is useful for adaptive systems, performance monitoring, competitive analysis,
/// and any scenario where decisions depend on relative positioning or comparison outcomes.
///
/// ## Usage Examples
///
/// ### Performance Comparison
/// ```swift
/// let performanceSpec = ComparativeSpec(
///     keyPath: \.currentValue,
///     comparison: .greaterThan(10.0)
/// )
///
/// @Satisfies(using: performanceSpec)
/// var isPerformingBetter: Bool
/// ```
public struct ComparativeSpec<Context, Value: Comparable>: Specification {
    public typealias T = Context

    /// Types of comparisons that can be performed
    public enum ComparisonType {
        /// Compare against a fixed value
        case greaterThan(Value)
        case lessThan(Value)
        case equalTo(Value)
        case between(Value, Value)

        /// Custom comparison logic
        case custom((Value, Context) -> Bool)
    }

    private let valueExtractor: (Context) -> Value?
    private let comparison: ComparisonType
    private let tolerance: Value?

    /// Creates a ComparativeSpec using a key path for value extraction
    /// - Parameters:
    ///   - keyPath: Key path to extract value from context
    ///   - comparison: The type of comparison to perform
    ///   - tolerance: Optional tolerance for equality comparisons
    public init(
        keyPath: KeyPath<Context, Value>,
        comparison: ComparisonType,
        tolerance: Value? = nil
    ) {
        self.valueExtractor = { context in context[keyPath: keyPath] }
        self.comparison = comparison
        self.tolerance = tolerance
    }

    /// Creates a ComparativeSpec using a closure for value extraction
    /// - Parameters:
    ///   - extractor: Closure that extracts the value from context
    ///   - comparison: The type of comparison to perform
    ///   - tolerance: Optional tolerance for equality comparisons
    public init(
        extracting extractor: @escaping (Context) -> Value?,
        comparison: ComparisonType,
        tolerance: Value? = nil
    ) {
        self.valueExtractor = extractor
        self.comparison = comparison
        self.tolerance = tolerance
    }

    /// Evaluates the comparative specification
    /// - Parameter candidate: The context to evaluate
    /// - Returns: True if the comparison is satisfied, false otherwise
    public func isSatisfiedBy(_ candidate: Context) -> Bool {
        guard let currentValue = valueExtractor(candidate) else {
            return false
        }

        return evaluateComparison(currentValue, against: comparison, context: candidate)
    }

    /// Performs the actual comparison evaluation
    private func evaluateComparison(
        _ value: Value,
        against comparison: ComparisonType,
        context: Context
    ) -> Bool {
        switch comparison {
        case .greaterThan(let threshold):
            return value > threshold

        case .lessThan(let threshold):
            return value < threshold

        case .equalTo(let expected):
            return isEqual(value, to: expected, tolerance: tolerance)

        case .between(let lower, let upper):
            return lower <= value && value <= upper

        case .custom(let comparator):
            return comparator(value, context)
        }
    }

    /// Checks equality with optional tolerance
    private func isEqual(_ lhs: Value, to rhs: Value, tolerance: Value?) -> Bool {
        if let tolerance = tolerance {
            // For numeric types, implement tolerance-based equality
            if let lhsDouble = lhs as? Double,
                let rhsDouble = rhs as? Double,
                let toleranceDouble = tolerance as? Double
            {
                return abs(lhsDouble - rhsDouble) <= toleranceDouble
            }
        }

        return lhs == rhs
    }
}

// MARK: - Convenience Extensions

extension ComparativeSpec where Value: AdditiveArithmetic {

    /// Creates a specification that checks if a value is within a tolerance range
    /// - Parameters:
    ///   - target: The target value
    ///   - tolerance: The allowed deviation
    /// - Returns: A specification checking if the value is within tolerance
    public static func withinTolerance(
        of target: Value,
        tolerance: Value,
        keyPath: KeyPath<Context, Value>
    ) -> ComparativeSpec<Context, Value> {
        ComparativeSpec(
            keyPath: keyPath,
            comparison: .between(target - tolerance, target + tolerance)
        )
    }
}

extension ComparativeSpec where Value: FloatingPoint {

    /// Creates a specification that checks for approximate equality with relative tolerance
    /// - Parameters:
    ///   - target: The target value
    ///   - relativeError: The relative error tolerance (e.g., 0.01 for 1%)
    /// - Returns: A specification checking approximate equality
    public static func approximatelyEqual(
        to target: Value,
        relativeError: Value,
        keyPath: KeyPath<Context, Value>
    ) -> ComparativeSpec<Context, Value> {
        let tolerance = target * relativeError
        return ComparativeSpec(
            keyPath: keyPath,
            comparison: .between(target - tolerance, target + tolerance)
        )
    }
}
