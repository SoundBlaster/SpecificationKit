//
//  ConditionalSpecification.swift
//  SpecificationKit
//
//  A specification wrapper that conditionally evaluates a wrapped specification
//  based on a predicate closure.
//

import Foundation

/// A specification that conditionally evaluates a wrapped specification based on a condition.
///
/// `ConditionalSpecification` allows you to gate specification evaluation behind a runtime
/// condition. If the condition returns `false`, the specification short-circuits and returns
/// `false` without evaluating the wrapped specification.
///
/// ## Usage
///
/// ```swift
/// let premiumFeature = MaxCountSpec(counterKey: "feature_usage", maxCount: 100)
/// let conditionalSpec = ConditionalSpecification(
///     condition: { ctx in ctx.flag(for: "is_premium") },
///     wrapping: premiumFeature
/// )
///
/// // Only checks usage limit if user is premium
/// let allowed = conditionalSpec.isSatisfiedBy(context)
/// ```
///
/// ## Use Cases
///
/// - Feature flags: Enable/disable specifications based on feature toggles
/// - User segments: Apply different specs based on user properties
/// - A/B testing: Conditionally evaluate specs for experiment groups
/// - Permission checks: Gate specifications behind authorization checks
///
/// ## Composition
///
/// Conditional specifications can be combined with other specifications:
///
/// ```swift
/// let gatedSpec = ConditionalSpecification(
///     condition: { ctx in ctx.flag(for: "beta_program") },
///     wrapping: BetaFeatureSpec()
/// ).and(GeneralAvailabilitySpec())
/// ```
public struct ConditionalSpecification<T>: Specification {

    /// The condition that determines if the wrapped spec should be evaluated
    private let condition: (T) -> Bool

    /// The specification to evaluate when condition is true
    private let wrappedSpec: AnySpecification<T>

    /// Creates a conditional specification with a condition and wrapped specification.
    ///
    /// - Parameters:
    ///   - condition: A closure that takes the candidate and returns `true` if the wrapped
    ///                specification should be evaluated, `false` to short-circuit
    ///   - wrapping: The specification to evaluate when the condition is satisfied
    public init<S: Specification>(
        condition: @escaping (T) -> Bool,
        wrapping spec: S
    ) where S.T == T {
        self.condition = condition
        self.wrappedSpec = AnySpecification(spec)
    }

    /// Evaluates the conditional specification.
    ///
    /// First evaluates the condition. If the condition returns `false`, immediately returns
    /// `false` without evaluating the wrapped specification. If the condition returns `true`,
    /// evaluates the wrapped specification and returns its result.
    ///
    /// - Parameter candidate: The candidate to evaluate
    /// - Returns: `false` if condition fails, otherwise the result of the wrapped specification
    public func isSatisfiedBy(_ candidate: T) -> Bool {
        guard condition(candidate) else {
            return false
        }
        return wrappedSpec.isSatisfiedBy(candidate)
    }
}

// MARK: - Convenience Extensions

extension Specification {
    /// Returns a conditional specification that only evaluates this spec when the condition is true.
    ///
    /// This is a convenience method for creating a `ConditionalSpecification` without
    /// explicitly wrapping the specification.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let premiumOnlySpec = MaxCountSpec(counterKey: "api_calls", maxCount: 1000)
    ///     .when { ctx in ctx.flag(for: "is_premium") }
    /// ```
    ///
    /// - Parameter condition: A closure that determines if this spec should be evaluated
    /// - Returns: A conditional specification wrapping this specification
    public func when(_ condition: @escaping (T) -> Bool) -> ConditionalSpecification<T> {
        ConditionalSpecification(condition: condition, wrapping: self)
    }

    /// Returns a conditional specification that only evaluates this spec when the condition is false.
    ///
    /// This is a convenience method for negated conditions, useful for "unless" semantics.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let rateLimitSpec = MaxCountSpec(counterKey: "requests", maxCount: 10)
    ///     .unless { ctx in ctx.flag(for: "unlimited_plan") }
    /// ```
    ///
    /// - Parameter condition: A closure that determines if this spec should NOT be evaluated
    /// - Returns: A conditional specification wrapping this specification with negated condition
    public func unless(_ condition: @escaping (T) -> Bool) -> ConditionalSpecification<T> {
        ConditionalSpecification(condition: { !condition($0) }, wrapping: self)
    }
}
