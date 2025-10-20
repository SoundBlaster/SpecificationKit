//
//  ThresholdSpec.swift
//  SpecificationKit
//
//  Created by SpecificationKit on 2025.
//

import Foundation

/// A specification that evaluates values against dynamic or static thresholds.
///
/// `ThresholdSpec` provides flexible threshold-based decision making with support for
/// static values, adaptive thresholds, contextual thresholds, and custom threshold logic.
/// This is essential for monitoring systems, alerts, adaptive controls, and any scenario
/// requiring threshold-based decisions.
///
/// ## Usage Examples
///
/// ### Performance Monitoring
/// ```swift
/// let performanceThreshold = ThresholdSpec(
///     keyPath: \.responseTime,
///     threshold: .adaptive { getCurrentPerformanceBaseline() }
/// )
///
/// @Satisfies(using: performanceThreshold)
/// var isPerformanceAcceptable: Bool
/// ```
public struct ThresholdSpec<Context, Value: Comparable>: Specification {
    public typealias T = Context

    /// Types of thresholds that can be evaluated
    public enum ThresholdType {
        /// Fixed threshold value that never changes
        case fixed(Value)

        /// Adaptive threshold computed at evaluation time
        case adaptive(() -> Value)

        /// Threshold extracted from the evaluation context
        case contextual(KeyPath<Context, Value>)

        /// Custom threshold calculation
        case custom((Context) -> Value)
    }

    /// Comparison operators for threshold evaluation
    public enum ComparisonOperator {
        case greaterThan
        case greaterThanOrEqual
        case lessThan
        case lessThanOrEqual
        case equal
        case notEqual
    }

    private let valueExtractor: (Context) -> Value?
    private let thresholdType: ThresholdType
    private let comparisonOperator: ComparisonOperator
    private let tolerance: Value?

    /// Creates a ThresholdSpec using a key path for value extraction
    /// - Parameters:
    ///   - keyPath: Key path to extract value from context
    ///   - threshold: The threshold type
    ///   - operator: The comparison operator
    ///   - tolerance: Optional tolerance for equality
    public init(
        keyPath: KeyPath<Context, Value>,
        threshold: ThresholdType,
        operator: ComparisonOperator = .greaterThanOrEqual,
        tolerance: Value? = nil
    ) {
        self.valueExtractor = { context in context[keyPath: keyPath] }
        self.thresholdType = threshold
        self.comparisonOperator = `operator`
        self.tolerance = tolerance
    }

    /// Creates a ThresholdSpec using a closure for value extraction
    /// - Parameters:
    ///   - extractor: Closure that extracts the value from context
    ///   - threshold: The threshold type
    ///   - operator: The comparison operator
    ///   - tolerance: Optional tolerance for equality
    public init(
        extracting extractor: @escaping (Context) -> Value?,
        threshold: ThresholdType,
        operator: ComparisonOperator = .greaterThanOrEqual,
        tolerance: Value? = nil
    ) {
        self.valueExtractor = extractor
        self.thresholdType = threshold
        self.comparisonOperator = `operator`
        self.tolerance = tolerance
    }

    /// Evaluates the threshold specification
    /// - Parameter candidate: The context to evaluate
    /// - Returns: True if the threshold condition is satisfied, false otherwise
    public func isSatisfiedBy(_ candidate: Context) -> Bool {
        guard let currentValue = valueExtractor(candidate) else {
            return false
        }

        let thresholdValue = resolveThreshold(thresholdType, context: candidate)
        return performComparison(
            currentValue, threshold: thresholdValue, operator: comparisonOperator)
    }

    /// Resolves the threshold value based on the threshold type
    private func resolveThreshold(_ type: ThresholdType, context: Context) -> Value {
        switch type {
        case .fixed(let value):
            return value

        case .adaptive(let provider):
            return provider()

        case .contextual(let keyPath):
            return context[keyPath: keyPath]

        case .custom(let calculator):
            return calculator(context)
        }
    }

    /// Performs the comparison between value and threshold
    private func performComparison(
        _ value: Value,
        threshold: Value,
        operator: ComparisonOperator
    ) -> Bool {
        switch `operator` {
        case .greaterThan:
            return value > threshold
        case .greaterThanOrEqual:
            return value >= threshold
        case .lessThan:
            return value < threshold
        case .lessThanOrEqual:
            return value <= threshold
        case .equal:
            return isEqual(value, to: threshold, tolerance: tolerance)
        case .notEqual:
            return !isEqual(value, to: threshold, tolerance: tolerance)
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

extension ThresholdSpec {

    /// Creates a threshold specification that must exceed a fixed value
    /// - Parameters:
    ///   - keyPath: Key path to extract value from context
    ///   - value: The threshold value to exceed
    /// - Returns: A specification checking if value exceeds threshold
    public static func exceeds(
        keyPath: KeyPath<Context, Value>,
        value: Value
    ) -> ThresholdSpec<Context, Value> {
        ThresholdSpec(
            keyPath: keyPath,
            threshold: .fixed(value),
            operator: .greaterThan
        )
    }

    /// Creates a threshold specification that must be below a fixed value
    /// - Parameters:
    ///   - keyPath: Key path to extract value from context
    ///   - value: The threshold value to stay below
    /// - Returns: A specification checking if value is below threshold
    public static func below(
        keyPath: KeyPath<Context, Value>,
        value: Value
    ) -> ThresholdSpec<Context, Value> {
        ThresholdSpec(
            keyPath: keyPath,
            threshold: .fixed(value),
            operator: .lessThan
        )
    }

    /// Creates a threshold specification with adaptive threshold calculation
    /// - Parameters:
    ///   - keyPath: Key path to extract value from context
    ///   - calculator: Function that calculates the threshold dynamically
    /// - Returns: A specification with adaptive threshold
    public static func adaptive(
        keyPath: KeyPath<Context, Value>,
        threshold calculator: @escaping () -> Value
    ) -> ThresholdSpec<Context, Value> {
        ThresholdSpec(
            keyPath: keyPath,
            threshold: .adaptive(calculator)
        )
    }
}
