//
//  DecidesOr.swift
//  SpecificationKit
//
//  A non-optional variant of Decides that always returns a value
//  by requiring a fallback.
//

import Foundation

@propertyWrapper
public struct DecidesOr<Context, Result> {
    private let contextFactory: () -> Context
    private let specification: AnyDecisionSpec<Context, Result>
    private let fallback: Result

    public var wrappedValue: Result {
        let context = contextFactory()
        return specification.decide(context) ?? fallback
    }

    public var projectedValue: Result? {
        let context = contextFactory()
        return specification.decide(context)
    }

    // MARK: - Designated initializers

    public init<Provider: ContextProviding, S: DecisionSpec>(
        provider: Provider,
        using specification: S,
        fallback: Result
    ) where Provider.Context == Context, S.Context == Context, S.Result == Result {
        self.contextFactory = provider.currentContext
        self.specification = AnyDecisionSpec(specification)
        self.fallback = fallback
    }

    public init<Provider: ContextProviding, S: Specification>(
        provider: Provider,
        firstMatch pairs: [(S, Result)],
        fallback: Result
    ) where Provider.Context == Context, S.T == Context {
        self.contextFactory = provider.currentContext
        self.specification = AnyDecisionSpec(FirstMatchSpec.withFallback(pairs, fallback: fallback))
        self.fallback = fallback
    }

    public init<Provider: ContextProviding>(
        provider: Provider,
        decide: @escaping (Context) -> Result?,
        fallback: Result
    ) where Provider.Context == Context {
        self.contextFactory = provider.currentContext
        self.specification = AnyDecisionSpec(decide)
        self.fallback = fallback
    }
}

// MARK: - EvaluationContext conveniences

extension DecidesOr where Context == EvaluationContext {
    public init<S: DecisionSpec>(using specification: S, fallback: Result)
    where S.Context == EvaluationContext, S.Result == Result {
        self.init(provider: DefaultContextProvider.shared, using: specification, fallback: fallback)
    }

    public init<S: Specification>(_ pairs: [(S, Result)], fallback: Result)
    where S.T == EvaluationContext {
        self.init(provider: DefaultContextProvider.shared, firstMatch: pairs, fallback: fallback)
    }

    public init(decide: @escaping (EvaluationContext) -> Result?, fallback: Result) {
        self.init(provider: DefaultContextProvider.shared, decide: decide, fallback: fallback)
    }

    public init(
        build: (FirstMatchSpec<EvaluationContext, Result>.Builder<EvaluationContext, Result>) ->
            FirstMatchSpec<EvaluationContext, Result>.Builder<EvaluationContext, Result>,
        fallback: Result
    ) {
        let builder = FirstMatchSpec<EvaluationContext, Result>.builder()
        let spec = build(builder).fallback(fallback).build()
        self.init(using: spec, fallback: fallback)
    }

    public init(_ specification: FirstMatchSpec<Context, Result>, fallback: Result) {
        self.init(provider: DefaultContextProvider.shared, using: specification, fallback: fallback)
    }

    // MARK: - Default value (wrappedValue) conveniences

    public init(wrappedValue defaultValue: Result, _ specification: FirstMatchSpec<Context, Result>) {
        self.init(provider: DefaultContextProvider.shared, using: specification, fallback: defaultValue)
    }

    public init<S: Specification>(wrappedValue defaultValue: Result, _ pairs: [(S, Result)])
    where S.T == EvaluationContext {
        self.init(provider: DefaultContextProvider.shared, firstMatch: pairs, fallback: defaultValue)
    }

    public init(wrappedValue defaultValue: Result,
                build: (FirstMatchSpec<EvaluationContext, Result>.Builder<EvaluationContext, Result>) ->
                    FirstMatchSpec<EvaluationContext, Result>.Builder<EvaluationContext, Result>) {
        let builder = FirstMatchSpec<EvaluationContext, Result>.builder()
        let spec = build(builder).fallback(defaultValue).build()
        self.init(provider: DefaultContextProvider.shared, using: spec, fallback: defaultValue)
    }

    public init<S: DecisionSpec>(wrappedValue defaultValue: Result, using specification: S)
    where S.Context == EvaluationContext, S.Result == Result {
        self.init(provider: DefaultContextProvider.shared, using: specification, fallback: defaultValue)
    }

    public init(wrappedValue defaultValue: Result, decide: @escaping (EvaluationContext) -> Result?) {
        self.init(provider: DefaultContextProvider.shared, decide: decide, fallback: defaultValue)
    }
}
