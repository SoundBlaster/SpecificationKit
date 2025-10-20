//
//  Specification.swift
//  SpecificationKit
//
//  Created by SpecificationKit on 2025.
//

import Foundation

/// A specification that evaluates whether a context satisfies certain conditions.
///
/// The `Specification` protocol is the foundation of the SpecificationKit framework,
/// implementing the Specification Pattern to encapsulate business rules and conditions
/// in a composable, testable manner.
///
/// ## Overview
///
/// Specifications allow you to define complex business logic through small, focused
/// components that can be combined using logical operators. This approach promotes
/// code reusability, testability, and maintainability.
///
/// ## Basic Usage
///
/// ```swift
/// struct UserAgeSpec: Specification {
///     let minimumAge: Int
///
///     func isSatisfiedBy(_ user: User) -> Bool {
///         return user.age >= minimumAge
///     }
/// }
///
/// let adultSpec = UserAgeSpec(minimumAge: 18)
/// let canVote = adultSpec.isSatisfiedBy(user)
/// ```
///
/// ## Composition
///
/// Specifications can be combined using logical operators:
///
/// ```swift
/// let adultSpec = UserAgeSpec(minimumAge: 18)
/// let citizenSpec = UserCitizenshipSpec(country: .usa)
/// let canVoteSpec = adultSpec.and(citizenSpec)
/// ```
///
/// ## Property Wrapper Integration
///
/// Use property wrappers for declarative specification evaluation:
///
/// ```swift
/// struct VotingView: View {
///     @Satisfies(using: adultSpec.and(citizenSpec))
///     var canVote: Bool
///
///     var body: some View {
///         if canVote {
///             VoteButton()
///         } else {
///             Text("Not eligible to vote")
///         }
///     }
/// }
/// ```
///
/// ## Topics
///
/// ### Creating Specifications
/// - ``isSatisfiedBy(_:)``
///
/// ### Composition
/// - ``and(_:)``
/// - ``or(_:)``
/// - ``not()``
///
/// ### Built-in Specifications
/// - ``PredicateSpec``
/// - ``CooldownIntervalSpec``
/// - ``MaxCountSpec``
/// - ``FeatureFlagSpec``
///
/// - Important: Always ensure specifications are thread-safe when used in concurrent environments.
/// - Note: Specifications should be stateless and deterministic for consistent behavior.
/// - Warning: Avoid heavy computations in `isSatisfiedBy(_:)` as it may be called frequently.
public protocol Specification<T> {
    /// The type of context that this specification evaluates.
    associatedtype T

    /**
     * Evaluates whether the given context satisfies this specification.
     *
     * This method contains the core business logic of the specification. It should
     * be idempotent and thread-safe, returning the same result for the same context.
     *
     * - Parameter candidate: The context to evaluate against this specification.
     * - Returns: `true` if the context satisfies the specification, `false` otherwise.
     *
     * ## Example
     *
     * ```swift
     * struct MinimumBalanceSpec: Specification {
     *     let minimumBalance: Decimal
     *
     *     func isSatisfiedBy(_ account: Account) -> Bool {
     *         return account.balance >= minimumBalance
     *     }
     * }
     *
     * let spec = MinimumBalanceSpec(minimumBalance: 100.0)
     * let hasMinimumBalance = spec.isSatisfiedBy(userAccount)
     * ```
     */
    func isSatisfiedBy(_ candidate: T) -> Bool
}

/// Extension providing default implementations for logical operations on specifications.
///
/// These methods enable composition of specifications using boolean logic, allowing you to
/// build complex business rules from simple, focused specifications.
extension Specification {

    /**
     * Creates a new specification that represents the logical AND of this specification and another.
     *
     * The resulting specification is satisfied only when both the current specification
     * and the provided specification are satisfied by the same context.
     *
     * - Parameter other: The specification to combine with this one using AND logic.
     * - Returns: A new specification that is satisfied only when both specifications are satisfied.
     *
     * ## Example
     *
     * ```swift
     * let adultSpec = UserAgeSpec(minimumAge: 18)
     * let citizenSpec = UserCitizenshipSpec(country: .usa)
     * let eligibleVoterSpec = adultSpec.and(citizenSpec)
     *
     * let canVote = eligibleVoterSpec.isSatisfiedBy(user)
     * // Returns true only if user is both adult AND citizen
     * ```
     */
    public func and<Other: Specification>(_ other: Other) -> AndSpecification<Self, Other>
    where Other.T == T {
        AndSpecification(left: self, right: other)
    }

    /**
     * Creates a new specification that represents the logical OR of this specification and another.
     *
     * The resulting specification is satisfied when either the current specification
     * or the provided specification (or both) are satisfied by the context.
     *
     * - Parameter other: The specification to combine with this one using OR logic.
     * - Returns: A new specification that is satisfied when either specification is satisfied.
     *
     * ## Example
     *
     * ```swift
     * let weekendSpec = IsWeekendSpec()
     * let holidaySpec = IsHolidaySpec()
     * let nonWorkingDaySpec = weekendSpec.or(holidaySpec)
     *
     * let isOffDay = nonWorkingDaySpec.isSatisfiedBy(date)
     * // Returns true if date is weekend OR holiday
     * ```
     */
    public func or<Other: Specification>(_ other: Other) -> OrSpecification<Self, Other>
    where Other.T == T {
        OrSpecification(left: self, right: other)
    }

