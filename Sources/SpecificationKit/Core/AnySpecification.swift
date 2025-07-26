//
//  AnySpecification.swift
//  SpecificationKit
//
//  Created by SpecificationKit on 2024.
//

import Foundation

/// A type-erased wrapper for any specification.
/// This allows you to store specifications of different concrete types in the same collection
/// or use them in contexts where the specific type isn't known at compile time.
public struct AnySpecification<T>: Specification {

    private let _isSatisfiedBy: (T) -> Bool

    /// Creates a type-erased specification wrapping the given specification.
    /// - Parameter specification: The specification to wrap
    public init<S: Specification>(_ specification: S) where S.T == T {
        self._isSatisfiedBy = specification.isSatisfiedBy
    }

    /// Creates a type-erased specification from a closure.
    /// - Parameter predicate: A closure that takes a candidate and returns whether it satisfies the specification
    public init(_ predicate: @escaping (T) -> Bool) {
        self._isSatisfiedBy = predicate
    }

    public func isSatisfiedBy(_ candidate: T) -> Bool {
        _isSatisfiedBy(candidate)
    }
}

// MARK: - Convenience Extensions

extension AnySpecification {

    /// Creates a specification that always returns true
    public static var always: AnySpecification<T> {
        AnySpecification { _ in true }
    }

    /// Creates a specification that always returns false
    public static var never: AnySpecification<T> {
        AnySpecification { _ in false }
    }
}

// MARK: - Collection Extensions

extension Collection where Element: Specification {

    /// Creates a specification that is satisfied when all specifications in the collection are satisfied
    /// - Returns: An AnySpecification that represents the AND of all specifications
    public func allSatisfied() -> AnySpecification<Element.T> {
        AnySpecification { candidate in
            self.allSatisfy { spec in
                spec.isSatisfiedBy(candidate)
            }
        }
    }

    /// Creates a specification that is satisfied when any specification in the collection is satisfied
    /// - Returns: An AnySpecification that represents the OR of all specifications
    public func anySatisfied() -> AnySpecification<Element.T> {
        AnySpecification { candidate in
            self.contains { spec in
                spec.isSatisfiedBy(candidate)
            }
        }
    }
}
