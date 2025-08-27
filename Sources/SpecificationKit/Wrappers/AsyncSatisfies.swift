import Foundation

/// A property wrapper for asynchronously evaluating specifications using a context provider.
///
/// Note: `wrappedValue` is optional and does not auto-update. Use the projected
/// value's `evaluate()` to compute the current value when needed.
@propertyWrapper
public struct AsyncSatisfies<Context> {
    private let asyncContextFactory: () async throws -> Context
    private let asyncSpec: AnyAsyncSpecification<Context>

    /// Last known value (not automatically refreshed).
    private var lastValue: Bool? = nil

    public var wrappedValue: Bool? { lastValue }

    public struct Projection {
        private let evaluator: () async throws -> Bool

        fileprivate init(_ evaluator: @escaping () async throws -> Bool) {
            self.evaluator = evaluator
        }

        /// Evaluates the specification asynchronously and returns the result.
        public func evaluate() async throws -> Bool {
            try await evaluator()
        }
    }

    public var projectedValue: Projection {
        Projection { [asyncContextFactory, asyncSpec] in
            let context = try await asyncContextFactory()
            return try await asyncSpec.isSatisfiedBy(context)
        }
    }

    // MARK: - Initializers

    /// Initialize with a provider and synchronous Specification.
    public init<Provider: ContextProviding, Spec: Specification>(
        provider: Provider,
        using specification: Spec
    ) where Provider.Context == Context, Spec.T == Context {
        self.asyncContextFactory = provider.currentContextAsync
        self.asyncSpec = AnyAsyncSpecification(specification)
    }

    /// Initialize with a provider and a predicate.
    public init<Provider: ContextProviding>(
        provider: Provider,
        predicate: @escaping (Context) -> Bool
    ) where Provider.Context == Context {
        self.asyncContextFactory = provider.currentContextAsync
        self.asyncSpec = AnyAsyncSpecification { candidate in predicate(candidate) }
    }

    /// Initialize with a provider and an asynchronous specification.
    public init<Provider: ContextProviding, Spec: AsyncSpecification>(
        provider: Provider,
        using specification: Spec
    ) where Provider.Context == Context, Spec.T == Context {
        self.asyncContextFactory = provider.currentContextAsync
        self.asyncSpec = AnyAsyncSpecification(specification)
    }
}

