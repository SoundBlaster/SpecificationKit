//
//  SpecificationKit.swift
//  SpecificationKit
//
//  Created by SpecificationKit on 2024.
//

import Foundation

/// # SpecificationKit
///
/// A powerful Swift framework that implements the Specification Pattern with modern Swift features
/// including property wrappers, macros, and async/await support.
///
/// ## Overview
///
/// SpecificationKit helps you encapsulate business rules as composable, reusable, and testable specifications.
/// Instead of scattering conditional logic throughout your codebase, you can define clear specifications
/// that express your business intent and combine them as needed.
///
/// ## Key Features
///
/// - **Composable Specifications**: Combine specifications using `.and()`, `.or()`, and `.not()` operators
/// - **Property Wrappers**: Declarative syntax with `@Satisfies`, `@Decides`, and `@Maybe`
/// - **Macro System**: Auto-generate composite specifications with `@specs` and `@AutoContext`
/// - **Async Support**: Full async/await compatibility for modern Swift applications
/// - **Context Providers**: Flexible context injection system with built-in providers
/// - **Type Safety**: Generic specifications with compile-time type checking
///
/// ## Quick Start
///
/// ### Basic Specification Usage
///
/// ```swift
/// import SpecificationKit
///
/// // Define a simple specification
/// let isEligible = MaxCountSpec(counterKey: "promoShown", maximumCount: 3)
///
/// // Use with property wrapper
/// @Satisfies(using: isEligible)
/// var shouldShowPromo: Bool
///
/// // Check the result
/// if shouldShowPromo {
///     showPromoBanner()
/// }
/// ```
///
/// ### Macro-Generated Composite Specifications
///
/// ```swift
/// @specs(
///     MaxCountSpec(counterKey: "promoShown", maximumCount: 3),
///     TimeSinceEventSpec(eventKey: "lastShown", minimumInterval: 24 * 3600)
/// )
/// @AutoContext
/// struct PromoEligibilitySpec: Specification {
///     typealias T = EvaluationContext
/// }
///
/// @Satisfies(using: PromoEligibilitySpec.self)
/// var isEligibleForPromo: Bool
/// ```
///
/// ### Decision Making with Results
///
/// ```swift
/// @Decides([
///     (PremiumUserSpec(), "premium_discount"),
///     (FirstTimeUserSpec(), "welcome_discount"),
///     (RegularUserSpec(), "standard_discount")
/// ], or: "no_discount")
/// var discountType: String
/// ```
///
/// ## Topics
///
/// ### Core Protocols
///
/// - ``Specification``
/// - ``DecisionSpec``
/// - ``AsyncSpecification``
/// - ``ContextProviding``
///
/// ### Type-Erased Wrappers
///
/// - ``AnySpecification``
/// - ``AnyDecisionSpec``
/// - ``AnyAsyncSpecification``
///
/// ### Property Wrappers
///
/// - ``Satisfies``
/// - ``Decides``
/// - ``Maybe``
/// - ``AsyncSatisfies``
/// - ``ObservedSatisfies``
///
/// ### Built-in Specifications
///
/// - ``MaxCountSpec``
/// - ``TimeSinceEventSpec``
/// - ``CooldownIntervalSpec``
/// - ``DateRangeSpec``
/// - ``DateComparisonSpec``
/// - ``FeatureFlagSpec``
/// - ``UserSegmentSpec``
/// - ``SubscriptionStatusSpec``
/// - ``PredicateSpec``
/// - ``FirstMatchSpec``
///
/// ### Context Providers
///
/// - ``DefaultContextProvider``
/// - ``EnvironmentContextProvider``
/// - ``MockContextProvider``
/// - ``EvaluationContext``
///
/// ### Macros
///
/// - ``specs(_:)``
/// - ``AutoContext()``
///
/// ### Base Types
///
/// - ``AutoContextSpecification``
/// - ``CompositeSpec``
public enum SpecificationKit {

    /// The current version of SpecificationKit
    public static let version = "2.0.0"

}

// MARK: - Macros

