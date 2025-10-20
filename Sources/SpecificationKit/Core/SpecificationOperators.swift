//
//  SpecificationOperators.swift
//  SpecificationKit
//
//  Created by SpecificationKit on 2025.
//

import Foundation

// MARK: - Custom Operators

infix operator && : LogicalConjunctionPrecedence
infix operator || : LogicalDisjunctionPrecedence
prefix operator !

// MARK: - Operator Implementations

/// Logical AND operator for specifications
/// - Parameters:
///   - left: The left specification
///   - right: The right specification
/// - Returns: A specification that is satisfied when both specifications are satisfied
public func && <Left: Specification, Right: Specification>(
    left: Left,
    right: Right
) -> AndSpecification<Left, Right> where Left.T == Right.T {
    left.and(right)
}

/// Logical OR operator for specifications
/// - Parameters:
///   - left: The left specification
///   - right: The right specification
/// - Returns: A specification that is satisfied when either specification is satisfied
public func || <Left: Specification, Right: Specification>(
    left: Left,
    right: Right
) -> OrSpecification<Left, Right> where Left.T == Right.T {
    left.or(right)
}

/// Logical NOT operator for specifications
/// - Parameter specification: The specification to negate
/// - Returns: A specification that is satisfied when the input specification is not satisfied
public prefix func ! <S: Specification>(specification: S) -> NotSpecification<S> {
    specification.not()
}

// MARK: - Convenience Functions

/// Creates a specification from a predicate function
/// - Parameter predicate: A function that takes a candidate and returns a Boolean
/// - Returns: An AnySpecification wrapping the predicate
public func spec<T>(_ predicate: @escaping (T) -> Bool) -> AnySpecification<T> {
    AnySpecification(predicate)
}

/// Creates a specification that always returns true
/// - Returns: A specification that is always satisfied
public func alwaysTrue<T>() -> AnySpecification<T> {
    .always
}

/// Creates a specification that always returns false
/// - Returns: A specification that is never satisfied
public func alwaysFalse<T>() -> AnySpecification<T> {
    .never
}

// MARK: - Builder Pattern Support

/// A builder for creating complex specifications using a fluent interface
public struct SpecificationBuilder<T> {
    private let specification: AnySpecification<T>

    internal init(_ specification: AnySpecification<T>) {
        self.specification = specification
    }

    /// Adds an AND condition to the specification
    /// - Parameter other: The specification to combine with AND logic
    /// - Returns: A new builder with the combined specification
    public func and<S: Specification>(_ other: S) -> SpecificationBuilder<T> where S.T == T {
        SpecificationBuilder(AnySpecification(specification.and(other)))
    }

    /// Adds an OR condition to the specification
    /// - Parameter other: The specification to combine with OR logic
    /// - Returns: A new builder with the combined specification
    public func or<S: Specification>(_ other: S) -> SpecificationBuilder<T> where S.T == T {
        SpecificationBuilder(AnySpecification(specification.or(other)))
    }

    /// Negates the current specification
    /// - Returns: A new builder with the negated specification
    public func not() -> SpecificationBuilder<T> {
        SpecificationBuilder(AnySpecification(specification.not()))
    }

    /// Builds the final specification
    /// - Returns: The constructed AnySpecification
    public func build() -> AnySpecification<T> {
        specification
    }
}

/// Creates a specification builder starting with the given specification
/// - Parameter specification: The initial specification
/// - Returns: A SpecificationBuilder for fluent composition
public func build<S: Specification>(_ specification: S) -> SpecificationBuilder<S.T> {
    SpecificationBuilder(AnySpecification(specification))
}

/// Creates a specification builder starting with a predicate
/// - Parameter predicate: The initial predicate function
/// - Returns: A SpecificationBuilder for fluent composition
public func build<T>(_ predicate: @escaping (T) -> Bool) -> SpecificationBuilder<T> {
    SpecificationBuilder(AnySpecification(predicate))
}
