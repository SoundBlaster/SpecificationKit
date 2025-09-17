//
//  Specification.swift
//  SpecificationKit
//
//  Created by SpecificationKit on 2025.
//

import Foundation

/// The core protocol that defines a specification pattern.
/// A specification encapsulates business rules and can be combined with other specifications.
public protocol Specification<T> {
    /// The type of candidate that this specification evaluates
    associatedtype T

    /// Determines whether the given candidate satisfies this specification
    /// - Parameter candidate: The candidate to evaluate
    /// - Returns: `true` if the candidate satisfies the specification, `false` otherwise
    func isSatisfiedBy(_ candidate: T) -> Bool
}

/// Extension providing default implementations for common specification operations
extension Specification {

    /// Creates a new specification that represents the logical AND of this specification and another
    /// - Parameter other: The specification to combine with this one using AND logic
    /// - Returns: A new specification that is satisfied only when both specifications are satisfied
    public func and<Other: Specification>(_ other: Other) -> AndSpecification<Self, Other>
    where Other.T == T {
        AndSpecification(left: self, right: other)
    }

    /// Creates a new specification that represents the logical OR of this specification and another
    /// - Parameter other: The specification to combine with this one using OR logic
    /// - Returns: A new specification that is satisfied when either specification is satisfied
    public func or<Other: Specification>(_ other: Other) -> OrSpecification<Self, Other>
    where Other.T == T {
        OrSpecification(left: self, right: other)
    }

    /// Creates a new specification that represents the logical NOT of this specification
    /// - Returns: A new specification that is satisfied when this specification is not satisfied
    public func not() -> NotSpecification<Self> {
        NotSpecification(wrapped: self)
    }
}

// MARK: - Composite Specifications

/// A specification that combines two specifications with AND logic
public struct AndSpecification<Left: Specification, Right: Specification>: Specification
where Left.T == Right.T {
    public typealias T = Left.T

    private let left: Left
    private let right: Right

    internal init(left: Left, right: Right) {
        self.left = left
        self.right = right
    }

    public func isSatisfiedBy(_ candidate: T) -> Bool {
        left.isSatisfiedBy(candidate) && right.isSatisfiedBy(candidate)
    }
}

/// A specification that combines two specifications with OR logic
public struct OrSpecification<Left: Specification, Right: Specification>: Specification
where Left.T == Right.T {
    public typealias T = Left.T

    private let left: Left
    private let right: Right

    internal init(left: Left, right: Right) {
        self.left = left
        self.right = right
    }

    public func isSatisfiedBy(_ candidate: T) -> Bool {
        left.isSatisfiedBy(candidate) || right.isSatisfiedBy(candidate)
    }
}

/// A specification that negates another specification
public struct NotSpecification<Wrapped: Specification>: Specification {
    public typealias T = Wrapped.T

    private let wrapped: Wrapped

    internal init(wrapped: Wrapped) {
        self.wrapped = wrapped
    }

    public func isSatisfiedBy(_ candidate: T) -> Bool {
        !wrapped.isSatisfiedBy(candidate)
    }
}
