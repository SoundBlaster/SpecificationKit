//
//  FirstMatchSpec.swift
//  SpecificationKit
//
//  Created by SpecificationKit on 2025.
//

import Foundation

/// A decision specification that evaluates child specifications in order and returns
/// the result of the first one that is satisfied.
///
/// `FirstMatchSpec` implements a priority-based decision system where specifications are
/// evaluated in order until one is satisfied. This is useful for tiered business rules,
/// routing decisions, discount calculations, and any scenario where you need to select
/// the first applicable option from a prioritized list.
///
/// ## Usage Examples
///
/// ### Discount Tier Selection
/// ```swift
/// let discountSpec = FirstMatchSpec([
///     (PremiumMemberSpec(), 0.20),           // 20% for premium members
///     (LoyalCustomerSpec(), 0.15),           // 15% for loyal customers
///     (FirstTimeUserSpec(), 0.10),           // 10% for first-time users
///     (RegularUserSpec(), 0.05)              // 5% for everyone else
/// ])
///
/// @Decides(using: discountSpec, or: 0.0)
/// var discountRate: Double
/// ```
///
/// ### Feature Experiment Assignment
/// ```swift
/// let experimentSpec = FirstMatchSpec([
///     (UserSegmentSpec(expectedSegment: .beta), "variant_a"),
///     (FeatureFlagSpec(flagKey: "experiment_b"), "variant_b"),
///     (RandomPercentageSpec(percentage: 50), "variant_c")
/// ])
///
/// @Maybe(using: experimentSpec)
/// var experimentVariant: String?
/// ```
///
/// ### Content Routing
/// ```swift
/// let routingSpec = FirstMatchSpec.builder()
///     .add(UserSegmentSpec(expectedSegment: .premium), result: "premium_content")
///     .add(DateRangeSpec(startDate: campaignStart, endDate: campaignEnd), result: "campaign_content")
///     .add(MaxCountSpec(counterKey: "onboarding_completed", maximumCount: 1), result: "onboarding_content")
///     .fallback("default_content")
///     .build()
/// ```
///
/// ### With Macro Integration
/// ```swift
/// @specs(
///     FirstMatchSpec([
///         (PremiumUserSpec(), "premium_theme"),
///         (BetaUserSpec(), "beta_theme")
///     ])
/// )
/// @AutoContext
/// struct ThemeSelectionSpec: DecisionSpec {
///     typealias Context = EvaluationContext
///     typealias Result = String
/// }
/// ```
public struct FirstMatchSpec<Context, Result>: DecisionSpec {

    /// A pair consisting of a specification and its associated result
    public typealias SpecificationPair = (specification: AnySpecification<Context>, result: Result)

    /// The specification-result pairs to evaluate in order
    private let pairs: [SpecificationPair]

    /// Metadata about the matched specification, if available
    private let includeMetadata: Bool

    /// Creates a new FirstMatchSpec with the given specification-result pairs
    /// - Parameter pairs: An array of specification-result pairs to evaluate in order
    /// - Parameter includeMetadata: Whether to include metadata about the matched specification
    public init(_ pairs: [SpecificationPair], includeMetadata: Bool = false) {
        self.pairs = pairs
        self.includeMetadata = includeMetadata
    }

    /// Creates a new FirstMatchSpec with specification-result pairs
    /// - Parameter pairs: Specification-result pairs to evaluate in order
    /// - Parameter includeMetadata: Whether to include metadata about the matched specification
    public init<S: Specification>(_ pairs: [(S, Result)], includeMetadata: Bool = false)
    where S.T == Context {
        self.pairs = pairs.map { (AnySpecification($0.0), $0.1) }
        self.includeMetadata = includeMetadata
    }

    /// Evaluates the specifications in order and returns the result of the first one that is satisfied
    /// - Parameter context: The context to evaluate against
    /// - Returns: The result of the first satisfied specification, or nil if none are satisfied
    public func decide(_ context: Context) -> Result? {
        for pair in pairs {
            if pair.specification.isSatisfiedBy(context) {
                return pair.result
            }
        }
        return nil
    }

    /// Evaluates the specifications in order and returns the result and metadata of the first one that is satisfied
    /// - Parameter context: The context to evaluate against
    /// - Returns: A tuple containing the result and metadata of the first satisfied specification, or nil if none are satisfied
    public func decideWithMetadata(_ context: Context) -> (result: Result, index: Int)? {
        for (index, pair) in pairs.enumerated() {
            if pair.specification.isSatisfiedBy(context) {
                return (pair.result, index)
            }
        }
        return nil
    }
}

