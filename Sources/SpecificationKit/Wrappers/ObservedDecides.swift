//
//  ObservedDecides.swift
//  SpecificationKit
//
//  Created by SpecificationKit on 2025.
//

#if canImport(SwiftUI)
    import SwiftUI
    #if canImport(Combine)
        import Combine
    #endif

    /// A SwiftUI-reactive property wrapper that evaluates decision specifications and automatically updates when context changes.
    ///
    /// `@ObservedDecides` combines the decision-making power of `@Decides` with SwiftUI reactivity.
    /// It evaluates decision specifications to return typed results and automatically triggers view updates
    /// when the underlying context changes. Unlike `@Decides`, this wrapper is specifically designed for
    /// SwiftUI applications where decision results need to trigger UI updates.
    ///
    /// ## Key Features
    ///
    /// - **SwiftUI Integration**: Conforms to `DynamicProperty` for automatic view updates
    /// - **Reactive Updates**: Automatically re-evaluates when context provider publishes changes
    /// - **Always Non-Optional**: Returns a fallback value when no specification matches
    /// - **Priority-Based**: Uses `FirstMatchSpec` internally for prioritized rules
    /// - **Combine Support**: Uses Combine publishers for efficient change propagation
    /// - **Projected Value**: Access the optional result without fallback and reactive publisher
    ///
    /// ## Usage Examples
    ///
    /// ### Dynamic User Interface Adaptation
    /// ```swift
    /// struct AdaptiveContentView: View {
    ///     @ObservedDecides([
    ///         (PremiumUserSpec(), "premium_layout"),
    ///         (TabletDeviceSpec(), "tablet_layout"),
    ///         (CompactSizeSpec(), "mobile_layout")
    ///     ], or: "default_layout")
    ///     var layoutType: String
    ///
    ///     var body: some View {
    ///         Group {
    ///             switch layoutType {
    ///             case "premium_layout": PremiumContentView()
    ///             case "tablet_layout": TabletContentView()
    ///             case "mobile_layout": MobileContentView()
    ///             default: DefaultContentView()
    ///             }
    ///         }
    ///         .onReceive($layoutType) { newLayout in
    ///             // React to layout changes
    ///             analyticsService.trackLayoutChange(newLayout)
    ///         }
    ///     }
    /// }
    /// ```
    ///
    /// ### Live Feature Tier Management
    /// ```swift
    /// enum FeatureTier: String, CaseIterable {
    ///     case premium = "premium"
    ///     case standard = "standard"
    ///     case basic = "basic"
    /// }
    ///
    /// struct SubscriptionView: View {
    ///     @ObservedDecides([
    ///         (ActiveSubscriptionSpec(tier: .premium), FeatureTier.premium),
    ///         (ActiveSubscriptionSpec(tier: .standard), FeatureTier.standard)
    ///     ], or: .basic)
    ///     var currentTier: FeatureTier
    ///
    ///     var body: some View {
    ///         VStack {
    ///             Text("Current Plan: \(currentTier.rawValue.capitalized)")
    ///                 .font(.headline)
    ///
    ///             // Features available for current tier
    ///             FeatureListView(tier: currentTier)
    ///
    ///             // Upgrade options
    ///             if currentTier != .premium {
    ///                 UpgradePromptView(currentTier: currentTier)
    ///             }
    ///         }
    ///     }
    /// }
    /// ```
    ///
    /// ## Performance Considerations
    ///
    /// - Updates are delivered on the main queue to ensure UI thread safety
    /// - Only re-evaluates specifications when context actually changes
    /// - Uses weak references to prevent retain cycles
    /// - Efficiently batches multiple rapid context changes
    /// - Decision specifications are evaluated in priority order and stop at first match
    @propertyWrapper
    public struct ObservedDecides<Context, Result>: DynamicProperty where Result: Equatable {

        // Evaluation plumbing
        private let contextFactory: () -> Context
        private let specification: AnyDecisionSpec<Context, Result>
        private let fallback: Result

        #if canImport(Combine)
            private let updates: AnyPublisher<Void, Never>?

            @MainActor
            final class DecisionObserver<C, R>: ObservableObject where R: Equatable {
                @Published var currentValue: R

                private let specification: AnyDecisionSpec<C, R>
                private let fallback: R
                private let contextFactory: () -> C
                private var cancellable: AnyCancellable?

                init(
                    specification: AnyDecisionSpec<C, R>,
                    fallback: R,
                    contextFactory: @escaping () -> C
                ) {
                    self.specification = specification
                    self.fallback = fallback
                    self.contextFactory = contextFactory

                    // Initial evaluation
                    let context = contextFactory()
                    self.currentValue = specification.decide(context) ?? fallback
                }

                func wire(updates: AnyPublisher<Void, Never>?) {
                    guard cancellable == nil, let updates = updates else { return }

                    cancellable =
                        updates
                        .receive(on: DispatchQueue.main)
                        .sink { [weak self] in
                            guard let self = self else { return }
                            let context = self.contextFactory()
                            let newValue = self.specification.decide(context) ?? self.fallback
                            if newValue != self.currentValue {
                                self.currentValue = newValue
                            }
                        }
                }
            }

            @ObservedObject private var observer: DecisionObserver<Context, Result>
        #else
            @State private var value: Result
        #endif

        /// The evaluated result of the decision specification, with fallback if no specification matches.
        public var wrappedValue: Result {
            #if canImport(Combine)
                observer.currentValue
            #else
                value
            #endif
        }

        /// The reactive publisher for the decision result and read-only binding.
        public var projectedValue: ProjectedValue {
            #if canImport(Combine)
                ProjectedValue(
                    publisher: observer.$currentValue.eraseToAnyPublisher(),
                    binding: Binding(get: { self.observer.currentValue }, set: { _ in })
                )
            #else
                ProjectedValue(
                    publisher: Just(value).eraseToAnyPublisher(),
                    binding: Binding(get: { self.value }, set: { _ in })
                )
            #endif
        }

        /// Projected value providing access to the reactive publisher and binding
        public struct ProjectedValue {
            public let publisher: AnyPublisher<Result, Never>
            public let binding: Binding<Result>

            /// Access to the current wrapped value
            public var wrappedValue: Result {
                binding.wrappedValue
            }
        }

        // MARK: - Initializers

        /// Initialize with a decision specification and fallback value
        public init<Provider: ContextProviding, S: DecisionSpec>(
            provider: Provider,
            using specification: S,
            or fallback: Result
        ) where Provider.Context == Context, S.Context == Context, S.Result == Result {
            self.contextFactory = provider.currentContext
            self.specification = AnyDecisionSpec(specification)
            self.fallback = fallback

            #if canImport(Combine)
                if let p = provider as? ContextUpdatesProviding {
                    self.updates = p.contextUpdates
                } else {
                    self.updates = nil
                }
                self._observer = ObservedObject(
                    wrappedValue: DecisionObserver(
                        specification: AnyDecisionSpec(specification),
                        fallback: fallback,
                        contextFactory: provider.currentContext
                    )
                )
            #else
                let context = provider.currentContext()
                self._value = State(
                    initialValue: AnyDecisionSpec(specification).decide(context) ?? fallback)
            #endif
        }

        /// Initialize with specification-result pairs using FirstMatchSpec
        public init<Provider: ContextProviding, S: Specification>(
            provider: Provider,
            decisions: [(S, Result)],
            or fallback: Result
        ) where Provider.Context == Context, S.T == Context {
            let firstMatchSpec = FirstMatchSpec(decisions)
            self.init(provider: provider, using: firstMatchSpec, or: fallback)
        }

        /// Initialize with a custom decision function
        public init<Provider: ContextProviding>(
            provider: Provider,
            decide: @escaping (Context) -> Result?,
            or fallback: Result
        ) where Provider.Context == Context {
            let decisionSpec = AnyDecisionSpec<Context, Result> { context in
                decide(context)
            }
            self.contextFactory = provider.currentContext
            self.specification = decisionSpec
            self.fallback = fallback

            #if canImport(Combine)
                if let p = provider as? ContextUpdatesProviding {
                    self.updates = p.contextUpdates
                } else {
                    self.updates = nil
                }
                self._observer = ObservedObject(
                    wrappedValue: DecisionObserver(
                        specification: decisionSpec,
                        fallback: fallback,
                        contextFactory: provider.currentContext
                    )
                )
            #else
                let context = provider.currentContext()
                self._value = State(initialValue: decide(context) ?? fallback)
            #endif
        }

        // MARK: - SwiftUI lifecycle
        public mutating func update() {
            #if canImport(Combine)
                observer.wire(updates: updates)
            #else
                let context = contextFactory()
                let newValue = specification.decide(context) ?? fallback
                if newValue != value {
                    value = newValue
                }
            #endif
        }
    }

    // MARK: - EvaluationContext conveniences
    extension ObservedDecides where Context == EvaluationContext {
        /// Initialize with a decision specification using default context provider
        public init<S: DecisionSpec>(using specification: S, or fallback: Result)
        where S.Context == EvaluationContext, S.Result == Result {
            self.init(provider: DefaultContextProvider.shared, using: specification, or: fallback)
        }

        /// Initialize with specification-result pairs using default context provider
        public init<S: Specification>(_ decisions: [(S, Result)], or fallback: Result)
        where S.T == EvaluationContext {
            self.init(provider: DefaultContextProvider.shared, decisions: decisions, or: fallback)
        }

        /// Initialize with a custom decision function using default context provider
        public init(decide: @escaping (EvaluationContext) -> Result?, or fallback: Result) {
            self.init(provider: DefaultContextProvider.shared, decide: decide, or: fallback)
        }

        /// Initialize with builder pattern using default context provider
        public init(
            build: (FirstMatchSpec<EvaluationContext, Result>.Builder<EvaluationContext, Result>) ->
                FirstMatchSpec<EvaluationContext, Result>.Builder<EvaluationContext, Result>,
            or fallback: Result
        ) {
            let builder = FirstMatchSpec<EvaluationContext, Result>.builder()
            let spec = build(builder).fallback(fallback).build()
            self.init(provider: DefaultContextProvider.shared, using: spec, or: fallback)
        }
    }

#endif
