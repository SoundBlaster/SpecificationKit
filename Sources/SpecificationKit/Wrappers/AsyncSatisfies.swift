import Foundation

/// A property wrapper for asynchronously evaluating specifications with async context providers.
///
/// `@AsyncSatisfies` is designed for scenarios where specification evaluation requires
/// asynchronous operations, such as network requests, database queries, or file I/O.
/// Unlike `@Satisfies`, this wrapper doesn't provide automatic evaluation but instead
/// requires explicit async evaluation via the projected value.
///
/// ## Key Features
///
/// - **Async Context Support**: Works with context providers that provide async context
/// - **Lazy Evaluation**: Only evaluates when explicitly requested via projected value
/// - **Error Handling**: Supports throwing async operations
/// - **Flexible Specs**: Works with both sync and async specifications
/// - **No Auto-Update**: Doesn't automatically refresh; requires manual evaluation
///
/// ## Usage Examples
///
/// ### Basic Async Evaluation
/// ```swift
/// @AsyncSatisfies(provider: networkProvider, using: RemoteFeatureFlagSpec(flagKey: "premium"))
/// var hasPremiumAccess: Bool?
///
/// // Evaluate asynchronously when needed
/// func checkPremiumAccess() async {
///     do {
///         let hasAccess = try await $hasPremiumAccess.evaluate()
///         if hasAccess {
///             showPremiumFeatures()
///         }
///     } catch {
///         handleNetworkError(error)
///     }
/// }
/// ```
///
/// ### Database Query Specification
/// ```swift
/// struct DatabaseUserSpec: AsyncSpecification {
///     typealias T = DatabaseContext
///
///     func isSatisfiedBy(_ context: DatabaseContext) async throws -> Bool {
///         let user = try await context.database.fetchUser(context.userId)
///         return user.isActive && user.hasValidSubscription
///     }
/// }
///
/// @AsyncSatisfies(provider: databaseProvider, using: DatabaseUserSpec())
/// var isValidUser: Bool?
///
/// // Use in async context
/// let isValid = try await $isValidUser.evaluate()
/// ```
///
/// ### Network-Based Feature Flags
/// ```swift
/// struct RemoteConfigSpec: AsyncSpecification {
///     typealias T = NetworkContext
///     let featureKey: String
///
///     func isSatisfiedBy(_ context: NetworkContext) async throws -> Bool {
///         let config = try await context.apiClient.fetchRemoteConfig()
///         return config.features[featureKey] == true
///     }
/// }
///
/// @AsyncSatisfies(
///     provider: networkContextProvider,
///     using: RemoteConfigSpec(featureKey: "new_ui_enabled")
/// )
/// var shouldShowNewUI: Bool?
///
/// // Evaluate with timeout and error handling
/// func updateUIBasedOnRemoteConfig() async {
///     do {
///         let enabled = try await withTimeout(seconds: 5) {
///             try await $shouldShowNewUI.evaluate()
///         }
///
///         if enabled {
///             switchToNewUI()
///         }
///     } catch {
///         // Fall back to local configuration or default behavior
///         useDefaultUI()
///     }
/// }
/// ```
///
/// ### Custom Async Predicate
/// ```swift
/// @AsyncSatisfies(provider: apiProvider, predicate: { context in
///     let userProfile = try await context.apiClient.fetchUserProfile()
///     let billingInfo = try await context.apiClient.fetchBillingInfo()
///
///     return userProfile.isVerified && billingInfo.isGoodStanding
/// })
/// var isEligibleUser: Bool?
///
/// // Usage in SwiftUI with Task
/// struct ContentView: View {
///     @AsyncSatisfies(provider: apiProvider, using: EligibilitySpec())
///     var isEligible: Bool?
///
///     @State private var eligibilityStatus: Bool?
///
///     var body: some View {
///         VStack {
///             if let status = eligibilityStatus {
///                 Text(status ? "Eligible" : "Not Eligible")
///             } else {
///                 ProgressView("Checking eligibility...")
///             }
///         }
///         .task {
///             eligibilityStatus = try? await $isEligible.evaluate()
///         }
///     }
/// }
/// ```
///
/// ### Combining with Regular Specifications
/// ```swift
/// // Use regular (synchronous) specifications with async wrapper
/// @AsyncSatisfies(using: MaxCountSpec(counterKey: "api_calls", maximumCount: 100))
/// var canMakeAPICall: Bool?
///
/// // This will use async context fetching but sync specification evaluation
/// let allowed = try await $canMakeAPICall.evaluate()
/// ```
///
/// ## Important Notes
///
/// - **No Automatic Updates**: Unlike `@Satisfies` or `@ObservedSatisfies`, this wrapper doesn't automatically update
/// - **Manual Evaluation**: Always use `$propertyName.evaluate()` to get current results
/// - **Error Propagation**: Any errors from context provider or specification are propagated to caller
/// - **Context Caching**: Context is fetched fresh on each evaluation call
/// - **Thread Safety**: Safe to call from any thread, but context provider should handle thread safety
///
/// ## Performance Considerations
///
/// - Context is fetched on every `evaluate()` call - consider caching at the provider level
/// - Async specifications may have network or I/O overhead
/// - Consider using timeouts for network-based specifications
/// - Use appropriate error handling and fallback mechanisms
@propertyWrapper
public struct AsyncSatisfies<Context> {
    private let asyncContextFactory: () async throws -> Context
    private let asyncSpec: AnyAsyncSpecification<Context>

    /// Last known value (not automatically refreshed).
    /// Always returns `nil` since async evaluation is required.
    private var lastValue: Bool? = nil

    /// The wrapped value is always `nil` for async specifications.
    /// Use the projected value's `evaluate()` method to get the actual result.
    public var wrappedValue: Bool? { lastValue }

    /// Provides async evaluation capabilities for the specification.
    public struct Projection {
        private let evaluator: () async throws -> Bool

        fileprivate init(_ evaluator: @escaping () async throws -> Bool) {
            self.evaluator = evaluator
        }

        /// Evaluates the specification asynchronously and returns the result.
        /// - Returns: `true` if the specification is satisfied, `false` otherwise
        /// - Throws: Any error that occurs during context fetching or specification evaluation
        public func evaluate() async throws -> Bool {
            try await evaluator()
        }
    }

    /// The projected value providing access to async evaluation methods.
    /// Use `$propertyName.evaluate()` to evaluate the specification asynchronously.
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
