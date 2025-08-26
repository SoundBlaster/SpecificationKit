//
//  Decides.swift
//  SpecificationKit
//
//  Created by SpecificationKit on 2024.
//

import Foundation

/// A property wrapper that applies a decision specification using a context provider.
/// This enables declarative specification usage for decision-oriented specifications.
@propertyWrapper
public struct Decides<Context, Result> {

    private let contextProvider: any ContextProviding
    private let specification: AnyDecisionSpec<Context, Result>

    /// The wrapped value representing the result of the decision specification
    public var wrappedValue: Result {
        let context = contextProvider.currentContext() as! Context
        guard let result = specification.decide(context) else {
            fatalError(
                "No result was returned from the decision specification. Consider using a fallback."
            )
        }
        return result
    }

    /// The projected value providing optional access to the result
    public var projectedValue: Result? {
        let context = contextProvider.currentContext() as! Context
        return specification.decide(context)
    }

    /// Creates a Decides property wrapper with a context provider and decision specification
    /// - Parameters:
    ///   - provider: The context provider to use for evaluation
    ///   - specification: The decision specification to evaluate
    public init<Provider: ContextProviding, S: DecisionSpec>(
        provider: Provider,
        using specification: S
    ) where Provider.Context == Context, S.Context == Context, S.Result == Result {
        self.contextProvider = provider
        self.specification = AnyDecisionSpec(specification)
    }

    /// Creates a Decides property wrapper with a context provider and first match specification
    /// - Parameters:
    ///   - provider: The context provider to use for evaluation
    ///   - pairs: The specification-result pairs to use in a FirstMatchSpec
    public init<Provider: ContextProviding, S: Specification>(
        provider: Provider,
        firstMatch pairs: [(S, Result)]
    ) where Provider.Context == Context, S.T == Context {
        self.contextProvider = provider
        self.specification = AnyDecisionSpec(FirstMatchSpec(pairs))
    }

    /// Creates a Decides property wrapper with a closure-based decision
    /// - Parameters:
    ///   - provider: The context provider to use for evaluation
    ///   - decide: A closure that takes a context and returns an optional result
    public init<Provider: ContextProviding>(
        provider: Provider,
        decide: @escaping (Context) -> Result?
    ) where Provider.Context == Context {
        self.contextProvider = provider
        self.specification = AnyDecisionSpec(decide)
    }
}

// MARK: - FirstMatchSpec Support

// (Note) Default provider shorthands are defined for EvaluationContext below.

// MARK: - EvaluationContext Convenience

extension Decides where Context == EvaluationContext {

    /// Creates a Decides property wrapper using the shared default context provider
    /// - Parameter specification: The decision specification to evaluate
    public init<S: DecisionSpec>(using specification: S)
    where S.Context == EvaluationContext, S.Result == Result {
        self.init(provider: DefaultContextProvider.shared, using: specification)
    }

    /// Creates a Decides property wrapper with a FirstMatchSpec using the shared default context provider
    /// - Parameter pairs: The specification-result pairs to use in a FirstMatchSpec
    public init<S: Specification>(_ pairs: [(S, Result)]) where S.T == EvaluationContext {
        self.init(provider: DefaultContextProvider.shared, firstMatch: pairs)
    }

    /// Creates a Decides property wrapper with a decide closure using the shared default context provider
    /// - Parameter decide: A closure that takes an EvaluationContext and returns an optional result
    public init(decide: @escaping (EvaluationContext) -> Result?) {
        self.init(provider: DefaultContextProvider.shared, decide: decide)
    }

    /// Creates a Decides property wrapper that returns a static result regardless of context
    /// - Parameter staticResult: The result to always return
    public init(staticResult: Result) {
        self.init(decide: { _ in staticResult })
    }

    /// Creates a Decides property wrapper with a FirstMatchSpec builder
    /// - Parameter build: A closure that configures a FirstMatchSpec builder
    public init(
        build: (FirstMatchSpec<EvaluationContext, Result>.Builder<EvaluationContext, Result>) ->
            FirstMatchSpec<EvaluationContext, Result>.Builder<EvaluationContext, Result>
    ) {
        let builder = FirstMatchSpec<EvaluationContext, Result>.builder()
        let spec = build(builder).build()
        self.init(using: spec)
    }

    /// Creates a Decides property wrapper with a FirstMatchSpec
    /// - Parameter specification: The FirstMatchSpec to evaluate
    public init(_ specification: FirstMatchSpec<Context, Result>) {
        self.init(
            provider: DefaultContextProvider.shared,
            using: specification)
    }

    /// Creates a Decides property wrapper with a FirstMatchSpec that has a fallback
    /// - Parameters:
    ///   - pairs: The specification-result pairs to evaluate in order
    ///   - fallback: The fallback result to return if no specification is satisfied
    public init<S: Specification>(
        _ pairs: [(S, Result)],
        fallback: Result
    ) where S.T == EvaluationContext {
        self.init(
            provider: DefaultContextProvider.shared,
            using: FirstMatchSpec.withFallback(pairs, fallback: fallback))
    }
}

// MARK: - Builder Pattern Support

extension Decides {

    /// Creates a builder for constructing complex specifications
    /// - Parameter provider: The context provider to use
    /// - Returns: A DecidesBuilder for fluent composition
    public static func builder<Provider: ContextProviding>(
        provider: Provider
    ) -> DecidesBuilder<Context, Result> where Provider.Context == Context {
        DecidesBuilder(provider: provider)
    }
}

/// A builder for creating complex Decides property wrappers using a fluent interface
public struct DecidesBuilder<Context, Result> {
    private let contextFactory: () -> Context
    private var builder = FirstMatchSpec<Context, Result>.builder()

    internal init<Provider: ContextProviding>(provider: Provider)
    where Provider.Context == Context {
        self.contextFactory = provider.currentContext
    }

    /// Adds a specification-result pair to the builder
    /// - Parameters:
    ///   - specification: The specification to evaluate
    ///   - result: The result to return if the specification is satisfied
    /// - Returns: Self for method chaining
    public func with<S: Specification>(_ specification: S, result: Result) -> DecidesBuilder
    where S.T == Context {
        _ = builder.add(specification, result: result)
        return self
    }

    /// Adds a predicate-result pair to the builder
    /// - Parameters:
    ///   - predicate: The predicate to evaluate
    ///   - result: The result to return if the predicate returns true
    /// - Returns: Self for method chaining
    public func with(_ predicate: @escaping (Context) -> Bool, result: Result) -> DecidesBuilder {
        _ = builder.add(predicate, result: result)
        return self
    }

    /// Adds a fallback result to return if no other specification is satisfied
    /// - Parameter fallback: The fallback result
    /// - Returns: Self for method chaining
    public func fallback(_ fallback: Result) -> DecidesBuilder {
        _ = builder.fallback(fallback)
        return self
    }

    /// Builds a Decides property wrapper with the configured pairs
    /// - Returns: A Decides property wrapper
    public func build() -> Decides<Context, Result> {
        Decides(provider: GenericContextProvider(contextFactory), using: builder.build())
    }
}
