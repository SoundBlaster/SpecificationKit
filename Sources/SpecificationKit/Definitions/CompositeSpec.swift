//
//  CompositeSpec.swift
//  SpecificationKit
//
//  Created by SpecificationKit on 2025.
//

import Foundation

/// An example composite specification that demonstrates how to combine multiple
/// individual specifications into a single, reusable business rule.
/// This serves as a template for creating domain-specific composite specifications.
public struct CompositeSpec: Specification {
    public typealias T = EvaluationContext

    private let composite: AnySpecification<EvaluationContext>

    /// Creates a CompositeSpec with default configuration
    /// This example combines time, count, and cooldown specifications
    public init() {
        // Example: A banner should show if:
        // 1. At least 10 seconds have passed since app launch
        // 2. It has been shown fewer than 3 times
        // 3. At least 1 week has passed since last shown

        let timeSinceLaunch = TimeSinceEventSpec.sinceAppLaunch(seconds: 10)
        let maxDisplayCount = MaxCountSpec(counterKey: "banner_shown", limit: 3)
        let cooldownPeriod = CooldownIntervalSpec(eventKey: "last_banner_shown", days: 7)

        self.composite = AnySpecification(
            timeSinceLaunch
                .and(AnySpecification(maxDisplayCount))
                .and(AnySpecification(cooldownPeriod))
        )
    }

    /// Creates a CompositeSpec with custom parameters
    /// - Parameters:
    ///   - minimumLaunchDelay: Minimum seconds since app launch
    ///   - maxShowCount: Maximum number of times to show
    ///   - cooldownDays: Days to wait between shows
    ///   - counterKey: Key for tracking show count
    ///   - eventKey: Key for tracking last show time
    public init(
        minimumLaunchDelay: TimeInterval,
        maxShowCount: Int,
        cooldownDays: TimeInterval,
        counterKey: String = "display_count",
        eventKey: String = "last_display"
    ) {
        let timeSinceLaunch = TimeSinceEventSpec.sinceAppLaunch(seconds: minimumLaunchDelay)
        let maxDisplayCount = MaxCountSpec(counterKey: counterKey, limit: maxShowCount)
        let cooldownPeriod = CooldownIntervalSpec(eventKey: eventKey, days: cooldownDays)

        self.composite = AnySpecification(
            timeSinceLaunch
                .and(AnySpecification(maxDisplayCount))
                .and(AnySpecification(cooldownPeriod))
        )
    }

    public func isSatisfiedBy(_ context: EvaluationContext) -> Bool {
        composite.isSatisfiedBy(context)
    }
}

// MARK: - Predefined Composite Specifications

extension CompositeSpec {

    /// A composite specification for promotional banners
    /// Shows after 30 seconds, max 2 times, with 3-day cooldown
    public static var promoBanner: CompositeSpec {
        CompositeSpec(
            minimumLaunchDelay: 30,
            maxShowCount: 2,
            cooldownDays: 3,
            counterKey: "promo_banner_count",
            eventKey: "last_promo_banner"
        )
    }

    /// A composite specification for onboarding tips
    /// Shows after 5 seconds, max 5 times, with 1-hour cooldown
    public static var onboardingTip: CompositeSpec {
        CompositeSpec(
            minimumLaunchDelay: 5,
            maxShowCount: 5,
            cooldownDays: TimeInterval.hours(1) / 86400,  // Convert hours to days
            counterKey: "onboarding_tip_count",
            eventKey: "last_onboarding_tip"
        )
    }

    /// A composite specification for feature announcements
    /// Shows after 60 seconds, max 1 time, no cooldown needed (since max is 1)
    public static var featureAnnouncement: CompositeSpec {
        CompositeSpec(
            minimumLaunchDelay: 60,
            maxShowCount: 1,
            cooldownDays: 0,
            counterKey: "feature_announcement_count",
            eventKey: "last_feature_announcement"
        )
    }

    /// A composite specification for rating prompts
    /// Shows after 5 minutes, max 3 times, with 2-week cooldown
    public static var ratingPrompt: CompositeSpec {
        CompositeSpec(
            minimumLaunchDelay: TimeInterval.minutes(5),
            maxShowCount: 3,
            cooldownDays: 14,
            counterKey: "rating_prompt_count",
            eventKey: "last_rating_prompt"
        )
    }
}

// MARK: - Advanced Composite Specifications

/// A more complex composite specification that includes additional business rules
public struct AdvancedCompositeSpec: Specification {
    public typealias T = EvaluationContext

    private let composite: AnySpecification<EvaluationContext>