// MARK: - Convenience Extensions

extension FirstMatchSpec {

    /// Creates a FirstMatchSpec with a fallback result
    /// - Parameters:
    ///   - pairs: The specification-result pairs to evaluate in order
    ///   - fallback: The fallback result to return if no specification is satisfied
    /// - Returns: A FirstMatchSpec that always returns a result
    public static func withFallback(
        _ pairs: [SpecificationPair],
        fallback: Result
    ) -> FirstMatchSpec<Context, Result> {
        let fallbackPair: SpecificationPair = (AnySpecification(AlwaysTrueSpec()), fallback)
        return FirstMatchSpec(pairs + [fallbackPair])
    }

    /// Creates a FirstMatchSpec with a fallback result
    /// - Parameters:
    ///   - pairs: The specification-result pairs to evaluate in order
    ///   - fallback: The fallback result to return if no specification is satisfied
    /// - Returns: A FirstMatchSpec that always returns a result
    public static func withFallback<S: Specification>(
        _ pairs: [(S, Result)],
        fallback: Result
    ) -> FirstMatchSpec<Context, Result> where S.T == Context {
        let allPairs = pairs.map { (AnySpecification($0.0), $0.1) }
        let fallbackPair: SpecificationPair = (AnySpecification(AlwaysTrueSpec()), fallback)
        return FirstMatchSpec(allPairs + [fallbackPair])
    }
}

// MARK: - AlwaysTrueSpec for fallback support

/// A specification that is always satisfied.
/// Useful as a fallback in FirstMatchSpec.
public struct AlwaysTrueSpec<T>: Specification {

    /// Creates a new AlwaysTrueSpec
    public init() {}

    /// Always returns true for any candidate
    /// - Parameter candidate: The candidate to evaluate
    /// - Returns: Always true
    public func isSatisfiedBy(_ candidate: T) -> Bool {
        return true
    }
}

/// A specification that is never satisfied.
/// Useful for testing and as a placeholder in certain scenarios.
public struct AlwaysFalseSpec<T>: Specification {

    /// Creates a new AlwaysFalseSpec
    public init() {}

    /// Always returns false for any candidate
    /// - Parameter candidate: The candidate to evaluate
    /// - Returns: Always false
    public func isSatisfiedBy(_ candidate: T) -> Bool {
        return false
    }
}

// MARK: - FirstMatchSpec+Builder

extension FirstMatchSpec {

    /// A builder for creating FirstMatchSpec instances using a fluent interface
    public class Builder<C, R> {
        private var pairs: [(AnySpecification<C>, R)] = []
        private var includeMetadata: Bool = false

        /// Creates a new builder
        public init() {}

        /// Adds a specification-result pair to the builder
        /// - Parameters:
        ///   - specification: The specification to evaluate
        ///   - result: The result to return if the specification is satisfied
        /// - Returns: The builder for method chaining
        public func add<S: Specification>(_ specification: S, result: R) -> Builder
        where S.T == C {
            pairs.append((AnySpecification(specification), result))
            return self
        }

        /// Adds a predicate-result pair to the builder
        /// - Parameters:
        ///   - predicate: The predicate to evaluate
        ///   - result: The result to return if the predicate returns true
        /// - Returns: The builder for method chaining
        public func add(_ predicate: @escaping (C) -> Bool, result: R) -> Builder {
            pairs.append((AnySpecification(predicate), result))
            return self
        }

        /// Sets whether to include metadata about the matched specification
        /// - Parameter include: Whether to include metadata
        /// - Returns: The builder for method chaining
        public func withMetadata(_ include: Bool = true) -> Builder {
            includeMetadata = include
            return self
        }

        /// Adds a fallback result to return if no other specification is satisfied
        /// - Parameter fallback: The fallback result
        /// - Returns: The builder for method chaining
        public func fallback(_ fallback: R) -> Builder {
            pairs.append((AnySpecification(AlwaysTrueSpec<C>()), fallback))
            return self
        }

        /// Builds a FirstMatchSpec with the configured pairs
        /// - Returns: A new FirstMatchSpec
        public func build() -> FirstMatchSpec<C, R> {
            FirstMatchSpec<C, R>(
                pairs.map { (specification: $0.0, result: $0.1) }, includeMetadata: includeMetadata)
        }
    }

    /// Creates a new builder for constructing a FirstMatchSpec
    /// - Returns: A builder for method chaining
    public static func builder() -> Builder<Context, Result> {
        Builder<Context, Result>()
    }
}
