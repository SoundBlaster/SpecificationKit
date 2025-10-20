//
//  Decides.swift
//  SpecificationKit
//
//  Created by SpecificationKit on 2025.
//

import Foundation

/// A property wrapper that evaluates decision specifications and always returns a non-optional result.
///
/// `@Decides` uses a decision-based specification system to determine a result based on business rules.
/// Unlike boolean specifications, decision specifications can return typed results (strings, numbers, enums, etc.).
/// A fallback value is always required to ensure the property always returns a value.
///
/// ## Key Features
///
/// - **Always Non-Optional**: Returns a fallback value when no specification matches
/// - **Priority-Based**: Uses `FirstMatchSpec` internally for prioritized rules
/// - **Type-Safe**: Generic over both context and result types
/// - **Projected Value**: Access the optional result without fallback via `$propertyName`
///
/// ## Usage Examples
///
/// ### Discount Calculation
/// ```swift
/// @Decides([
///     (PremiumMemberSpec(), 25.0),      // 25% discount for premium
///     (LoyalCustomerSpec(), 15.0),      // 15% discount for loyal customers
///     (FirstTimeUserSpec(), 10.0),      // 10% discount for first-time users
/// ], or: 0.0)                           // No discount by default
/// var discountPercentage: Double
/// ```
///
/// ### Feature Tier Selection
/// ```swift
/// enum FeatureTier: String {
///     case premium = "premium"
///     case standard = "standard"
///     case basic = "basic"
/// }
///
/// @Decides([
///     (SubscriptionStatusSpec(status: .premium), FeatureTier.premium),
///     (SubscriptionStatusSpec(status: .standard), FeatureTier.standard)
/// ], or: .basic)
/// var userTier: FeatureTier
/// ```
///
/// ### Content Routing with Builder Pattern
/// ```swift
/// @Decides(build: { builder in
///     builder
///         .add(UserSegmentSpec(expectedSegment: .beta), result: "beta_content")
///         .add(FeatureFlagSpec(flagKey: "new_content"), result: "new_content")
///         .add(DateRangeSpec(startDate: campaignStart, endDate: campaignEnd), result: "campaign_content")
/// }, or: "default_content")
/// var contentVariant: String
/// ```
///
/// ### Using DecisionSpec Directly
/// ```swift
/// let routingSpec = FirstMatchSpec([
///     (PremiumUserSpec(), "premium_route"),
///     (MobileUserSpec(), "mobile_route")
/// ])
///
/// @Decides(using: routingSpec, or: "default_route")
/// var navigationRoute: String
/// ```
///
/// ### Custom Decision Logic
/// ```swift
/// @Decides(decide: { context in
///     let score = context.counter(for: "engagement_score")
///     switch score {
///     case 80...100: return "high_engagement"
///     case 50...79: return "medium_engagement"
///     case 20...49: return "low_engagement"
///     default: return nil // Will use fallback
///     }
/// }, or: "no_engagement")
/// var engagementLevel: String
/// ```
///
/// ## Projected Value Access
///
/// The projected value (`$propertyName`) gives you access to the optional result without the fallback:
///
/// ```swift
/// @Decides([(PremiumUserSpec(), "premium")], or: "standard")
/// var userType: String
///
/// // Regular access returns fallback if no match
/// print(userType) // "premium" or "standard"
///
/// // Projected value is optional, nil if no specification matched
/// if let actualMatch = $userType {
///     print("Specification matched with: \(actualMatch)")
/// } else {
///     print("No specification matched, using fallback")
/// }
/// ```
@propertyWrapper
public struct Decides<Context, Result> {
    private let contextFactory: () -> Context
    private let specification: AnyDecisionSpec<Context, Result>
    private let fallback: Result

    /// The evaluated result of the decision specification, with fallback if no specification matches.
    public var wrappedValue: Result {
        let context = contextFactory()
        return specification.decide(context) ?? fallback
    }

    /// The optional result of the decision specification without fallback.
    /// Returns `nil` if no specification was satisfied.
    public var projectedValue: Result? {
        let context = contextFactory()
        return specification.decide(context)
    }

    // MARK: - Designated initializers

    public init<Provider: ContextProviding, S: DecisionSpec>(
        provider: Provider,
        using specification: S,
        fallback: Result
    ) where Provider.Context == Context, S.Context == Context, S.Result == Result {
        self.contextFactory = provider.currentContext
        self.specification = AnyDecisionSpec(specification)
        self.fallback = fallback
    }

