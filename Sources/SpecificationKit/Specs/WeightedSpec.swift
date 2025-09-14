//
//  WeightedSpec.swift
//  SpecificationKit
//
//  Created by SpecificationKit on 2024.
//

import Foundation

/// A decision specification that performs weighted random selection among multiple specifications.
///
/// `WeightedSpec` implements probability-based decision making where each specification has an
/// associated weight that determines its selection probability. This is useful for A/B testing,
/// feature rollouts, load balancing, and any scenario requiring probabilistic outcomes.
///
/// ## Mathematical Foundation
///
/// The specification uses weighted random sampling where each candidate has a probability
/// proportional to its weight:
/// - Total weight: W = Σ(w_i) for all weights w_i
/// - Probability of selection: P(i) = w_i / W
///
/// ## Usage Examples
///
/// ### A/B Test Distribution
/// ```swift
/// let abTestSpec = WeightedSpec([
///     (FeatureFlagSpec(flag: "variant_a"), weight: 0.5, result: "variant_a"),
///     (FeatureFlagSpec(flag: "variant_b"), weight: 0.3, result: "variant_b"),
///     (FeatureFlagSpec(flag: "control"), weight: 0.2, result: "control")
/// ])
///
/// @Maybe(using: abTestSpec)
/// var experimentVariant: String?
/// ```
public struct WeightedSpec<Context, Result>: DecisionSpec {

    /// A candidate specification with its weight and associated result
    public typealias Candidate = (
        specification: AnySpecification<Context>, weight: Double, result: Result
    )

    /// The candidate specifications with their weights and results
    private let candidates: [Candidate]

    /// Random double generator used for weighted selection (injectable for tests)
    private let randomInRange: (ClosedRange<Double>) -> Double

    /// Creates a new WeightedSpec with the given candidates
    /// - Parameter candidates: Array of specification-weight-result tuples
    /// - Precondition: At least one candidate must be provided with positive weight
    public init(candidates: [Candidate]) {
        precondition(!candidates.isEmpty, "WeightedSpec requires at least one candidate")
        precondition(
            candidates.allSatisfy { $0.weight > 0 && $0.weight.isFinite },
            "All weights must be positive finite numbers"
        )

        self.candidates = candidates
        self.randomInRange = { range in Double.random(in: range) }
    }

    /// Creates a new WeightedSpec with the given candidates and a custom random generator
    /// - Parameters:
    ///   - candidates: Array of specification-weight-result tuples
    ///   - generator: A random number generator to use for selections (useful for deterministic tests)
    /// - Throws: `WeightedSpecError` when candidates are invalid
    public init<G: RandomNumberGenerator>(
        candidates: [Candidate],
        using generator: G
    ) {
        precondition(!candidates.isEmpty, "WeightedSpec requires at least one candidate")
        precondition(
            candidates.allSatisfy { $0.weight > 0 && $0.weight.isFinite },
            "All weights must be positive finite numbers"
        )

        self.candidates = candidates
        var g = generator
        self.randomInRange = { range in Double.random(in: range, using: &g) }
    }

    /// Creates a new WeightedSpec with typed specifications
    /// - Parameter candidates: Array of specification-weight-result tuples
    public init<S: Specification>(_ candidates: [(S, Double, Result)]) where S.T == Context {
        self.init(candidates: candidates.map { (AnySpecification($0.0), $0.1, $0.2) })
    }

    /// Creates a new WeightedSpec with typed specifications and a custom random generator
    /// - Parameters:
    ///   - candidates: Array of specification-weight-result tuples
    ///   - generator: A random number generator to use for selections
    /// - Throws: `WeightedSpecError` when candidates are invalid
    public init<S: Specification, G: RandomNumberGenerator>(
        _ candidates: [(S, Double, Result)],
        using generator: G
    ) where S.T == Context {
        self.init(
            candidates: candidates.map { (AnySpecification($0.0), $0.1, $0.2) },
            using: generator
        )
    }

    /// Evaluates the weighted specification selection
    /// - Parameter context: The context to evaluate against
    /// - Returns: The result of the selected specification if satisfied, nil otherwise
    public func decide(_ context: Context) -> Result? {
        // First, filter to satisfied specifications
        let satisfiedCandidates = candidates.filter {
            $0.specification.isSatisfiedBy(context)
        }

        guard !satisfiedCandidates.isEmpty else {
            return nil
        }

        // Perform weighted selection among satisfied candidates
        return performWeightedSelection(from: satisfiedCandidates)
    }

    /// Performs weighted random selection from satisfied candidates
    private func performWeightedSelection(from candidates: [Candidate]) -> Result? {
        let totalWeight = candidates.map(\.weight).reduce(0, +)

        // Handle edge case of zero total weight
        guard totalWeight > 0 else {
            return candidates.randomElement()?.result
        }

        let randomValue = randomInRange(0...totalWeight)

        var cumulativeWeight: Double = 0
        for candidate in candidates {
            cumulativeWeight += candidate.weight
            if randomValue <= cumulativeWeight {
                return candidate.result
            }
        }

        // Fallback to last candidate (should rarely happen due to floating point precision)
        return candidates.last?.result
    }
}

// MARK: - Statistical Analysis Extensions

extension WeightedSpec {

    /// Returns the normalized probability distribution for all candidates
    public var probabilityDistribution: [Double] {
        let totalWeight = candidates.map(\.weight).reduce(0, +)
        guard totalWeight > 0 else {
            // Equal probability if all weights are zero
            let equalProbability = 1.0 / Double(candidates.count)
            return Array(repeating: equalProbability, count: candidates.count)
        }

        return candidates.map { $0.weight / totalWeight }
    }

