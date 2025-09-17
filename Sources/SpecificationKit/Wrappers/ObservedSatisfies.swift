//
//  ObservedSatisfies.swift
//  SpecificationKit
//
//  Created by SpecificationKit on 2025.
//

#if canImport(SwiftUI)
    import SwiftUI
    #if canImport(Combine)
        import Combine
    #endif

    /// A SwiftUI-reactive property wrapper that evaluates specifications and automatically updates when context changes.
    ///
    /// `@ObservedSatisfies` is specifically designed for SwiftUI applications where you need specification
    /// evaluation to trigger view updates automatically. It observes changes from context providers
    /// that conform to `ContextUpdatesProviding` and re-evaluates specifications when the context changes.
    ///
    /// ## Key Features
    ///
    /// - **SwiftUI Integration**: Conforms to `DynamicProperty` for automatic view updates
    /// - **Reactive Updates**: Automatically re-evaluates when context provider publishes changes
    /// - **Combine Support**: Uses Combine publishers for efficient change propagation
    /// - **Fallback Support**: Works even without Combine, using `@State` as fallback
    /// - **Binding Support**: Provides read-only `Binding` access via projected value
    ///
    /// ## Usage Examples
    ///
    /// ### Basic SwiftUI Integration
    /// ```swift
    /// struct ContentView: View {
    ///     @ObservedSatisfies(using: MaxCountSpec(counterKey: "banner_shown", maximumCount: 3))
    ///     var shouldShowBanner: Bool
    ///
    ///     var body: some View {
    ///         VStack {
    ///             if shouldShowBanner {
    ///                 PromoBannerView()
    ///                     .onTapGesture {
    ///                         DefaultContextProvider.shared.incrementCounter("banner_shown")
    ///                         // View will automatically update when counter changes
    ///                     }
    ///             }
    ///             MainContentView()
    ///         }
    ///     }
    /// }
    /// ```
    ///
    /// ### Live Feature Flags
    /// ```swift
    /// struct SettingsView: View {
    ///     @ObservedSatisfies(using: FeatureFlagSpec(flagKey: "dark_mode_toggle"))
    ///     var showDarkModeToggle: Bool
    ///
    ///     var body: some View {
    ///         Form {
    ///             if showDarkModeToggle {
    ///                 Toggle("Dark Mode", isOn: $darkModeEnabled)
    ///             }
    ///             // Other settings...
    ///         }
    ///     }
    /// }
    /// ```
    ///
    /// ### Dynamic Content with Multiple Specs
    /// ```swift
    /// @specs(
    ///     UserSegmentSpec(expectedSegment: .premium),
    ///     FeatureFlagSpec(flagKey: "premium_content_enabled"),
    ///     DateRangeSpec(startDate: campaignStart, endDate: campaignEnd)
    /// )
    /// @AutoContext
    /// struct PremiumContentSpec: Specification {
    ///     typealias T = EvaluationContext
    /// }
    ///
    /// struct HomeView: View {
    ///     @ObservedSatisfies(using: PremiumContentSpec.self)
    ///     var showPremiumContent: Bool
    ///
    ///     var body: some View {
    ///         ScrollView {
    ///             if showPremiumContent {
    ///                 PremiumContentSection()
    ///             }
    ///             StandardContentSection()
    ///         }
    ///     }
    /// }
    /// ```
    ///
    /// ### Custom Predicate with Live Updates
    /// ```swift
    /// struct NotificationBadge: View {
    ///     @ObservedSatisfies(predicate: { context in
    ///         context.counter(for: "unread_messages") > 0
    ///     })
    ///     var hasUnreadMessages: Bool
    ///
    ///     var body: some View {
    ///         TabView {
    ///             MessagesView()
    ///                 .tabItem {
    ///                     Image(systemName: hasUnreadMessages ? "message.fill" : "message")
    ///                     Text("Messages")
    ///                 }
    ///                 .badge(hasUnreadMessages ? context.counter(for: "unread_messages") : nil)
    ///         }
    ///     }
    /// }
    /// ```
    ///
    /// ### Using with Environment Context Provider
    /// ```swift
    /// struct App: View {
    ///     @StateObject private var environmentProvider = EnvironmentContextProvider()
    ///
    ///     var body: some View {
    ///         ContentView()
    ///             .environmentObject(environmentProvider)
    ///     }
    /// }
    ///
    /// struct ContentView: View {
    ///     @EnvironmentObject var contextProvider: EnvironmentContextProvider
    ///
    ///     @ObservedSatisfies(provider: contextProvider, using: FeatureFlagSpec(flagKey: "new_feature"))
    ///     var isNewFeatureEnabled: Bool
    ///
    ///     var body: some View {
    ///         VStack {
    ///             if isNewFeatureEnabled {
    ///                 NewFeatureView()
    ///             } else {
    ///                 StandardView()
    ///             }
    ///         }
    ///     }
    /// }
    /// ```
    ///
    /// ## Context Provider Requirements
    ///
    /// For automatic updates to work, your context provider should conform to `ContextUpdatesProviding`:
    ///
    /// ```swift
    /// extension DefaultContextProvider: ContextUpdatesProviding {
    ///     public var contextUpdates: AnyPublisher<Void, Never> {
    ///         objectWillChange.eraseToAnyPublisher()
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
                    cancellable =
                        updates
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
        public init<Spec: Specification>(using specification: Spec)
        where Spec.T == EvaluationContext {
            self.init(provider: DefaultContextProvider.shared, using: specification)
        }

        public init(predicate: @escaping (EvaluationContext) -> Bool) {
            self.init(provider: DefaultContextProvider.shared, predicate: predicate)
        }
    }

#endif