/// Automatically synthesizes a composite specification by combining the provided specifications with logical AND.
///
/// The `@specs` macro generates a complete `Specification` implementation that combines multiple
/// specifications into a single composite specification. All provided specifications must share
/// the same `Context` type.
///
/// ## Generated Members
///
/// The macro generates the following members:
/// - `private let composite: AnySpecification<T>` - The combined specification
/// - `public init()` - Default initializer that creates the composite
/// - `public func isSatisfiedBy(_ candidate: T) -> Bool` - Specification evaluation
/// - `public func isSatisfiedByAsync(_ candidate: T) async -> Bool` - Async specification evaluation
/// - `public var isSatisfied: Bool` (for `@AutoContext` specs) - Computed property for current satisfaction
///
/// ## Usage Examples
///
/// ### Basic Composite Specification
/// ```swift
/// @specs(
///     MaxCountSpec(counterKey: "promoShown", maximumCount: 3),
///     TimeSinceEventSpec(eventKey: "lastPromo", minimumInterval: 24 * 3600)
/// )
/// struct PromoEligibilitySpec: Specification {
///     typealias T = EvaluationContext
/// }
/// ```
///
/// ### With AutoContext for Automatic Context Injection
/// ```swift
/// @specs(
///     MaxCountSpec(counterKey: "tutorialShown", maximumCount: 1),
///     FeatureFlagSpec(flagKey: "tutorials_enabled", expectedValue: true)
/// )
/// @AutoContext
/// struct TutorialSpec: Specification {
///     typealias T = EvaluationContext
/// }
///
/// // Usage becomes simpler
/// @Satisfies(using: TutorialSpec.self)
/// var shouldShowTutorial: Bool
/// ```
///
/// ### Complex Business Logic
/// ```swift
/// @specs(
///     UserSegmentSpec(expectedSegment: .premium),
///     DateRangeSpec(startDate: campaignStart, endDate: campaignEnd),
///     MaxCountSpec(counterKey: "premiumCampaignShown", maximumCount: 2)
/// )
/// @AutoContext
/// struct PremiumCampaignSpec: Specification {
///     typealias T = EvaluationContext
/// }
/// ```
///
/// ## Compile-Time Validation
///
/// The macro performs several compile-time checks:
/// - Ensures all specifications conform to `Specification`
/// - Warns if mixed `Context` types are detected
/// - Suggests adding `typealias T` if missing
/// - Validates proper specification instantiation
///
/// - Parameters:
///   - specifications: Variable number of specification instances to combine with AND logic
@attached(
    member, names: named(init), named(isSatisfiedBy), named(isSatisfiedByAsync), named(isSatisfied),
    named(composite))
public macro specs(
    _ specifications: Any...
) = #externalMacro(module: "SpecificationKitMacros", type: "SpecsMacro")

/// Augments a `Specification` type to become an `AutoContextSpecification` with automatic context injection.
///
/// The `@AutoContext` macro transforms a regular specification into one that can automatically
/// access the default context provider, eliminating the need to manually pass context providers
/// when using property wrappers.
///
/// ## Generated Members
///
/// The macro injects the following members:
/// - `public typealias Provider = DefaultContextProvider` - The context provider type
/// - `public static var contextProvider: DefaultContextProvider { .shared }` - Static provider access
/// - `public init()` - Default initializer (if not already present)
///
/// ## Usage Examples
///
/// ### Basic AutoContext Specification
/// ```swift
/// @AutoContext
/// struct SimpleSpec: Specification {
///     typealias T = EvaluationContext
///
///     func isSatisfiedBy(_ context: EvaluationContext) -> Bool {
///         context.flag(for: "feature_enabled") == true
///     }
/// }
///
/// // Usage without explicit provider
/// @Satisfies(using: SimpleSpec.self)
/// var isFeatureEnabled: Bool
/// ```
///
/// ### Combined with @specs Macro
/// ```swift
/// @specs(
///     MaxCountSpec(counterKey: "onboarding_shown", maximumCount: 1),
///     FeatureFlagSpec(flagKey: "onboarding_enabled", expectedValue: true)
/// )
/// @AutoContext
/// struct OnboardingSpec: Specification {
///     typealias T = EvaluationContext
/// }
///
/// @Satisfies(using: OnboardingSpec.self)
/// var shouldShowOnboarding: Bool
///
/// // Also generates async computed property for @AutoContext + @specs types
/// let eligible = await OnboardingSpec().isSatisfied
/// ```
///
/// ### SwiftUI Integration
/// ```swift
/// @AutoContext
/// struct PromoBannerSpec: Specification {
///     typealias T = EvaluationContext
///
///     func isSatisfiedBy(_ context: EvaluationContext) -> Bool {
///         context.counter(for: "promo_shown") < 3
///     }
/// }
///
/// struct ContentView: View {
///     @ObservedSatisfies(using: PromoBannerSpec.self)
///     var shouldShowPromo: Bool
///
///     var body: some View {
///         VStack {
///             if shouldShowPromo {
///                 PromoBannerView()
///             }
///             MainContentView()
///         }
///     }
/// }
/// ```
///
/// ## Benefits
///
/// - **Simplified Usage**: No need to explicitly pass context providers
/// - **Consistent Context**: All evaluations use the shared default provider
/// - **SwiftUI Ready**: Works seamlessly with `@ObservedSatisfies` and other property wrappers
/// - **Async Support**: Automatic async evaluation support when combined with `@specs`
///
/// ## Requirements
///
/// - Must be applied to a type that conforms to `Specification`
/// - The specification's `Context` type should be compatible with `DefaultContextProvider.Context`
/// - Works best with `EvaluationContext` as the context type
@attached(member, names: named(Provider), named(contextProvider), named(init))
public macro AutoContext() =
    #externalMacro(
        module: "SpecificationKitMacros",
        type: "AutoContextMacro"
    )