    /// Calculates expected value for numeric results
    /// - Returns: Expected value based on probability distribution
    public func expectedValue() -> Double where Result == Double {
        let probabilities = probabilityDistribution
        return zip(candidates.map(\.result), probabilities)
            .map(*)
            .reduce(0, +)
    }

    /// Calculates variance for numeric results
    /// - Returns: Variance based on probability distribution
    public func variance() -> Double where Result == Double {
        let expected = expectedValue()
        let probabilities = probabilityDistribution

        return zip(candidates.map(\.result), probabilities)
            .map { pow($0 - expected, 2) * $1 }
            .reduce(0, +)
    }

    /// Returns the standard deviation for numeric results
    /// - Returns: Standard deviation based on variance
    public func standardDeviation() -> Double where Result == Double {
        sqrt(variance())
    }
}

// MARK: - Convenience Extensions

extension WeightedSpec {

    /// Creates a WeightedSpec with a guaranteed fallback result
    /// - Parameters:
    ///   - candidates: The weighted candidates to evaluate
    ///   - fallback: The fallback result to return if no specification is satisfied
    /// - Returns: A WeightedSpec that always returns a result
    public static func withFallback(
        _ candidates: [Candidate],
        fallback: Result
    ) -> WeightedSpec<Context, Result> {
        let fallbackCandidate: Candidate = (
            specification: AnySpecification(AlwaysTrueSpec<Context>()),
            weight: 1.0,
            result: fallback
        )
        return WeightedSpec(candidates: candidates + [fallbackCandidate])
    }

    /// Creates a WeightedSpec with typed specifications and fallback
    /// - Parameters:
    ///   - candidates: The typed candidates to evaluate
    ///   - fallback: The fallback result
    /// - Returns: A WeightedSpec that always returns a result
    public static func withFallback<S: Specification>(
        _ candidates: [(S, Double, Result)],
        fallback: Result
    ) -> WeightedSpec<Context, Result> where S.T == Context {
        let typedCandidates = candidates.map {
            (AnySpecification($0.0), $0.1, $0.2)
        }
        let fallbackCandidate: Candidate = (
            specification: AnySpecification(AlwaysTrueSpec<Context>()),
            weight: 1.0,
            result: fallback
        )
        return WeightedSpec(candidates: typedCandidates + [fallbackCandidate])
    }
}

// MARK: - Error Types

/// Errors that can occur when working with WeightedSpec
public enum WeightedSpecError: Error, LocalizedError {
    case invalidWeight(Double)
    case emptyCandidates
    case invalidConfiguration(String)

    public var errorDescription: String? {
        switch self {
        case .invalidWeight(let weight):
            return "Invalid weight: \(weight). Weights must be positive finite numbers."
        case .emptyCandidates:
            return "WeightedSpec requires at least one candidate."
        case .invalidConfiguration(let message):
            return "Invalid configuration: \(message)"
        }
    }
}

// MARK: - WeightedSpec+Builder

extension WeightedSpec {

    /// A builder for creating WeightedSpec instances using a fluent interface
    public class Builder<C, R> {
        private var candidates: [(AnySpecification<C>, Double, R)] = []

        /// Creates a new builder
        public init() {}

        /// Adds a specification-weight-result triple to the builder
        /// - Parameters:
        ///   - specification: The specification to evaluate
        ///   - weight: The selection weight (must be > 0 and finite)
        ///   - result: The result to return if the specification is satisfied
        /// - Returns: The builder for method chaining
        @discardableResult
        public func add<S: Specification>(
            _ specification: S,
            weight: Double,
            result: R
        ) throws -> Builder where S.T == C {
            guard weight.isFinite, weight > 0 else { throw WeightedSpecError.invalidWeight(weight) }
            candidates.append((AnySpecification(specification), weight, result))
            return self
        }

        /// Adds a predicate-weight-result triple to the builder
        /// - Parameters:
        ///   - predicate: The predicate to evaluate
        ///   - weight: The selection weight (must be > 0 and finite)
        ///   - result: The result to return if the predicate is satisfied
        /// - Returns: The builder for method chaining
        @discardableResult
        public func add(
            _ predicate: @escaping (C) -> Bool,
            weight: Double,
            result: R
        ) throws -> Builder {
            guard weight.isFinite, weight > 0 else { throw WeightedSpecError.invalidWeight(weight) }
            candidates.append((AnySpecification(predicate), weight, result))
            return self
        }

        /// Adds a fallback result that is always eligible
        /// - Parameter fallback: The fallback result to use when no other spec matches
        /// - Returns: The builder for method chaining
        @discardableResult
        public func fallback(_ fallback: R) -> Builder {
            candidates.append((AnySpecification(AlwaysTrueSpec<C>()), 1.0, fallback))
            return self
        }

        /// Builds a WeightedSpec with the configured candidates
        /// - Returns: A new WeightedSpec
        public func build() -> WeightedSpec<C, R> {
            return WeightedSpec<C, R>(
                candidates: candidates.map { (specification: $0.0, weight: $0.1, result: $0.2) }
            )
        }

        /// Builds a WeightedSpec with a custom RNG for deterministic behavior
        /// - Parameter generator: The RNG to use
        /// - Returns: A new WeightedSpec using the provided RNG
        public func build<G: RandomNumberGenerator>(using generator: G) -> WeightedSpec<C, R> {
            return WeightedSpec<C, R>(
                candidates: candidates.map { (specification: $0.0, weight: $0.1, result: $0.2) },
                using: generator
            )
        }
    }

    /// Creates a new builder for constructing a WeightedSpec
    /// - Returns: A builder for method chaining
    public static func builder() -> Builder<Context, Result> {
        Builder<Context, Result>()
    }
}
