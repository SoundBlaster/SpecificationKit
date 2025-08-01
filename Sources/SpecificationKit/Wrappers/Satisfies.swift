//
//  Satisfies.swift
//  SpecificationKit
//
//  Created by SpecificationKit on 2024.
//

import Foundation

/// A property wrapper that applies a specification using a context provider.
/// This enables declarative specification usage throughout your application.
@propertyWrapper
public struct Satisfies<Context> {

    private let contextProvider: any ContextProviding
    private let specification: AnySpecification<Context>

    /// The wrapped value representing whether the specification is satisfied
    public var wrappedValue: Bool {
        let context = contextProvider.currentContext() as! Context
        return specification.isSatisfiedBy(context)
    }

    /// Creates a Satisfies property wrapper with a context provider and specification
    /// - Parameters:
    ///   - provider: The context provider to use for evaluation
    ///   - specification: The specification to evaluate
    public init<Provider: ContextProviding, Spec: Specification>(
        provider: Provider,
        using specification: Spec
    ) where Provider.Context == Context, Spec.T == Context {
        self.contextProvider = provider
        self.specification = AnySpecification(specification)
    }

    /// Creates a Satisfies property wrapper with a context provider and specification type
    /// - Parameters:
    ///   - provider: The context provider to use for evaluation
    ///   - specificationType: The specification type to instantiate and use
    public init<Provider: ContextProviding, Spec: Specification>(
        provider: Provider,
        using specificationType: Spec.Type
    ) where Provider.Context == Context, Spec.T == Context, Spec: ExpressibleByNilLiteral {
        self.contextProvider = provider
        self.specification = AnySpecification(Spec(nilLiteral: ()))
    }

    /// Creates a Satisfies property wrapper with a predicate function
    /// - Parameters:
    ///   - provider: The context provider to use for evaluation
    ///   - predicate: A predicate function that takes the context and returns a Bool
    public init<Provider: ContextProviding>(
        provider: Provider,
        predicate: @escaping (Context) -> Bool
    ) where Provider.Context == Context {
        self.contextProvider = provider
        self.specification = AnySpecification(predicate)
    }
}

// MARK: - AutoContextSpecification Support

/// Protocol for specifications that can provide their own context
public protocol AutoContextSpecification: Specification {
    /// The type of context provider this specification uses
    associatedtype Provider: ContextProviding where Provider.Context == T

    /// The context provider for this specification
    static var contextProvider: Provider { get }

    /// Creates a new instance of this specification
    init()
}

extension Satisfies {

    /// Creates a Satisfies property wrapper using an AutoContextSpecification
    /// - Parameter specificationType: The specification type that provides its own context
    public init<Spec: AutoContextSpecification>(
        using specificationType: Spec.Type
    ) where Spec.T == Context {
        self.contextProvider = specificationType.contextProvider
        self.specification = AnySpecification(specificationType.init())
    }
}

// MARK: - EvaluationContext Convenience

extension Satisfies where Context == EvaluationContext {

    /// Creates a Satisfies property wrapper using the shared default context provider
    /// - Parameter specification: The specification to evaluate
    public init<Spec: Specification>(using specification: Spec) where Spec.T == EvaluationContext {
        self.init(provider: DefaultContextProvider.shared, using: specification)
    }

    /// Creates a Satisfies property wrapper using the shared default context provider
    /// - Parameter specificationType: The specification type to use
    public init<Spec: Specification>(
        using specificationType: Spec.Type
    ) where Spec.T == EvaluationContext, Spec: ExpressibleByNilLiteral {
        self.init(provider: DefaultContextProvider.shared, using: specificationType)
    }

    /// Creates a Satisfies property wrapper with a predicate using the shared default context provider
    /// - Parameter predicate: A predicate function that takes EvaluationContext and returns Bool
    public init(predicate: @escaping (EvaluationContext) -> Bool) {
        self.init(provider: DefaultContextProvider.shared, predicate: predicate)
    }

    /// Creates a Satisfies property wrapper from a simple boolean predicate with no context
    /// - Parameter value: A boolean value or expression
    public init(_ value: Bool) {
        self.init(predicate: { _ in value })
    }

    /// Creates a Satisfies property wrapper that combines multiple specifications with AND logic
    /// - Parameter specifications: The specifications to combine
    public init(allOf specifications: [AnySpecification<EvaluationContext>]) {
        self.init(predicate: { context in
            specifications.allSatisfy { spec in spec.isSatisfiedBy(context) }
        })
    }

