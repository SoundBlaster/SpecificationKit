//
//  Maybe.swift
//  SpecificationKit
//

import Foundation

/// Optional decision wrapper. Returns an optional result without crashing when no rule matches.
@propertyWrapper
public struct Maybe<Context, Result> {
    private let contextFactory: () -> Context
    private let specification: AnyDecisionSpec<Context, Result>

    public var wrappedValue: Result? {
        let context = contextFactory()
        return specification.decide(context)
    }

    public var projectedValue: Result? {
        let context = contextFactory()
        return specification.decide(context)
    }

    public init<Provider: ContextProviding, S: DecisionSpec>(
        provider: Provider,
        using specification: S
    ) where Provider.Context == Context, S.Context == Context, S.Result == Result {
        self.contextFactory = provider.currentContext
        self.specification = AnyDecisionSpec(specification)
    }

    public init<Provider: ContextProviding, S: Specification>(
        provider: Provider,
        firstMatch pairs: [(S, Result)]
    ) where Provider.Context == Context, S.T == Context {
        self.contextFactory = provider.currentContext
        self.specification = AnyDecisionSpec(FirstMatchSpec(pairs))
    }

    public init<Provider: ContextProviding>(
        provider: Provider,
        decide: @escaping (Context) -> Result?
    ) where Provider.Context == Context {
        self.contextFactory = provider.currentContext
        self.specification = AnyDecisionSpec(decide)
    }
}

// MARK: - EvaluationContext conveniences

extension Maybe where Context == EvaluationContext {
    public init<S: DecisionSpec>(using specification: S)
    where S.Context == EvaluationContext, S.Result == Result {
        self.init(provider: DefaultContextProvider.shared, using: specification)
    }

    public init<S: Specification>(_ pairs: [(S, Result)]) where S.T == EvaluationContext {
        self.init(provider: DefaultContextProvider.shared, firstMatch: pairs)
    }

    public init(decide: @escaping (EvaluationContext) -> Result?) {
        self.init(provider: DefaultContextProvider.shared, decide: decide)
    }
}

// MARK: - Builder Pattern Support (optional results)

extension Maybe {
    public static func builder<Provider: ContextProviding>(
        provider: Provider
    ) -> MaybeBuilder<Context, Result> where Provider.Context == Context {
        MaybeBuilder(provider: provider)
    }
}

public struct MaybeBuilder<Context, Result> {
    private let contextFactory: () -> Context
    private var builder = FirstMatchSpec<Context, Result>.builder()

    internal init<Provider: ContextProviding>(provider: Provider)
    where Provider.Context == Context {
        self.contextFactory = provider.currentContext
    }

    public func with<S: Specification>(_ specification: S, result: Result) -> MaybeBuilder
    where S.T == Context {
        _ = builder.add(specification, result: result)
        return self
    }

    public func with(_ predicate: @escaping (Context) -> Bool, result: Result) -> MaybeBuilder {
        _ = builder.add(predicate, result: result)
        return self
    }

    public func build() -> Maybe<Context, Result> {
        Maybe(provider: GenericContextProvider(contextFactory), using: builder.build())
    }
}

@available(*, deprecated, message: "Use MaybeBuilder instead")
public typealias DecidesBuilder<Context, Result> = MaybeBuilder<Context, Result>

