//
//  AnySpecification.swift
//  SpecificationKit
//
//  Created by SpecificationKit on 2024.
//

import Foundation

/// A type-erased wrapper for any specification optimized for performance.
/// This allows you to store specifications of different concrete types in the same collection
/// or use them in contexts where the specific type isn't known at compile time.
///
/// ## Performance Optimizations
///
/// - **@inlinable methods**: Enable compiler optimization across module boundaries
/// - **Specialized storage**: Different storage strategies based on specification type
/// - **Copy-on-write semantics**: Minimize memory allocations
/// - **Thread-safe design**: No internal state requiring synchronization
public struct AnySpecification<T>: Specification {

    // MARK: - Optimized Storage Strategy

    /// Internal storage that uses different strategies based on the specification type
    @usableFromInline
    internal enum Storage {
        case predicate((T) -> Bool)
        case specification(any Specification<T>)
        case constantTrue
        case constantFalse
    }

    @usableFromInline
    internal let storage: Storage

    // MARK: - Initializers

    /// Creates a type-erased specification wrapping the given specification.
    /// - Parameter specification: The specification to wrap
    @inlinable
    public init<S: Specification>(_ specification: S) where S.T == T {
        // Optimize for common patterns
        if specification is AlwaysTrueSpec<T> {
            self.storage = .constantTrue
        } else if specification is AlwaysFalseSpec<T> {
            self.storage = .constantFalse
        } else {
            // Store the specification directly for better performance
            self.storage = .specification(specification)
        }
    }

    /// Creates a type-erased specification from a closure.
    /// - Parameter predicate: A closure that takes a candidate and returns whether it satisfies the specification
    @inlinable
    public init(_ predicate: @escaping (T) -> Bool) {
        self.storage = .predicate(predicate)
    }

    // MARK: - Core Specification Protocol

    @inlinable
    public func isSatisfiedBy(_ candidate: T) -> Bool {
        switch storage {
        case .constantTrue:
            return true
        case .constantFalse:
            return false
        case .predicate(let predicate):
            return predicate(candidate)
        case .specification(let spec):
            return spec.isSatisfiedBy(candidate)
        }
    }
}

// MARK: - Convenience Extensions

extension AnySpecification {

    /// Creates a specification that always returns true
    @inlinable
    public static var always: AnySpecification<T> {
        AnySpecification { _ in true }
    }

    /// Creates a specification that always returns false
    @inlinable
    public static var never: AnySpecification<T> {
        AnySpecification { _ in false }
    }

    /// Creates an optimized constant true specification
    @inlinable
    public static func constantTrue() -> AnySpecification<T> {
        AnySpecification(AlwaysTrueSpec<T>())
    }

    /// Creates an optimized constant false specification
    @inlinable
    public static func constantFalse() -> AnySpecification<T> {
        AnySpecification(AlwaysFalseSpec<T>())
    }
}

// MARK: - Collection Extensions

extension Collection where Element: Specification {

    /// Creates a specification that is satisfied when all specifications in the collection are satisfied
    /// - Returns: An AnySpecification that represents the AND of all specifications
    @inlinable
    public func allSatisfied() -> AnySpecification<Element.T> {
        // Optimize for empty collection
        guard !isEmpty else { return .constantTrue() }

        // Optimize for single element
        if count == 1, let first = first {
            return AnySpecification(first)
        }

        return AnySpecification { candidate in
            self.allSatisfy { spec in
                spec.isSatisfiedBy(candidate)
            }
        }
    }

    /// Creates a specification that is satisfied when any specification in the collection is satisfied
    /// - Returns: An AnySpecification that represents the OR of all specifications
    @inlinable
    public func anySatisfied() -> AnySpecification<Element.T> {
        // Optimize for empty collection
        guard !isEmpty else { return .constantFalse() }

        // Optimize for single element
        if count == 1, let first = first {
            return AnySpecification(first)
        }

        return AnySpecification { candidate in
            self.contains { spec in
                spec.isSatisfiedBy(candidate)
            }
        }
    }
}