    /// Creates a Satisfies property wrapper that combines multiple specifications with OR logic
    /// - Parameter specifications: The specifications to combine
    public init(anyOf specifications: [AnySpecification<EvaluationContext>]) {
        self.init(predicate: { context in
            specifications.contains { spec in spec.isSatisfiedBy(context) }
        })
    }
}

// MARK: - Builder Pattern Support

extension Satisfies {

    /// Creates a builder for constructing complex specifications
    /// - Parameter provider: The context provider to use
    /// - Returns: A SatisfiesBuilder for fluent composition
    public static func builder<Provider: ContextProviding>(
        provider: Provider
    ) -> SatisfiesBuilder<Context> where Provider.Context == Context {
        SatisfiesBuilder(provider: provider)
    }
}

/// A builder for creating complex Satisfies property wrappers using a fluent interface
public struct SatisfiesBuilder<Context> {
    private let contextFactory: () -> Context
    private var specifications: [AnySpecification<Context>] = []

    internal init<Provider: ContextProviding>(provider: Provider)
    where Provider.Context == Context {
        self.contextFactory = provider.currentContext
    }

    /// Adds a specification to the builder
    /// - Parameter spec: The specification to add
    /// - Returns: Self for method chaining
    public func with<S: Specification>(_ spec: S) -> SatisfiesBuilder<Context>
    where S.T == Context {
        var builder = self
        builder.specifications.append(AnySpecification(spec))
        return builder
    }

    /// Adds a predicate specification to the builder
    /// - Parameter predicate: The predicate function
    /// - Returns: Self for method chaining
    public func with(_ predicate: @escaping (Context) -> Bool) -> SatisfiesBuilder<Context> {
        var builder = self
        builder.specifications.append(AnySpecification(predicate))
        return builder
    }

    /// Builds a Satisfies property wrapper that requires all specifications to be satisfied
    /// - Returns: A Satisfies property wrapper using AND logic
    public func buildAll() -> Satisfies<Context> {
        Satisfies(
            provider: GenericContextProvider(contextFactory),
            predicate: { context in
                specifications.allSatisfy { spec in
                    spec.isSatisfiedBy(context)
                }
            }
        )
    }

    /// Builds a Satisfies property wrapper that requires any specification to be satisfied
    /// - Returns: A Satisfies property wrapper using OR logic
    public func buildAny() -> Satisfies<Context> {
        Satisfies(
            provider: GenericContextProvider(contextFactory),
            predicate: { context in
                specifications.contains { spec in
                    spec.isSatisfiedBy(context)
                }
            }
        )
    }
}

// MARK: - Convenience Extensions for Common Patterns

extension Satisfies where Context == EvaluationContext {

    /// Creates a specification for time-based conditions
    /// - Parameter minimumSeconds: Minimum seconds since launch
    /// - Returns: A Satisfies wrapper for launch time checking
    public static func timeSinceLaunch(minimumSeconds: TimeInterval) -> Satisfies<EvaluationContext>
    {
        Satisfies(predicate: { context in
            context.timeSinceLaunch >= minimumSeconds
        })
    }

    /// Creates a specification for counter-based conditions
    /// - Parameters:
    ///   - counterKey: The counter key to check
    ///   - maximum: The maximum allowed value (exclusive)
    /// - Returns: A Satisfies wrapper for counter checking
    public static func counter(_ counterKey: String, lessThan maximum: Int) -> Satisfies<
        EvaluationContext
    > {
        Satisfies(predicate: { context in
            context.counter(for: counterKey) < maximum
        })
    }

    /// Creates a specification for flag-based conditions
    /// - Parameters:
    ///   - flagKey: The flag key to check
    ///   - expectedValue: The expected flag value
    /// - Returns: A Satisfies wrapper for flag checking
    public static func flag(_ flagKey: String, equals expectedValue: Bool = true) -> Satisfies<
        EvaluationContext
    > {
        Satisfies(predicate: { context in
            context.flag(for: flagKey) == expectedValue
        })
    }

    /// Creates a specification for cooldown-based conditions
    /// - Parameters:
    ///   - eventKey: The event key to check
    ///   - minimumInterval: The minimum time that must have passed
    /// - Returns: A Satisfies wrapper for cooldown checking
    public static func cooldown(_ eventKey: String, minimumInterval: TimeInterval) -> Satisfies<
        EvaluationContext
    > {
        Satisfies(predicate: { context in
            guard let lastEvent = context.event(for: eventKey) else { return true }
            return context.currentDate.timeIntervalSince(lastEvent) >= minimumInterval
        })
    }
}