    /**
     * Creates a new specification that represents the logical NOT of this specification.
     *
     * The resulting specification is satisfied when the current specification
     * is NOT satisfied by the context.
     *
     * - Returns: A new specification that is satisfied when this specification is not satisfied.
     *
     * ## Example
     *
     * ```swift
     * let workingDaySpec = IsWorkingDaySpec()
     * let nonWorkingDaySpec = workingDaySpec.not()
     *
     * let isOffDay = nonWorkingDaySpec.isSatisfiedBy(date)
     * // Returns true if date is NOT a working day
     * ```
     */
    public func not() -> NotSpecification<Self> {
        NotSpecification(wrapped: self)
    }
}

// MARK: - Composite Specifications

/// A specification that combines two specifications with AND logic.
///
/// This specification is satisfied only when both the left and right specifications
/// are satisfied by the same context. It provides short-circuit evaluation,
/// meaning if the left specification fails, the right specification is not evaluated.
///
/// ## Example
///
/// ```swift
/// let ageSpec = UserAgeSpec(minimumAge: 18)
/// let citizenshipSpec = UserCitizenshipSpec(country: .usa)
/// let combinedSpec = AndSpecification(left: ageSpec, right: citizenshipSpec)
///
/// // Alternatively, use the convenience method:
/// let combinedSpec = ageSpec.and(citizenshipSpec)
/// ```
///
/// - Note: Prefer using the ``Specification/and(_:)`` method for better readability.
public struct AndSpecification<Left: Specification, Right: Specification>: Specification
where Left.T == Right.T {
    /// The context type that both specifications evaluate.
    public typealias T = Left.T

    private let left: Left
    private let right: Right

    internal init(left: Left, right: Right) {
        self.left = left
        self.right = right
    }

    /**
     * Evaluates whether both specifications are satisfied by the context.
     *
     * - Parameter candidate: The context to evaluate.
     * - Returns: `true` if both specifications are satisfied, `false` otherwise.
     */
    public func isSatisfiedBy(_ candidate: T) -> Bool {
        left.isSatisfiedBy(candidate) && right.isSatisfiedBy(candidate)
    }
}

/// A specification that combines two specifications with OR logic.
///
/// This specification is satisfied when either the left or right specification
/// (or both) are satisfied by the context. It provides short-circuit evaluation,
/// meaning if the left specification succeeds, the right specification is not evaluated.
///
/// ## Example
///
/// ```swift
/// let weekendSpec = IsWeekendSpec()
/// let holidaySpec = IsHolidaySpec()
/// let combinedSpec = OrSpecification(left: weekendSpec, right: holidaySpec)
///
/// // Alternatively, use the convenience method:
/// let combinedSpec = weekendSpec.or(holidaySpec)
/// ```
///
/// - Note: Prefer using the ``Specification/or(_:)`` method for better readability.
public struct OrSpecification<Left: Specification, Right: Specification>: Specification
where Left.T == Right.T {
    /// The context type that both specifications evaluate.
    public typealias T = Left.T

    private let left: Left
    private let right: Right

    internal init(left: Left, right: Right) {
        self.left = left
        self.right = right
    }

    /**
     * Evaluates whether either specification is satisfied by the context.
     *
     * - Parameter candidate: The context to evaluate.
     * - Returns: `true` if either specification is satisfied, `false` otherwise.
     */
    public func isSatisfiedBy(_ candidate: T) -> Bool {
        left.isSatisfiedBy(candidate) || right.isSatisfiedBy(candidate)
    }
}

/// A specification that negates another specification.
///
/// This specification is satisfied when the wrapped specification is NOT satisfied
/// by the context, effectively inverting the boolean result.
///
/// ## Example
///
/// ```swift
/// let workingDaySpec = IsWorkingDaySpec()
/// let notWorkingDaySpec = NotSpecification(wrapped: workingDaySpec)
///
/// // Alternatively, use the convenience method:
/// let notWorkingDaySpec = workingDaySpec.not()
/// ```
///
/// - Note: Prefer using the ``Specification/not()`` method for better readability.
public struct NotSpecification<Wrapped: Specification>: Specification {
    /// The context type that the wrapped specification evaluates.
    public typealias T = Wrapped.T

    private let wrapped: Wrapped

    internal init(wrapped: Wrapped) {
        self.wrapped = wrapped
    }

    /**
     * Evaluates whether the wrapped specification is NOT satisfied by the context.
     *
     * - Parameter candidate: The context to evaluate.
     * - Returns: `true` if the wrapped specification is NOT satisfied, `false` otherwise.
     */
    public func isSatisfiedBy(_ candidate: T) -> Bool {
        !wrapped.isSatisfiedBy(candidate)
    }
}
