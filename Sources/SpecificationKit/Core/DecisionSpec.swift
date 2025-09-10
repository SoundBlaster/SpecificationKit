//
//  DecisionSpec.swift
//  SpecificationKit
//
//  Created by SpecificationKit on 2024.
//

import Foundation

/// A protocol for specifications that can return a typed result instead of just a boolean.
/// This extends the specification pattern to support decision-making with payload results.
public protocol DecisionSpec {
    /// The type of context this specification evaluates
    associatedtype Context

    /// The type of result this specification produces
    associatedtype Result

    /// Evaluates the specification and produces a result if the specification is satisfied
    /// - Parameter context: The context to evaluate against
    /// - Returns: A result if the specification is satisfied, or `nil` otherwise
    func decide(_ context: Context) -> Result?
}

// MARK: - Boolean Specification Bridge

/// Extension to allow any boolean Specification to be used where a DecisionSpec is expected
extension Specification {

    /// Creates a DecisionSpec that returns the given result when this specification is satisfied
    /// - Parameter result: The result to return when the specification is satisfied
    /// - Returns: A DecisionSpec that returns the given result when this specification is satisfied
    public func returning<Result>(_ result: Result) -> BooleanDecisionAdapter<Self, Result> {
        BooleanDecisionAdapter(specification: self, result: result)
    }
}

/// An adapter that converts a boolean Specification into a DecisionSpec
public struct BooleanDecisionAdapter<S: Specification, R>: DecisionSpec {
    public typealias Context = S.T
    public typealias Result = R

    private let specification: S
    private let result: R

    /// Creates a new adapter that wraps a boolean specification
    /// - Parameters:
    ///   - specification: The boolean specification to adapt
    ///   - result: The result to return when the specification is satisfied
    public init(specification: S, result: R) {
        self.specification = specification
        self.result = result
    }

    public func decide(_ context: Context) -> Result? {
        specification.isSatisfiedBy(context) ? result : nil
    }
}

// MARK: - Type Erasure

/// A type-erased DecisionSpec that can wrap any concrete DecisionSpec implementation
public struct AnyDecisionSpec<Context, Result>: DecisionSpec {
    private let _decide: (Context) -> Result?

    /// Creates a type-erased decision specification
    /// - Parameter decide: The decision function
    public init(_ decide: @escaping (Context) -> Result?) {
        self._decide = decide
    }

    /// Creates a type-erased decision specification wrapping a concrete implementation
    /// - Parameter spec: The concrete decision specification to wrap
    public init<S: DecisionSpec>(_ spec: S) where S.Context == Context, S.Result == Result {
        self._decide = spec.decide
    }

    public func decide(_ context: Context) -> Result? {
        _decide(context)
    }
}

// MARK: - Predicate DecisionSpec

/// A DecisionSpec that uses a predicate function and result
public struct PredicateDecisionSpec<Context, Result>: DecisionSpec {
    private let predicate: (Context) -> Bool
    private let result: Result

    /// Creates a new PredicateDecisionSpec with the given predicate and result
    /// - Parameters:
    ///   - predicate: A function that determines if the specification is satisfied
    ///   - result: The result to return if the predicate returns true
    public init(predicate: @escaping (Context) -> Bool, result: Result) {
        self.predicate = predicate
        self.result = result
    }

    public func decide(_ context: Context) -> Result? {
        predicate(context) ? result : nil
    }
}
