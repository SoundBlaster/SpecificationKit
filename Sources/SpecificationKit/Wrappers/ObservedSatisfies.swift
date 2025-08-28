//
//  ObservedSatisfies.swift
//  SpecificationKit
//
//  A SwiftUI-friendly variant of @Satisfies that auto-updates when the
//  underlying context provider publishes changes.
//

#if canImport(SwiftUI)
import SwiftUI
#if canImport(Combine)
import Combine
#endif

@propertyWrapper
public struct ObservedSatisfies<Context>: DynamicProperty {

    // Evaluation plumbing
    private let contextFactory: () -> Context
    private let specification: AnySpecification<Context>

    #if canImport(Combine)
    private let updates: AnyPublisher<Void, Never>?

    final class Observer: ObservableObject {
        @Published var value: Bool = false
        var cancellable: AnyCancellable?
        func wire(updates: AnyPublisher<Void, Never>?, evaluate: @escaping () -> Bool) {
            // compute immediately
            let v = evaluate()
            if v != value { value = v }
            guard cancellable == nil, let updates else { return }
            cancellable = updates
                .receive(on: DispatchQueue.main)
                .sink { [weak self] in
                    guard let self else { return }
                    let v2 = evaluate()
                    if v2 != self.value { self.value = v2 }
                }
        }
    }

    @ObservedObject private var observer: Observer
    #else
    @State private var value: Bool = false
    #endif

    public var wrappedValue: Bool {
        #if canImport(Combine)
        observer.value
        #else
        value
        #endif
    }

    public var projectedValue: Binding<Bool> {
        #if canImport(Combine)
        Binding(get: { observer.value }, set: { _ in })
        #else
        Binding(get: { value }, set: { _ in })
        #endif
    }

    // MARK: - Initializers

    public init<Provider: ContextProviding, Spec: Specification>(
        provider: Provider,
        using specification: Spec
    ) where Provider.Context == Context, Spec.T == Context {
        self.contextFactory = provider.currentContext
        self.specification = AnySpecification(specification)
        #if canImport(Combine)
        if let p = provider as? ContextUpdatesProviding {
            self.updates = p.contextUpdates
        } else {
            self.updates = nil
        }
        self._observer = ObservedObject(wrappedValue: Observer())
        #endif
    }

    public init<Provider: ContextProviding>(
        provider: Provider,
        predicate: @escaping (Context) -> Bool
    ) where Provider.Context == Context {
        self.contextFactory = provider.currentContext
        self.specification = AnySpecification { ctx in predicate(ctx) }
        #if canImport(Combine)
        if let p = provider as? ContextUpdatesProviding {
            self.updates = p.contextUpdates
        } else {
            self.updates = nil
        }
        self._observer = ObservedObject(wrappedValue: Observer())
        #endif
    }

    // MARK: - SwiftUI lifecycle
    public mutating func update() {
        #if canImport(Combine)
        let localUpdates = updates
        let spec = specification
        let ctxFactory = contextFactory
        observer.wire(updates: localUpdates, evaluate: { spec.isSatisfiedBy(ctxFactory()) })
        #else
        let newValue = specification.isSatisfiedBy(contextFactory())
        if newValue != value { value = newValue }
        #endif
    }
}

// MARK: - EvaluationContext conveniences
extension ObservedSatisfies where Context == EvaluationContext {
    public init<Spec: Specification>(using specification: Spec) where Spec.T == EvaluationContext {
        self.init(provider: DefaultContextProvider.shared, using: specification)
    }

    public init(predicate: @escaping (EvaluationContext) -> Bool) {
        self.init(provider: DefaultContextProvider.shared, predicate: predicate)
    }
}

#endif
