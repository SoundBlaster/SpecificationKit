//
//  CompositeContextProvider.swift
//  SpecificationKit
//
//  Merges multiple EvaluationContext providers using a deterministic strategy.
//

import Foundation

/// A context provider that composes multiple providers and merges their values.
///
/// - Note: This type operates on `EvaluationContext` snapshots. It is UI-agnostic
///   and thread-safe as long as the underlying providers' `currentContext()` are.
///   For reactive updates, use providers that conform to `ContextUpdatesProviding`
///   and forward update signals at a higher level.
public final class CompositeContextProvider: ContextProviding {
    public typealias Context = EvaluationContext

    /// Strategy for merging contexts from multiple providers.
    public enum MergeStrategy {
        /// Earlier providers take precedence; later providers fill missing keys.
        case preferFirst
        /// Later providers override earlier providers on key conflicts.
        case preferLast
        /// Custom merge implementation.
        case custom((_ contexts: [EvaluationContext]) -> EvaluationContext)
    }

    private let providers: [AnyContextProvider<EvaluationContext>]
    private let strategy: MergeStrategy

    /// Creates a composite provider from concrete providers.
    /// - Parameters:
    ///   - providers: Ordered list of providers to compose.
    ///   - strategy: Conflict resolution strategy (default `.preferLast`).
    public init<P: ContextProviding>(
        providers: [P],
        strategy: MergeStrategy = .preferLast
    ) where P.Context == EvaluationContext {
        self.providers = providers.map(AnyContextProvider.init)
        self.strategy = strategy
    }

    /// Creates a composite provider from type-erased providers.
    /// - Parameters:
    ///   - providers: Ordered list of type-erased providers.
    ///   - strategy: Conflict resolution strategy (default `.preferLast`).
    public init(
        providers: [AnyContextProvider<EvaluationContext>],
        strategy: MergeStrategy = .preferLast
    ) {
        precondition(!providers.isEmpty, "CompositeContextProvider requires at least one provider")
        self.providers = providers
        self.strategy = strategy
    }

    public func currentContext() -> EvaluationContext {
        let contexts = providers.map { $0.currentContext() }
        switch strategy {
        case .custom(let merge):
            return merge(contexts)
        case .preferFirst:
            return mergePreferFirst(contexts)
        case .preferLast:
            return mergePreferLast(contexts)
        }
    }

    // MARK: - Merge Implementations

    private func mergePreferLast(_ contexts: [EvaluationContext]) -> EvaluationContext {
        guard var result = contexts.first else { return EvaluationContext() }
        // Start from second context, overriding keys progressively.
        for ctx in contexts.dropFirst() {
            result = EvaluationContext(
                currentDate: Date(),
                launchDate: ctx.launchDate, // later overrides
                userData: result.userData.merging(ctx.userData) { _, rhs in rhs },
                counters: result.counters.merging(ctx.counters) { _, rhs in rhs },
                events: result.events.merging(ctx.events) { _, rhs in rhs },
                flags: result.flags.merging(ctx.flags) { _, rhs in rhs },
                segments: result.segments.union(ctx.segments)
            )
        }
        return result
    }

    private func mergePreferFirst(_ contexts: [EvaluationContext]) -> EvaluationContext {
        guard let first = contexts.first else { return EvaluationContext() }
        var result = first
        for ctx in contexts.dropFirst() {
            result = EvaluationContext(
                currentDate: Date(),
                launchDate: result.launchDate, // keep first
                userData: ctx.userData.merging(result.userData) { _, rhs in rhs },
                counters: ctx.counters.merging(result.counters) { _, rhs in rhs },
                events: ctx.events.merging(result.events) { _, rhs in rhs },
                flags: ctx.flags.merging(result.flags) { _, rhs in rhs },
                segments: result.segments.union(ctx.segments)
            )
        }
        return result
    }
}
