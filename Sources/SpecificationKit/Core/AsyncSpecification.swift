import Foundation

/// A protocol for specifications that require asynchronous evaluation.
///
/// `AsyncSpecification` extends the specification pattern to support async operations
/// such as network requests, database queries, file I/O, or any evaluation that
/// needs to be performed asynchronously. This protocol follows the same pattern
/// as `Specification` but allows for async/await and error handling.
///
/// ## Usage Examples
///
/// ### Network-Based Specification
/// ```swift
/// struct RemoteFeatureFlagSpec: AsyncSpecification {
///     typealias T = EvaluationContext
///
///     let flagKey: String
///     let apiClient: APIClient
///
///     func isSatisfiedBy(_ context: EvaluationContext) async throws -> Bool {
///         let flags = try await apiClient.fetchFeatureFlags(for: context.userId)
///         return flags[flagKey] == true
///     }
/// }
///
/// @AsyncSatisfies(using: RemoteFeatureFlagSpec(flagKey: "premium_features", apiClient: client))
/// var hasPremiumFeatures: Bool
///
/// let isEligible = try await $hasPremiumFeatures.evaluateAsync()
/// ```
///
/// ### Database Query Specification
/// ```swift
/// struct UserSubscriptionSpec: AsyncSpecification {
///     typealias T = EvaluationContext
///
///     let database: Database
///
///     func isSatisfiedBy(_ context: EvaluationContext) async throws -> Bool {
///         let subscription = try await database.fetchSubscription(userId: context.userId)
///         return subscription?.isActive == true && !subscription.isExpired
///     }
/// }
/// ```
///
/// ### Complex Async Logic with Multiple Sources
/// ```swift
/// struct EligibilityCheckSpec: AsyncSpecification {
///     typealias T = EvaluationContext
///
///     let userService: UserService
///     let billingService: BillingService
///
///     func isSatisfiedBy(_ context: EvaluationContext) async throws -> Bool {
///         async let userProfile = userService.fetchProfile(context.userId)
///         async let billingStatus = billingService.checkStatus(context.userId)
///
///         let (profile, billing) = try await (userProfile, billingStatus)
///
///         return profile.isVerified && billing.isGoodStanding
///     }
/// }
/// ```
public protocol AsyncSpecification {
    /// The type of candidate that this specification evaluates
    associatedtype T

    /// Asynchronously determines whether the given candidate satisfies this specification
    /// - Parameter candidate: The candidate to evaluate
    /// - Returns: `true` if the candidate satisfies the specification, `false` otherwise
    /// - Throws: Any error that occurs during evaluation
    func isSatisfiedBy(_ candidate: T) async throws -> Bool
}

/// A type-erased wrapper for any asynchronous specification.
///
/// `AnyAsyncSpecification` allows you to store async specifications of different
/// concrete types in the same collection or use them in contexts where the
/// specific type isn't known at compile time. It also provides bridging from
/// synchronous specifications to async context.
///
/// ## Usage Examples
///
/// ### Type Erasure for Collections
/// ```swift
/// let asyncSpecs: [AnyAsyncSpecification<EvaluationContext>] = [
///     AnyAsyncSpecification(RemoteFeatureFlagSpec(flagKey: "feature_a")),
///     AnyAsyncSpecification(DatabaseUserSpec()),
///     AnyAsyncSpecification(MaxCountSpec(counterKey: "attempts", maximumCount: 3)) // sync spec
/// ]
///
/// for spec in asyncSpecs {
///     let result = try await spec.isSatisfiedBy(context)
///     print("Spec satisfied: \(result)")
/// }
/// ```
///
/// ### Bridging Synchronous Specifications
/// ```swift
/// let syncSpec = MaxCountSpec(counterKey: "login_attempts", maximumCount: 3)
/// let asyncSpec = AnyAsyncSpecification(syncSpec) // Bridge to async
///
/// let isAllowed = try await asyncSpec.isSatisfiedBy(context)
/// ```
///
/// ### Custom Async Logic
/// ```swift
/// let customAsyncSpec = AnyAsyncSpecification<EvaluationContext> { context in
///     // Simulate async network call
///     try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
///     return context.flag(for: "delayed_feature") == true
/// }
/// ```
public struct AnyAsyncSpecification<T>: AsyncSpecification {
    private let _isSatisfied: (T) async throws -> Bool

    /// Creates a type-erased async specification wrapping the given async specification.
    /// - Parameter spec: The async specification to wrap
    public init<S: AsyncSpecification>(_ spec: S) where S.T == T {
        self._isSatisfied = spec.isSatisfiedBy
    }

    /// Creates a type-erased async specification from an async closure.
    /// - Parameter predicate: An async closure that takes a candidate and returns whether it satisfies the specification
    public init(_ predicate: @escaping (T) async throws -> Bool) {
        self._isSatisfied = predicate
    }

    public func isSatisfiedBy(_ candidate: T) async throws -> Bool {
        try await _isSatisfied(candidate)
    }
}

// MARK: - Bridging

extension AnyAsyncSpecification {
    /// Bridge a synchronous specification to async form.
    public init<S: Specification>(_ spec: S) where S.T == T {
        self._isSatisfied = { candidate in spec.isSatisfiedBy(candidate) }
    }
}