    /// Creates an advanced composite with business hours and user engagement rules
    /// - Parameters:
    ///   - baseSpec: The base composite specification to extend
    ///   - requireBusinessHours: Whether to only show during business hours (9 AM - 5 PM)
    ///   - requireWeekdays: Whether to only show on weekdays
    ///   - minimumEngagementLevel: Minimum user engagement score required
    public init(
        baseSpec: CompositeSpec,
        requireBusinessHours: Bool = false,
        requireWeekdays: Bool = false,
        minimumEngagementLevel: Int? = nil
    ) {
        var specs: [AnySpecification<EvaluationContext>] = [AnySpecification(baseSpec)]

        if requireBusinessHours {
            let businessHours = PredicateSpec<EvaluationContext>.currentHour(
                in: 9...17,
                description: "Business hours"
            )
            specs.append(AnySpecification(businessHours))
        }

        if requireWeekdays {
            let weekdaysOnly = PredicateSpec<EvaluationContext>.isWeekday(
                description: "Weekdays only"
            )
            specs.append(AnySpecification(weekdaysOnly))
        }

        if let minEngagement = minimumEngagementLevel {
            let engagementSpec = PredicateSpec<EvaluationContext>.counter(
                "user_engagement_score",
                .greaterThanOrEqual,
                minEngagement,
                description: "Minimum engagement level"
            )
            specs.append(AnySpecification(engagementSpec))
        }

        // Combine all specifications with AND logic
        self.composite = specs.allSatisfied()
    }

    public func isSatisfiedBy(_ context: EvaluationContext) -> Bool {
        composite.isSatisfiedBy(context)
    }
}

// MARK: - Domain-Specific Composite Examples

/// A composite specification specifically for e-commerce promotional banners
public struct ECommercePromoBannerSpec: Specification {
    public typealias T = EvaluationContext

    private let composite: AnySpecification<EvaluationContext>

    public init() {
        // E-commerce specific rules:
        // 1. User has been active for at least 2 minutes
        // 2. Has viewed at least 3 products
        // 3. Haven't made a purchase in the last 24 hours
        // 4. Haven't seen a promo in the last 4 hours
        // 5. It's during shopping hours (10 AM - 10 PM)

        let minimumActivity = TimeSinceEventSpec.sinceAppLaunch(minutes: 2)
        let productViewCount = PredicateSpec<EvaluationContext>.counter(
            "products_viewed",
            .greaterThanOrEqual,
            3
        )
        let noPurchaseRecently = CooldownIntervalSpec(
            eventKey: "last_purchase",
            hours: 24
        )
        let promoCoolddown = CooldownIntervalSpec(
            eventKey: "last_promo_shown",
            hours: 4
        )
        let shoppingHours = PredicateSpec<EvaluationContext>.currentHour(
            in: 10...22,
            description: "Shopping hours"
        )

        self.composite = AnySpecification(
            minimumActivity
                .and(AnySpecification(productViewCount))
                .and(AnySpecification(noPurchaseRecently))
                .and(AnySpecification(promoCoolddown))
                .and(AnySpecification(shoppingHours))
        )
    }

    public func isSatisfiedBy(_ context: EvaluationContext) -> Bool {
        composite.isSatisfiedBy(context)
    }
}

/// A composite specification for subscription upgrade prompts
public struct SubscriptionUpgradeSpec: Specification {
    public typealias T = EvaluationContext

    private let composite: AnySpecification<EvaluationContext>

    public init() {
        // Subscription upgrade rules:
        // 1. User has been using the app for at least 1 week
        // 2. Has used premium features at least 5 times
        // 3. Is not currently a premium subscriber
        // 4. Haven't shown upgrade prompt in the last 3 days
        // 5. Has opened the app at least 10 times

        let weeklyUser = TimeSinceEventSpec.sinceAppLaunch(days: 7)
        let premiumFeatureUsage = PredicateSpec<EvaluationContext>.counter(
            "premium_feature_usage",
            .greaterThanOrEqual,
            5
        )
        let notPremiumSubscriber = PredicateSpec<EvaluationContext>.flag(
            "is_premium_subscriber",
            equals: false
        )
        let upgradePromptCooldown = CooldownIntervalSpec(
            eventKey: "last_upgrade_prompt",
            days: 3
        )
        let activeUser = PredicateSpec<EvaluationContext>.counter(
            "app_opens",
            .greaterThanOrEqual,
            10
        )

        self.composite = AnySpecification(
            weeklyUser
                .and(AnySpecification(premiumFeatureUsage))
                .and(AnySpecification(notPremiumSubscriber))
                .and(AnySpecification(upgradePromptCooldown))
                .and(AnySpecification(activeUser))
        )
    }

    public func isSatisfiedBy(_ context: EvaluationContext) -> Bool {
        composite.isSatisfiedBy(context)
    }
}
