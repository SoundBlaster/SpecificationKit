//
//  ObservedMaybe.swift
//  SpecificationKit
//
//  Created by SpecificationKit on 2025.
//

#if canImport(SwiftUI)
import SwiftUI
#if canImport(Combine)
import Combine
#endif

/// A SwiftUI-reactive property wrapper that evaluates decision specifications and updates when context changes.
///
/// `@ObservedMaybe` mirrors `@Maybe` but integrates with SwiftUI. It observes context providers
/// that conform to `ContextUpdatesProviding` and re-evaluates the decision specification on updates.
/// The wrapped value is optional and becomes `nil` when no rule matches.
@propertyWrapper
public struct ObservedMaybe<Context, Result>: DynamicProperty {

    // MARK: - Evaluation plumbing
    private let contextFactory: () -> Context
    private let specification: AnyDecisionSpec<Context, Result>

    #if canImport(Combine)
    private let updates: AnyPublisher<Void, Never>?

    final class Observer: ObservableObject {
        @Published var value: Result?
        var cancellable: AnyCancellable?
        func wire(updates: AnyPublisher<Void, Never>?, evaluate: @escaping () -> Result?) {
            // Compute immediately
            let v = evaluate()
            self.value = v
            guard cancellable == nil, let updates else { return }
            cancellable = updates
                .receive(on: DispatchQueue.main)
                .sink { [weak self] in
                    guard let self else { return }
                    let v2 = evaluate()
                    self.value = v2
                }
            }
        }

    @ObservedObject private var observer: Observer
    #else
    @State private var value: Result?
    #endif

    // MARK: - DynamicProperty outputs
    public var wrappedValue: Result? {
        #if canImport(Combine)
        observer.value
        #else
        value
        #endif
    }

    /// Read-only binding to the optional result.
    public var projectedValue: Binding<Result?> {
        #if canImport(Combine)
        Binding(get: { observer.value }, set: { _ in })
        #else
        Binding(get: { value }, set: { _ in })
        #endif
    }

    // MARK: - Initializers

    /// Designated initializer with a decision specification.
    public init<Provider: ContextProviding, S: DecisionSpec>(
        provider: Provider,
        using specification: S
    ) where Provider.Context == Context, S.Context == Context, S.Result == Result {
        self.contextFactory = provider.currentContext
        self.specification = AnyDecisionSpec(specification)
        #if canImport(Combine)
        if let p = provider as? ContextUpdatesProviding {
            self.updates = p.contextUpdates
        } else {
            self.updates = nil
        }
        self._observer = ObservedObject(wrappedValue: Observer())
        #else
        self._value = State(initialValue: nil)
        #endif
    }

    /// Convenience initializer using FirstMatch pairs.
    public init<Provider: ContextProviding, S: Specification>(
        provider: Provider,
        firstMatch pairs: [(S, Result)]
    ) where Provider.Context == Context, S.T == Context {
        self.contextFactory = provider.currentContext
        self.specification = AnyDecisionSpec(FirstMatchSpec(pairs))
        #if canImport(Combine)
        if let p = provider as? ContextUpdatesProviding {
            self.updates = p.contextUpdates
        } else {
            self.updates = nil
        }
        self._observer = ObservedObject(wrappedValue: Observer())
        #else
        self._value = State(initialValue: nil)
        #endif
    }

    /// Convenience initializer using a decision closure.
    public init<Provider: ContextProviding>(
        provider: Provider,
        decide: @escaping (Context) -> Result?
    ) where Provider.Context == Context {
        self.contextFactory = provider.currentContext
        self.specification = AnyDecisionSpec(decide)
        #if canImport(Combine)
        if let p = provider as? ContextUpdatesProviding {
            self.updates = p.contextUpdates
        } else {
            self.updates = nil
        }
        self._observer = ObservedObject(wrappedValue: Observer())
        #else
        self._value = State(initialValue: nil)
        #endif
    }

    // MARK: - SwiftUI lifecycle
    public mutating func update() {
        #if canImport(Combine)
        let localUpdates = updates
        let spec = specification
        let ctxFactory = contextFactory
        observer.wire(updates: localUpdates, evaluate: { spec.decide(ctxFactory()) })
        #else
        let newValue = specification.decide(contextFactory())
        value = newValue
        #endif
    }
}

// MARK: - EvaluationContext conveniences
extension ObservedMaybe where Context == EvaluationContext {

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

#endif
