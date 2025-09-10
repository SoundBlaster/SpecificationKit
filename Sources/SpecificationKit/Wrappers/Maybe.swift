//
//  Maybe.swift
//  SpecificationKit
//
//  Created by SpecificationKit on 2024.
//

import Foundation

/// A property wrapper that evaluates decision specifications and returns an optional result.
///
/// `@Maybe` is the optional counterpart to `@Decides`. It evaluates decision specifications
/// and returns the result if a specification is satisfied, or `nil` if no specification matches.
/// This is useful when you want to handle the "no match" case explicitly without providing a fallback.
///
/// ## Key Features
///
/// - **Optional Results**: Returns `nil` when no specification matches
/// - **Priority-Based**: Uses `FirstMatchSpec` internally for prioritized rules
/// - **Type-Safe**: Generic over both context and result types
/// - **No Fallback Required**: Unlike `@Decides`, no default value is needed
///
/// ## Usage Examples
///
/// ### Optional Feature Selection
/// ```swift
/// @Maybe([
///     (PremiumUserSpec(), "premium_theme"),
///     (BetaUserSpec(), "experimental_theme"),
///     (HolidaySeasonSpec(), "holiday_theme")
/// ])
/// var specialTheme: String?
///
/// if let theme = specialTheme {
///     applyTheme(theme)
/// } else {
///     useDefaultTheme()
/// }
/// ```
///
/// ### Conditional Discounts
/// ```swift
/// @Maybe([
///     (FirstTimeUserSpec(), 0.20),      // 20% for new users
///     (VIPMemberSpec(), 0.15),          // 15% for VIP
///     (FlashSaleSpec(), 0.10)           // 10% during flash sale
/// ])
/// var discount: Double?
///
/// let finalPrice = originalPrice * (1.0 - (discount ?? 0.0))
/// ```
///
/// ### Optional Content Routing
/// ```swift
/// @Maybe([
///     (ABTestVariantASpec(), "variant_a_content"),
///     (ABTestVariantBSpec(), "variant_b_content")
/// ])
/// var experimentContent: String?
///
/// let content = experimentContent ?? standardContent
/// ```
///
/// ### Custom Decision Logic
/// ```swift
/// @Maybe(decide: { context in
///     let score = context.counter(for: "engagement_score")
///     guard score > 0 else { return nil }
///
///     switch score {
///     case 90...100: return "gold_badge"
///     case 70...89: return "silver_badge"
///     case 50...69: return "bronze_badge"
///     default: return nil
///     }
/// })
/// var achievementBadge: String?
/// ```
///
/// ### Using with DecisionSpec
/// ```swift
/// let personalizationSpec = FirstMatchSpec([
///     (UserPreferenceSpec(theme: .dark), "dark_mode_content"),
///     (TimeOfDaySpec(after: 18), "evening_content"),
///     (WeatherConditionSpec(.rainy), "cozy_content")
/// ])
///
/// @Maybe(using: personalizationSpec)
/// var personalizedContent: String?
/// ```
///
/// ## Comparison with @Decides
///
/// ```swift
/// // @Maybe - returns nil when no match
/// @Maybe([(PremiumUserSpec(), "premium")])
/// var optionalFeature: String? // Can be nil
///
/// // @Decides - always returns a value with fallback
/// @Decides([(PremiumUserSpec(), "premium")], or: "standard")
/// var guaranteedFeature: String // Never nil
/// ```
@propertyWrapper
public struct Maybe<Context, Result> {
    private let contextFactory: () -> Context
    private let specification: AnyDecisionSpec<Context, Result>

    /// The optional result of the decision specification.
    /// Returns the result if a specification is satisfied, `nil` otherwise.
    public var wrappedValue: Result? {
        let context = contextFactory()
        return specification.decide(context)
    }

    /// The projected value, identical to `wrappedValue` for Maybe.
    /// Both provide the same optional result.
    public var projectedValue: Result? {
        let context = contextFactory()
        return specification.decide(context)
    }

    public init<Provider: ContextProviding, S: DecisionSpec>(
        provider: Provider,
        using specification: S
    ) where Provider.Context == Context, S.Context == Context, S.Result == Result {
        self.contextFactory = provider.currentContext
        self.specification = AnyDecisionSpec(specification)
    }

    public init<Provider: ContextProviding, S: Specification>(
        provider: Provider,
        firstMatch pairs: [(S, Result)]
    ) where Provider.Context == Context, S.T == Context {
        self.contextFactory = provider.currentContext
        self.specification = AnyDecisionSpec(FirstMatchSpec(pairs))
    }

    public init<Provider: ContextProviding>(
        provider: Provider,
        decide: @escaping (Context) -> Result?
    ) where Provider.Context == Context {
        self.contextFactory = provider.currentContext
        self.specification = AnyDecisionSpec(decide)
    }
}

// MARK: - EvaluationContext conveniences

extension Maybe where Context == EvaluationContext {
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

// MARK: - Builder Pattern Support (optional results)

extension Maybe {
    public static func builder<Provider: ContextProviding>(
        provider: Provider
    ) -> MaybeBuilder<Context, Result> where Provider.Context == Context {
        MaybeBuilder(provider: provider)
    }
}

public struct MaybeBuilder<Context, Result> {
    private let contextFactory: () -> Context
    private var builder = FirstMatchSpec<Context, Result>.builder()

    internal init<Provider: ContextProviding>(provider: Provider)
    where Provider.Context == Context {
        self.contextFactory = provider.currentContext
    }

    public func with<S: Specification>(_ specification: S, result: Result) -> MaybeBuilder
    where S.T == Context {
        _ = builder.add(specification, result: result)
        return self
    }

    public func with(_ predicate: @escaping (Context) -> Bool, result: Result) -> MaybeBuilder {
        _ = builder.add(predicate, result: result)
        return self
    }

    public func build() -> Maybe<Context, Result> {
        Maybe(provider: GenericContextProvider(contextFactory), using: builder.build())
    }
}

@available(*, deprecated, message: "Use MaybeBuilder instead")
public typealias DecidesBuilder<Context, Result> = MaybeBuilder<Context, Result>