    public init<Provider: ContextProviding, S: Specification>(
        provider: Provider,
        firstMatch pairs: [(S, Result)],
        fallback: Result
    ) where Provider.Context == Context, S.T == Context {
        self.contextFactory = provider.currentContext
        self.specification = AnyDecisionSpec(FirstMatchSpec.withFallback(pairs, fallback: fallback))
        self.fallback = fallback
    }

    public init<Provider: ContextProviding>(
        provider: Provider,
        decide: @escaping (Context) -> Result?,
        fallback: Result
    ) where Provider.Context == Context {
        self.contextFactory = provider.currentContext
        self.specification = AnyDecisionSpec(decide)
        self.fallback = fallback
    }
}

// MARK: - EvaluationContext conveniences

extension Decides where Context == EvaluationContext {
    public init<S: DecisionSpec>(using specification: S, fallback: Result)
    where S.Context == EvaluationContext, S.Result == Result {
        self.init(provider: DefaultContextProvider.shared, using: specification, fallback: fallback)
    }

    public init<S: DecisionSpec>(using specification: S, or fallback: Result)
    where S.Context == EvaluationContext, S.Result == Result {
        self.init(provider: DefaultContextProvider.shared, using: specification, fallback: fallback)
    }

    public init<S: Specification>(_ pairs: [(S, Result)], fallback: Result)
    where S.T == EvaluationContext {
        self.init(provider: DefaultContextProvider.shared, firstMatch: pairs, fallback: fallback)
    }

    public init<S: Specification>(_ pairs: [(S, Result)], or fallback: Result)
    where S.T == EvaluationContext {
        self.init(provider: DefaultContextProvider.shared, firstMatch: pairs, fallback: fallback)
    }

    public init(decide: @escaping (EvaluationContext) -> Result?, fallback: Result) {
        self.init(provider: DefaultContextProvider.shared, decide: decide, fallback: fallback)
    }

    public init(decide: @escaping (EvaluationContext) -> Result?, or fallback: Result) {
        self.init(provider: DefaultContextProvider.shared, decide: decide, fallback: fallback)
    }

    public init(
        build: (FirstMatchSpec<EvaluationContext, Result>.Builder<EvaluationContext, Result>) ->
            FirstMatchSpec<EvaluationContext, Result>.Builder<EvaluationContext, Result>,
        fallback: Result
    ) {
        let builder = FirstMatchSpec<EvaluationContext, Result>.builder()
        let spec = build(builder).fallback(fallback).build()
        self.init(using: spec, fallback: fallback)
    }

    public init(
        build: (FirstMatchSpec<EvaluationContext, Result>.Builder<EvaluationContext, Result>) ->
            FirstMatchSpec<EvaluationContext, Result>.Builder<EvaluationContext, Result>,
        or fallback: Result
    ) {
        self.init(build: build, fallback: fallback)
    }

    public init(_ specification: FirstMatchSpec<Context, Result>, fallback: Result) {
        self.init(provider: DefaultContextProvider.shared, using: specification, fallback: fallback)
    }

    public init(_ specification: FirstMatchSpec<Context, Result>, or fallback: Result) {
        self.init(provider: DefaultContextProvider.shared, using: specification, fallback: fallback)
    }

    // MARK: - Default value (wrappedValue) conveniences

    public init(wrappedValue defaultValue: Result, _ specification: FirstMatchSpec<Context, Result>)
    {
        self.init(
            provider: DefaultContextProvider.shared, using: specification, fallback: defaultValue)
    }

    public init<S: Specification>(wrappedValue defaultValue: Result, _ pairs: [(S, Result)])
    where S.T == EvaluationContext {
        self.init(
            provider: DefaultContextProvider.shared, firstMatch: pairs, fallback: defaultValue)
    }

    public init(
        wrappedValue defaultValue: Result,
        build: (FirstMatchSpec<EvaluationContext, Result>.Builder<EvaluationContext, Result>) ->
            FirstMatchSpec<EvaluationContext, Result>.Builder<EvaluationContext, Result>
    ) {
        let builder = FirstMatchSpec<EvaluationContext, Result>.builder()
        let spec = build(builder).fallback(defaultValue).build()
        self.init(provider: DefaultContextProvider.shared, using: spec, fallback: defaultValue)
    }

    public init<S: DecisionSpec>(wrappedValue defaultValue: Result, using specification: S)
    where S.Context == EvaluationContext, S.Result == Result {
        self.init(
            provider: DefaultContextProvider.shared, using: specification, fallback: defaultValue)
    }

    public init(wrappedValue defaultValue: Result, decide: @escaping (EvaluationContext) -> Result?)
    {
        self.init(provider: DefaultContextProvider.shared, decide: decide, fallback: defaultValue)
    }
}
