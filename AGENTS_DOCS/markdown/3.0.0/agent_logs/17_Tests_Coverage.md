## User (checkpoint)

Lets start working on increasing test coverage metric. Now common average metric is near 62%. For example [@CompositeSpec.swift](file:///Users/egor/Development/GitHub/SpecificationKit/Sources/SpecificationKit/Definitions/CompositeSpec.swift) file has very low coverage - 10%. only `CompositeSpec.init()` and `CompositeSpec.isSatisfiedBy(_:)` are covered. Add missed tests for this file.

## Assistant

I'll help you increase test coverage for the `CompositeSpec.swift` file. Let me first examine the current implementation and existing tests to understand what's missing.

**Tool Call: Read /Users/egor/Development/GitHub/SpecificationKit/Sources/SpecificationKit/Definitions/CompositeSpec.swift**
Status: Completed

```
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
```

**Tool Call: mcp__serena__find_file**
Status: Completed

Error: No active project. Ask to user to select a project from this list: ['SpecificationKit']

**Tool Call: mcp__serena__activate_project**
Status: Completed

Activated existing project with name 'SpecificationKit' at /Users/egor/Development/GitHub/SpecificationKit, language: swift
Available memories:
 ["codebase_structure", "task_completion_requirements", "project_overview", "suggested_commands", "code_style_conventions"]You should not read these memories directly, but rather use the `read_memory` tool to read them later if needed for the task.
Available tools:
 ["activate_project", "check_onboarding_performed", "delete_memory", "find_file", "find_referencing_symbols", "find_symbol", "get_current_config", "get_symbols_overview", "insert_after_symbol", "insert_before_symbol", "list_dir", "list_memories", "onboarding", "read_memory", "replace_symbol_body", "search_for_pattern", "think_about_collected_information", "think_about_task_adherence", "think_about_whether_you_are_done", "write_memory"]

**Tool Call: mcp__serena__find_file**
Status: Completed

{"files": []}

**Tool Call: mcp__serena__search_for_pattern**
Status: Completed

{"Tests/SpecificationKitTests/SpecificationKitTests.swift": ["  > 438:    // MARK: - CompositeSpec Tests", "  > 440:    func testCompositeSpec_DefaultConfiguration() {", "  > 450:        let spec = CompositeSpec()", "  > 456:        XCTAssertTrue(result, \"CompositeSpec should be satisfied with valid conditions\")", "  > 459:    func testCompositeSpec_FailsWhenCountExceedsLimit() {", "  > 469:        let spec = CompositeSpec()", "  > 475:        XCTAssertFalse(result, \"CompositeSpec should fail when count exceeds limit\")"], "Tests/SpecificationKitTests/SpecificationTracerTests.swift": ["  > 168:    func testCompositeSpecificationANDTracing() {", "  > 192:    func testCompositeSpecificationORTracing() {", "  > 215:    func testCompositeSpecificationANDShortCircuit() {", "  > 237:    func testCompositeSpecificationORShortCircuit() {"]}

**Tool Call: Read /Users/egor/Development/GitHub/SpecificationKit/Tests/SpecificationKitTests/SpecificationKitTests.swift (from line 436)**
Status: Completed

```
    }

    // MARK: - CompositeSpec Tests

    func testCompositeSpec_DefaultConfiguration() {
        // Given
        let currentDate = Date()
        let launchDate = currentDate.addingTimeInterval(-15)  // 15 seconds ago
        let context = EvaluationContext(
            currentDate: currentDate,
            launchDate: launchDate,
            counters: ["banner_shown": 1],
            events: ["last_banner_shown": currentDate.addingTimeInterval(-604800)]  // 1 week ago
        )
        let spec = CompositeSpec()

        // When
        let result = spec.isSatisfiedBy(context)

        // Then
        XCTAssertTrue(result, "CompositeSpec should be satisfied with valid conditions")
    }

    func testCompositeSpec_FailsWhenCountExceedsLimit() {
        // Given
        let currentDate = Date()
        let launchDate = currentDate.addingTimeInterval(-15)  // 15 seconds ago
        let context = EvaluationContext(
            currentDate: currentDate,
            launchDate: launchDate,
            counters: ["banner_shown": 5],  // Exceeds limit of 3
            events: ["last_banner_shown": currentDate.addingTimeInterval(-604800)]  // 1 week ago
        )
        let spec = CompositeSpec()

        // When
        let result = spec.isSatisfiedBy(context)

        // Then
        XCTAssertFalse(result, "CompositeSpec should fail when count exceeds limit")
    }
}


<file-read-info>Read lines 436-477. </file-read-info>
```

## Assistant

Now I can see what's missing from the test coverage. The current tests only cover:
1. `CompositeSpec.init()` (default constructor)
2. `CompositeSpec.isSatisfiedBy(_:)` method

Based on the implementation, here's what's NOT tested:

1. **Custom initializer**: `init(minimumLaunchDelay:maxShowCount:cooldownDays:counterKey:eventKey:)`
2. **Static predefine specifications**: `.promoBanner`, `.onboardingTip`, `.featureAnnouncement`, `.ratingPrompt`
3. **AdvancedCompositeSpec**: Complete class with all its functionality
4. **ECommercePromoBannerSpec**: Complete class
5. **SubscriptionUpgradeSpec**: Complete class
6. **Edge cases**: Empty contexts, missing keys, boundary conditionsI'll add comprehensive tests for all the missing functionality. Let me add these tests to the existing test file:

**Tool Call: Edit `/Users/egor/Development/GitHub/SpecificationKit/Tests/SpecificationKitTests/SpecificationKitTests.swift`**
Status: Completed

Diff: /Users/egor/Development/GitHub/SpecificationKit/Tests/SpecificationKitTests/SpecificationKitTests.swift
```
//
//  SpecificationKitTests.swift
//  SpecificationKitTests
//
//  Created by SpecificationKit on 2025.
//

import XCTest

@testable import SpecificationKit

final class SpecificationKitTests: XCTestCase {

    // MARK: - TimeSinceEventSpec Tests

    func testTimeSinceEventSpec_WhenEventNeverOccurred_ReturnTrue() {
        // Given
        let context = EvaluationContext(
            currentDate: Date(),
            events: [:]
        )
        let spec = TimeSinceEventSpec(eventKey: "test_event", minimumInterval: 60)

        // When
        let result = spec.isSatisfiedBy(context)

        // Then
        XCTAssertTrue(result, "Specification should be satisfied when event never occurred")
    }

    func testTimeSinceEventSpec_WhenEnoughTimePassed_ReturnTrue() {
        // Given
        let currentDate = Date()
        let eventDate = currentDate.addingTimeInterval(-120)  // 2 minutes ago
        let context = EvaluationContext(
            currentDate: currentDate,
            events: ["test_event": eventDate]
        )
        let spec = TimeSinceEventSpec(eventKey: "test_event", minimumInterval: 60)  // 1 minute required

        // When
        let result = spec.isSatisfiedBy(context)

        // Then
        XCTAssertTrue(result, "Specification should be satisfied when enough time has passed")
    }

    func testTimeSinceEventSpec_WhenNotEnoughTimePassed_ReturnFalse() {
        // Given
        let currentDate = Date()
        let eventDate = currentDate.addingTimeInterval(-30)  // 30 seconds ago
        let context = EvaluationContext(
            currentDate: currentDate,
            events: ["test_event": eventDate]
        )
        let spec = TimeSinceEventSpec(eventKey: "test_event", minimumInterval: 60)  // 1 minute required

        // When
        let result = spec.isSatisfiedBy(context)

        // Then
        XCTAssertFalse(
            result, "Specification should not be satisfied when not enough time has passed")
    }

    func testTimeSinceEventSpec_ConvenienceInitializers() {
        let spec1 = TimeSinceEventSpec(eventKey: "test", seconds: 60)
        let spec2 = TimeSinceEventSpec(eventKey: "test", minutes: 1)
        let spec3 = TimeSinceEventSpec(eventKey: "test", hours: 1)
        let spec4 = TimeSinceEventSpec(eventKey: "test", days: 1)

        XCTAssertEqual(spec1.minimumInterval, 60)
        XCTAssertEqual(spec2.minimumInterval, 60)
        XCTAssertEqual(spec3.minimumInterval, 3600)
        XCTAssertEqual(spec4.minimumInterval, 86400)
    }

    // MARK: - MaxCountSpec Tests

    func testMaxCountSpec_WhenCountBelowLimit_ReturnTrue() {
        // Given
        let context = EvaluationContext(
            counters: ["test_counter": 2]
        )
        let spec = MaxCountSpec(counterKey: "test_counter", limit: 5)

        // When
        let result = spec.isSatisfiedBy(context)

        // Then
        XCTAssertTrue(result, "Specification should be satisfied when count is below limit")
    }

    func testMaxCountSpec_WhenCountAtLimit_ReturnFalse() {
        // Given
        let context = EvaluationContext(
            counters: ["test_counter": 5]
        )
        let spec = MaxCountSpec(counterKey: "test_counter", limit: 5)

        // When
        let result = spec.isSatisfiedBy(context)

        // Then
        XCTAssertFalse(result, "Specification should not be satisfied when count equals limit")
    }

    func testMaxCountSpec_WhenCountAboveLimit_ReturnFalse() {
        // Given
        let context = EvaluationContext(
            counters: ["test_counter": 7]
        )
        let spec = MaxCountSpec(counterKey: "test_counter", limit: 5)

        // When
        let result = spec.isSatisfiedBy(context)

        // Then
        XCTAssertFalse(result, "Specification should not be satisfied when count exceeds limit")
    }

    func testMaxCountSpec_WhenCounterNotExists_ReturnTrue() {
        // Given
        let context = EvaluationContext(
            counters: [:]
        )
        let spec = MaxCountSpec(counterKey: "nonexistent_counter", limit: 5)

        // When
        let result = spec.isSatisfiedBy(context)

        // Then
        XCTAssertTrue(
            result, "Specification should be satisfied when counter doesn't exist (defaults to 0)")
    }

    // MARK: - CooldownIntervalSpec Tests

    func testCooldownIntervalSpec_WhenNoPreviousEvent_ReturnTrue() {
        // Given
        let context = EvaluationContext(
            currentDate: Date(),
            events: [:]
        )
        let spec = CooldownIntervalSpec(eventKey: "test_event", cooldownInterval: 3600)

        // When
        let result = spec.isSatisfiedBy(context)

        // Then
        XCTAssertTrue(result, "Specification should be satisfied when no previous event exists")
    }

    func testCooldownIntervalSpec_WhenCooldownComplete_ReturnTrue() {
        // Given
        let currentDate = Date()
        let lastEvent = currentDate.addingTimeInterval(-7200)  // 2 hours ago
        let context = EvaluationContext(
            currentDate: currentDate,
            events: ["test_event": lastEvent]
        )
        let spec = CooldownIntervalSpec(eventKey: "test_event", cooldownInterval: 3600)  // 1 hour cooldown

        // When
        let result = spec.isSatisfiedBy(context)

        // Then
        XCTAssertTrue(result, "Specification should be satisfied when cooldown period has passed")
    }

    func testCooldownIntervalSpec_WhenCooldownActive_ReturnFalse() {
        // Given
        let currentDate = Date()
        let lastEvent = currentDate.addingTimeInterval(-1800)  // 30 minutes ago
        let context = EvaluationContext(
            currentDate: currentDate,
            events: ["test_event": lastEvent]
        )
        let spec = CooldownIntervalSpec(eventKey: "test_event", cooldownInterval: 3600)  // 1 hour cooldown

        // When
        let result = spec.isSatisfiedBy(context)

        // Then
        XCTAssertFalse(
            result, "Specification should not be satisfied when cooldown is still active")
    }

    // MARK: - PredicateSpec Tests

    func testPredicateSpec_WithCustomPredicate() {
        // Given
        let spec = PredicateSpec<Int> { value in
            value > 10
        }

        // When & Then
        XCTAssertTrue(spec.isSatisfiedBy(15))
        XCTAssertFalse(spec.isSatisfiedBy(5))
        XCTAssertFalse(spec.isSatisfiedBy(10))
    }

    func testPredicateSpec_AlwaysTrue() {
        // Given
        let spec = PredicateSpec<String>.alwaysTrue()

        // When & Then
        XCTAssertTrue(spec.isSatisfiedBy("anything"))
        XCTAssertTrue(spec.isSatisfiedBy(""))
    }

    func testPredicateSpec_AlwaysFalse() {
        // Given
        let spec = PredicateSpec<String>.alwaysFalse()

        // When & Then
        XCTAssertFalse(spec.isSatisfiedBy("anything"))
        XCTAssertFalse(spec.isSatisfiedBy(""))
    }

    // MARK: - Specification Operators Tests

    func testSpecificationOperators_And() {
        // Given
        let spec1 = PredicateSpec<Int> { $0 > 5 }
        let spec2 = PredicateSpec<Int> { $0 < 15 }
        let combinedSpec = spec1.and(spec2)

        // When & Then
        XCTAssertTrue(combinedSpec.isSatisfiedBy(10))
        XCTAssertFalse(combinedSpec.isSatisfiedBy(3))
        XCTAssertFalse(combinedSpec.isSatisfiedBy(20))
    }

    func testSpecificationOperators_Or() {
        // Given
        let spec1 = PredicateSpec<Int> { $0 < 5 }
        let spec2 = PredicateSpec<Int> { $0 > 15 }
        let combinedSpec = spec1.or(spec2)

        // When & Then
        XCTAssertTrue(combinedSpec.isSatisfiedBy(3))
        XCTAssertTrue(combinedSpec.isSatisfiedBy(20))
        XCTAssertFalse(combinedSpec.isSatisfiedBy(10))
    }

    func testSpecificationOperators_Not() {
        // Given
        let spec = PredicateSpec<Int> { $0 > 10 }
        let notSpec = spec.not()

        // When & Then
        XCTAssertFalse(notSpec.isSatisfiedBy(15))
        XCTAssertTrue(notSpec.isSatisfiedBy(5))
    }

    // MARK: - AnySpecification Tests

    func testAnySpecification_TypeErasure() {
        // Given
        let spec1 = PredicateSpec<Int> { $0 > 10 }
        let spec2 = MaxCountSpec(counterKey: "test", limit: 5)

        let anySpec1 = AnySpecification(spec1)
        let anySpec2 = AnySpecification(spec2)

        // When & Then
        XCTAssertTrue(anySpec1.isSatisfiedBy(15))
        XCTAssertFalse(anySpec1.isSatisfiedBy(5))

        let context = EvaluationContext(counters: ["test": 3])
        XCTAssertTrue(anySpec2.isSatisfiedBy(context))
    }

    func testAnySpecification_Always() {
        // Given
        let spec = AnySpecification<String>.always

        // When & Then
        XCTAssertTrue(spec.isSatisfiedBy("test"))
        XCTAssertTrue(spec.isSatisfiedBy(""))
    }

    func testAnySpecification_Never() {
        // Given
        let spec = AnySpecification<String>.never

        // When & Then
        XCTAssertFalse(spec.isSatisfiedBy("test"))
        XCTAssertFalse(spec.isSatisfiedBy(""))
    }

    // MARK: - EvaluationContext Tests

    func testEvaluationContext_TimeSinceLaunch() {
        // Given
        let launchDate = Date().addingTimeInterval(-300)  // 5 minutes ago
        let currentDate = Date()
        let context = EvaluationContext(
            currentDate: currentDate,
            launchDate: launchDate
        )

        // When
        let timeSinceLaunch = context.timeSinceLaunch

        // Then
        XCTAssertEqual(timeSinceLaunch, 300, accuracy: 1)
    }

    func testEvaluationContext_CounterAccess() {
        // Given
        let context = EvaluationContext(
            counters: ["test_counter": 42]
        )

        // When & Then
        XCTAssertEqual(context.counter(for: "test_counter"), 42)
        XCTAssertEqual(context.counter(for: "nonexistent"), 0)
    }

    func testEvaluationContext_EventAccess() {
        // Given
        let testDate = Date()
        let context = EvaluationContext(
            events: ["test_event": testDate]
        )

        // When & Then
        XCTAssertEqual(context.event(for: "test_event"), testDate)
        XCTAssertNil(context.event(for: "nonexistent"))
    }

    func testEvaluationContext_FlagAccess() {
        // Given
        let context = EvaluationContext(
            flags: ["test_flag": true, "false_flag": false]
        )

        // When & Then
        XCTAssertTrue(context.flag(for: "test_flag"))
        XCTAssertFalse(context.flag(for: "false_flag"))
        XCTAssertFalse(context.flag(for: "nonexistent"))
    }

    // MARK: - DefaultContextProvider Tests

    func testDefaultContextProvider_CounterManagement() {
        // Given
        let provider = DefaultContextProvider()

        // When
        provider.setCounter("test", to: 5)
        provider.incrementCounter("test", by: 3)

        // Then
        XCTAssertEqual(provider.getCounter("test"), 8)

        // When
        provider.decrementCounter("test", by: 2)

        // Then
        XCTAssertEqual(provider.getCounter("test"), 6)
    }

    func testDefaultContextProvider_EventManagement() {
        // Given
        let provider = DefaultContextProvider()
        let testDate = Date()

        // When
        provider.recordEvent("test_event", at: testDate)

        // Then
        XCTAssertEqual(provider.getEvent("test_event"), testDate)

        // When
        provider.removeEvent("test_event")

        // Then
        XCTAssertNil(provider.getEvent("test_event"))
    }

    func testDefaultContextProvider_FlagManagement() {
        // Given
        let provider = DefaultContextProvider()

        // When
        provider.setFlag("test_flag", to: true)

        // Then
        XCTAssertTrue(provider.getFlag("test_flag"))

        // When
        let toggled = provider.toggleFlag("test_flag")

        // Then
        XCTAssertFalse(toggled)
        XCTAssertFalse(provider.getFlag("test_flag"))
    }

    // MARK: - MockContextProvider Tests

    func testMockContextProvider_BasicUsage() {
        // Given
        let context = EvaluationContext(
            counters: ["test": 5],
            flags: ["enabled": true]
        )
        let provider = MockContextProvider(context: context)

        // When
        let retrievedContext = provider.currentContext()

        // Then
        XCTAssertEqual(retrievedContext.counter(for: "test"), 5)
        XCTAssertTrue(retrievedContext.flag(for: "enabled"))
        XCTAssertEqual(provider.contextRequestCount, 1)
    }

    func testMockContextProvider_RequestTracking() {
        // Given
        let provider = MockContextProvider()
        var callbackCount = 0
        provider.onContextRequested = {
            callbackCount += 1
        }

        // When
        _ = provider.currentContext()
        _ = provider.currentContext()

        // Then
        XCTAssertEqual(provider.contextRequestCount, 2)
        XCTAssertEqual(callbackCount, 2)
    }

    // MARK: - CompositeSpec Tests

    func testCompositeSpec_DefaultConfiguration() {
        // Given
        let currentDate = Date()
        let launchDate = currentDate.addingTimeInterval(-15)  // 15 seconds ago
        let context = EvaluationContext(
            currentDate: currentDate,
            launchDate: launchDate,
            counters: ["banner_shown": 1],
            events: ["last_banner_shown": currentDate.addingTimeInterval(-604800)]  // 1 week ago
        )
        let spec = CompositeSpec()

        // When
        let result = spec.isSatisfiedBy(context)

        // Then
        XCTAssertTrue(result, "CompositeSpec should be satisfied with valid conditions")
    }

    func testCompositeSpec_FailsWhenCountExceedsLimit() {
        // Given
        let currentDate = Date()
        let launchDate = currentDate.addingTimeInterval(-15)  // 15 seconds ago
        let context = EvaluationContext(
            currentDate: currentDate,
            launchDate: launchDate,
            counters: ["banner_shown": 5],  // Exceeds limit of 3
            events: ["last_banner_shown": currentDate.addingTimeInterval(-604800)]  // 1 week ago
        )
        let spec = CompositeSpec()

        // When
        let result = spec.isSatisfiedBy(context)

        // Then
        XCTAssertFalse(result, "CompositeSpec should fail when count exceeds limit")
    }

    func testCompositeSpec_CustomConfiguration() {
        // Given
        let currentDate = Date()
        let launchDate = currentDate.addingTimeInterval(-300)  // 5 minutes ago
        let context = EvaluationContext(
            currentDate: currentDate,
            launchDate: launchDate,
            counters: ["custom_counter": 2],
            events: ["custom_event": currentDate.addingTimeInterval(-172800)]  // 2 days ago
        )
        let spec = CompositeSpec(
            minimumLaunchDelay: 60,  // 1 minute
            maxShowCount: 5,
            cooldownDays: 1,  // 1 day
            counterKey: "custom_counter",
            eventKey: "custom_event"
        )

        // When
        let result = spec.isSatisfiedBy(context)

        // Then
        XCTAssertTrue(result, "Custom CompositeSpec should be satisfied")
    }

    func testCompositeSpec_CustomConfiguration_FailsInsufficientTime() {
        // Given
        let currentDate = Date()
        let launchDate = currentDate.addingTimeInterval(-30)  // 30 seconds ago
        let context = EvaluationContext(
            currentDate: currentDate,
            launchDate: launchDate,
            counters: ["custom_counter": 2],
            events: ["custom_event": currentDate.addingTimeInterval(-172800)]  // 2 days ago
        )
        let spec = CompositeSpec(
            minimumLaunchDelay: 60,  // 1 minute required
            maxShowCount: 5,
            cooldownDays: 1,
            counterKey: "custom_counter",
            eventKey: "custom_event"
        )

        // When
        let result = spec.isSatisfiedBy(context)

        // Then
        XCTAssertFalse(result, "Custom CompositeSpec should fail when insufficient time has passed")
    }

    func testCompositeSpec_PromoBanner() {
        // Given
        let currentDate = Date()
        let launchDate = currentDate.addingTimeInterval(-60)  // 1 minute ago
        let context = EvaluationContext(
            currentDate: currentDate,
            launchDate: launchDate,
            counters: ["promo_banner_count": 1],
            events: ["last_promo_banner": currentDate.addingTimeInterval(-259200)]  // 3 days ago
        )

        // When
        let result = CompositeSpec.promoBanner.isSatisfiedBy(context)

        // Then
        XCTAssertTrue(result, "PromoBanner spec should be satisfied")
    }

    func testCompositeSpec_PromoBanner_FailsMaxCount() {
        // Given
        let currentDate = Date()
        let launchDate = currentDate.addingTimeInterval(-60)  // 1 minute ago
        let context = EvaluationContext(
            currentDate: currentDate,
            launchDate: launchDate,
            counters: ["promo_banner_count": 3],  // Exceeds limit of 2
            events: ["last_promo_banner": currentDate.addingTimeInterval(-259200)]  // 3 days ago
        )

        // When
        let result = CompositeSpec.promoBanner.isSatisfiedBy(context)

        // Then
        XCTAssertFalse(result, "PromoBanner spec should fail when max count exceeded")
    }

    func testCompositeSpec_OnboardingTip() {
        // Given
        let currentDate = Date()
        let launchDate = currentDate.addingTimeInterval(-10)  // 10 seconds ago
        let context = EvaluationContext(
            currentDate: currentDate,
            launchDate: launchDate,
            counters: ["onboarding_tip_count": 2],
            events: ["last_onboarding_tip": currentDate.addingTimeInterval(-7200)]  // 2 hours ago
        )

        // When
        let result = CompositeSpec.onboardingTip.isSatisfiedBy(context)

        // Then
        XCTAssertTrue(result, "OnboardingTip spec should be satisfied")
    }

    func testCompositeSpec_OnboardingTip_FailsCooldown() {
        // Given
        let currentDate = Date()
        let launchDate = currentDate.addingTimeInterval(-10)  // 10 seconds ago
        let context = EvaluationContext(
            currentDate: currentDate,
            launchDate: launchDate,
            counters: ["onboarding_tip_count": 2],
            events: ["last_onboarding_tip": currentDate.addingTimeInterval(-1800)]  // 30 minutes ago (within 1 hour cooldown)
        )

        // When
        let result = CompositeSpec.onboardingTip.isSatisfiedBy(context)

        // Then
        XCTAssertFalse(result, "OnboardingTip spec should fail within cooldown period")
    }

    func testCompositeSpec_FeatureAnnouncement() {
        // Given
        let currentDate = Date()
        let launchDate = currentDate.addingTimeInterval(-120)  // 2 minutes ago
        let context = EvaluationContext(
            currentDate: currentDate,
            launchDate: launchDate,
            counters: ["feature_announcement_count": 0],
            events: [:]
        )

        // When
        let result = CompositeSpec.featureAnnouncement.isSatisfiedBy(context)

        // Then
        XCTAssertTrue(result, "FeatureAnnouncement spec should be satisfied")
    }

    func testCompositeSpec_FeatureAnnouncement_FailsMaxCount() {
        // Given
        let currentDate = Date()
        let launchDate = currentDate.addingTimeInterval(-120)  // 2 minutes ago
        let context = EvaluationContext(
            currentDate: currentDate,
            launchDate: launchDate,
            counters: ["feature_announcement_count": 1],  // Max is 1
            events: [:]
        )

        // When
        let result = CompositeSpec.featureAnnouncement.isSatisfiedBy(context)

        // Then
        XCTAssertFalse(result, "FeatureAnnouncement spec should fail when max count reached")
    }

    func testCompositeSpec_RatingPrompt() {
        // Given
        let currentDate = Date()
        let launchDate = currentDate.addingTimeInterval(-600)  // 10 minutes ago
        let context = EvaluationContext(
            currentDate: currentDate,
            launchDate: launchDate,
            counters: ["rating_prompt_count": 1],
            events: ["last_rating_prompt": currentDate.addingTimeInterval(-1209600)]  // 2 weeks ago
        )

        // When
        let result = CompositeSpec.ratingPrompt.isSatisfiedBy(context)

        // Then
        XCTAssertTrue(result, "RatingPrompt spec should be satisfied")
    }

    func testCompositeSpec_RatingPrompt_FailsInsufficientTime() {
        // Given
        let currentDate = Date()
        let launchDate = currentDate.addingTimeInterval(-120)  // 2 minutes ago (less than 5 minutes required)
        let context = EvaluationContext(
            currentDate: currentDate,
            launchDate: launchDate,
            counters: ["rating_prompt_count": 1],
            events: ["last_rating_prompt": currentDate.addingTimeInterval(-1209600)]  // 2 weeks ago
        )

        // When
        let result = CompositeSpec.ratingPrompt.isSatisfiedBy(context)

        // Then
        XCTAssertFalse(result, "RatingPrompt spec should fail with insufficient launch time")
    }

    // MARK: - AdvancedCompositeSpec Tests

    func testAdvancedCompositeSpec_BasicComposition() {
        // Given
        let baseSpec = CompositeSpec(
            minimumLaunchDelay: 60,
            maxShowCount: 3,
            cooldownDays: 1,
            counterKey: "test_counter",
            eventKey: "test_event"
        )
        let currentDate = Date()
        let launchDate = currentDate.addingTimeInterval(-120)  // 2 minutes ago
        let context = EvaluationContext(
            currentDate: currentDate,
            launchDate: launchDate,
            counters: ["test_counter": 1],
            events: ["test_event": currentDate.addingTimeInterval(-172800)]  // 2 days ago
        )
        let advancedSpec = AdvancedCompositeSpec(baseSpec: baseSpec)

        // When
        let result = advancedSpec.isSatisfiedBy(context)

        // Then
        XCTAssertTrue(result, "AdvancedCompositeSpec should satisfy base spec")
    }

    func testAdvancedCompositeSpec_WithBusinessHours() {
        // Given
        let baseSpec = CompositeSpec(
            minimumLaunchDelay: 60,
            maxShowCount: 3,
            cooldownDays: 1,
            counterKey: "test_counter",
            eventKey: "test_event"
        )

        // Create a date during business hours (2 PM)
        let calendar = Calendar.current
        let currentDate = calendar.date(bySettingHour: 14, minute: 0, second: 0, of: Date())!
        let launchDate = currentDate.addingTimeInterval(-120)  // 2 minutes ago
        let context = EvaluationContext(
            currentDate: currentDate,
            launchDate: launchDate,
            counters: ["test_counter": 1],
            events: ["test_event": currentDate.addingTimeInterval(-172800)]  // 2 days ago
        )
        let advancedSpec = AdvancedCompositeSpec(
            baseSpec: baseSpec,
            requireBusinessHours: true
        )

        // When
        let result = advancedSpec.isSatisfiedBy(context)

        // Then
        XCTAssertTrue(result, "AdvancedCompositeSpec should satisfy during business hours")
    }

    func testAdvancedCompositeSpec_WithBusinessHours_FailsOutsideHours() {
        // Given
        let baseSpec = CompositeSpec(
            minimumLaunchDelay: 60,
            maxShowCount: 3,
            cooldownDays: 1,
            counterKey: "test_counter",
            eventKey: "test_event"
        )

        // Create a date outside business hours (8 PM)
        let calendar = Calendar.current
        let currentDate = calendar.date(bySettingHour: 20, minute: 0, second: 0, of: Date())!
        let launchDate = currentDate.addingTimeInterval(-120)  // 2 minutes ago
        let context = EvaluationContext(
            currentDate: currentDate,
            launchDate: launchDate,
            counters: ["test_counter": 1],
            events: ["test_event": currentDate.addingTimeInterval(-172800)]  // 2 days ago
        )
        let advancedSpec = AdvancedCompositeSpec(
            baseSpec: baseSpec,
            requireBusinessHours: true
        )

        // When
        let result = advancedSpec.isSatisfiedBy(context)

        // Then
        XCTAssertFalse(result, "AdvancedCompositeSpec should fail outside business hours")
    }

    func testAdvancedCompositeSpec_WithWeekdays() {
        // Given
        let baseSpec = CompositeSpec(
            minimumLaunchDelay: 60,
            maxShowCount: 3,
            cooldownDays: 1,
            counterKey: "test_counter",
            eventKey: "test_event"
        )

        // Create a date on a weekday (Tuesday)
        let calendar = Calendar.current
        let currentDate = calendar.dateInterval(of: .weekOfYear, for: Date())?.start.addingTimeInterval(86400) ?? Date() // Tuesday
        let launchDate = currentDate.addingTimeInterval(-120)  // 2 minutes ago
        let context = EvaluationContext(
            currentDate: currentDate,
            launchDate: launchDate,
            counters: ["test_counter": 1],
            events: ["test_event": currentDate.addingTimeInterval(-172800)]  // 2 days ago
        )
        let advancedSpec = AdvancedCompositeSpec(
            baseSpec: baseSpec,
            requireWeekdays: true
        )

        // When
        let result = advancedSpec.isSatisfiedBy(context)

        // Then
        XCTAssertTrue(result, "AdvancedCompositeSpec should satisfy on weekdays")
    }

    func testAdvancedCompositeSpec_WithMinimumEngagement() {
        // Given
        let baseSpec = CompositeSpec(
            minimumLaunchDelay: 60,
            maxShowCount: 3,
            cooldownDays: 1,
            counterKey: "test_counter",
            eventKey: "test_event"
        )
        let currentDate = Date()
        let launchDate = currentDate.addingTimeInterval(-120)  // 2 minutes ago
        let context = EvaluationContext(
            currentDate: currentDate,
            launchDate: launchDate,
            counters: ["test_counter": 1, "user_engagement_score": 85],
            events: ["test_event": currentDate.addingTimeInterval(-172800)]  // 2 days ago
        )
        let advancedSpec = AdvancedCompositeSpec(
            baseSpec: baseSpec,
            minimumEngagementLevel: 80
        )

        // When
        let result = advancedSpec.isSatisfiedBy(context)

        // Then
        XCTAssertTrue(result, "AdvancedCompositeSpec should satisfy with sufficient engagement")
    }

    func testAdvancedCompositeSpec_WithMinimumEngagement_FailsLowEngagement() {
        // Given
        let baseSpec = CompositeSpec(
            minimumLaunchDelay: 60,
            maxShowCount: 3,
            cooldownDays: 1,
            counterKey: "test_counter",
            eventKey: "test_event"
        )
        let currentDate = Date()
        let launchDate = currentDate.addingTimeInterval(-120)  // 2 minutes ago
        let context = EvaluationContext(
            currentDate: currentDate,
            launchDate: launchDate,
            counters: ["test_counter": 1, "user_engagement_score": 50],
            events: ["test_event": currentDate.addingTimeInterval(-172800)]  // 2 days ago
        )
        let advancedSpec = AdvancedCompositeSpec(
            baseSpec: baseSpec,
            minimumEngagementLevel: 80
        )

        // When
        let result = advancedSpec.isSatisfiedBy(context)

        // Then
        XCTAssertFalse(result, "AdvancedCompositeSpec should fail with low engagement")
    }

    // MARK: - ECommercePromoBannerSpec Tests

    func testECommercePromoBannerSpec_AllConditionsMet() {
        // Given
        let calendar = Calendar.current
        let currentDate = calendar.date(bySettingHour: 15, minute: 0, second: 0, of: Date())! // 3 PM (shopping hours)
        let launchDate = currentDate.addingTimeInterval(-180)  // 3 minutes ago
        let context = EvaluationContext(
            currentDate: currentDate,
            launchDate: launchDate,
            counters: ["products_viewed": 5],
            events: [
                "last_purchase": currentDate.addingTimeInterval(-172800),  // 2 days ago
                "last_promo_shown": currentDate.addingTimeInterval(-18000)  // 5 hours ago
            ]
        )
        let spec = ECommercePromoBannerSpec()

        // When
        let result = spec.isSatisfiedBy(context)

        // Then
        XCTAssertTrue(result, "ECommercePromoBannerSpec should be satisfied when all conditions are met")
    }

    func testECommercePromoBannerSpec_FailsInsufficientActivity() {
        // Given
        let calendar = Calendar.current
        let currentDate = calendar.date(bySettingHour: 15, minute: 0, second: 0, of: Date())! // 3 PM
        let launchDate = currentDate.addingTimeInterval(-60)  // 1 minute ago (insufficient)
        let context = EvaluationContext(
            currentDate: currentDate,
            launchDate: launchDate,
            counters: ["products_viewed": 5],
            events: [
                "last_purchase": currentDate.addingTimeInterval(-172800),  // 2 days ago
                "last_promo_shown": currentDate.addingTimeInterval(-18000)  // 5 hours ago
            ]
        )
        let spec = ECommercePromoBannerSpec()

        // When
        let result = spec.isSatisfiedBy(context)

        // Then
        XCTAssertFalse(result, "ECommercePromoBannerSpec should fail with insufficient activity time")
    }

    func testECommercePromoBannerSpec_FailsInsufficientProductViews() {
        // Given
        let calendar = Calendar.current
        let currentDate = calendar.date(bySettingHour: 15, minute: 0, second: 0, of: Date())! // 3 PM
        let launchDate = currentDate.addingTimeInterval(-180)  // 3 minutes ago
        let context = EvaluationContext(
            currentDate: currentDate,
            launchDate: launchDate,
            counters: ["products_viewed": 2],  // Insufficient (needs 3+)
            events: [
                "last_purchase": currentDate.addingTimeInterval(-172800),  // 2 days ago
                "last_promo_shown": currentDate.addingTimeInterval(-18000)  // 5 hours ago
            ]
        )
        let spec = ECommercePromoBannerSpec()

        // When
        let result = spec.isSatisfiedBy(context)

        // Then
        XCTAssertFalse(result, "ECommercePromoBannerSpec should fail with insufficient product views")
    }

    func testECommercePromoBannerSpec_FailsOutsideShoppingHours() {
        // Given
        let calendar = Calendar.current
        let currentDate = calendar.date(bySettingHour: 23, minute: 0, second: 0, of: Date())! // 11 PM (outside shopping hours)
        let launchDate = currentDate.addingTimeInterval(-180)  // 3 minutes ago
        let context = EvaluationContext(
            currentDate: currentDate,
            launchDate: launchDate,
            counters: ["products_viewed": 5],
            events: [
                "last_purchase": currentDate.addingTimeInterval(-172800),  // 2 days ago
                "last_promo_shown": currentDate.addingTimeInterval(-18000)  // 5 hours ago
            ]
        )
        let spec = ECommercePromoBannerSpec()

        // When
        let result = spec.isSatisfiedBy(context)

        // Then
        XCTAssertFalse(result, "ECommercePromoBannerSpec should fail outside shopping hours")
    }

    // MARK: - SubscriptionUpgradeSpec Tests

    func testSubscriptionUpgradeSpec_AllConditionsMet() {
        // Given
        let currentDate = Date()
        let launchDate = currentDate.addingTimeInterval(-1209600)  // 2 weeks ago
        let context = EvaluationContext(
            currentDate: currentDate,
            launchDate: launchDate,
            counters: [
                "premium_feature_usage": 8,
                "app_opens": 15
            ],
            flags: ["is_premium_subscriber": false],
            events: ["last_upgrade_prompt": currentDate.addingTimeInterval(-345600)]  // 4 days ago
        )
        let spec = SubscriptionUpgradeSpec()

        // When
        let result = spec.isSatisfiedBy(context)

        // Then
        XCTAssertTrue(result, "SubscriptionUpgradeSpec should be satisfied when all conditions are met")
    }

    func testSubscriptionUpgradeSpec_FailsPremiumSubscriber() {
        // Given
        let currentDate = Date()
        let launchDate = currentDate.addingTimeInterval(-1209600)  // 2 weeks ago
        let context = EvaluationContext(
            currentDate: currentDate,
            launchDate: launchDate,
            counters: [
                "premium_feature_usage": 8,
                "app_opens": 15
            ],
            flags: ["is_premium_subscriber": true],  // Already premium
            events: ["last_upgrade_prompt": currentDate.addingTimeInterval(-345600)]  // 4 days ago
        )
        let spec = SubscriptionUpgradeSpec()

        // When
        let result = spec.isSatisfiedBy(context)

        // Then
        XCTAssertFalse(result, "SubscriptionUpgradeSpec should fail for premium subscribers")
    }

    func testSubscriptionUpgradeSpec_FailsInsufficientPremiumUsage() {
        // Given
        let currentDate = Date()
        let launchDate = currentDate.addingTimeInterval(-1209600)  // 2 weeks ago
        let context = EvaluationContext(
            currentDate: currentDate,
            launchDate: launchDate,
            counters: [
                "premium_feature_usage": 3,  // Insufficient (needs 5+)
                "app_opens": 15
            ],
            flags: ["is_premium_subscriber": false],
            events: ["last_upgrade_prompt": currentDate.addingTimeInterval(-345600)]  // 4 days ago
        )
        let spec = SubscriptionUpgradeSpec()

        // When
        let result = spec.isSatisfiedBy(context)

        // Then
        XCTAssertFalse(result, "SubscriptionUpgradeSpec should fail with insufficient premium feature usage")
    }

    func testSubscriptionUpgradeSpec_FailsInsufficientAppOpens() {
        // Given
        let currentDate = Date()
        let launchDate = currentDate.addingTimeInterval(-1209600)  // 2 weeks ago
        let context = EvaluationContext(
            currentDate: currentDate,
            launchDate: launchDate,
            counters: [
                "premium_feature_usage": 8,
                "app_opens": 5  // Insufficient (needs 10+)
            ],
            flags: ["is_premium_subscriber": false],
            events: ["last_upgrade_prompt": currentDate.addingTimeInterval(-345600)]  // 4 days ago
        )
        let spec = SubscriptionUpgradeSpec()

        // When
        let result = spec.isSatisfiedBy(context)

        // Then
        XCTAssertFalse(result, "SubscriptionUpgradeSpec should fail with insufficient app opens")
    }
}

```


## Assistant

Now let me run the tests to ensure everything compiles and works correctly:

**Tool Call: `cd /Users/egor/Development/GitHub/SpecificationKit && swift test --filter testCompositeSpec`**
Status: Completed

Terminal:
```
[1/1] Planning build
Building for debugging...
/Users/egor/Development/GitHub/SpecificationKit/Tests/SpecificationKitTests/SpecificationKitTests.swift:967:13: error: argument 'events' must precede argument 'flags'
 965 |             ],
 966 |             flags: ["is_premium_subscriber": false],
 967 |             events: ["last_upgrade_prompt": currentDate.addingTimeInterval(-345600)]  // 4 days ago
     |             `- error: argument 'events' must precede argument 'flags'
 968 |         )
 969 |         let spec = SubscriptionUpgradeSpec()

/Users/egor/Development/GitHub/SpecificationKit/Tests/SpecificationKitTests/SpecificationKitTests.swift:991:13: error: argument 'events' must precede argument 'flags'
 989 |             ],
 990 |             flags: ["is_premium_subscriber": true],  // Already premium
 991 |             events: ["last_upgrade_prompt": currentDate.addingTimeInterval(-345600)]  // 4 days ago
     |             `- error: argument 'events' must precede argument 'flags'
 992 |         )
 993 |         let spec = SubscriptionUpgradeSpec()

/Users/egor/Development/GitHub/SpecificationKit/Tests/SpecificationKitTests/SpecificationKitTests.swift:1014:13: error: argument 'events' must precede argument 'flags'
1012 |             ],
1013 |             flags: ["is_premium_subscriber": false],
1014 |             events: ["last_upgrade_prompt": currentDate.addingTimeInterval(-345600)]  // 4 days ago
     |             `- error: argument 'events' must precede argument 'flags'
1015 |         )
1016 |         let spec = SubscriptionUpgradeSpec()

/Users/egor/Development/GitHub/SpecificationKit/Tests/SpecificationKitTests/SpecificationKitTests.swift:1038:13: error: argument 'events' must precede argument 'flags'
1036 |             ],
1037 |             flags: ["is_premium_subscriber": false],
1038 |             events: ["last_upgrade_prompt": currentDate.addingTimeInterval(-345600)]  // 4 days ago
     |             `- error: argument 'events' must precede argument 'flags'
1039 |         )
1040 |         let spec = SubscriptionUpgradeSpec()
[6/7] Compiling SpecificationKitTests Specifi…
error: fatalError

```


## Assistant

I need to fix the parameter order in the `EvaluationContext` initializer. Let me check the correct parameter order:

**Tool Call: mcp__serena__find_symbol**
Status: Completed

[]

**Tool Call: mcp__serena__find_symbol**
Status: Completed

[{"name_path": "SpecificationKit/Sources/SpecificationKit/Providers/EvaluationContext", "kind": "File", "body_location": {"start_line": 0, "end_line": 205}, "body": null, "relative_path": "Sources/SpecificationKit/Providers/EvaluationContext.swift"}, {"name_path": "EvaluationContext", "kind": "Struct", "body_location": {"start_line": 12, "end_line": 61}, "body": "public struct EvaluationContext {\n\n    /// The current date and time for time-based evaluations\n    public let currentDate: Date\n\n    /// Application launch time for calculating time since launch\n    public let launchDate: Date\n\n    /// A dictionary for storing arbitrary key-value data\n    public let userData: [String: Any]\n\n    /// A dictionary for storing counters and numeric values\n    public let counters: [String: Int]\n\n    /// A dictionary for storing date-based events\n    public let events: [String: Date]\n\n    /// A dictionary for storing boolean flags\n    public let flags: [String: Bool]\n\n    /// A set of user segments (e.g., \"vip\", \"beta\", etc.)\n    public let segments: Set<String>\n\n    /// Creates a new evaluation context with the specified parameters\n    /// - Parameters:\n    ///   - currentDate: The current date and time (defaults to now)\n    ///   - launchDate: The application launch date (defaults to now)\n    ///   - userData: Custom user data dictionary\n    ///   - counters: Numeric counters dictionary\n    ///   - events: Event timestamps dictionary\n    ///   - flags: Boolean flags dictionary\n    ///   - segments: Set of string segments\n    public init(\n        currentDate: Date = Date(),\n        launchDate: Date = Date(),\n        userData: [String: Any] = [:],\n        counters: [String: Int] = [:],\n        events: [String: Date] = [:],\n        flags: [String: Bool] = [:],\n        segments: Set<String> = []\n    ) {\n        self.currentDate = currentDate\n        self.launchDate = launchDate\n        self.userData = userData\n        self.counters = counters\n        self.events = events\n        self.flags = flags\n        self.segments = segments\n    }\n}", "relative_path": "Sources/SpecificationKit/Providers/EvaluationContext.swift"}, {"name_path": "EvaluationContext", "kind": "Namespace", "body_location": {"start_line": 65, "end_line": 81}, "body": "extension EvaluationContext {\n\n    /// Time interval since application launch in seconds\n    public var timeSinceLaunch: TimeInterval {\n        currentDate.timeIntervalSince(launchDate)\n    }\n\n    /// Current calendar components for date-based logic\n    public var calendar: Calendar {\n        Calendar.current\n    }\n\n    /// Current time zone\n    public var timeZone: TimeZone {\n        TimeZone.current\n    }\n}", "relative_path": "Sources/SpecificationKit/Providers/EvaluationContext.swift"}, {"name_path": "EvaluationContext", "kind": "Namespace", "body_location": {"start_line": 85, "end_line": 123}, "body": "extension EvaluationContext {\n\n    /// Gets a counter value for the given key\n    /// - Parameter key: The counter key\n    /// - Returns: The counter value, or 0 if not found\n    public func counter(for key: String) -> Int {\n        counters[key] ?? 0\n    }\n\n    /// Gets an event date for the given key\n    /// - Parameter key: The event key\n    /// - Returns: The event date, or nil if not found\n    public func event(for key: String) -> Date? {\n        events[key]\n    }\n\n    /// Gets a flag value for the given key\n    /// - Parameter key: The flag key\n    /// - Returns: The flag value, or false if not found\n    public func flag(for key: String) -> Bool {\n        flags[key] ?? false\n    }\n\n    /// Gets user data for the given key\n    /// - Parameter key: The data key\n    /// - Parameter type: The type of data\n    /// - Returns: The user data value, or nil if not found\n    public func userData<T>(for key: String, as type: T.Type = T.self) -> T? {\n        userData[key] as? T\n    }\n\n    /// Calculates time since an event occurred\n    /// - Parameter eventKey: The event key\n    /// - Returns: Time interval since the event, or nil if event not found\n    public func timeSinceEvent(_ eventKey: String) -> TimeInterval? {\n        guard let eventDate = event(for: eventKey) else { return nil }\n        return currentDate.timeIntervalSince(eventDate)\n    }\n}", "relative_path": "Sources/SpecificationKit/Providers/EvaluationContext.swift"}, {"name_path": "EvaluationContext", "kind": "Namespace", "body_location": {"start_line": 127, "end_line": 203}, "body": "extension EvaluationContext {\n\n    /// Creates a new context with updated user data\n    /// - Parameter userData: The new user data dictionary\n    /// - Returns: A new EvaluationContext with the updated user data\n    public func withUserData(_ userData: [String: Any]) -> EvaluationContext {\n        EvaluationContext(\n            currentDate: currentDate,\n            launchDate: launchDate,\n            userData: userData,\n            counters: counters,\n            events: events,\n            flags: flags,\n            segments: segments\n        )\n    }\n\n    /// Creates a new context with updated counters\n    /// - Parameter counters: The new counters dictionary\n    /// - Returns: A new EvaluationContext with the updated counters\n    public func withCounters(_ counters: [String: Int]) -> EvaluationContext {\n        EvaluationContext(\n            currentDate: currentDate,\n            launchDate: launchDate,\n            userData: userData,\n            counters: counters,\n            events: events,\n            flags: flags,\n            segments: segments\n        )\n    }\n\n    /// Creates a new context with updated events\n    /// - Parameter events: The new events dictionary\n    /// - Returns: A new EvaluationContext with the updated events\n    public func withEvents(_ events: [String: Date]) -> EvaluationContext {\n        EvaluationContext(\n            currentDate: currentDate,\n            launchDate: launchDate,\n            userData: userData,\n            counters: counters,\n            events: events,\n            flags: flags,\n            segments: segments\n        )\n    }\n\n    /// Creates a new context with updated flags\n    /// - Parameter flags: The new flags dictionary\n    /// - Returns: A new EvaluationContext with the updated flags\n    public func withFlags(_ flags: [String: Bool]) -> EvaluationContext {\n        EvaluationContext(\n            currentDate: currentDate,\n            launchDate: launchDate,\n            userData: userData,\n            counters: counters,\n            events: events,\n            flags: flags,\n            segments: segments\n        )\n    }\n\n    /// Creates a new context with an updated current date\n    /// - Parameter currentDate: The new current date\n    /// - Returns: A new EvaluationContext with the updated current date\n    public func withCurrentDate(_ currentDate: Date) -> EvaluationContext {\n        EvaluationContext(\n            currentDate: currentDate,\n            launchDate: launchDate,\n            userData: userData,\n            counters: counters,\n            events: events,\n            flags: flags,\n            segments: segments\n        )\n    }\n}", "relative_path": "Sources/SpecificationKit/Providers/EvaluationContext.swift"}]

## Assistant

I can see from the EvaluationContext initializer that the correct parameter order is: `currentDate`, `launchDate`, `userData`, `counters`, `events`, `flags`, `segments`. I need to fix the parameter order in my tests where I put `flags` before `events`.

**Tool Call: Edit /Users/egor/Development/GitHub/SpecificationKit/Tests/SpecificationKitTests/SpecificationKitTests.swift**
Status: Failed

```
The provided `old_string` does not appear in the file: "        let context = EvaluationContext(
            currentDate: currentDate,
            launchDate: launchDate,
            counters: [
                "premium_feature_usage": 8,
                "app_opens": 15
            ],
            flags: ["is_premium_subscriber": false],
            events: ["last_upgrade_prompt": currentDate.addingTimeInterval(-345600)]  // 4 days ago
        )".

No edits were applied.
```

## Assistant

Let me check the exact content around those lines to get the correct formatting:

**Tool Call: Read /Users/egor/Development/GitHub/SpecificationKit/Tests/SpecificationKitTests/SpecificationKitTests.swift (from line 961)**
Status: Completed

```
            launchDate: launchDate,
            counters: [
                "premium_feature_usage": 8,
                "app_opens": 15,
            ],
            flags: ["is_premium_subscriber": false],
            events: ["last_upgrade_prompt": currentDate.addingTimeInterval(-345600)]  // 4 days ago
        )
        let spec = SubscriptionUpgradeSpec()

        // When
        let result = spec.isSatisfiedBy(context)

        // Then
        XCTAssertTrue(

<file-read-info>Read lines 961-974. </file-read-info>
```

## Assistant

I can see there are trailing commas in the arrays. Let me fix all four instances:

**Tool Call: Edit /Users/egor/Development/GitHub/SpecificationKit/Tests/SpecificationKitTests/SpecificationKitTests.swift**
Status: Completed

Diff: /Users/egor/Development/GitHub/SpecificationKit/Tests/SpecificationKitTests/SpecificationKitTests.swift
```
//
//  SpecificationKitTests.swift
//  SpecificationKitTests
//
//  Created by SpecificationKit on 2025.
//

import XCTest

@testable import SpecificationKit

final class SpecificationKitTests: XCTestCase {

    // MARK: - TimeSinceEventSpec Tests

    func testTimeSinceEventSpec_WhenEventNeverOccurred_ReturnTrue() {
        // Given
        let context = EvaluationContext(
            currentDate: Date(),
            events: [:]
        )
        let spec = TimeSinceEventSpec(eventKey: "test_event", minimumInterval: 60)

        // When
        let result = spec.isSatisfiedBy(context)

        // Then
        XCTAssertTrue(result, "Specification should be satisfied when event never occurred")
    }

    func testTimeSinceEventSpec_WhenEnoughTimePassed_ReturnTrue() {
        // Given
        let currentDate = Date()
        let eventDate = currentDate.addingTimeInterval(-120)  // 2 minutes ago
        let context = EvaluationContext(
            currentDate: currentDate,
            events: ["test_event": eventDate]
        )
        let spec = TimeSinceEventSpec(eventKey: "test_event", minimumInterval: 60)  // 1 minute required

        // When
        let result = spec.isSatisfiedBy(context)

        // Then
        XCTAssertTrue(result, "Specification should be satisfied when enough time has passed")
    }

    func testTimeSinceEventSpec_WhenNotEnoughTimePassed_ReturnFalse() {
        // Given
        let currentDate = Date()
        let eventDate = currentDate.addingTimeInterval(-30)  // 30 seconds ago
        let context = EvaluationContext(
            currentDate: currentDate,
            events: ["test_event": eventDate]
        )
        let spec = TimeSinceEventSpec(eventKey: "test_event", minimumInterval: 60)  // 1 minute required

        // When
        let result = spec.isSatisfiedBy(context)

        // Then
        XCTAssertFalse(
            result, "Specification should not be satisfied when not enough time has passed")
    }

    func testTimeSinceEventSpec_ConvenienceInitializers() {
        let spec1 = TimeSinceEventSpec(eventKey: "test", seconds: 60)
        let spec2 = TimeSinceEventSpec(eventKey: "test", minutes: 1)
        let spec3 = TimeSinceEventSpec(eventKey: "test", hours: 1)
        let spec4 = TimeSinceEventSpec(eventKey: "test", days: 1)

        XCTAssertEqual(spec1.minimumInterval, 60)
        XCTAssertEqual(spec2.minimumInterval, 60)
        XCTAssertEqual(spec3.minimumInterval, 3600)
        XCTAssertEqual(spec4.minimumInterval, 86400)
    }

    // MARK: - MaxCountSpec Tests

    func testMaxCountSpec_WhenCountBelowLimit_ReturnTrue() {
        // Given
        let context = EvaluationContext(
            counters: ["test_counter": 2]
        )
        let spec = MaxCountSpec(counterKey: "test_counter", limit: 5)

        // When
        let result = spec.isSatisfiedBy(context)

        // Then
        XCTAssertTrue(result, "Specification should be satisfied when count is below limit")
    }

    func testMaxCountSpec_WhenCountAtLimit_ReturnFalse() {
        // Given
        let context = EvaluationContext(
            counters: ["test_counter": 5]
        )
        let spec = MaxCountSpec(counterKey: "test_counter", limit: 5)

        // When
        let result = spec.isSatisfiedBy(context)

        // Then
        XCTAssertFalse(result, "Specification should not be satisfied when count equals limit")
    }

    func testMaxCountSpec_WhenCountAboveLimit_ReturnFalse() {
        // Given
        let context = EvaluationContext(
            counters: ["test_counter": 7]
        )
        let spec = MaxCountSpec(counterKey: "test_counter", limit: 5)

        // When
        let result = spec.isSatisfiedBy(context)

        // Then
        XCTAssertFalse(result, "Specification should not be satisfied when count exceeds limit")
    }

    func testMaxCountSpec_WhenCounterNotExists_ReturnTrue() {
        // Given
        let context = EvaluationContext(
            counters: [:]
        )
        let spec = MaxCountSpec(counterKey: "nonexistent_counter", limit: 5)

        // When
        let result = spec.isSatisfiedBy(context)

        // Then
        XCTAssertTrue(
            result, "Specification should be satisfied when counter doesn't exist (defaults to 0)")
    }

    // MARK: - CooldownIntervalSpec Tests

    func testCooldownIntervalSpec_WhenNoPreviousEvent_ReturnTrue() {
        // Given
        let context = EvaluationContext(
            currentDate: Date(),
            events: [:]
        )
        let spec = CooldownIntervalSpec(eventKey: "test_event", cooldownInterval: 3600)

        // When
        let result = spec.isSatisfiedBy(context)

        // Then
        XCTAssertTrue(result, "Specification should be satisfied when no previous event exists")
    }

    func testCooldownIntervalSpec_WhenCooldownComplete_ReturnTrue() {
        // Given
        let currentDate = Date()
        let lastEvent = currentDate.addingTimeInterval(-7200)  // 2 hours ago
        let context = EvaluationContext(
            currentDate: currentDate,
            events: ["test_event": lastEvent]
        )
        let spec = CooldownIntervalSpec(eventKey: "test_event", cooldownInterval: 3600)  // 1 hour cooldown

        // When
        let result = spec.isSatisfiedBy(context)

        // Then
        XCTAssertTrue(result, "Specification should be satisfied when cooldown period has passed")
    }

    func testCooldownIntervalSpec_WhenCooldownActive_ReturnFalse() {
        // Given
        let currentDate = Date()
        let lastEvent = currentDate.addingTimeInterval(-1800)  // 30 minutes ago
        let context = EvaluationContext(
            currentDate: currentDate,
            events: ["test_event": lastEvent]
        )
        let spec = CooldownIntervalSpec(eventKey: "test_event", cooldownInterval: 3600)  // 1 hour cooldown

        // When
        let result = spec.isSatisfiedBy(context)

        // Then
        XCTAssertFalse(
            result, "Specification should not be satisfied when cooldown is still active")
    }

    // MARK: - PredicateSpec Tests

    func testPredicateSpec_WithCustomPredicate() {
        // Given
        let spec = PredicateSpec<Int> { value in
            value > 10
        }

        // When & Then
        XCTAssertTrue(spec.isSatisfiedBy(15))
        XCTAssertFalse(spec.isSatisfiedBy(5))
        XCTAssertFalse(spec.isSatisfiedBy(10))
    }

    func testPredicateSpec_AlwaysTrue() {
        // Given
        let spec = PredicateSpec<String>.alwaysTrue()

        // When & Then
        XCTAssertTrue(spec.isSatisfiedBy("anything"))
        XCTAssertTrue(spec.isSatisfiedBy(""))
    }

    func testPredicateSpec_AlwaysFalse() {
        // Given
        let spec = PredicateSpec<String>.alwaysFalse()

        // When & Then
        XCTAssertFalse(spec.isSatisfiedBy("anything"))
        XCTAssertFalse(spec.isSatisfiedBy(""))
    }

    // MARK: - Specification Operators Tests

    func testSpecificationOperators_And() {
        // Given
        let spec1 = PredicateSpec<Int> { $0 > 5 }
        let spec2 = PredicateSpec<Int> { $0 < 15 }
        let combinedSpec = spec1.and(spec2)

        // When & Then
        XCTAssertTrue(combinedSpec.isSatisfiedBy(10))
        XCTAssertFalse(combinedSpec.isSatisfiedBy(3))
        XCTAssertFalse(combinedSpec.isSatisfiedBy(20))
    }

    func testSpecificationOperators_Or() {
        // Given
        let spec1 = PredicateSpec<Int> { $0 < 5 }
        let spec2 = PredicateSpec<Int> { $0 > 15 }
        let combinedSpec = spec1.or(spec2)

        // When & Then
        XCTAssertTrue(combinedSpec.isSatisfiedBy(3))
        XCTAssertTrue(combinedSpec.isSatisfiedBy(20))
        XCTAssertFalse(combinedSpec.isSatisfiedBy(10))
    }

    func testSpecificationOperators_Not() {
        // Given
        let spec = PredicateSpec<Int> { $0 > 10 }
        let notSpec = spec.not()

        // When & Then
        XCTAssertFalse(notSpec.isSatisfiedBy(15))
        XCTAssertTrue(notSpec.isSatisfiedBy(5))
    }

    // MARK: - AnySpecification Tests

    func testAnySpecification_TypeErasure() {
        // Given
        let spec1 = PredicateSpec<Int> { $0 > 10 }
        let spec2 = MaxCountSpec(counterKey: "test", limit: 5)

        let anySpec1 = AnySpecification(spec1)
        let anySpec2 = AnySpecification(spec2)

        // When & Then
        XCTAssertTrue(anySpec1.isSatisfiedBy(15))
        XCTAssertFalse(anySpec1.isSatisfiedBy(5))

        let context = EvaluationContext(counters: ["test": 3])
        XCTAssertTrue(anySpec2.isSatisfiedBy(context))
    }

    func testAnySpecification_Always() {
        // Given
        let spec = AnySpecification<String>.always

        // When & Then
        XCTAssertTrue(spec.isSatisfiedBy("test"))
        XCTAssertTrue(spec.isSatisfiedBy(""))
    }

    func testAnySpecification_Never() {
        // Given
        let spec = AnySpecification<String>.never

        // When & Then
        XCTAssertFalse(spec.isSatisfiedBy("test"))
        XCTAssertFalse(spec.isSatisfiedBy(""))
    }

    // MARK: - EvaluationContext Tests

    func testEvaluationContext_TimeSinceLaunch() {
        // Given
        let launchDate = Date().addingTimeInterval(-300)  // 5 minutes ago
        let currentDate = Date()
        let context = EvaluationContext(
            currentDate: currentDate,
            launchDate: launchDate
        )

        // When
        let timeSinceLaunch = context.timeSinceLaunch

        // Then
        XCTAssertEqual(timeSinceLaunch, 300, accuracy: 1)
    }

    func testEvaluationContext_CounterAccess() {
        // Given
        let context = EvaluationContext(
            counters: ["test_counter": 42]
        )

        // When & Then
        XCTAssertEqual(context.counter(for: "test_counter"), 42)
        XCTAssertEqual(context.counter(for: "nonexistent"), 0)
    }

    func testEvaluationContext_EventAccess() {
        // Given
        let testDate = Date()
        let context = EvaluationContext(
            events: ["test_event": testDate]
        )

        // When & Then
        XCTAssertEqual(context.event(for: "test_event"), testDate)
        XCTAssertNil(context.event(for: "nonexistent"))
    }

    func testEvaluationContext_FlagAccess() {
        // Given
        let context = EvaluationContext(
            flags: ["test_flag": true, "false_flag": false]
        )

        // When & Then
        XCTAssertTrue(context.flag(for: "test_flag"))
        XCTAssertFalse(context.flag(for: "false_flag"))
        XCTAssertFalse(context.flag(for: "nonexistent"))
    }

    // MARK: - DefaultContextProvider Tests

    func testDefaultContextProvider_CounterManagement() {
        // Given
        let provider = DefaultContextProvider()

        // When
        provider.setCounter("test", to: 5)
        provider.incrementCounter("test", by: 3)

        // Then
        XCTAssertEqual(provider.getCounter("test"), 8)

        // When
        provider.decrementCounter("test", by: 2)

        // Then
        XCTAssertEqual(provider.getCounter("test"), 6)
    }

    func testDefaultContextProvider_EventManagement() {
        // Given
        let provider = DefaultContextProvider()
        let testDate = Date()

        // When
        provider.recordEvent("test_event", at: testDate)

        // Then
        XCTAssertEqual(provider.getEvent("test_event"), testDate)

        // When
        provider.removeEvent("test_event")

        // Then
        XCTAssertNil(provider.getEvent("test_event"))
    }

    func testDefaultContextProvider_FlagManagement() {
        // Given
        let provider = DefaultContextProvider()

        // When
        provider.setFlag("test_flag", to: true)

        // Then
        XCTAssertTrue(provider.getFlag("test_flag"))

        // When
        let toggled = provider.toggleFlag("test_flag")

        // Then
        XCTAssertFalse(toggled)
        XCTAssertFalse(provider.getFlag("test_flag"))
    }

    // MARK: - MockContextProvider Tests

    func testMockContextProvider_BasicUsage() {
        // Given
        let context = EvaluationContext(
            counters: ["test": 5],
            flags: ["enabled": true]
        )
        let provider = MockContextProvider(context: context)

        // When
        let retrievedContext = provider.currentContext()

        // Then
        XCTAssertEqual(retrievedContext.counter(for: "test"), 5)
        XCTAssertTrue(retrievedContext.flag(for: "enabled"))
        XCTAssertEqual(provider.contextRequestCount, 1)
    }

    func testMockContextProvider_RequestTracking() {
        // Given
        let provider = MockContextProvider()
        var callbackCount = 0
        provider.onContextRequested = {
            callbackCount += 1
        }

        // When
        _ = provider.currentContext()
        _ = provider.currentContext()

        // Then
        XCTAssertEqual(provider.contextRequestCount, 2)
        XCTAssertEqual(callbackCount, 2)
    }

    // MARK: - CompositeSpec Tests

    func testCompositeSpec_DefaultConfiguration() {
        // Given
        let currentDate = Date()
        let launchDate = currentDate.addingTimeInterval(-15)  // 15 seconds ago
        let context = EvaluationContext(
            currentDate: currentDate,
            launchDate: launchDate,
            counters: ["banner_shown": 1],
            events: ["last_banner_shown": currentDate.addingTimeInterval(-604800)]  // 1 week ago
        )
        let spec = CompositeSpec()

        // When
        let result = spec.isSatisfiedBy(context)

        // Then
        XCTAssertTrue(result, "CompositeSpec should be satisfied with valid conditions")
    }

    func testCompositeSpec_FailsWhenCountExceedsLimit() {
        // Given
        let currentDate = Date()
        let launchDate = currentDate.addingTimeInterval(-15)  // 15 seconds ago
        let context = EvaluationContext(
            currentDate: currentDate,
            launchDate: launchDate,
            counters: ["banner_shown": 5],  // Exceeds limit of 3
            events: ["last_banner_shown": currentDate.addingTimeInterval(-604800)]  // 1 week ago
        )
        let spec = CompositeSpec()

        // When
        let result = spec.isSatisfiedBy(context)

        // Then
        XCTAssertFalse(result, "CompositeSpec should fail when count exceeds limit")
    }

    func testCompositeSpec_CustomConfiguration() {
        // Given
        let currentDate = Date()
        let launchDate = currentDate.addingTimeInterval(-300)  // 5 minutes ago
        let context = EvaluationContext(
            currentDate: currentDate,
            launchDate: launchDate,
            counters: ["custom_counter": 2],
            events: ["custom_event": currentDate.addingTimeInterval(-172800)]  // 2 days ago
        )
        let spec = CompositeSpec(
            minimumLaunchDelay: 60,  // 1 minute
            maxShowCount: 5,
            cooldownDays: 1,  // 1 day
            counterKey: "custom_counter",
            eventKey: "custom_event"
        )

        // When
        let result = spec.isSatisfiedBy(context)

        // Then
        XCTAssertTrue(result, "Custom CompositeSpec should be satisfied")
    }

    func testCompositeSpec_CustomConfiguration_FailsInsufficientTime() {
        // Given
        let currentDate = Date()
        let launchDate = currentDate.addingTimeInterval(-30)  // 30 seconds ago
        let context = EvaluationContext(
            currentDate: currentDate,
            launchDate: launchDate,
            counters: ["custom_counter": 2],
            events: ["custom_event": currentDate.addingTimeInterval(-172800)]  // 2 days ago
        )
        let spec = CompositeSpec(
            minimumLaunchDelay: 60,  // 1 minute required
            maxShowCount: 5,
            cooldownDays: 1,
            counterKey: "custom_counter",
            eventKey: "custom_event"
        )

        // When
        let result = spec.isSatisfiedBy(context)

        // Then
        XCTAssertFalse(result, "Custom CompositeSpec should fail when insufficient time has passed")
    }

    func testCompositeSpec_PromoBanner() {
        // Given
        let currentDate = Date()
        let launchDate = currentDate.addingTimeInterval(-60)  // 1 minute ago
        let context = EvaluationContext(
            currentDate: currentDate,
            launchDate: launchDate,
            counters: ["promo_banner_count": 1],
            events: ["last_promo_banner": currentDate.addingTimeInterval(-259200)]  // 3 days ago
        )

        // When
        let result = CompositeSpec.promoBanner.isSatisfiedBy(context)

        // Then
        XCTAssertTrue(result, "PromoBanner spec should be satisfied")
    }

    func testCompositeSpec_PromoBanner_FailsMaxCount() {
        // Given
        let currentDate = Date()
        let launchDate = currentDate.addingTimeInterval(-60)  // 1 minute ago
        let context = EvaluationContext(
            currentDate: currentDate,
            launchDate: launchDate,
            counters: ["promo_banner_count": 3],  // Exceeds limit of 2
            events: ["last_promo_banner": currentDate.addingTimeInterval(-259200)]  // 3 days ago
        )

        // When
        let result = CompositeSpec.promoBanner.isSatisfiedBy(context)

        // Then
        XCTAssertFalse(result, "PromoBanner spec should fail when max count exceeded")
    }

    func testCompositeSpec_OnboardingTip() {
        // Given
        let currentDate = Date()
        let launchDate = currentDate.addingTimeInterval(-10)  // 10 seconds ago
        let context = EvaluationContext(
            currentDate: currentDate,
            launchDate: launchDate,
            counters: ["onboarding_tip_count": 2],
            events: ["last_onboarding_tip": currentDate.addingTimeInterval(-7200)]  // 2 hours ago
        )

        // When
        let result = CompositeSpec.onboardingTip.isSatisfiedBy(context)

        // Then
        XCTAssertTrue(result, "OnboardingTip spec should be satisfied")
    }

    func testCompositeSpec_OnboardingTip_FailsCooldown() {
        // Given
        let currentDate = Date()
        let launchDate = currentDate.addingTimeInterval(-10)  // 10 seconds ago
        let context = EvaluationContext(
            currentDate: currentDate,
            launchDate: launchDate,
            counters: ["onboarding_tip_count": 2],
            events: ["last_onboarding_tip": currentDate.addingTimeInterval(-1800)]  // 30 minutes ago (within 1 hour cooldown)
        )

        // When
        let result = CompositeSpec.onboardingTip.isSatisfiedBy(context)

        // Then
        XCTAssertFalse(result, "OnboardingTip spec should fail within cooldown period")
    }

    func testCompositeSpec_FeatureAnnouncement() {
        // Given
        let currentDate = Date()
        let launchDate = currentDate.addingTimeInterval(-120)  // 2 minutes ago
        let context = EvaluationContext(
            currentDate: currentDate,
            launchDate: launchDate,
            counters: ["feature_announcement_count": 0],
            events: [:]
        )

        // When
        let result = CompositeSpec.featureAnnouncement.isSatisfiedBy(context)

        // Then
        XCTAssertTrue(result, "FeatureAnnouncement spec should be satisfied")
    }

    func testCompositeSpec_FeatureAnnouncement_FailsMaxCount() {
        // Given
        let currentDate = Date()
        let launchDate = currentDate.addingTimeInterval(-120)  // 2 minutes ago
        let context = EvaluationContext(
            currentDate: currentDate,
            launchDate: launchDate,
            counters: ["feature_announcement_count": 1],  // Max is 1
            events: [:]
        )

        // When
        let result = CompositeSpec.featureAnnouncement.isSatisfiedBy(context)

        // Then
        XCTAssertFalse(result, "FeatureAnnouncement spec should fail when max count reached")
    }

    func testCompositeSpec_RatingPrompt() {
        // Given
        let currentDate = Date()
        let launchDate = currentDate.addingTimeInterval(-600)  // 10 minutes ago
        let context = EvaluationContext(
            currentDate: currentDate,
            launchDate: launchDate,
            counters: ["rating_prompt_count": 1],
            events: ["last_rating_prompt": currentDate.addingTimeInterval(-1_209_600)]  // 2 weeks ago
        )

        // When
        let result = CompositeSpec.ratingPrompt.isSatisfiedBy(context)

        // Then
        XCTAssertTrue(result, "RatingPrompt spec should be satisfied")
    }

    func testCompositeSpec_RatingPrompt_FailsInsufficientTime() {
        // Given
        let currentDate = Date()
        let launchDate = currentDate.addingTimeInterval(-120)  // 2 minutes ago (less than 5 minutes required)
        let context = EvaluationContext(
            currentDate: currentDate,
            launchDate: launchDate,
            counters: ["rating_prompt_count": 1],
            events: ["last_rating_prompt": currentDate.addingTimeInterval(-1_209_600)]  // 2 weeks ago
        )

        // When
        let result = CompositeSpec.ratingPrompt.isSatisfiedBy(context)

        // Then
        XCTAssertFalse(result, "RatingPrompt spec should fail with insufficient launch time")
    }

    // MARK: - AdvancedCompositeSpec Tests

    func testAdvancedCompositeSpec_BasicComposition() {
        // Given
        let baseSpec = CompositeSpec(
            minimumLaunchDelay: 60,
            maxShowCount: 3,
            cooldownDays: 1,
            counterKey: "test_counter",
            eventKey: "test_event"
        )
        let currentDate = Date()
        let launchDate = currentDate.addingTimeInterval(-120)  // 2 minutes ago
        let context = EvaluationContext(
            currentDate: currentDate,
            launchDate: launchDate,
            counters: ["test_counter": 1],
            events: ["test_event": currentDate.addingTimeInterval(-172800)]  // 2 days ago
        )
        let advancedSpec = AdvancedCompositeSpec(baseSpec: baseSpec)

        // When
        let result = advancedSpec.isSatisfiedBy(context)

        // Then
        XCTAssertTrue(result, "AdvancedCompositeSpec should satisfy base spec")
    }

    func testAdvancedCompositeSpec_WithBusinessHours() {
        // Given
        let baseSpec = CompositeSpec(
            minimumLaunchDelay: 60,
            maxShowCount: 3,
            cooldownDays: 1,
            counterKey: "test_counter",
            eventKey: "test_event"
        )

        // Create a date during business hours (2 PM)
        let calendar = Calendar.current
        let currentDate = calendar.date(bySettingHour: 14, minute: 0, second: 0, of: Date())!
        let launchDate = currentDate.addingTimeInterval(-120)  // 2 minutes ago
        let context = EvaluationContext(
            currentDate: currentDate,
            launchDate: launchDate,
            counters: ["test_counter": 1],
            events: ["test_event": currentDate.addingTimeInterval(-172800)]  // 2 days ago
        )
        let advancedSpec = AdvancedCompositeSpec(
            baseSpec: baseSpec,
            requireBusinessHours: true
        )

        // When
        let result = advancedSpec.isSatisfiedBy(context)

        // Then
        XCTAssertTrue(result, "AdvancedCompositeSpec should satisfy during business hours")
    }

    func testAdvancedCompositeSpec_WithBusinessHours_FailsOutsideHours() {
        // Given
        let baseSpec = CompositeSpec(
            minimumLaunchDelay: 60,
            maxShowCount: 3,
            cooldownDays: 1,
            counterKey: "test_counter",
            eventKey: "test_event"
        )

        // Create a date outside business hours (8 PM)
        let calendar = Calendar.current
        let currentDate = calendar.date(bySettingHour: 20, minute: 0, second: 0, of: Date())!
        let launchDate = currentDate.addingTimeInterval(-120)  // 2 minutes ago
        let context = EvaluationContext(
            currentDate: currentDate,
            launchDate: launchDate,
            counters: ["test_counter": 1],
            events: ["test_event": currentDate.addingTimeInterval(-172800)]  // 2 days ago
        )
        let advancedSpec = AdvancedCompositeSpec(
            baseSpec: baseSpec,
            requireBusinessHours: true
        )

        // When
        let result = advancedSpec.isSatisfiedBy(context)

        // Then
        XCTAssertFalse(result, "AdvancedCompositeSpec should fail outside business hours")
    }

    func testAdvancedCompositeSpec_WithWeekdays() {
        // Given
        let baseSpec = CompositeSpec(
            minimumLaunchDelay: 60,
            maxShowCount: 3,
            cooldownDays: 1,
            counterKey: "test_counter",
            eventKey: "test_event"
        )

        // Create a date on a weekday (Tuesday)
        let calendar = Calendar.current
        let currentDate =
            calendar.dateInterval(of: .weekOfYear, for: Date())?.start.addingTimeInterval(86400)
            ?? Date()  // Tuesday
        let launchDate = currentDate.addingTimeInterval(-120)  // 2 minutes ago
        let context = EvaluationContext(
            currentDate: currentDate,
            launchDate: launchDate,
            counters: ["test_counter": 1],
            events: ["test_event": currentDate.addingTimeInterval(-172800)]  // 2 days ago
        )
        let advancedSpec = AdvancedCompositeSpec(
            baseSpec: baseSpec,
            requireWeekdays: true
        )

        // When
        let result = advancedSpec.isSatisfiedBy(context)

        // Then
        XCTAssertTrue(result, "AdvancedCompositeSpec should satisfy on weekdays")
    }

    func testAdvancedCompositeSpec_WithMinimumEngagement() {
        // Given
        let baseSpec = CompositeSpec(
            minimumLaunchDelay: 60,
            maxShowCount: 3,
            cooldownDays: 1,
            counterKey: "test_counter",
            eventKey: "test_event"
        )
        let currentDate = Date()
        let launchDate = currentDate.addingTimeInterval(-120)  // 2 minutes ago
        let context = EvaluationContext(
            currentDate: currentDate,
            launchDate: launchDate,
            counters: ["test_counter": 1, "user_engagement_score": 85],
            events: ["test_event": currentDate.addingTimeInterval(-172800)]  // 2 days ago
        )
        let advancedSpec = AdvancedCompositeSpec(
            baseSpec: baseSpec,
            minimumEngagementLevel: 80
        )

        // When
        let result = advancedSpec.isSatisfiedBy(context)

        // Then
        XCTAssertTrue(result, "AdvancedCompositeSpec should satisfy with sufficient engagement")
    }

    func testAdvancedCompositeSpec_WithMinimumEngagement_FailsLowEngagement() {
        // Given
        let baseSpec = CompositeSpec(
            minimumLaunchDelay: 60,
            maxShowCount: 3,
            cooldownDays: 1,
            counterKey: "test_counter",
            eventKey: "test_event"
        )
        let currentDate = Date()
        let launchDate = currentDate.addingTimeInterval(-120)  // 2 minutes ago
        let context = EvaluationContext(
            currentDate: currentDate,
            launchDate: launchDate,
            counters: ["test_counter": 1, "user_engagement_score": 50],
            events: ["test_event": currentDate.addingTimeInterval(-172800)]  // 2 days ago
        )
        let advancedSpec = AdvancedCompositeSpec(
            baseSpec: baseSpec,
            minimumEngagementLevel: 80
        )

        // When
        let result = advancedSpec.isSatisfiedBy(context)

        // Then
        XCTAssertFalse(result, "AdvancedCompositeSpec should fail with low engagement")
    }

    // MARK: - ECommercePromoBannerSpec Tests

    func testECommercePromoBannerSpec_AllConditionsMet() {
        // Given
        let calendar = Calendar.current
        let currentDate = calendar.date(bySettingHour: 15, minute: 0, second: 0, of: Date())!  // 3 PM (shopping hours)
        let launchDate = currentDate.addingTimeInterval(-180)  // 3 minutes ago
        let context = EvaluationContext(
            currentDate: currentDate,
            launchDate: launchDate,
            counters: ["products_viewed": 5],
            events: [
                "last_purchase": currentDate.addingTimeInterval(-172800),  // 2 days ago
                "last_promo_shown": currentDate.addingTimeInterval(-18000),  // 5 hours ago
            ]
        )
        let spec = ECommercePromoBannerSpec()

        // When
        let result = spec.isSatisfiedBy(context)

        // Then
        XCTAssertTrue(
            result, "ECommercePromoBannerSpec should be satisfied when all conditions are met")
    }

    func testECommercePromoBannerSpec_FailsInsufficientActivity() {
        // Given
        let calendar = Calendar.current
        let currentDate = calendar.date(bySettingHour: 15, minute: 0, second: 0, of: Date())!  // 3 PM
        let launchDate = currentDate.addingTimeInterval(-60)  // 1 minute ago (insufficient)
        let context = EvaluationContext(
            currentDate: currentDate,
            launchDate: launchDate,
            counters: ["products_viewed": 5],
            events: [
                "last_purchase": currentDate.addingTimeInterval(-172800),  // 2 days ago
                "last_promo_shown": currentDate.addingTimeInterval(-18000),  // 5 hours ago
            ]
        )
        let spec = ECommercePromoBannerSpec()

        // When
        let result = spec.isSatisfiedBy(context)

        // Then
        XCTAssertFalse(
            result, "ECommercePromoBannerSpec should fail with insufficient activity time")
    }

    func testECommercePromoBannerSpec_FailsInsufficientProductViews() {
        // Given
        let calendar = Calendar.current
        let currentDate = calendar.date(bySettingHour: 15, minute: 0, second: 0, of: Date())!  // 3 PM
        let launchDate = currentDate.addingTimeInterval(-180)  // 3 minutes ago
        let context = EvaluationContext(
            currentDate: currentDate,
            launchDate: launchDate,
            counters: ["products_viewed": 2],  // Insufficient (needs 3+)
            events: [
                "last_purchase": currentDate.addingTimeInterval(-172800),  // 2 days ago
                "last_promo_shown": currentDate.addingTimeInterval(-18000),  // 5 hours ago
            ]
        )
        let spec = ECommercePromoBannerSpec()

        // When
        let result = spec.isSatisfiedBy(context)

        // Then
        XCTAssertFalse(
            result, "ECommercePromoBannerSpec should fail with insufficient product views")
    }

    func testECommercePromoBannerSpec_FailsOutsideShoppingHours() {
        // Given
        let calendar = Calendar.current
        let currentDate = calendar.date(bySettingHour: 23, minute: 0, second: 0, of: Date())!  // 11 PM (outside shopping hours)
        let launchDate = currentDate.addingTimeInterval(-180)  // 3 minutes ago
        let context = EvaluationContext(
            currentDate: currentDate,
            launchDate: launchDate,
            counters: ["products_viewed": 5],
            events: [
                "last_purchase": currentDate.addingTimeInterval(-172800),  // 2 days ago
                "last_promo_shown": currentDate.addingTimeInterval(-18000),  // 5 hours ago
            ]
        )
        let spec = ECommercePromoBannerSpec()

        // When
        let result = spec.isSatisfiedBy(context)

        // Then
        XCTAssertFalse(result, "ECommercePromoBannerSpec should fail outside shopping hours")
    }

    // MARK: - SubscriptionUpgradeSpec Tests

    func testSubscriptionUpgradeSpec_AllConditionsMet() {
        // Given
        let currentDate = Date()
        let launchDate = currentDate.addingTimeInterval(-1_209_600)  // 2 weeks ago
        let context = EvaluationContext(
            currentDate: currentDate,
            launchDate: launchDate,
            counters: [
                "premium_feature_usage": 8,
                "app_opens": 15,
            ],
            events: ["last_upgrade_prompt": currentDate.addingTimeInterval(-345600)],  // 4 days ago
            flags: ["is_premium_subscriber": false]
        )
        let spec = SubscriptionUpgradeSpec()

        // When
        let result = spec.isSatisfiedBy(context)

        // Then
        XCTAssertTrue(
            result, "SubscriptionUpgradeSpec should be satisfied when all conditions are met")
    }

    func testSubscriptionUpgradeSpec_FailsPremiumSubscriber() {
        // Given
        let currentDate = Date()
        let launchDate = currentDate.addingTimeInterval(-1_209_600)  // 2 weeks ago
        let context = EvaluationContext(
            currentDate: currentDate,
            launchDate: launchDate,
            counters: [
                "premium_feature_usage": 8,
                "app_opens": 15,
            ],
            events: ["last_upgrade_prompt": currentDate.addingTimeInterval(-345600)],  // 4 days ago
            flags: ["is_premium_subscriber": true]  // Already premium
        )
        let spec = SubscriptionUpgradeSpec()

        // When
        let result = spec.isSatisfiedBy(context)

        // Then
        XCTAssertFalse(result, "SubscriptionUpgradeSpec should fail for premium subscribers")
    }

    func testSubscriptionUpgradeSpec_FailsInsufficientPremiumUsage() {
        // Given
        let currentDate = Date()
        let launchDate = currentDate.addingTimeInterval(-1_209_600)  // 2 weeks ago
        let context = EvaluationContext(
            currentDate: currentDate,
            launchDate: launchDate,
            counters: [
                "premium_feature_usage": 3,  // Insufficient (needs 5+)
                "app_opens": 15,
            ],
            events: ["last_upgrade_prompt": currentDate.addingTimeInterval(-345600)],  // 4 days ago
            flags: ["is_premium_subscriber": false]
        )
        let spec = SubscriptionUpgradeSpec()

        // When
        let result = spec.isSatisfiedBy(context)

        // Then
        XCTAssertFalse(
            result, "SubscriptionUpgradeSpec should fail with insufficient premium feature usage")
    }

    func testSubscriptionUpgradeSpec_FailsInsufficientAppOpens() {
        // Given
        let currentDate = Date()
        let launchDate = currentDate.addingTimeInterval(-1_209_600)  // 2 weeks ago
        let context = EvaluationContext(
            currentDate: currentDate,
            launchDate: launchDate,
            counters: [
                "premium_feature_usage": 8,
                "app_opens": 5,  // Insufficient (needs 10+)
            ],
            events: ["last_upgrade_prompt": currentDate.addingTimeInterval(-345600)],  // 4 days ago
            flags: ["is_premium_subscriber": false]
        )
        let spec = SubscriptionUpgradeSpec()

        // When
        let result = spec.isSatisfiedBy(context)

        // Then
        XCTAssertFalse(result, "SubscriptionUpgradeSpec should fail with insufficient app opens")
    }
}

```


## Assistant

Now let me run the tests to make sure they all pass:

**Tool Call: `cd /Users/egor/Development/GitHub/SpecificationKit && swift test --filter testCompositeSpec`**
Status: Completed

Terminal:
```
Building for debugging...
[8/8] Linking SpecificationKitPackageTests
Build complete! (1.71s)
Test Suite 'Selected tests' started at 2025-09-18 22:55:41.205.
Test Suite 'SpecificationKitPackageTests.xctest' started at 2025-09-18 22:55:41.206.
Test Suite 'SpecificationKitTests' started at 2025-09-18 22:55:41.206.
Test Case '-[SpecificationKitTests.SpecificationKitTests testCompositeSpec_CustomConfiguration]' started.
Test Case '-[SpecificationKitTests.SpecificationKitTests testCompositeSpec_CustomConfiguration]' passed (0.001 seconds).
Test Case '-[SpecificationKitTests.SpecificationKitTests testCompositeSpec_CustomConfiguration_FailsInsufficientTime]' started.
Test Case '-[SpecificationKitTests.SpecificationKitTests testCompositeSpec_CustomConfiguration_FailsInsufficientTime]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SpecificationKitTests testCompositeSpec_DefaultConfiguration]' started.
Test Case '-[SpecificationKitTests.SpecificationKitTests testCompositeSpec_DefaultConfiguration]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SpecificationKitTests testCompositeSpec_FailsWhenCountExceedsLimit]' started.
Test Case '-[SpecificationKitTests.SpecificationKitTests testCompositeSpec_FailsWhenCountExceedsLimit]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SpecificationKitTests testCompositeSpec_FeatureAnnouncement]' started.
Test Case '-[SpecificationKitTests.SpecificationKitTests testCompositeSpec_FeatureAnnouncement]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SpecificationKitTests testCompositeSpec_FeatureAnnouncement_FailsMaxCount]' started.
Test Case '-[SpecificationKitTests.SpecificationKitTests testCompositeSpec_FeatureAnnouncement_FailsMaxCount]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SpecificationKitTests testCompositeSpec_OnboardingTip]' started.
Test Case '-[SpecificationKitTests.SpecificationKitTests testCompositeSpec_OnboardingTip]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SpecificationKitTests testCompositeSpec_OnboardingTip_FailsCooldown]' started.
Test Case '-[SpecificationKitTests.SpecificationKitTests testCompositeSpec_OnboardingTip_FailsCooldown]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SpecificationKitTests testCompositeSpec_PromoBanner]' started.
Test Case '-[SpecificationKitTests.SpecificationKitTests testCompositeSpec_PromoBanner]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SpecificationKitTests testCompositeSpec_PromoBanner_FailsMaxCount]' started.
Test Case '-[SpecificationKitTests.SpecificationKitTests testCompositeSpec_PromoBanner_FailsMaxCount]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SpecificationKitTests testCompositeSpec_RatingPrompt]' started.
Test Case '-[SpecificationKitTests.SpecificationKitTests testCompositeSpec_RatingPrompt]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SpecificationKitTests testCompositeSpec_RatingPrompt_FailsInsufficientTime]' started.
Test Case '-[SpecificationKitTests.SpecificationKitTests testCompositeSpec_RatingPrompt_FailsInsufficientTime]' passed (0.000 seconds).
Test Suite 'SpecificationKitTests' passed at 2025-09-18 22:55:41.208.
	 Executed 12 tests, with 0 failures (0 unexpected) in 0.002 (0.002) seconds
Test Suite 'SpecificationTracerTests' started at 2025-09-18 22:55:41.208.
Test Case '-[SpecificationKitTests.SpecificationTracerTests testCompositeSpecificationANDShortCircuit]' started.
Test Case '-[SpecificationKitTests.SpecificationTracerTests testCompositeSpecificationANDShortCircuit]' passed (0.001 seconds).
Test Case '-[SpecificationKitTests.SpecificationTracerTests testCompositeSpecificationANDTracing]' started.
Test Case '-[SpecificationKitTests.SpecificationTracerTests testCompositeSpecificationANDTracing]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SpecificationTracerTests testCompositeSpecificationORShortCircuit]' started.
Test Case '-[SpecificationKitTests.SpecificationTracerTests testCompositeSpecificationORShortCircuit]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SpecificationTracerTests testCompositeSpecificationORTracing]' started.
Test Case '-[SpecificationKitTests.SpecificationTracerTests testCompositeSpecificationORTracing]' passed (0.000 seconds).
Test Suite 'SpecificationTracerTests' passed at 2025-09-18 22:55:41.210.
	 Executed 4 tests, with 0 failures (0 unexpected) in 0.001 (0.002) seconds
Test Suite 'SpecificationKitPackageTests.xctest' passed at 2025-09-18 22:55:41.210.
	 Executed 16 tests, with 0 failures (0 unexpected) in 0.003 (0.004) seconds
Test Suite 'Selected tests' passed at 2025-09-18 22:55:41.210.
	 Executed 16 tests, with 0 failures (0 unexpected) in 0.003 (0.004) seconds
􀟈  Test run started.
􀄵  Testing Library Version: 1085
􀄵  Target Platform: arm64e-apple-macos14.0
􁁛  Test run with 0 tests in 0 suites passed after 0.001 seconds.

```


## Assistant

Good! But I notice that some of my tests didn't run. Let me run the tests for the other classes I added:

**Tool Call: `cd /Users/egor/Development/GitHub/SpecificationKit && swift test --filter testAdvancedCompositeSpec`**
Status: Completed

Terminal:
```
Building for debugging...
[3/3] Write swift-version--58304C5D6DBC2206.txt
Build complete! (0.09s)
Test Suite 'Selected tests' started at 2025-09-18 22:55:45.934.
Test Suite 'SpecificationKitPackageTests.xctest' started at 2025-09-18 22:55:45.935.
Test Suite 'SpecificationKitTests' started at 2025-09-18 22:55:45.935.
Test Case '-[SpecificationKitTests.SpecificationKitTests testAdvancedCompositeSpec_BasicComposition]' started.
Test Case '-[SpecificationKitTests.SpecificationKitTests testAdvancedCompositeSpec_BasicComposition]' passed (0.001 seconds).
Test Case '-[SpecificationKitTests.SpecificationKitTests testAdvancedCompositeSpec_WithBusinessHours]' started.
Test Case '-[SpecificationKitTests.SpecificationKitTests testAdvancedCompositeSpec_WithBusinessHours]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SpecificationKitTests testAdvancedCompositeSpec_WithBusinessHours_FailsOutsideHours]' started.
Test Case '-[SpecificationKitTests.SpecificationKitTests testAdvancedCompositeSpec_WithBusinessHours_FailsOutsideHours]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SpecificationKitTests testAdvancedCompositeSpec_WithMinimumEngagement]' started.
Test Case '-[SpecificationKitTests.SpecificationKitTests testAdvancedCompositeSpec_WithMinimumEngagement]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SpecificationKitTests testAdvancedCompositeSpec_WithMinimumEngagement_FailsLowEngagement]' started.
Test Case '-[SpecificationKitTests.SpecificationKitTests testAdvancedCompositeSpec_WithMinimumEngagement_FailsLowEngagement]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SpecificationKitTests testAdvancedCompositeSpec_WithWeekdays]' started.
Test Case '-[SpecificationKitTests.SpecificationKitTests testAdvancedCompositeSpec_WithWeekdays]' passed (0.000 seconds).
Test Suite 'SpecificationKitTests' passed at 2025-09-18 22:55:45.936.
	 Executed 6 tests, with 0 failures (0 unexpected) in 0.001 (0.001) seconds
Test Suite 'SpecificationKitPackageTests.xctest' passed at 2025-09-18 22:55:45.936.
	 Executed 6 tests, with 0 failures (0 unexpected) in 0.001 (0.001) seconds
Test Suite 'Selected tests' passed at 2025-09-18 22:55:45.936.
	 Executed 6 tests, with 0 failures (0 unexpected) in 0.001 (0.002) seconds
􀟈  Test run started.
􀄵  Testing Library Version: 1085
􀄵  Target Platform: arm64e-apple-macos14.0
􁁛  Test run with 0 tests in 0 suites passed after 0.001 seconds.

```


**Tool Call: `cd /Users/egor/Development/GitHub/SpecificationKit && swift test --filter testECommercePromoBannerSpec`**
Status: Completed

Terminal:
```
Building for debugging...
[3/3] Write swift-version--58304C5D6DBC2206.txt
Build complete! (0.09s)
Test Suite 'Selected tests' started at 2025-09-18 22:55:50.204.
Test Suite 'SpecificationKitPackageTests.xctest' started at 2025-09-18 22:55:50.205.
Test Suite 'SpecificationKitTests' started at 2025-09-18 22:55:50.205.
Test Case '-[SpecificationKitTests.SpecificationKitTests testECommercePromoBannerSpec_AllConditionsMet]' started.
Test Case '-[SpecificationKitTests.SpecificationKitTests testECommercePromoBannerSpec_AllConditionsMet]' passed (0.001 seconds).
Test Case '-[SpecificationKitTests.SpecificationKitTests testECommercePromoBannerSpec_FailsInsufficientActivity]' started.
Test Case '-[SpecificationKitTests.SpecificationKitTests testECommercePromoBannerSpec_FailsInsufficientActivity]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SpecificationKitTests testECommercePromoBannerSpec_FailsInsufficientProductViews]' started.
Test Case '-[SpecificationKitTests.SpecificationKitTests testECommercePromoBannerSpec_FailsInsufficientProductViews]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SpecificationKitTests testECommercePromoBannerSpec_FailsOutsideShoppingHours]' started.
Test Case '-[SpecificationKitTests.SpecificationKitTests testECommercePromoBannerSpec_FailsOutsideShoppingHours]' passed (0.000 seconds).
Test Suite 'SpecificationKitTests' passed at 2025-09-18 22:55:50.207.
	 Executed 4 tests, with 0 failures (0 unexpected) in 0.001 (0.001) seconds
Test Suite 'SpecificationKitPackageTests.xctest' passed at 2025-09-18 22:55:50.207.
	 Executed 4 tests, with 0 failures (0 unexpected) in 0.001 (0.001) seconds
Test Suite 'Selected tests' passed at 2025-09-18 22:55:50.207.
	 Executed 4 tests, with 0 failures (0 unexpected) in 0.001 (0.002) seconds
􀟈  Test run started.
􀄵  Testing Library Version: 1085
􀄵  Target Platform: arm64e-apple-macos14.0
􁁛  Test run with 0 tests in 0 suites passed after 0.001 seconds.

```


**Tool Call: `cd /Users/egor/Development/GitHub/SpecificationKit && swift test --filter testSubscriptionUpgradeSpec`**
Status: Completed

Terminal:
```
Building for debugging...
[3/3] Write swift-version--58304C5D6DBC2206.txt
Build complete! (0.09s)
Test Suite 'Selected tests' started at 2025-09-18 22:55:56.258.
Test Suite 'SpecificationKitPackageTests.xctest' started at 2025-09-18 22:55:56.259.
Test Suite 'SpecificationKitTests' started at 2025-09-18 22:55:56.259.
Test Case '-[SpecificationKitTests.SpecificationKitTests testSubscriptionUpgradeSpec_AllConditionsMet]' started.
Test Case '-[SpecificationKitTests.SpecificationKitTests testSubscriptionUpgradeSpec_AllConditionsMet]' passed (0.001 seconds).
Test Case '-[SpecificationKitTests.SpecificationKitTests testSubscriptionUpgradeSpec_FailsInsufficientAppOpens]' started.
Test Case '-[SpecificationKitTests.SpecificationKitTests testSubscriptionUpgradeSpec_FailsInsufficientAppOpens]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SpecificationKitTests testSubscriptionUpgradeSpec_FailsInsufficientPremiumUsage]' started.
Test Case '-[SpecificationKitTests.SpecificationKitTests testSubscriptionUpgradeSpec_FailsInsufficientPremiumUsage]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SpecificationKitTests testSubscriptionUpgradeSpec_FailsPremiumSubscriber]' started.
Test Case '-[SpecificationKitTests.SpecificationKitTests testSubscriptionUpgradeSpec_FailsPremiumSubscriber]' passed (0.000 seconds).
Test Suite 'SpecificationKitTests' passed at 2025-09-18 22:55:56.260.
	 Executed 4 tests, with 0 failures (0 unexpected) in 0.001 (0.001) seconds
Test Suite 'SpecificationKitPackageTests.xctest' passed at 2025-09-18 22:55:56.260.
	 Executed 4 tests, with 0 failures (0 unexpected) in 0.001 (0.001) seconds
Test Suite 'Selected tests' passed at 2025-09-18 22:55:56.260.
	 Executed 4 tests, with 0 failures (0 unexpected) in 0.001 (0.002) seconds
􀟈  Test run started.
􀄵  Testing Library Version: 1085
􀄵  Target Platform: arm64e-apple-macos14.0
􁁛  Test run with 0 tests in 0 suites passed after 0.001 seconds.

```


## Assistant

Perfect! All the new tests are passing. Let me run all the tests to make sure I didn't break anything:

**Tool Call: `cd /Users/egor/Development/GitHub/SpecificationKit && swift test`**
Status: Completed

Terminal:
```
Building for debugging...
[3/3] Write swift-version--58304C5D6DBC2206.txt
Build complete! (0.09s)
Test Suite 'All tests' started at 2025-09-18 22:56:07.185.
Test Suite 'SpecificationKitPackageTests.xctest' started at 2025-09-18 22:56:07.186.
Test Suite 'AnySpecificationPerformanceTests' started at 2025-09-18 22:56:07.186.
Test Case '-[SpecificationKitTests.AnySpecificationPerformanceTests testAllSatisfyPerformance]' started.
/Users/egor/Development/GitHub/SpecificationKit/Tests/SpecificationKitTests/AnySpecificationPerformanceTests.swift:71: Test Case '-[SpecificationKitTests.AnySpecificationPerformanceTests testAllSatisfyPerformance]' measured [Time, seconds] average: 0.011, relative standard deviation: 19.314%, values: [0.016233, 0.013152, 0.012401, 0.011445, 0.010705, 0.009954, 0.009705, 0.009359, 0.009193, 0.009159], performanceMetricID:com.apple.XCTPerformanceMetric_WallClockTime, baselineName: "", baselineAverage: , polarity: prefers smaller, maxPercentRegression: 10.000%, maxPercentRelativeStandardDeviation: 10.000%, maxRegression: 0.100, maxStandardDeviation: 0.100
Test Case '-[SpecificationKitTests.AnySpecificationPerformanceTests testAllSatisfyPerformance]' passed (0.537 seconds).
Test Case '-[SpecificationKitTests.AnySpecificationPerformanceTests testAlwaysFalsePerformance]' started.
/Users/egor/Development/GitHub/SpecificationKit/Tests/SpecificationKitTests/AnySpecificationPerformanceTests.swift:109: Test Case '-[SpecificationKitTests.AnySpecificationPerformanceTests testAlwaysFalsePerformance]' measured [Time, seconds] average: 0.003, relative standard deviation: 12.152%, values: [0.004373, 0.003960, 0.003815, 0.003361, 0.003431, 0.003353, 0.003168, 0.003153, 0.002995, 0.003074], performanceMetricID:com.apple.XCTPerformanceMetric_WallClockTime, baselineName: "", baselineAverage: , polarity: prefers smaller, maxPercentRegression: 10.000%, maxPercentRelativeStandardDeviation: 10.000%, maxRegression: 0.100, maxStandardDeviation: 0.100
Test Case '-[SpecificationKitTests.AnySpecificationPerformanceTests testAlwaysFalsePerformance]' passed (0.290 seconds).
Test Case '-[SpecificationKitTests.AnySpecificationPerformanceTests testAlwaysTruePerformance]' started.
/Users/egor/Development/GitHub/SpecificationKit/Tests/SpecificationKitTests/AnySpecificationPerformanceTests.swift:98: Test Case '-[SpecificationKitTests.AnySpecificationPerformanceTests testAlwaysTruePerformance]' measured [Time, seconds] average: 0.004, relative standard deviation: 11.350%, values: [0.004615, 0.004044, 0.003982, 0.003915, 0.003767, 0.003450, 0.003293, 0.003424, 0.003338, 0.003205], performanceMetricID:com.apple.XCTPerformanceMetric_WallClockTime, baselineName: "", baselineAverage: , polarity: prefers smaller, maxPercentRegression: 10.000%, maxPercentRelativeStandardDeviation: 10.000%, maxRegression: 0.100, maxStandardDeviation: 0.100
Test Case '-[SpecificationKitTests.AnySpecificationPerformanceTests testAlwaysTruePerformance]' passed (0.292 seconds).
Test Case '-[SpecificationKitTests.AnySpecificationPerformanceTests testAnySatisfyPerformance]' started.
/Users/egor/Development/GitHub/SpecificationKit/Tests/SpecificationKitTests/AnySpecificationPerformanceTests.swift:85: Test Case '-[SpecificationKitTests.AnySpecificationPerformanceTests testAnySatisfyPerformance]' measured [Time, seconds] average: 0.008, relative standard deviation: 17.093%, values: [0.010968, 0.009622, 0.009052, 0.008485, 0.008039, 0.007544, 0.007161, 0.006844, 0.006628, 0.006499], performanceMetricID:com.apple.XCTPerformanceMetric_WallClockTime, baselineName: "", baselineAverage: , polarity: prefers smaller, maxPercentRegression: 10.000%, maxPercentRelativeStandardDeviation: 10.000%, maxRegression: 0.100, maxStandardDeviation: 0.100
Test Case '-[SpecificationKitTests.AnySpecificationPerformanceTests testAnySatisfyPerformance]' passed (0.333 seconds).
Test Case '-[SpecificationKitTests.AnySpecificationPerformanceTests testCompositionPerformance]' started.
/Users/egor/Development/GitHub/SpecificationKit/Tests/SpecificationKitTests/AnySpecificationPerformanceTests.swift:58: Test Case '-[SpecificationKitTests.AnySpecificationPerformanceTests testCompositionPerformance]' measured [Time, seconds] average: 0.009, relative standard deviation: 19.073%, values: [0.013414, 0.011408, 0.009891, 0.009528, 0.009040, 0.008529, 0.008189, 0.007962, 0.007586, 0.007532], performanceMetricID:com.apple.XCTPerformanceMetric_WallClockTime, baselineName: "", baselineAverage: , polarity: prefers smaller, maxPercentRegression: 10.000%, maxPercentRelativeStandardDeviation: 10.000%, maxRegression: 0.100, maxStandardDeviation: 0.100
Test Case '-[SpecificationKitTests.AnySpecificationPerformanceTests testCompositionPerformance]' passed (0.345 seconds).
Test Case '-[SpecificationKitTests.AnySpecificationPerformanceTests testDirectSpecificationPerformance]' started.
/Users/egor/Development/GitHub/SpecificationKit/Tests/SpecificationKitTests/AnySpecificationPerformanceTests.swift:43: Test Case '-[SpecificationKitTests.AnySpecificationPerformanceTests testDirectSpecificationPerformance]' measured [Time, seconds] average: 0.001, relative standard deviation: 14.032%, values: [0.001389, 0.001212, 0.001280, 0.000928, 0.001380, 0.000917, 0.001105, 0.001257, 0.001402, 0.001150], performanceMetricID:com.apple.XCTPerformanceMetric_WallClockTime, baselineName: "", baselineAverage: , polarity: prefers smaller, maxPercentRegression: 10.000%, maxPercentRelativeStandardDeviation: 10.000%, maxRegression: 0.100, maxStandardDeviation: 0.100
Test Case '-[SpecificationKitTests.AnySpecificationPerformanceTests testDirectSpecificationPerformance]' passed (0.265 seconds).
Test Case '-[SpecificationKitTests.AnySpecificationPerformanceTests testLargeDatasetPerformance]' started.
/Users/egor/Development/GitHub/SpecificationKit/Tests/SpecificationKitTests/AnySpecificationPerformanceTests.swift:152: Test Case '-[SpecificationKitTests.AnySpecificationPerformanceTests testLargeDatasetPerformance]' measured [Time, seconds] average: 0.004, relative standard deviation: 13.531%, values: [0.005068, 0.004701, 0.004991, 0.004889, 0.004136, 0.004223, 0.003617, 0.003884, 0.003509, 0.003615], performanceMetricID:com.apple.XCTPerformanceMetric_WallClockTime, baselineName: "", baselineAverage: , polarity: prefers smaller, maxPercentRegression: 10.000%, maxPercentRelativeStandardDeviation: 10.000%, maxRegression: 0.100, maxStandardDeviation: 0.100
Test Case '-[SpecificationKitTests.AnySpecificationPerformanceTests testLargeDatasetPerformance]' passed (0.297 seconds).
Test Case '-[SpecificationKitTests.AnySpecificationPerformanceTests testMemoryAllocationPerformance]' started.
/Users/egor/Development/GitHub/SpecificationKit/Tests/SpecificationKitTests/AnySpecificationPerformanceTests.swift:132: Test Case '-[SpecificationKitTests.AnySpecificationPerformanceTests testMemoryAllocationPerformance]' measured [Time, seconds] average: 0.003, relative standard deviation: 12.513%, values: [0.003131, 0.003315, 0.002951, 0.002268, 0.002712, 0.002744, 0.002623, 0.002389, 0.002598, 0.002241], performanceMetricID:com.apple.XCTPerformanceMetric_WallClockTime, baselineName: "", baselineAverage: , polarity: prefers smaller, maxPercentRegression: 10.000%, maxPercentRelativeStandardDeviation: 10.000%, maxRegression: 0.100, maxStandardDeviation: 0.100
Test Case '-[SpecificationKitTests.AnySpecificationPerformanceTests testMemoryAllocationPerformance]' passed (0.280 seconds).
Test Case '-[SpecificationKitTests.AnySpecificationPerformanceTests testNestedCompositionPerformance]' started.
/Users/egor/Development/GitHub/SpecificationKit/Tests/SpecificationKitTests/AnySpecificationPerformanceTests.swift:171: Test Case '-[SpecificationKitTests.AnySpecificationPerformanceTests testNestedCompositionPerformance]' measured [Time, seconds] average: 0.001, relative standard deviation: 21.604%, values: [0.002020, 0.001402, 0.001403, 0.000959, 0.001232, 0.001296, 0.001567, 0.001225, 0.001457, 0.000957], performanceMetricID:com.apple.XCTPerformanceMetric_WallClockTime, baselineName: "", baselineAverage: , polarity: prefers smaller, maxPercentRegression: 10.000%, maxPercentRelativeStandardDeviation: 10.000%, maxRegression: 0.100, maxStandardDeviation: 0.100
Test Case '-[SpecificationKitTests.AnySpecificationPerformanceTests testNestedCompositionPerformance]' passed (0.266 seconds).
Test Case '-[SpecificationKitTests.AnySpecificationPerformanceTests testPredicateSpecPerformance]' started.
/Users/egor/Development/GitHub/SpecificationKit/Tests/SpecificationKitTests/AnySpecificationPerformanceTests.swift:120: Test Case '-[SpecificationKitTests.AnySpecificationPerformanceTests testPredicateSpecPerformance]' measured [Time, seconds] average: 0.002, relative standard deviation: 10.819%, values: [0.002604, 0.002098, 0.002517, 0.002044, 0.002264, 0.001897, 0.002144, 0.002160, 0.001935, 0.001893], performanceMetricID:com.apple.XCTPerformanceMetric_WallClockTime, baselineName: "", baselineAverage: , polarity: prefers smaller, maxPercentRegression: 10.000%, maxPercentRelativeStandardDeviation: 10.000%, maxRegression: 0.100, maxStandardDeviation: 0.100
Test Case '-[SpecificationKitTests.AnySpecificationPerformanceTests testPredicateSpecPerformance]' passed (0.275 seconds).
Test Case '-[SpecificationKitTests.AnySpecificationPerformanceTests testSingleSpecificationPerformance]' started.
/Users/egor/Development/GitHub/SpecificationKit/Tests/SpecificationKitTests/AnySpecificationPerformanceTests.swift:32: Test Case '-[SpecificationKitTests.AnySpecificationPerformanceTests testSingleSpecificationPerformance]' measured [Time, seconds] average: 0.002, relative standard deviation: 15.955%, values: [0.001968, 0.001513, 0.001476, 0.001871, 0.001070, 0.001654, 0.001379, 0.001549, 0.001380, 0.001426], performanceMetricID:com.apple.XCTPerformanceMetric_WallClockTime, baselineName: "", baselineAverage: , polarity: prefers smaller, maxPercentRegression: 10.000%, maxPercentRelativeStandardDeviation: 10.000%, maxRegression: 0.100, maxStandardDeviation: 0.100
Test Case '-[SpecificationKitTests.AnySpecificationPerformanceTests testSingleSpecificationPerformance]' passed (0.268 seconds).
Test Case '-[SpecificationKitTests.AnySpecificationPerformanceTests testWrappedSpecificationOverhead]' started.
/Users/egor/Development/GitHub/SpecificationKit/Tests/SpecificationKitTests/AnySpecificationPerformanceTests.swift:199: Test Case '-[SpecificationKitTests.AnySpecificationPerformanceTests testWrappedSpecificationOverhead]' measured [Memory Physical, kB] average: 6.554, relative standard deviation: 122.474%, values: [0.000000, 16.384000, 0.000000, 0.000000, 16.384000], performanceMetricID:com.apple.dt.XCTMetric_Memory.physical, baselineName: "", baselineAverage: , polarity: prefers smaller, maxPercentRegression: 10.000%, maxPercentRelativeStandardDeviation: 10.000%, maxRegression: 0.000, maxStandardDeviation: 0.000
/Users/egor/Development/GitHub/SpecificationKit/Tests/SpecificationKitTests/AnySpecificationPerformanceTests.swift:199: Test Case '-[SpecificationKitTests.AnySpecificationPerformanceTests testWrappedSpecificationOverhead]' measured [CPU Instructions Retired, kI] average: 308711.891, relative standard deviation: 0.009%, values: [308732.436000, 308741.992000, 308730.144000, 308682.701000, 308672.182000], performanceMetricID:com.apple.dt.XCTMetric_CPU.instructions_retired, baselineName: "", baselineAverage: , polarity: prefers smaller, maxPercentRegression: 10.000%, maxPercentRelativeStandardDeviation: 10.000%, maxRegression: 0.000, maxStandardDeviation: 0.000
/Users/egor/Development/GitHub/SpecificationKit/Tests/SpecificationKitTests/AnySpecificationPerformanceTests.swift:199: Test Case '-[SpecificationKitTests.AnySpecificationPerformanceTests testWrappedSpecificationOverhead]' measured [CPU Cycles, kC] average: 49765.884, relative standard deviation: 1.038%, values: [50126.479000, 49590.351000, 48840.354000, 50283.497000, 49988.741000], performanceMetricID:com.apple.dt.XCTMetric_CPU.cycles, baselineName: "", baselineAverage: , polarity: prefers smaller, maxPercentRegression: 10.000%, maxPercentRelativeStandardDeviation: 10.000%, maxRegression: 0.000, maxStandardDeviation: 0.000
/Users/egor/Development/GitHub/SpecificationKit/Tests/SpecificationKitTests/AnySpecificationPerformanceTests.swift:199: Test Case '-[SpecificationKitTests.AnySpecificationPerformanceTests testWrappedSpecificationOverhead]' measured [CPU Time, s] average: 0.013, relative standard deviation: 10.003%, values: [0.015472, 0.013754, 0.012595, 0.012354, 0.011735], performanceMetricID:com.apple.dt.XCTMetric_CPU.time, baselineName: "", baselineAverage: , polarity: prefers smaller, maxPercentRegression: 10.000%, maxPercentRelativeStandardDeviation: 10.000%, maxRegression: 0.000, maxStandardDeviation: 0.000
/Users/egor/Development/GitHub/SpecificationKit/Tests/SpecificationKitTests/AnySpecificationPerformanceTests.swift:199: Test Case '-[SpecificationKitTests.AnySpecificationPerformanceTests testWrappedSpecificationOverhead]' measured [Memory Peak Physical, kB] average: 114357.787, relative standard deviation: 0.029%, values: [114311.912000, 114344.680000, 114344.680000, 114377.448000, 114410.216000], performanceMetricID:com.apple.dt.XCTMetric_Memory.physical_peak, baselineName: "", baselineAverage: , polarity: prefers smaller, maxPercentRegression: 10.000%, maxPercentRelativeStandardDeviation: 10.000%, maxRegression: 0.000, maxStandardDeviation: 0.000
Test Case '-[SpecificationKitTests.AnySpecificationPerformanceTests testWrappedSpecificationOverhead]' passed (0.089 seconds).
Test Case '-[SpecificationKitTests.AnySpecificationPerformanceTests testWrappedVsDirectComparison]' started.
/Users/egor/Development/GitHub/SpecificationKit/Tests/SpecificationKitTests/AnySpecificationPerformanceTests.swift:186: Test Case '-[SpecificationKitTests.AnySpecificationPerformanceTests testWrappedVsDirectComparison]' measured [Memory Physical, kB] average: 0.000, relative standard deviation: 0.000%, values: [0.000000, 0.000000, 0.000000, 0.000000, 0.000000], performanceMetricID:com.apple.dt.XCTMetric_Memory.physical, baselineName: "", baselineAverage: , polarity: prefers smaller, maxPercentRegression: 10.000%, maxPercentRelativeStandardDeviation: 10.000%, maxRegression: 0.000, maxStandardDeviation: 0.000
/Users/egor/Development/GitHub/SpecificationKit/Tests/SpecificationKitTests/AnySpecificationPerformanceTests.swift:186: Test Case '-[SpecificationKitTests.AnySpecificationPerformanceTests testWrappedVsDirectComparison]' measured [CPU Instructions Retired, kI] average: 288156.377, relative standard deviation: 0.009%, values: [288195.924000, 288138.976000, 288174.536000, 288148.488000, 288123.960000], performanceMetricID:com.apple.dt.XCTMetric_CPU.instructions_retired, baselineName: "", baselineAverage: , polarity: prefers smaller, maxPercentRegression: 10.000%, maxPercentRelativeStandardDeviation: 10.000%, maxRegression: 0.000, maxStandardDeviation: 0.000
/Users/egor/Development/GitHub/SpecificationKit/Tests/SpecificationKitTests/AnySpecificationPerformanceTests.swift:186: Test Case '-[SpecificationKitTests.AnySpecificationPerformanceTests testWrappedVsDirectComparison]' measured [CPU Cycles, kC] average: 45923.463, relative standard deviation: 0.920%, values: [46368.855000, 45929.303000, 46023.084000, 45131.819000, 46164.256000], performanceMetricID:com.apple.dt.XCTMetric_CPU.cycles, baselineName: "", baselineAverage: , polarity: prefers smaller, maxPercentRegression: 10.000%, maxPercentRelativeStandardDeviation: 10.000%, maxRegression: 0.000, maxStandardDeviation: 0.000
/Users/egor/Development/GitHub/SpecificationKit/Tests/SpecificationKitTests/AnySpecificationPerformanceTests.swift:186: Test Case '-[SpecificationKitTests.AnySpecificationPerformanceTests testWrappedVsDirectComparison]' measured [CPU Time, s] average: 0.011, relative standard deviation: 0.411%, values: [0.010496, 0.010435, 0.010539, 0.010523, 0.010560], performanceMetricID:com.apple.dt.XCTMetric_CPU.time, baselineName: "", baselineAverage: , polarity: prefers smaller, maxPercentRegression: 10.000%, maxPercentRelativeStandardDeviation: 10.000%, maxRegression: 0.000, maxStandardDeviation: 0.000
/Users/egor/Development/GitHub/SpecificationKit/Tests/SpecificationKitTests/AnySpecificationPerformanceTests.swift:186: Test Case '-[SpecificationKitTests.AnySpecificationPerformanceTests testWrappedVsDirectComparison]' measured [Memory Peak Physical, kB] average: 114574.056, relative standard deviation: 0.000%, values: [114574.056000, 114574.056000, 114574.056000, 114574.056000, 114574.056000], performanceMetricID:com.apple.dt.XCTMetric_Memory.physical_peak, baselineName: "", baselineAverage: , polarity: prefers smaller, maxPercentRegression: 10.000%, maxPercentRelativeStandardDeviation: 10.000%, maxRegression: 0.000, maxStandardDeviation: 0.000
Test Case '-[SpecificationKitTests.AnySpecificationPerformanceTests testWrappedVsDirectComparison]' passed (0.067 seconds).
Test Suite 'AnySpecificationPerformanceTests' passed at 2025-09-18 22:56:10.790.
	 Executed 13 tests, with 0 failures (0 unexpected) in 3.603 (3.604) seconds
Test Suite 'AppleTVContextProviderCrossPlatformTests' started at 2025-09-18 22:56:10.790.
Test Case '-[SpecificationKitTests.AppleTVContextProviderCrossPlatformTests testAppleTVContextProviderNonTVOSDefaults]' started.
Test Case '-[SpecificationKitTests.AppleTVContextProviderCrossPlatformTests testAppleTVContextProviderNonTVOSDefaults]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.AppleTVContextProviderCrossPlatformTests testAppleTVSpecificationsNonTVOSReturnFalse]' started.
Test Case '-[SpecificationKitTests.AppleTVContextProviderCrossPlatformTests testAppleTVSpecificationsNonTVOSReturnFalse]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.AppleTVContextProviderCrossPlatformTests testPlatformProvidersAppleTVPerformanceSpecifications]' started.
Test Case '-[SpecificationKitTests.AppleTVContextProviderCrossPlatformTests testPlatformProvidersAppleTVPerformanceSpecifications]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.AppleTVContextProviderCrossPlatformTests testPlatformProvidersAppleTVSpecificationResults]' started.
Test Case '-[SpecificationKitTests.AppleTVContextProviderCrossPlatformTests testPlatformProvidersAppleTVSpecificationResults]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.AppleTVContextProviderCrossPlatformTests testPlatformProvidersAppleTVSupportFlags]' started.
Test Case '-[SpecificationKitTests.AppleTVContextProviderCrossPlatformTests testPlatformProvidersAppleTVSupportFlags]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.AppleTVContextProviderCrossPlatformTests testPlatformProvidersReturnCorrectContextProvider]' started.
Test Case '-[SpecificationKitTests.AppleTVContextProviderCrossPlatformTests testPlatformProvidersReturnCorrectContextProvider]' passed (0.000 seconds).
Test Suite 'AppleTVContextProviderCrossPlatformTests' passed at 2025-09-18 22:56:10.791.
	 Executed 6 tests, with 0 failures (0 unexpected) in 0.001 (0.001) seconds
Test Suite 'AsyncFeaturesTests' started at 2025-09-18 22:56:10.791.
Test Case '-[SpecificationKitTests.AsyncFeaturesTests test_AnyAsyncSpecification_canThrow_andDelay]' started.
Test Case '-[SpecificationKitTests.AsyncFeaturesTests test_AnyAsyncSpecification_canThrow_andDelay]' passed (0.013 seconds).
Test Case '-[SpecificationKitTests.AsyncFeaturesTests test_AnyAsyncSpecification_predicate]' started.
Test Case '-[SpecificationKitTests.AsyncFeaturesTests test_AnyAsyncSpecification_predicate]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.AsyncFeaturesTests test_ContextProviding_asyncDefault_returnsContext]' started.
Test Case '-[SpecificationKitTests.AsyncFeaturesTests test_ContextProviding_asyncDefault_returnsContext]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.AsyncFeaturesTests test_Satisfies_evaluateAsync_usesProvider]' started.
Test Case '-[SpecificationKitTests.AsyncFeaturesTests test_Satisfies_evaluateAsync_usesProvider]' passed (0.000 seconds).
Test Suite 'AsyncFeaturesTests' passed at 2025-09-18 22:56:10.804.
	 Executed 4 tests, with 0 failures (0 unexpected) in 0.013 (0.013) seconds
Test Suite 'AsyncSatisfiesWrapperTests' started at 2025-09-18 22:56:10.804.
Test Case '-[SpecificationKitTests.AsyncSatisfiesWrapperTests test_AsyncSatisfies_evaluate_withPredicate]' started.
Test Case '-[SpecificationKitTests.AsyncSatisfiesWrapperTests test_AsyncSatisfies_evaluate_withPredicate]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.AsyncSatisfiesWrapperTests test_AsyncSatisfies_evaluate_withSyncSpec]' started.
Test Case '-[SpecificationKitTests.AsyncSatisfiesWrapperTests test_AsyncSatisfies_evaluate_withSyncSpec]' passed (0.000 seconds).
Test Suite 'AsyncSatisfiesWrapperTests' passed at 2025-09-18 22:56:10.805.
	 Executed 2 tests, with 0 failures (0 unexpected) in 0.000 (0.000) seconds
Test Suite 'AutoContextMacroTests' started at 2025-09-18 22:56:10.805.
Test Case '-[SpecificationKitTests.AutoContextMacroTests testAutoContext_ExposesProviderTypealias_andContextType]' started.
Test Case '-[SpecificationKitTests.AutoContextMacroTests testAutoContext_ExposesProviderTypealias_andContextType]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.AutoContextMacroTests testAutoContext_InjectsDefaultProviderAndWorksWithSatisfies]' started.
Test Case '-[SpecificationKitTests.AutoContextMacroTests testAutoContext_InjectsDefaultProviderAndWorksWithSatisfies]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.AutoContextMacroTests testAutoContext_ProvidesStaticContextProvider]' started.
Test Case '-[SpecificationKitTests.AutoContextMacroTests testAutoContext_ProvidesStaticContextProvider]' passed (0.000 seconds).
Test Suite 'AutoContextMacroTests' passed at 2025-09-18 22:56:10.805.
	 Executed 3 tests, with 0 failures (0 unexpected) in 0.000 (0.000) seconds
Test Suite 'BenchmarkValidation' started at 2025-09-18 22:56:10.805.
Test Case '-[SpecificationKitTests.BenchmarkValidation testBenchmarkStorage]' started.
Test Case '-[SpecificationKitTests.BenchmarkValidation testBenchmarkStorage]' passed (0.003 seconds).
Test Case '-[SpecificationKitTests.BenchmarkValidation testProfilerOverhead]' started.
Test Case '-[SpecificationKitTests.BenchmarkValidation testProfilerOverhead]' passed (0.015 seconds).
Test Case '-[SpecificationKitTests.BenchmarkValidation testSpecificationPerformanceBaseline]' started.
Test Case '-[SpecificationKitTests.BenchmarkValidation testSpecificationPerformanceBaseline]' passed (0.026 seconds).
Test Suite 'BenchmarkValidation' passed at 2025-09-18 22:56:10.849.
	 Executed 3 tests, with 0 failures (0 unexpected) in 0.044 (0.044) seconds
Test Suite 'CachedSatisfiesTests' started at 2025-09-18 22:56:10.849.
Test Case '-[SpecificationKitTests.CachedSatisfiesTests testBasicCaching]' started.
Test Case '-[SpecificationKitTests.CachedSatisfiesTests testBasicCaching]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.CachedSatisfiesTests testCacheExpiration]' started.
Test Case '-[SpecificationKitTests.CachedSatisfiesTests testCacheExpiration]' passed (0.151 seconds).
Test Case '-[SpecificationKitTests.CachedSatisfiesTests testCacheInvalidation]' started.
Test Case '-[SpecificationKitTests.CachedSatisfiesTests testCacheInvalidation]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.CachedSatisfiesTests testCacheStatistics]' started.
Test Case '-[SpecificationKitTests.CachedSatisfiesTests testCacheStatistics]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.CachedSatisfiesTests testCachingPerformanceImprovement]' started.
Test Case '-[SpecificationKitTests.CachedSatisfiesTests testCachingPerformanceImprovement]' passed (0.052 seconds).
Test Case '-[SpecificationKitTests.CachedSatisfiesTests testConcurrentAccess]' started.
Test Case '-[SpecificationKitTests.CachedSatisfiesTests testConcurrentAccess]' passed (0.013 seconds).
Test Case '-[SpecificationKitTests.CachedSatisfiesTests testConvenienceMethodCaching]' started.
Test Case '-[SpecificationKitTests.CachedSatisfiesTests testConvenienceMethodCaching]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.CachedSatisfiesTests testCounterCaching]' started.
Test Case '-[SpecificationKitTests.CachedSatisfiesTests testCounterCaching]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.CachedSatisfiesTests testGlobalCacheManagement]' started.
Test Case '-[SpecificationKitTests.CachedSatisfiesTests testGlobalCacheManagement]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.CachedSatisfiesTests testMultipleInstancesIndependentCaching]' started.
Test Case '-[SpecificationKitTests.CachedSatisfiesTests testMultipleInstancesIndependentCaching]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.CachedSatisfiesTests testPredicateBasedCaching]' started.
Test Case '-[SpecificationKitTests.CachedSatisfiesTests testPredicateBasedCaching]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.CachedSatisfiesTests testProjectedValueFunctionality]' started.
Test Case '-[SpecificationKitTests.CachedSatisfiesTests testProjectedValueFunctionality]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.CachedSatisfiesTests testTimeSinceLaunchCaching]' started.
Test Case '-[SpecificationKitTests.CachedSatisfiesTests testTimeSinceLaunchCaching]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.CachedSatisfiesTests testVeryLongTTL]' started.
Test Case '-[SpecificationKitTests.CachedSatisfiesTests testVeryLongTTL]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.CachedSatisfiesTests testZeroTTL]' started.
Test Case '-[SpecificationKitTests.CachedSatisfiesTests testZeroTTL]' passed (0.000 seconds).
Test Suite 'CachedSatisfiesTests' passed at 2025-09-18 22:56:11.067.
	 Executed 15 tests, with 0 failures (0 unexpected) in 0.217 (0.218) seconds
Test Suite 'ComparativeSpecTests' started at 2025-09-18 22:56:11.067.
Test Case '-[SpecificationKitTests.ComparativeSpecTests testComparativeSpec_approximatelyEqual_returnsTrue]' started.
Test Case '-[SpecificationKitTests.ComparativeSpecTests testComparativeSpec_approximatelyEqual_returnsTrue]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.ComparativeSpecTests testComparativeSpec_between_fixedValues_returnsFalse]' started.
Test Case '-[SpecificationKitTests.ComparativeSpecTests testComparativeSpec_between_fixedValues_returnsFalse]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.ComparativeSpecTests testComparativeSpec_between_fixedValues_returnsTrue]' started.
Test Case '-[SpecificationKitTests.ComparativeSpecTests testComparativeSpec_between_fixedValues_returnsTrue]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.ComparativeSpecTests testComparativeSpec_custom_returnsTrue]' started.
Test Case '-[SpecificationKitTests.ComparativeSpecTests testComparativeSpec_custom_returnsTrue]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.ComparativeSpecTests testComparativeSpec_equalTo_fixedValue_returnsTrue]' started.
Test Case '-[SpecificationKitTests.ComparativeSpecTests testComparativeSpec_equalTo_fixedValue_returnsTrue]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.ComparativeSpecTests testComparativeSpec_equalTo_withTolerance_returnsFalse]' started.
Test Case '-[SpecificationKitTests.ComparativeSpecTests testComparativeSpec_equalTo_withTolerance_returnsFalse]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.ComparativeSpecTests testComparativeSpec_equalTo_withTolerance_returnsTrue]' started.
Test Case '-[SpecificationKitTests.ComparativeSpecTests testComparativeSpec_equalTo_withTolerance_returnsTrue]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.ComparativeSpecTests testComparativeSpec_greaterThan_dynamicThreshold_returnsFalse]' started.
Test Case '-[SpecificationKitTests.ComparativeSpecTests testComparativeSpec_greaterThan_dynamicThreshold_returnsFalse]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.ComparativeSpecTests testComparativeSpec_greaterThan_dynamicThreshold_returnsTrue]' started.
Test Case '-[SpecificationKitTests.ComparativeSpecTests testComparativeSpec_greaterThan_dynamicThreshold_returnsTrue]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.ComparativeSpecTests testComparativeSpec_greaterThan_fixedValue_returnsFalse]' started.
Test Case '-[SpecificationKitTests.ComparativeSpecTests testComparativeSpec_greaterThan_fixedValue_returnsFalse]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.ComparativeSpecTests testComparativeSpec_greaterThan_fixedValue_returnsTrue]' started.
Test Case '-[SpecificationKitTests.ComparativeSpecTests testComparativeSpec_greaterThan_fixedValue_returnsTrue]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.ComparativeSpecTests testComparativeSpec_initWithExtracting_succeeds]' started.
Test Case '-[SpecificationKitTests.ComparativeSpecTests testComparativeSpec_initWithExtracting_succeeds]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.ComparativeSpecTests testComparativeSpec_initWithKeyPath_succeeds]' started.
Test Case '-[SpecificationKitTests.ComparativeSpecTests testComparativeSpec_initWithKeyPath_succeeds]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.ComparativeSpecTests testComparativeSpec_lessThan_fixedValue_returnsTrue]' started.
Test Case '-[SpecificationKitTests.ComparativeSpecTests testComparativeSpec_lessThan_fixedValue_returnsTrue]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.ComparativeSpecTests testComparativeSpec_nilValueExtraction_returnsFalse]' started.
Test Case '-[SpecificationKitTests.ComparativeSpecTests testComparativeSpec_nilValueExtraction_returnsFalse]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.ComparativeSpecTests testComparativeSpec_withinTolerance_returnsTrue]' started.
Test Case '-[SpecificationKitTests.ComparativeSpecTests testComparativeSpec_withinTolerance_returnsTrue]' passed (0.000 seconds).
Test Suite 'ComparativeSpecTests' passed at 2025-09-18 22:56:11.069.
	 Executed 16 tests, with 0 failures (0 unexpected) in 0.001 (0.002) seconds
Test Suite 'CompositeContextProviderTests' started at 2025-09-18 22:56:11.069.
Test Case '-[SpecificationKitTests.CompositeContextProviderTests testPreferFirst_preservesFirst_onConflicts]' started.
Test Case '-[SpecificationKitTests.CompositeContextProviderTests testPreferFirst_preservesFirst_onConflicts]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.CompositeContextProviderTests testPreferLast_overridesConflicts_andUnionsSegments]' started.
Test Case '-[SpecificationKitTests.CompositeContextProviderTests testPreferLast_overridesConflicts_andUnionsSegments]' passed (0.000 seconds).
Test Suite 'CompositeContextProviderTests' passed at 2025-09-18 22:56:11.069.
	 Executed 2 tests, with 0 failures (0 unexpected) in 0.000 (0.001) seconds
Test Suite 'ConditionalSatisfiesTests' started at 2025-09-18 22:56:11.069.
Test Case '-[SpecificationKitTests.ConditionalSatisfiesTests testBasicConditionalSelection]' started.
Test Case '-[SpecificationKitTests.ConditionalSatisfiesTests testBasicConditionalSelection]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.ConditionalSatisfiesTests testBuilderPattern]' started.
Test Case '-[SpecificationKitTests.ConditionalSatisfiesTests testBuilderPattern]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.ConditionalSatisfiesTests testBuilderWithPredicateFunctions]' started.
Test Case '-[SpecificationKitTests.ConditionalSatisfiesTests testBuilderWithPredicateFunctions]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.ConditionalSatisfiesTests testCustomContextProvider]' started.
Test Case '-[SpecificationKitTests.ConditionalSatisfiesTests testCustomContextProvider]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.ConditionalSatisfiesTests testDynamicConditionChanges]' started.
Test Case '-[SpecificationKitTests.ConditionalSatisfiesTests testDynamicConditionChanges]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.ConditionalSatisfiesTests testFallbackSpecificationUsed]' started.
Test Case '-[SpecificationKitTests.ConditionalSatisfiesTests testFallbackSpecificationUsed]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.ConditionalSatisfiesTests testIntegrationWithEvaluationContext]' started.
Test Case '-[SpecificationKitTests.ConditionalSatisfiesTests testIntegrationWithEvaluationContext]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.ConditionalSatisfiesTests testPredicateFunctionConditions]' started.
Test Case '-[SpecificationKitTests.ConditionalSatisfiesTests testPredicateFunctionConditions]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.ConditionalSatisfiesTests testProjectedValueAsyncEvaluation]' started.
Test Case '-[SpecificationKitTests.ConditionalSatisfiesTests testProjectedValueAsyncEvaluation]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.ConditionalSatisfiesTests testProjectedValueConditionAnalysis]' started.
Test Case '-[SpecificationKitTests.ConditionalSatisfiesTests testProjectedValueConditionAnalysis]' passed (0.000 seconds).
Test Suite 'ConditionalSatisfiesTests' passed at 2025-09-18 22:56:11.071.
	 Executed 10 tests, with 0 failures (0 unexpected) in 0.001 (0.002) seconds
Test Suite 'ContextUpdatesProviderTests' started at 2025-09-18 22:56:11.071.
Test Case '-[SpecificationKitTests.ContextUpdatesProviderTests test_DefaultProvider_contextStream_yields_onUpdate]' started.
Test Case '-[SpecificationKitTests.ContextUpdatesProviderTests test_DefaultProvider_contextStream_yields_onUpdate]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.ContextUpdatesProviderTests test_DefaultProvider_emits_onCounterAndEvent]' started.
Test Case '-[SpecificationKitTests.ContextUpdatesProviderTests test_DefaultProvider_emits_onCounterAndEvent]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.ContextUpdatesProviderTests test_DefaultProvider_emits_onFlagSet]' started.
Test Case '-[SpecificationKitTests.ContextUpdatesProviderTests test_DefaultProvider_emits_onFlagSet]' passed (0.000 seconds).
Test Suite 'ContextUpdatesProviderTests' passed at 2025-09-18 22:56:11.072.
	 Executed 3 tests, with 0 failures (0 unexpected) in 0.001 (0.001) seconds
Test Suite 'DateComparisonSpecTests' started at 2025-09-18 22:56:11.072.
Test Case '-[SpecificationKitTests.DateComparisonSpecTests test_DateComparisonSpec_before_after]' started.
Test Case '-[SpecificationKitTests.DateComparisonSpecTests test_DateComparisonSpec_before_after]' passed (0.000 seconds).
Test Suite 'DateComparisonSpecTests' passed at 2025-09-18 22:56:11.072.
	 Executed 1 test, with 0 failures (0 unexpected) in 0.000 (0.000) seconds
Test Suite 'DateRangeSpecTests' started at 2025-09-18 22:56:11.072.
Test Case '-[SpecificationKitTests.DateRangeSpecTests test_DateRangeSpec_inclusiveRange]' started.
Test Case '-[SpecificationKitTests.DateRangeSpecTests test_DateRangeSpec_inclusiveRange]' passed (0.002 seconds).
Test Suite 'DateRangeSpecTests' passed at 2025-09-18 22:56:11.074.
	 Executed 1 test, with 0 failures (0 unexpected) in 0.002 (0.002) seconds
Test Suite 'DecidesGenericContextTests' started at 2025-09-18 22:56:11.074.
Test Case '-[SpecificationKitTests.DecidesGenericContextTests test_Decides_withGenericProvider_andPredicate]' started.
Test Case '-[SpecificationKitTests.DecidesGenericContextTests test_Decides_withGenericProvider_andPredicate]' passed (0.000 seconds).
Test Suite 'DecidesGenericContextTests' passed at 2025-09-18 22:56:11.074.
	 Executed 1 test, with 0 failures (0 unexpected) in 0.000 (0.000) seconds
Test Suite 'DecidesWrapperTests' started at 2025-09-18 22:56:11.074.
Test Case '-[SpecificationKitTests.DecidesWrapperTests test_Decides_builderInitializer_withFallback]' started.
Test Case '-[SpecificationKitTests.DecidesWrapperTests test_Decides_builderInitializer_withFallback]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.DecidesWrapperTests test_Decides_pairsInitializer_and_fallbackLabel]' started.
Test Case '-[SpecificationKitTests.DecidesWrapperTests test_Decides_pairsInitializer_and_fallbackLabel]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.DecidesWrapperTests test_Decides_projectedValue_reflectsOptionalMatch]' started.
Test Case '-[SpecificationKitTests.DecidesWrapperTests test_Decides_projectedValue_reflectsOptionalMatch]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.DecidesWrapperTests test_Decides_returnsFallback_whenNoMatch]' started.
Test Case '-[SpecificationKitTests.DecidesWrapperTests test_Decides_returnsFallback_whenNoMatch]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.DecidesWrapperTests test_Decides_returnsMatchedValue_whenMatchExists]' started.
Test Case '-[SpecificationKitTests.DecidesWrapperTests test_Decides_returnsMatchedValue_whenMatchExists]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.DecidesWrapperTests test_Decides_withDecideClosure_orLabel]' started.
Test Case '-[SpecificationKitTests.DecidesWrapperTests test_Decides_withDecideClosure_orLabel]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.DecidesWrapperTests test_Decides_wrappedValueDefault_initializesFallback]' started.
Test Case '-[SpecificationKitTests.DecidesWrapperTests test_Decides_wrappedValueDefault_initializesFallback]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.DecidesWrapperTests test_Decides_wrappedValueDefault_withPairs]' started.
Test Case '-[SpecificationKitTests.DecidesWrapperTests test_Decides_wrappedValueDefault_withPairs]' passed (0.000 seconds).
Test Suite 'DecidesWrapperTests' passed at 2025-09-18 22:56:11.076.
	 Executed 8 tests, with 0 failures (0 unexpected) in 0.001 (0.001) seconds
Test Suite 'DecisionSpecTests' started at 2025-09-18 22:56:11.076.
Test Case '-[SpecificationKitTests.DecisionSpecTests testCustomDecisionSpec_implementsLogic]' started.
Test Case '-[SpecificationKitTests.DecisionSpecTests testCustomDecisionSpec_implementsLogic]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.DecisionSpecTests testDecisionSpec_returnsNil_whenNotSatisfied]' started.
Test Case '-[SpecificationKitTests.DecisionSpecTests testDecisionSpec_returnsNil_whenNotSatisfied]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.DecisionSpecTests testDecisionSpec_returnsResult_whenSatisfied]' started.
Test Case '-[SpecificationKitTests.DecisionSpecTests testDecisionSpec_returnsResult_whenSatisfied]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.DecisionSpecTests testFirstMatchSpec_builder_createsCorrectSpec]' started.
Test Case '-[SpecificationKitTests.DecisionSpecTests testFirstMatchSpec_builder_createsCorrectSpec]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.DecisionSpecTests testFirstMatchSpec_returnsFirstMatchingResult]' started.
Test Case '-[SpecificationKitTests.DecisionSpecTests testFirstMatchSpec_returnsFirstMatchingResult]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.DecisionSpecTests testFirstMatchSpec_shortCircuits_atFirstMatch]' started.
Test Case '-[SpecificationKitTests.DecisionSpecTests testFirstMatchSpec_shortCircuits_atFirstMatch]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.DecisionSpecTests testFirstMatchSpec_withFallback_alwaysReturnsResult]' started.
Test Case '-[SpecificationKitTests.DecisionSpecTests testFirstMatchSpec_withFallback_alwaysReturnsResult]' passed (0.000 seconds).
Test Suite 'DecisionSpecTests' passed at 2025-09-18 22:56:11.076.
	 Executed 7 tests, with 0 failures (0 unexpected) in 0.001 (0.001) seconds
Test Suite 'DecisionsDemoLogicTests' started at 2025-09-18 22:56:11.076.
Test Case '-[SpecificationKitTests.DecisionsDemoLogicTests test_bothSelected_prefersVip50]' started.
Test Case '-[SpecificationKitTests.DecisionsDemoLogicTests test_bothSelected_prefersVip50]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.DecisionsDemoLogicTests test_noneSelected_returnsNilAndZero]' started.
Test Case '-[SpecificationKitTests.DecisionsDemoLogicTests test_noneSelected_returnsNilAndZero]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.DecisionsDemoLogicTests test_promoOnly_returns20]' started.
Test Case '-[SpecificationKitTests.DecisionsDemoLogicTests test_promoOnly_returns20]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.DecisionsDemoLogicTests test_vipOnly_returns50]' started.
Test Case '-[SpecificationKitTests.DecisionsDemoLogicTests test_vipOnly_returns50]' passed (0.000 seconds).
Test Suite 'DecisionsDemoLogicTests' passed at 2025-09-18 22:56:11.077.
	 Executed 4 tests, with 0 failures (0 unexpected) in 0.000 (0.000) seconds
Test Suite 'EnvironmentContextProviderTests' started at 2025-09-18 22:56:11.077.
Test Case '-[SpecificationKitTests.EnvironmentContextProviderTests testContextReflectsFlagsCountersEvents]' started.
Test Case '-[SpecificationKitTests.EnvironmentContextProviderTests testContextReflectsFlagsCountersEvents]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.EnvironmentContextProviderTests testEnvironmentSnapshotInjectedIntoUserData]' started.
Test Case '-[SpecificationKitTests.EnvironmentContextProviderTests testEnvironmentSnapshotInjectedIntoUserData]' passed (0.000 seconds).
Test Suite 'EnvironmentContextProviderTests' passed at 2025-09-18 22:56:11.078.
	 Executed 2 tests, with 0 failures (0 unexpected) in 0.001 (0.001) seconds
Test Suite 'EnvironmentContextProviderUpdatesTests' started at 2025-09-18 22:56:11.078.
Test Case '-[SpecificationKitTests.EnvironmentContextProviderUpdatesTests test_EnvironmentProvider_emits_onPublishedChange]' started.
Test Case '-[SpecificationKitTests.EnvironmentContextProviderUpdatesTests test_EnvironmentProvider_emits_onPublishedChange]' passed (0.000 seconds).
Test Suite 'EnvironmentContextProviderUpdatesTests' passed at 2025-09-18 22:56:11.078.
	 Executed 1 test, with 0 failures (0 unexpected) in 0.000 (0.000) seconds
Test Suite 'FeatureFlagSpecTests' started at 2025-09-18 22:56:11.078.
Test Case '-[SpecificationKitTests.FeatureFlagSpecTests test_FeatureFlagSpec_matchesExpectedValue]' started.
Test Case '-[SpecificationKitTests.FeatureFlagSpecTests test_FeatureFlagSpec_matchesExpectedValue]' passed (0.000 seconds).
Test Suite 'FeatureFlagSpecTests' passed at 2025-09-18 22:56:11.078.
	 Executed 1 test, with 0 failures (0 unexpected) in 0.000 (0.000) seconds
Test Suite 'FirstMatchSpecTests' started at 2025-09-18 22:56:11.078.
Test Case '-[SpecificationKitTests.FirstMatchSpecTests test_builder_createsCorrectFirstMatchSpec]' started.
Test Case '-[SpecificationKitTests.FirstMatchSpecTests test_builder_createsCorrectFirstMatchSpec]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.FirstMatchSpecTests test_firstMatch_returnsFirstPayload_whenMultipleSpecsMatch]' started.
Test Case '-[SpecificationKitTests.FirstMatchSpecTests test_firstMatch_returnsFirstPayload_whenMultipleSpecsMatch]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.FirstMatchSpecTests test_firstMatch_returnsNil_whenNoSpecsMatch]' started.
Test Case '-[SpecificationKitTests.FirstMatchSpecTests test_firstMatch_returnsNil_whenNoSpecsMatch]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.FirstMatchSpecTests test_firstMatch_returnsPayload_whenSingleSpecMatches]' started.
Test Case '-[SpecificationKitTests.FirstMatchSpecTests test_firstMatch_returnsPayload_whenSingleSpecMatches]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.FirstMatchSpecTests test_firstMatch_withFallbackSpec_returnsFallbackPayload]' started.
Test Case '-[SpecificationKitTests.FirstMatchSpecTests test_firstMatch_withFallbackSpec_returnsFallbackPayload]' passed (0.000 seconds).
Test Suite 'FirstMatchSpecTests' passed at 2025-09-18 22:56:11.079.
	 Executed 5 tests, with 0 failures (0 unexpected) in 0.000 (0.001) seconds
Test Suite 'HistoricalSpecTests' started at 2025-09-18 22:56:11.079.
Test Case '-[SpecificationKitTests.HistoricalSpecTests testHistoricalSpec_averageAggregation_calculatesCorrectly]' started.
Test Case '-[SpecificationKitTests.HistoricalSpecTests testHistoricalSpec_averageAggregation_calculatesCorrectly]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.HistoricalSpecTests testHistoricalSpec_customAggregation_calculatesCorrectly]' started.
Test Case '-[SpecificationKitTests.HistoricalSpecTests testHistoricalSpec_customAggregation_calculatesCorrectly]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.HistoricalSpecTests testHistoricalSpec_emptyDataset_returnsNil]' started.
Test Case '-[SpecificationKitTests.HistoricalSpecTests testHistoricalSpec_emptyDataset_returnsNil]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.HistoricalSpecTests testHistoricalSpec_init_succeeds]' started.
Test Case '-[SpecificationKitTests.HistoricalSpecTests testHistoricalSpec_init_succeeds]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.HistoricalSpecTests testHistoricalSpec_insufficientData_returnsNil]' started.
Test Case '-[SpecificationKitTests.HistoricalSpecTests testHistoricalSpec_insufficientData_returnsNil]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.HistoricalSpecTests testHistoricalSpec_lastNWindow_returnsCorrectData]' started.
Test Case '-[SpecificationKitTests.HistoricalSpecTests testHistoricalSpec_lastNWindow_returnsCorrectData]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.HistoricalSpecTests testHistoricalSpec_medianAggregation_calculatesCorrectly]' started.
Test Case '-[SpecificationKitTests.HistoricalSpecTests testHistoricalSpec_medianAggregation_calculatesCorrectly]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.HistoricalSpecTests testHistoricalSpec_percentileAggregation_calculatesCorrectly]' started.
Test Case '-[SpecificationKitTests.HistoricalSpecTests testHistoricalSpec_percentileAggregation_calculatesCorrectly]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.HistoricalSpecTests testHistoricalSpec_performance_largeDataset]' started.
/Users/egor/Development/GitHub/SpecificationKit/Tests/SpecificationKitTests/HistoricalSpecTests.swift:260: Test Case '-[SpecificationKitTests.HistoricalSpecTests testHistoricalSpec_performance_largeDataset]' measured [Time, seconds] average: 0.002, relative standard deviation: 18.462%, values: [0.002598, 0.001314, 0.001897, 0.002096, 0.002222, 0.001743, 0.001683, 0.001943, 0.001566, 0.001683], performanceMetricID:com.apple.XCTPerformanceMetric_WallClockTime, baselineName: "", baselineAverage: , polarity: prefers smaller, maxPercentRegression: 10.000%, maxPercentRelativeStandardDeviation: 10.000%, maxRegression: 0.100, maxStandardDeviation: 0.100
Test Case '-[SpecificationKitTests.HistoricalSpecTests testHistoricalSpec_performance_largeDataset]' passed (0.275 seconds).
Test Case '-[SpecificationKitTests.HistoricalSpecTests testHistoricalSpec_singleDataPoint_returnsValue]' started.
Test Case '-[SpecificationKitTests.HistoricalSpecTests testHistoricalSpec_singleDataPoint_returnsValue]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.HistoricalSpecTests testHistoricalSpec_sufficientData_returnsResult]' started.
Test Case '-[SpecificationKitTests.HistoricalSpecTests testHistoricalSpec_sufficientData_returnsResult]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.HistoricalSpecTests testHistoricalSpec_timeRangeWindow_filtersCorrectly]' started.
Test Case '-[SpecificationKitTests.HistoricalSpecTests testHistoricalSpec_timeRangeWindow_filtersCorrectly]' passed (0.000 seconds).
Test Suite 'HistoricalSpecTests' passed at 2025-09-18 22:56:11.356.
	 Executed 12 tests, with 0 failures (0 unexpected) in 0.277 (0.277) seconds
Test Suite 'LocationContextProviderTests' started at 2025-09-18 22:56:11.356.
Test Case '-[SpecificationKitTests.LocationContextProviderTests testLocationContextProviderConfiguration]' started.
Test Case '-[SpecificationKitTests.LocationContextProviderTests testLocationContextProviderConfiguration]' passed (0.001 seconds).
Test Case '-[SpecificationKitTests.LocationContextProviderTests testLocationContextProviderPresets]' started.
Test Case '-[SpecificationKitTests.LocationContextProviderTests testLocationContextProviderPresets]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.LocationContextProviderTests testLocationGeographicConditionSpecification]' started.
Test Case '-[SpecificationKitTests.LocationContextProviderTests testLocationGeographicConditionSpecification]' passed (0.003 seconds).
Test Case '-[SpecificationKitTests.LocationContextProviderTests testLocationProximitySpecification]' started.
Test Case '-[SpecificationKitTests.LocationContextProviderTests testLocationProximitySpecification]' passed (0.004 seconds).
Test Case '-[SpecificationKitTests.LocationContextProviderTests testLocationRegionSpecification]' started.
Test Case '-[SpecificationKitTests.LocationContextProviderTests testLocationRegionSpecification]' passed (0.002 seconds).
Test Suite 'LocationContextProviderTests' passed at 2025-09-18 22:56:11.367.
	 Executed 5 tests, with 0 failures (0 unexpected) in 0.011 (0.011) seconds
Test Suite 'MacOSSystemContextProviderTests' started at 2025-09-18 22:56:11.367.
Test Case '-[SpecificationKitTests.MacOSSystemContextProviderTests testMacOSSpecificationFactories]' started.
Test Case '-[SpecificationKitTests.MacOSSystemContextProviderTests testMacOSSpecificationFactories]' passed (0.002 seconds).
Test Case '-[SpecificationKitTests.MacOSSystemContextProviderTests testMacOSSystemCapabilityDetection]' started.
Test Case '-[SpecificationKitTests.MacOSSystemContextProviderTests testMacOSSystemCapabilityDetection]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.MacOSSystemContextProviderTests testMacOSSystemContextEnvironmentDetection]' started.
Test Case '-[SpecificationKitTests.MacOSSystemContextProviderTests testMacOSSystemContextEnvironmentDetection]' passed (0.001 seconds).
Test Case '-[SpecificationKitTests.MacOSSystemContextProviderTests testMacOSSystemContextProviderCaching]' started.
Test Case '-[SpecificationKitTests.MacOSSystemContextProviderTests testMacOSSystemContextProviderCaching]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.MacOSSystemContextProviderTests testMacOSSystemContextProviderCreation]' started.
Test Case '-[SpecificationKitTests.MacOSSystemContextProviderTests testMacOSSystemContextProviderCreation]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.MacOSSystemContextProviderTests testMacOSSystemContextProviderInvalidKeys]' started.
Test Case '-[SpecificationKitTests.MacOSSystemContextProviderTests testMacOSSystemContextProviderInvalidKeys]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.MacOSSystemContextProviderTests testMacOSSystemContextValues]' started.
Test Case '-[SpecificationKitTests.MacOSSystemContextProviderTests testMacOSSystemContextValues]' passed (0.000 seconds).
Test Suite 'MacOSSystemContextProviderTests' passed at 2025-09-18 22:56:11.371.
	 Executed 7 tests, with 0 failures (0 unexpected) in 0.004 (0.004) seconds
Test Suite 'MaybeWrapperTests' started at 2025-09-18 22:56:11.371.
Test Case '-[SpecificationKitTests.MaybeWrapperTests test_Maybe_builder_buildsOptionalSpec]' started.
Test Case '-[SpecificationKitTests.MaybeWrapperTests test_Maybe_builder_buildsOptionalSpec]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.MaybeWrapperTests test_Maybe_projectedValue_matchesWrappedValue]' started.
Test Case '-[SpecificationKitTests.MaybeWrapperTests test_Maybe_projectedValue_matchesWrappedValue]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.MaybeWrapperTests test_Maybe_returnsMatchedValue_whenMatchExists]' started.
Test Case '-[SpecificationKitTests.MaybeWrapperTests test_Maybe_returnsMatchedValue_whenMatchExists]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.MaybeWrapperTests test_Maybe_returnsNil_whenNoMatch]' started.
Test Case '-[SpecificationKitTests.MaybeWrapperTests test_Maybe_returnsNil_whenNoMatch]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.MaybeWrapperTests test_Maybe_withDecideClosure]' started.
Test Case '-[SpecificationKitTests.MaybeWrapperTests test_Maybe_withDecideClosure]' passed (0.000 seconds).
Test Suite 'MaybeWrapperTests' passed at 2025-09-18 22:56:11.372.
	 Executed 5 tests, with 0 failures (0 unexpected) in 0.000 (0.001) seconds
Test Suite 'MockSpecificationBuilderTests' started at 2025-09-18 22:56:11.372.
Test Case '-[SpecificationKitTests.MockSpecificationBuilderTests testAlwaysReturnsFalse]' started.
Test Case '-[SpecificationKitTests.MockSpecificationBuilderTests testAlwaysReturnsFalse]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.MockSpecificationBuilderTests testAlwaysReturnsTrue]' started.
Test Case '-[SpecificationKitTests.MockSpecificationBuilderTests testAlwaysReturnsTrue]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.MockSpecificationBuilderTests testConcurrentEvaluationsAreThreadSafe]' started.
Test Case '-[SpecificationKitTests.MockSpecificationBuilderTests testConcurrentEvaluationsAreThreadSafe]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.MockSpecificationBuilderTests testConditionalBehaviorEvaluatesPredicate]' started.
Test Case '-[SpecificationKitTests.MockSpecificationBuilderTests testConditionalBehaviorEvaluatesPredicate]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.MockSpecificationBuilderTests testContextDependentBehaviorUsesKeyPath]' started.
Test Case '-[SpecificationKitTests.MockSpecificationBuilderTests testContextDependentBehaviorUsesKeyPath]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.MockSpecificationBuilderTests testExecutionTimeAddsSyntheticDelay]' started.
Test Case '-[SpecificationKitTests.MockSpecificationBuilderTests testExecutionTimeAddsSyntheticDelay]' passed (0.025 seconds).
Test Case '-[SpecificationKitTests.MockSpecificationBuilderTests testFlakyFactoryUsesProbability]' started.
Test Case '-[SpecificationKitTests.MockSpecificationBuilderTests testFlakyFactoryUsesProbability]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.MockSpecificationBuilderTests testRecordedCallsCaptureContextAndTimestamps]' started.
Test Case '-[SpecificationKitTests.MockSpecificationBuilderTests testRecordedCallsCaptureContextAndTimestamps]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.MockSpecificationBuilderTests testResetClearsCallHistory]' started.
Test Case '-[SpecificationKitTests.MockSpecificationBuilderTests testResetClearsCallHistory]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.MockSpecificationBuilderTests testSequenceBehaviorCyclesThroughResults]' started.
Test Case '-[SpecificationKitTests.MockSpecificationBuilderTests testSequenceBehaviorCyclesThroughResults]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.MockSpecificationBuilderTests testSlowFactoryAddsDelay]' started.
Test Case '-[SpecificationKitTests.MockSpecificationBuilderTests testSlowFactoryAddsDelay]' passed (0.013 seconds).
Test Suite 'MockSpecificationBuilderTests' passed at 2025-09-18 22:56:11.411.
	 Executed 11 tests, with 0 failures (0 unexpected) in 0.039 (0.039) seconds
Test Suite 'NetworkContextProviderTests' started at 2025-09-18 22:56:11.411.
Test Case '-[SpecificationKitTests.NetworkContextProviderTests testCacheDisabled]' started.
Test Case '-[SpecificationKitTests.NetworkContextProviderTests testCacheDisabled]' passed (0.010 seconds).
Test Case '-[SpecificationKitTests.NetworkContextProviderTests testConfigurationDefaults]' started.
Test Case '-[SpecificationKitTests.NetworkContextProviderTests testConfigurationDefaults]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.NetworkContextProviderTests testContextUpdatesProvider]' started.
Test Case '-[SpecificationKitTests.NetworkContextProviderTests testContextUpdatesProvider]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.NetworkContextProviderTests testDateParsing]' started.
Test Case '-[SpecificationKitTests.NetworkContextProviderTests testDateParsing]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.NetworkContextProviderTests testFallbackContextWhenNetworkFails]' started.
Test Case '-[SpecificationKitTests.NetworkContextProviderTests testFallbackContextWhenNetworkFails]' passed (0.002 seconds).
Test Case '-[SpecificationKitTests.NetworkContextProviderTests testNetworkErrorDescriptions]' started.
Test Case '-[SpecificationKitTests.NetworkContextProviderTests testNetworkErrorDescriptions]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.NetworkContextProviderTests testRetryPolicyCustom]' started.
Test Case '-[SpecificationKitTests.NetworkContextProviderTests testRetryPolicyCustom]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.NetworkContextProviderTests testRetryPolicyExponentialBackoff]' started.
Test Case '-[SpecificationKitTests.NetworkContextProviderTests testRetryPolicyExponentialBackoff]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.NetworkContextProviderTests testRetryPolicyFixedDelay]' started.
Test Case '-[SpecificationKitTests.NetworkContextProviderTests testRetryPolicyFixedDelay]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.NetworkContextProviderTests testRetryPolicyNone]' started.
Test Case '-[SpecificationKitTests.NetworkContextProviderTests testRetryPolicyNone]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.NetworkContextProviderTests testSuccessfulNetworkRequest]' started.
Test Case '-[SpecificationKitTests.NetworkContextProviderTests testSuccessfulNetworkRequest]' passed (0.002 seconds).
Test Case '-[SpecificationKitTests.NetworkContextProviderTests testSynchronousContextReturnsFallback]' started.
Test Case '-[SpecificationKitTests.NetworkContextProviderTests testSynchronousContextReturnsFallback]' passed (0.000 seconds).
Test Suite 'NetworkContextProviderTests' passed at 2025-09-18 22:56:11.427.
	 Executed 12 tests, with 0 failures (0 unexpected) in 0.015 (0.016) seconds
Test Suite 'ObservedDecidesWrapperTests' started at 2025-09-18 22:56:11.427.
Test Case '-[SpecificationKitTests.ObservedDecidesWrapperTests test_ObservedDecides_enum_result_type]' started.
Test Case '-[SpecificationKitTests.ObservedDecidesWrapperTests test_ObservedDecides_enum_result_type]' passed (0.108 seconds).
Test Case '-[SpecificationKitTests.ObservedDecidesWrapperTests test_ObservedDecides_initialFallback_and_reactsToProviderChange]' started.
Test Case '-[SpecificationKitTests.ObservedDecidesWrapperTests test_ObservedDecides_initialFallback_and_reactsToProviderChange]' passed (0.054 seconds).
Test Case '-[SpecificationKitTests.ObservedDecidesWrapperTests test_ObservedDecides_numeric_result_type]' started.
Test Case '-[SpecificationKitTests.ObservedDecidesWrapperTests test_ObservedDecides_numeric_result_type]' passed (0.108 seconds).
Test Case '-[SpecificationKitTests.ObservedDecidesWrapperTests test_ObservedDecides_performance_with_multiple_updates]' started.
/Users/egor/Development/GitHub/SpecificationKit/Tests/SpecificationKitTests/ObservedDecidesWrapperTests.swift:299: Test Case '-[SpecificationKitTests.ObservedDecidesWrapperTests test_ObservedDecides_performance_with_multiple_updates]' measured [Time, seconds] average: 0.000, relative standard deviation: 25.765%, values: [0.000275, 0.000167, 0.000157, 0.000165, 0.000160, 0.000165, 0.000156, 0.000158, 0.000175, 0.000088], performanceMetricID:com.apple.XCTPerformanceMetric_WallClockTime, baselineName: "", baselineAverage: , polarity: prefers smaller, maxPercentRegression: 10.000%, maxPercentRelativeStandardDeviation: 10.000%, maxRegression: 0.100, maxStandardDeviation: 0.100
Test Case '-[SpecificationKitTests.ObservedDecidesWrapperTests test_ObservedDecides_performance_with_multiple_updates]' passed (0.259 seconds).
Test Case '-[SpecificationKitTests.ObservedDecidesWrapperTests test_ObservedDecides_priorityOrder]' started.
Test Case '-[SpecificationKitTests.ObservedDecidesWrapperTests test_ObservedDecides_priorityOrder]' passed (0.108 seconds).
Test Case '-[SpecificationKitTests.ObservedDecidesWrapperTests test_ObservedDecides_projectedValue_binding]' started.
Test Case '-[SpecificationKitTests.ObservedDecidesWrapperTests test_ObservedDecides_projectedValue_binding]' passed (0.054 seconds).
Test Case '-[SpecificationKitTests.ObservedDecidesWrapperTests test_ObservedDecides_projectedValue_publisher]' started.
Test Case '-[SpecificationKitTests.ObservedDecidesWrapperTests test_ObservedDecides_projectedValue_publisher]' passed (0.054 seconds).
Test Case '-[SpecificationKitTests.ObservedDecidesWrapperTests test_ObservedDecides_with_builder_pattern]' started.
Test Case '-[SpecificationKitTests.ObservedDecidesWrapperTests test_ObservedDecides_with_builder_pattern]' passed (0.108 seconds).
Test Case '-[SpecificationKitTests.ObservedDecidesWrapperTests test_ObservedDecides_with_custom_decide_function]' started.
Test Case '-[SpecificationKitTests.ObservedDecidesWrapperTests test_ObservedDecides_with_custom_decide_function]' passed (0.108 seconds).
Test Case '-[SpecificationKitTests.ObservedDecidesWrapperTests test_ObservedDecides_with_DecisionSpec]' started.
Test Case '-[SpecificationKitTests.ObservedDecidesWrapperTests test_ObservedDecides_with_DecisionSpec]' passed (0.108 seconds).
Test Case '-[SpecificationKitTests.ObservedDecidesWrapperTests test_ObservedDecides_without_provider_updates]' started.
Test Case '-[SpecificationKitTests.ObservedDecidesWrapperTests test_ObservedDecides_without_provider_updates]' passed (0.000 seconds).
Test Suite 'ObservedDecidesWrapperTests' passed at 2025-09-18 22:56:12.498.
	 Executed 11 tests, with 0 failures (0 unexpected) in 1.070 (1.071) seconds
Test Suite 'ObservedMaybeAdditionalTests' started at 2025-09-18 22:56:12.498.
Test Case '-[SpecificationKitTests.ObservedMaybeAdditionalTests test_ObservedMaybe_bindingProjectsCurrentValue]' started.
Test Case '-[SpecificationKitTests.ObservedMaybeAdditionalTests test_ObservedMaybe_bindingProjectsCurrentValue]' passed (0.054 seconds).
Test Case '-[SpecificationKitTests.ObservedMaybeAdditionalTests test_ObservedMaybe_convenience_pairs_and_decide]' started.
Test Case '-[SpecificationKitTests.ObservedMaybeAdditionalTests test_ObservedMaybe_convenience_pairs_and_decide]' passed (0.108 seconds).
Test Case '-[SpecificationKitTests.ObservedMaybeAdditionalTests test_ObservedMaybe_convenience_usingSpec_reactive]' started.
Test Case '-[SpecificationKitTests.ObservedMaybeAdditionalTests test_ObservedMaybe_convenience_usingSpec_reactive]' passed (0.054 seconds).
Test Case '-[SpecificationKitTests.ObservedMaybeAdditionalTests test_ObservedMaybe_environmentProvider_reactsToPublished]' started.
Test Case '-[SpecificationKitTests.ObservedMaybeAdditionalTests test_ObservedMaybe_environmentProvider_reactsToPublished]' passed (0.054 seconds).
Test Suite 'ObservedMaybeAdditionalTests' passed at 2025-09-18 22:56:12.769.
	 Executed 4 tests, with 0 failures (0 unexpected) in 0.270 (0.271) seconds
Test Suite 'ObservedMaybeWrapperTests' started at 2025-09-18 22:56:12.769.
Test Case '-[SpecificationKitTests.ObservedMaybeWrapperTests test_ObservedMaybe_initialNil_and_reactsToProviderChange]' started.
Test Case '-[SpecificationKitTests.ObservedMaybeWrapperTests test_ObservedMaybe_initialNil_and_reactsToProviderChange]' passed (0.054 seconds).
Test Case '-[SpecificationKitTests.ObservedMaybeWrapperTests test_ObservedMaybe_supports_decide_and_pairs_initializers]' started.
Test Case '-[SpecificationKitTests.ObservedMaybeWrapperTests test_ObservedMaybe_supports_decide_and_pairs_initializers]' passed (0.108 seconds).
Test Suite 'ObservedMaybeWrapperTests' passed at 2025-09-18 22:56:12.931.
	 Executed 2 tests, with 0 failures (0 unexpected) in 0.162 (0.162) seconds
Test Suite 'PerformanceBenchmarks' started at 2025-09-18 22:56:12.932.
Test Case '-[SpecificationKitTests.PerformanceBenchmarks testAnySpecificationPerformance]' started.
/Users/egor/Development/GitHub/SpecificationKit/Tests/SpecificationKitTests/PerformanceBenchmarks.swift:107: Test Case '-[SpecificationKitTests.PerformanceBenchmarks testAnySpecificationPerformance]' measured [Clock Monotonic Time, s] average: 0.003, relative standard deviation: 7.404%, values: [0.002855, 0.002520, 0.002594, 0.002571, 0.002260], performanceMetricID:com.apple.dt.XCTMetric_Clock.time.monotonic, baselineName: "", baselineAverage: , polarity: prefers smaller, maxPercentRegression: 10.000%, maxPercentRelativeStandardDeviation: 10.000%, maxRegression: 0.000, maxStandardDeviation: 0.000
Test Case '-[SpecificationKitTests.PerformanceBenchmarks testAnySpecificationPerformance]' passed (0.018 seconds).
Test Case '-[SpecificationKitTests.PerformanceBenchmarks testCachedSatisfiesCacheHitPerformance]' started.
/Users/egor/Development/GitHub/SpecificationKit/Tests/SpecificationKitTests/PerformanceBenchmarks.swift:250: Test Case '-[SpecificationKitTests.PerformanceBenchmarks testCachedSatisfiesCacheHitPerformance]' measured [Clock Monotonic Time, s] average: 0.000, relative standard deviation: 13.885%, values: [0.000386, 0.000467, 0.000566, 0.000575, 0.000504], performanceMetricID:com.apple.dt.XCTMetric_Clock.time.monotonic, baselineName: "", baselineAverage: , polarity: prefers smaller, maxPercentRegression: 10.000%, maxPercentRelativeStandardDeviation: 10.000%, maxRegression: 0.000, maxStandardDeviation: 0.000
Test Case '-[SpecificationKitTests.PerformanceBenchmarks testCachedSatisfiesCacheHitPerformance]' passed (0.004 seconds).
Test Case '-[SpecificationKitTests.PerformanceBenchmarks testCachedSatisfiesCacheMissPerformance]' started.
/Users/egor/Development/GitHub/SpecificationKit/Tests/SpecificationKitTests/PerformanceBenchmarks.swift:232: Test Case '-[SpecificationKitTests.PerformanceBenchmarks testCachedSatisfiesCacheMissPerformance]' measured [Clock Monotonic Time, s] average: 0.001, relative standard deviation: 2.176%, values: [0.000726, 0.000682, 0.000693, 0.000702, 0.000690], performanceMetricID:com.apple.dt.XCTMetric_Clock.time.monotonic, baselineName: "", baselineAverage: , polarity: prefers smaller, maxPercentRegression: 10.000%, maxPercentRelativeStandardDeviation: 10.000%, maxRegression: 0.000, maxStandardDeviation: 0.000
Test Case '-[SpecificationKitTests.PerformanceBenchmarks testCachedSatisfiesCacheMissPerformance]' passed (0.005 seconds).
Test Case '-[SpecificationKitTests.PerformanceBenchmarks testCachedSatisfiesMemoryPerformance]' started.
/Users/egor/Development/GitHub/SpecificationKit/Tests/SpecificationKitTests/PerformanceBenchmarks.swift:270: Test Case '-[SpecificationKitTests.PerformanceBenchmarks testCachedSatisfiesMemoryPerformance]' measured [Memory Physical, kB] average: 16.384, relative standard deviation: 63.246%, values: [32.768000, 16.384000, 16.384000, 16.384000, 0.000000], performanceMetricID:com.apple.dt.XCTMetric_Memory.physical, baselineName: "", baselineAverage: , polarity: prefers smaller, maxPercentRegression: 10.000%, maxPercentRelativeStandardDeviation: 10.000%, maxRegression: 0.000, maxStandardDeviation: 0.000
/Users/egor/Development/GitHub/SpecificationKit/Tests/SpecificationKitTests/PerformanceBenchmarks.swift:270: Test Case '-[SpecificationKitTests.PerformanceBenchmarks testCachedSatisfiesMemoryPerformance]' measured [Memory Peak Physical, kB] average: 117274.139, relative standard deviation: 0.016%, values: [117244.648000, 117261.032000, 117277.416000, 117293.800000, 117293.800000], performanceMetricID:com.apple.dt.XCTMetric_Memory.physical_peak, baselineName: "", baselineAverage: , polarity: prefers smaller, maxPercentRegression: 10.000%, maxPercentRelativeStandardDeviation: 10.000%, maxRegression: 0.000, maxStandardDeviation: 0.000
Test Case '-[SpecificationKitTests.PerformanceBenchmarks testCachedSatisfiesMemoryPerformance]' passed (0.003 seconds).
Test Case '-[SpecificationKitTests.PerformanceBenchmarks testCachedSatisfiesPerformance]' started.
/Users/egor/Development/GitHub/SpecificationKit/Tests/SpecificationKitTests/PerformanceBenchmarks.swift:213: Test Case '-[SpecificationKitTests.PerformanceBenchmarks testCachedSatisfiesPerformance]' measured [Memory Peak Physical, kB] average: 117310.184, relative standard deviation: 0.000%, values: [117310.184000, 117310.184000, 117310.184000, 117310.184000, 117310.184000], performanceMetricID:com.apple.dt.XCTMetric_Memory.physical_peak, baselineName: "", baselineAverage: , polarity: prefers smaller, maxPercentRegression: 10.000%, maxPercentRelativeStandardDeviation: 10.000%, maxRegression: 0.000, maxStandardDeviation: 0.000
/Users/egor/Development/GitHub/SpecificationKit/Tests/SpecificationKitTests/PerformanceBenchmarks.swift:213: Test Case '-[SpecificationKitTests.PerformanceBenchmarks testCachedSatisfiesPerformance]' measured [Memory Physical, kB] average: 0.000, relative standard deviation: 0.000%, values: [0.000000, 0.000000, 0.000000, 0.000000, 0.000000], performanceMetricID:com.apple.dt.XCTMetric_Memory.physical, baselineName: "", baselineAverage: , polarity: prefers smaller, maxPercentRegression: 10.000%, maxPercentRelativeStandardDeviation: 10.000%, maxRegression: 0.000, maxStandardDeviation: 0.000
/Users/egor/Development/GitHub/SpecificationKit/Tests/SpecificationKitTests/PerformanceBenchmarks.swift:213: Test Case '-[SpecificationKitTests.PerformanceBenchmarks testCachedSatisfiesPerformance]' measured [Clock Monotonic Time, s] average: 0.000, relative standard deviation: 4.557%, values: [0.000398, 0.000437, 0.000452, 0.000451, 0.000435], performanceMetricID:com.apple.dt.XCTMetric_Clock.time.monotonic, baselineName: "", baselineAverage: , polarity: prefers smaller, maxPercentRegression: 10.000%, maxPercentRelativeStandardDeviation: 10.000%, maxRegression: 0.000, maxStandardDeviation: 0.000
Test Case '-[SpecificationKitTests.PerformanceBenchmarks testCachedSatisfiesPerformance]' passed (0.006 seconds).
Test Case '-[SpecificationKitTests.PerformanceBenchmarks testComplexSpecificationPerformance]' started.
/Users/egor/Development/GitHub/SpecificationKit/Tests/SpecificationKitTests/PerformanceBenchmarks.swift:52: Test Case '-[SpecificationKitTests.PerformanceBenchmarks testComplexSpecificationPerformance]' measured [Memory Peak Physical, kB] average: 117310.184, relative standard deviation: 0.000%, values: [117310.184000, 117310.184000, 117310.184000, 117310.184000, 117310.184000], performanceMetricID:com.apple.dt.XCTMetric_Memory.physical_peak, baselineName: "", baselineAverage: , polarity: prefers smaller, maxPercentRegression: 10.000%, maxPercentRelativeStandardDeviation: 10.000%, maxRegression: 0.000, maxStandardDeviation: 0.000
/Users/egor/Development/GitHub/SpecificationKit/Tests/SpecificationKitTests/PerformanceBenchmarks.swift:52: Test Case '-[SpecificationKitTests.PerformanceBenchmarks testComplexSpecificationPerformance]' measured [Memory Physical, kB] average: 0.000, relative standard deviation: 0.000%, values: [0.000000, 0.000000, 0.000000, 0.000000, 0.000000], performanceMetricID:com.apple.dt.XCTMetric_Memory.physical, baselineName: "", baselineAverage: , polarity: prefers smaller, maxPercentRegression: 10.000%, maxPercentRelativeStandardDeviation: 10.000%, maxRegression: 0.000, maxStandardDeviation: 0.000
/Users/egor/Development/GitHub/SpecificationKit/Tests/SpecificationKitTests/PerformanceBenchmarks.swift:52: Test Case '-[SpecificationKitTests.PerformanceBenchmarks testComplexSpecificationPerformance]' measured [Clock Monotonic Time, s] average: 0.000, relative standard deviation: 2.698%, values: [0.000349, 0.000369, 0.000371, 0.000372, 0.000379], performanceMetricID:com.apple.dt.XCTMetric_Clock.time.monotonic, baselineName: "", baselineAverage: , polarity: prefers smaller, maxPercentRegression: 10.000%, maxPercentRelativeStandardDeviation: 10.000%, maxRegression: 0.000, maxStandardDeviation: 0.000
Test Case '-[SpecificationKitTests.PerformanceBenchmarks testComplexSpecificationPerformance]' passed (0.005 seconds).
Test Case '-[SpecificationKitTests.PerformanceBenchmarks testConcurrentContextProviderAccess]' started.
/Users/egor/Development/GitHub/SpecificationKit/Tests/SpecificationKitTests/PerformanceBenchmarks.swift:138: Test Case '-[SpecificationKitTests.PerformanceBenchmarks testConcurrentContextProviderAccess]' measured [Clock Monotonic Time, s] average: 0.000, relative standard deviation: 8.522%, values: [0.000097, 0.000120, 0.000104, 0.000110, 0.000095], performanceMetricID:com.apple.dt.XCTMetric_Clock.time.monotonic, baselineName: "", baselineAverage: , polarity: prefers smaller, maxPercentRegression: 10.000%, maxPercentRelativeStandardDeviation: 10.000%, maxRegression: 0.000, maxStandardDeviation: 0.000
Test Case '-[SpecificationKitTests.PerformanceBenchmarks testConcurrentContextProviderAccess]' passed (0.002 seconds).
Test Case '-[SpecificationKitTests.PerformanceBenchmarks testContextCachePerformance]' started.
/Users/egor/Development/GitHub/SpecificationKit/Tests/SpecificationKitTests/PerformanceBenchmarks.swift:158: Test Case '-[SpecificationKitTests.PerformanceBenchmarks testContextCachePerformance]' measured [Memory Peak Physical, kB] average: 117310.184, relative standard deviation: 0.000%, values: [117310.184000, 117310.184000, 117310.184000, 117310.184000, 117310.184000], performanceMetricID:com.apple.dt.XCTMetric_Memory.physical_peak, baselineName: "", baselineAverage: , polarity: prefers smaller, maxPercentRegression: 10.000%, maxPercentRelativeStandardDeviation: 10.000%, maxRegression: 0.000, maxStandardDeviation: 0.000
/Users/egor/Development/GitHub/SpecificationKit/Tests/SpecificationKitTests/PerformanceBenchmarks.swift:158: Test Case '-[SpecificationKitTests.PerformanceBenchmarks testContextCachePerformance]' measured [Memory Physical, kB] average: 0.000, relative standard deviation: 0.000%, values: [0.000000, 0.000000, 0.000000, 0.000000, 0.000000], performanceMetricID:com.apple.dt.XCTMetric_Memory.physical, baselineName: "", baselineAverage: , polarity: prefers smaller, maxPercentRegression: 10.000%, maxPercentRelativeStandardDeviation: 10.000%, maxRegression: 0.000, maxStandardDeviation: 0.000
/Users/egor/Development/GitHub/SpecificationKit/Tests/SpecificationKitTests/PerformanceBenchmarks.swift:158: Test Case '-[SpecificationKitTests.PerformanceBenchmarks testContextCachePerformance]' measured [Clock Monotonic Time, s] average: 0.003, relative standard deviation: 3.302%, values: [0.003270, 0.003245, 0.003179, 0.003013, 0.003046], performanceMetricID:com.apple.dt.XCTMetric_Clock.time.monotonic, baselineName: "", baselineAverage: , polarity: prefers smaller, maxPercentRegression: 10.000%, maxPercentRelativeStandardDeviation: 10.000%, maxRegression: 0.000, maxStandardDeviation: 0.000
Test Case '-[SpecificationKitTests.PerformanceBenchmarks testContextCachePerformance]' passed (0.022 seconds).
Test Case '-[SpecificationKitTests.PerformanceBenchmarks testContextProviderPerformance]' started.
/Users/egor/Development/GitHub/SpecificationKit/Tests/SpecificationKitTests/PerformanceBenchmarks.swift:88: Test Case '-[SpecificationKitTests.PerformanceBenchmarks testContextProviderPerformance]' measured [Memory Peak Physical, kB] average: 117326.568, relative standard deviation: 0.000%, values: [117326.568000, 117326.568000, 117326.568000, 117326.568000, 117326.568000], performanceMetricID:com.apple.dt.XCTMetric_Memory.physical_peak, baselineName: "", baselineAverage: , polarity: prefers smaller, maxPercentRegression: 10.000%, maxPercentRelativeStandardDeviation: 10.000%, maxRegression: 0.000, maxStandardDeviation: 0.000
/Users/egor/Development/GitHub/SpecificationKit/Tests/SpecificationKitTests/PerformanceBenchmarks.swift:88: Test Case '-[SpecificationKitTests.PerformanceBenchmarks testContextProviderPerformance]' measured [Memory Physical, kB] average: 0.000, relative standard deviation: 0.000%, values: [0.000000, 0.000000, 0.000000, 0.000000, 0.000000], performanceMetricID:com.apple.dt.XCTMetric_Memory.physical, baselineName: "", baselineAverage: , polarity: prefers smaller, maxPercentRegression: 10.000%, maxPercentRelativeStandardDeviation: 10.000%, maxRegression: 0.000, maxStandardDeviation: 0.000
/Users/egor/Development/GitHub/SpecificationKit/Tests/SpecificationKitTests/PerformanceBenchmarks.swift:88: Test Case '-[SpecificationKitTests.PerformanceBenchmarks testContextProviderPerformance]' measured [Clock Monotonic Time, s] average: 0.000, relative standard deviation: 0.574%, values: [0.000428, 0.000424, 0.000426, 0.000422, 0.000421], performanceMetricID:com.apple.dt.XCTMetric_Clock.time.monotonic, baselineName: "", baselineAverage: , polarity: prefers smaller, maxPercentRegression: 10.000%, maxPercentRelativeStandardDeviation: 10.000%, maxRegression: 0.000, maxStandardDeviation: 0.000
Test Case '-[SpecificationKitTests.PerformanceBenchmarks testContextProviderPerformance]' passed (0.005 seconds).
Test Case '-[SpecificationKitTests.PerformanceBenchmarks testDirectSpecificationPerformance]' started.
/Users/egor/Development/GitHub/SpecificationKit/Tests/SpecificationKitTests/PerformanceBenchmarks.swift:69: Test Case '-[SpecificationKitTests.PerformanceBenchmarks testDirectSpecificationPerformance]' measured [Clock Monotonic Time, s] average: 0.002, relative standard deviation: 1.883%, values: [0.001627, 0.001599, 0.001536, 0.001589, 0.001577], performanceMetricID:com.apple.dt.XCTMetric_Clock.time.monotonic, baselineName: "", baselineAverage: , polarity: prefers smaller, maxPercentRegression: 10.000%, maxPercentRelativeStandardDeviation: 10.000%, maxRegression: 0.000, maxStandardDeviation: 0.000
Test Case '-[SpecificationKitTests.PerformanceBenchmarks testDirectSpecificationPerformance]' passed (0.010 seconds).
Test Case '-[SpecificationKitTests.PerformanceBenchmarks testProfilerIntegration]' started.
/Users/egor/Development/GitHub/SpecificationKit/Tests/SpecificationKitTests/PerformanceBenchmarks.swift:175: Test Case '-[SpecificationKitTests.PerformanceBenchmarks testProfilerIntegration]' measured [Clock Monotonic Time, s] average: 0.001, relative standard deviation: 7.226%, values: [0.001100, 0.001031, 0.000998, 0.001014, 0.001208], performanceMetricID:com.apple.dt.XCTMetric_Clock.time.monotonic, baselineName: "", baselineAverage: , polarity: prefers smaller, maxPercentRegression: 10.000%, maxPercentRelativeStandardDeviation: 10.000%, maxRegression: 0.000, maxStandardDeviation: 0.000
Test Case '-[SpecificationKitTests.PerformanceBenchmarks testProfilerIntegration]' passed (0.010 seconds).
Test Case '-[SpecificationKitTests.PerformanceBenchmarks testSpecificationEvaluationPerformance]' started.
/Users/egor/Development/GitHub/SpecificationKit/Tests/SpecificationKitTests/PerformanceBenchmarks.swift:32: Test Case '-[SpecificationKitTests.PerformanceBenchmarks testSpecificationEvaluationPerformance]' measured [Memory Peak Physical, kB] average: 117375.720, relative standard deviation: 0.000%, values: [117375.720000, 117375.720000, 117375.720000, 117375.720000, 117375.720000], performanceMetricID:com.apple.dt.XCTMetric_Memory.physical_peak, baselineName: "", baselineAverage: , polarity: prefers smaller, maxPercentRegression: 10.000%, maxPercentRelativeStandardDeviation: 10.000%, maxRegression: 0.000, maxStandardDeviation: 0.000
/Users/egor/Development/GitHub/SpecificationKit/Tests/SpecificationKitTests/PerformanceBenchmarks.swift:32: Test Case '-[SpecificationKitTests.PerformanceBenchmarks testSpecificationEvaluationPerformance]' measured [Memory Physical, kB] average: 0.000, relative standard deviation: 0.000%, values: [0.000000, 0.000000, 0.000000, 0.000000, 0.000000], performanceMetricID:com.apple.dt.XCTMetric_Memory.physical, baselineName: "", baselineAverage: , polarity: prefers smaller, maxPercentRegression: 10.000%, maxPercentRelativeStandardDeviation: 10.000%, maxRegression: 0.000, maxStandardDeviation: 0.000
/Users/egor/Development/GitHub/SpecificationKit/Tests/SpecificationKitTests/PerformanceBenchmarks.swift:32: Test Case '-[SpecificationKitTests.PerformanceBenchmarks testSpecificationEvaluationPerformance]' measured [Clock Monotonic Time, s] average: 0.000, relative standard deviation: 2.815%, values: [0.000197, 0.000203, 0.000196, 0.000188, 0.000189], performanceMetricID:com.apple.dt.XCTMetric_Clock.time.monotonic, baselineName: "", baselineAverage: , polarity: prefers smaller, maxPercentRegression: 10.000%, maxPercentRelativeStandardDeviation: 10.000%, maxRegression: 0.000, maxStandardDeviation: 0.000
Test Case '-[SpecificationKitTests.PerformanceBenchmarks testSpecificationEvaluationPerformance]' passed (0.003 seconds).
Test Case '-[SpecificationKitTests.PerformanceBenchmarks testSpecificationMemoryUsage]' started.
/Users/egor/Development/GitHub/SpecificationKit/Tests/SpecificationKitTests/PerformanceBenchmarks.swift:117: Test Case '-[SpecificationKitTests.PerformanceBenchmarks testSpecificationMemoryUsage]' measured [Memory Physical, kB] average: 3.277, relative standard deviation: 200.000%, values: [0.000000, 0.000000, 16.384000, 0.000000, 0.000000], performanceMetricID:com.apple.dt.XCTMetric_Memory.physical, baselineName: "", baselineAverage: , polarity: prefers smaller, maxPercentRegression: 10.000%, maxPercentRelativeStandardDeviation: 10.000%, maxRegression: 0.000, maxStandardDeviation: 0.000
/Users/egor/Development/GitHub/SpecificationKit/Tests/SpecificationKitTests/PerformanceBenchmarks.swift:117: Test Case '-[SpecificationKitTests.PerformanceBenchmarks testSpecificationMemoryUsage]' measured [Memory Peak Physical, kB] average: 117467.494, relative standard deviation: 0.007%, values: [117457.664000, 117457.664000, 117474.048000, 117474.048000, 117474.048000], performanceMetricID:com.apple.dt.XCTMetric_Memory.physical_peak, baselineName: "", baselineAverage: , polarity: prefers smaller, maxPercentRegression: 10.000%, maxPercentRelativeStandardDeviation: 10.000%, maxRegression: 0.000, maxStandardDeviation: 0.000
Test Case '-[SpecificationKitTests.PerformanceBenchmarks testSpecificationMemoryUsage]' passed (0.004 seconds).
Test Suite 'PerformanceBenchmarks' passed at 2025-09-18 22:56:13.031.
	 Executed 13 tests, with 0 failures (0 unexpected) in 0.098 (0.099) seconds
Test Suite 'PersistentContextProviderTests' started at 2025-09-18 22:56:13.031.
Test Case '-[SpecificationKitTests.PersistentContextProviderTests testAddSegmentPersistsStringSet]' started.
Test Case '-[SpecificationKitTests.PersistentContextProviderTests testAddSegmentPersistsStringSet]' passed (0.004 seconds).
Test Case '-[SpecificationKitTests.PersistentContextProviderTests testAsyncContextReturnsPersistedData]' started.
Test Case '-[SpecificationKitTests.PersistentContextProviderTests testAsyncContextReturnsPersistedData]' passed (0.002 seconds).
Test Case '-[SpecificationKitTests.PersistentContextProviderTests testAutomaticMigrationConfiguration]' started.
Test Case '-[SpecificationKitTests.PersistentContextProviderTests testAutomaticMigrationConfiguration]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.PersistentContextProviderTests testClearAllData]' started.
Test Case '-[SpecificationKitTests.PersistentContextProviderTests testClearAllData]' passed (0.001 seconds).
Test Case '-[SpecificationKitTests.PersistentContextProviderTests testConcurrentReadsAndWrites]' started.
Test Case '-[SpecificationKitTests.PersistentContextProviderTests testConcurrentReadsAndWrites]' passed (0.053 seconds).
Test Case '-[SpecificationKitTests.PersistentContextProviderTests testConcurrentWrites]' started.
Test Case '-[SpecificationKitTests.PersistentContextProviderTests testConcurrentWrites]' passed (0.057 seconds).
Test Case '-[SpecificationKitTests.PersistentContextProviderTests testContextChangeNotifications]' started.
Test Case '-[SpecificationKitTests.PersistentContextProviderTests testContextChangeNotifications]' passed (0.001 seconds).
Test Case '-[SpecificationKitTests.PersistentContextProviderTests testContextStreamNotifications]' started.
Test Case '-[SpecificationKitTests.PersistentContextProviderTests testContextStreamNotifications]' passed (0.001 seconds).
Test Case '-[SpecificationKitTests.PersistentContextProviderTests testDefaultConfiguration]' started.
Test Case '-[SpecificationKitTests.PersistentContextProviderTests testDefaultConfiguration]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.PersistentContextProviderTests testIncrementCounterUpdatesValue]' started.
Test Case '-[SpecificationKitTests.PersistentContextProviderTests testIncrementCounterUpdatesValue]' passed (0.001 seconds).
Test Case '-[SpecificationKitTests.PersistentContextProviderTests testManualMigrationConfiguration]' started.
Test Case '-[SpecificationKitTests.PersistentContextProviderTests testManualMigrationConfiguration]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.PersistentContextProviderTests testPerformanceBatchOperations]' started.
/Users/egor/Development/GitHub/SpecificationKit/Tests/SpecificationKitTests/PersistentContextProviderTests.swift:558: Test Case '-[SpecificationKitTests.PersistentContextProviderTests testPerformanceBatchOperations]' measured [Time, seconds] average: 0.103, relative standard deviation: 1.854%, values: [0.105170, 0.100466, 0.105166, 0.103133, 0.105175, 0.101672, 0.101398, 0.101036, 0.105149, 0.105132], performanceMetricID:com.apple.XCTPerformanceMetric_WallClockTime, baselineName: "", baselineAverage: , polarity: prefers smaller, maxPercentRegression: 10.000%, maxPercentRelativeStandardDeviation: 10.000%, maxRegression: 0.100, maxStandardDeviation: 0.100
Test Case '-[SpecificationKitTests.PersistentContextProviderTests testPerformanceBatchOperations]' passed (1.035 seconds).
Test Case '-[SpecificationKitTests.PersistentContextProviderTests testPerformanceSingleRead]' started.
/Users/egor/Development/GitHub/SpecificationKit/Tests/SpecificationKitTests/PersistentContextProviderTests.swift:530: Test Case '-[SpecificationKitTests.PersistentContextProviderTests testPerformanceSingleRead]' measured [Time, seconds] average: 0.104, relative standard deviation: 1.599%, values: [0.105079, 0.105121, 0.105143, 0.105141, 0.101129, 0.101244, 0.105195, 0.105170, 0.102342, 0.105151], performanceMetricID:com.apple.XCTPerformanceMetric_WallClockTime, baselineName: "", baselineAverage: , polarity: prefers smaller, maxPercentRegression: 10.000%, maxPercentRelativeStandardDeviation: 10.000%, maxRegression: 0.100, maxStandardDeviation: 0.100
Test Case '-[SpecificationKitTests.PersistentContextProviderTests testPerformanceSingleRead]' passed (1.042 seconds).
Test Case '-[SpecificationKitTests.PersistentContextProviderTests testPerformanceSingleWrite]' started.
/Users/egor/Development/GitHub/SpecificationKit/Tests/SpecificationKitTests/PersistentContextProviderTests.swift:544: Test Case '-[SpecificationKitTests.PersistentContextProviderTests testPerformanceSingleWrite]' measured [Time, seconds] average: 0.103, relative standard deviation: 1.918%, values: [0.102006, 0.101205, 0.105165, 0.105159, 0.105145, 0.101147, 0.105144, 0.105119, 0.100662, 0.101160], performanceMetricID:com.apple.XCTPerformanceMetric_WallClockTime, baselineName: "", baselineAverage: , polarity: prefers smaller, maxPercentRegression: 10.000%, maxPercentRelativeStandardDeviation: 10.000%, maxRegression: 0.100, maxStandardDeviation: 0.100
Test Case '-[SpecificationKitTests.PersistentContextProviderTests testPerformanceSingleWrite]' passed (1.035 seconds).
Test Case '-[SpecificationKitTests.PersistentContextProviderTests testPersistenceErrorHandling]' started.
Test Case '-[SpecificationKitTests.PersistentContextProviderTests testPersistenceErrorHandling]' passed (0.002 seconds).
Test Case '-[SpecificationKitTests.PersistentContextProviderTests testRemoveExpiredData]' started.
Test Case '-[SpecificationKitTests.PersistentContextProviderTests testRemoveExpiredData]' passed (0.003 seconds).
Test Case '-[SpecificationKitTests.PersistentContextProviderTests testRemoveSegmentPersistsRemoval]' started.
Test Case '-[SpecificationKitTests.PersistentContextProviderTests testRemoveSegmentPersistsRemoval]' passed (0.002 seconds).
Test Case '-[SpecificationKitTests.PersistentContextProviderTests testSetCounterPersistsNumericData]' started.
Test Case '-[SpecificationKitTests.PersistentContextProviderTests testSetCounterPersistsNumericData]' passed (0.001 seconds).
Test Case '-[SpecificationKitTests.PersistentContextProviderTests testSetEventPersistsDateData]' started.
Test Case '-[SpecificationKitTests.PersistentContextProviderTests testSetEventPersistsDateData]' passed (0.002 seconds).
Test Case '-[SpecificationKitTests.PersistentContextProviderTests testSetFlagPersistsBooleanData]' started.
Test Case '-[SpecificationKitTests.PersistentContextProviderTests testSetFlagPersistsBooleanData]' passed (0.001 seconds).
Test Case '-[SpecificationKitTests.PersistentContextProviderTests testSetValuePersistsData]' started.
Test Case '-[SpecificationKitTests.PersistentContextProviderTests testSetValuePersistsData]' passed (0.001 seconds).
Test Case '-[SpecificationKitTests.PersistentContextProviderTests testSetValueWithExpirationRemovesExpiredData]' started.
Test Case '-[SpecificationKitTests.PersistentContextProviderTests testSetValueWithExpirationRemovesExpiredData]' passed (0.001 seconds).
Test Case '-[SpecificationKitTests.PersistentContextProviderTests testSetValueWithFutureExpirationKeepsData]' started.
Test Case '-[SpecificationKitTests.PersistentContextProviderTests testSetValueWithFutureExpirationKeepsData]' passed (0.001 seconds).
Test Case '-[SpecificationKitTests.PersistentContextProviderTests testSupportsArrayDataType]' started.
Test Case '-[SpecificationKitTests.PersistentContextProviderTests testSupportsArrayDataType]' passed (0.002 seconds).
Test Case '-[SpecificationKitTests.PersistentContextProviderTests testSupportsBoolDataType]' started.
Test Case '-[SpecificationKitTests.PersistentContextProviderTests testSupportsBoolDataType]' passed (0.001 seconds).
Test Case '-[SpecificationKitTests.PersistentContextProviderTests testSupportsDateDataType]' started.
Test Case '-[SpecificationKitTests.PersistentContextProviderTests testSupportsDateDataType]' passed (0.001 seconds).
Test Case '-[SpecificationKitTests.PersistentContextProviderTests testSupportsDictionaryDataType]' started.
Test Case '-[SpecificationKitTests.PersistentContextProviderTests testSupportsDictionaryDataType]' passed (0.002 seconds).
Test Case '-[SpecificationKitTests.PersistentContextProviderTests testSupportsDoubleDataType]' started.
Test Case '-[SpecificationKitTests.PersistentContextProviderTests testSupportsDoubleDataType]' passed (0.001 seconds).
Test Case '-[SpecificationKitTests.PersistentContextProviderTests testSupportsIntDataType]' started.
Test Case '-[SpecificationKitTests.PersistentContextProviderTests testSupportsIntDataType]' passed (0.001 seconds).
Test Case '-[SpecificationKitTests.PersistentContextProviderTests testSupportsStringDataType]' started.
Test Case '-[SpecificationKitTests.PersistentContextProviderTests testSupportsStringDataType]' passed (0.001 seconds).
Test Case '-[SpecificationKitTests.PersistentContextProviderTests testSynchronousContextReturnsEmpty]' started.
Test Case '-[SpecificationKitTests.PersistentContextProviderTests testSynchronousContextReturnsEmpty]' passed (0.000 seconds).
Test Suite 'PersistentContextProviderTests' passed at 2025-09-18 22:56:16.287.
	 Executed 31 tests, with 0 failures (0 unexpected) in 3.255 (3.257) seconds
Test Suite 'PlatformContextProvidersTests' started at 2025-09-18 22:56:16.287.
Test Case '-[SpecificationKitTests.PlatformContextProvidersTests testBasicDeviceContext]' started.
Test Case '-[SpecificationKitTests.PlatformContextProvidersTests testBasicDeviceContext]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.PlatformContextProvidersTests testBatterySpec]' started.
Test Case '-[SpecificationKitTests.PlatformContextProvidersTests testBatterySpec]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.PlatformContextProvidersTests testDeviceCapabilitySpecs]' started.
Test Case '-[SpecificationKitTests.PlatformContextProvidersTests testDeviceCapabilitySpecs]' passed (0.002 seconds).
Test Case '-[SpecificationKitTests.PlatformContextProvidersTests testDeviceContextProviderFactory]' started.
Test Case '-[SpecificationKitTests.PlatformContextProvidersTests testDeviceContextProviderFactory]' passed (0.001 seconds).
Test Case '-[SpecificationKitTests.PlatformContextProvidersTests testDeviceContextProviderIntegration]' started.
Test Case '-[SpecificationKitTests.PlatformContextProvidersTests testDeviceContextProviderIntegration]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.PlatformContextProvidersTests testEmptyLocationContext]' started.
Test Case '-[SpecificationKitTests.PlatformContextProvidersTests testEmptyLocationContext]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.PlatformContextProvidersTests testGracefulDegradation]' started.
Test Case '-[SpecificationKitTests.PlatformContextProvidersTests testGracefulDegradation]' passed (0.006 seconds).
Test Case '-[SpecificationKitTests.PlatformContextProvidersTests testHealthPermissionCheck]' started.
Test Case '-[SpecificationKitTests.PlatformContextProvidersTests testHealthPermissionCheck]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.PlatformContextProvidersTests testLocationContextProviderFactory]' started.
Test Case '-[SpecificationKitTests.PlatformContextProvidersTests testLocationContextProviderFactory]' passed (0.001 seconds).
Test Case '-[SpecificationKitTests.PlatformContextProvidersTests testLocationContextProviderIntegration]' started.
Test Case '-[SpecificationKitTests.PlatformContextProvidersTests testLocationContextProviderIntegration]' passed (0.003 seconds).
Test Case '-[SpecificationKitTests.PlatformContextProvidersTests testLocationCoordinateCoreLocationConversion]' started.
Test Case '-[SpecificationKitTests.PlatformContextProvidersTests testLocationCoordinateCoreLocationConversion]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.PlatformContextProvidersTests testLocationCoordinateCreation]' started.
Test Case '-[SpecificationKitTests.PlatformContextProvidersTests testLocationCoordinateCreation]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.PlatformContextProvidersTests testLocationPermissionCheck]' started.
Test Case '-[SpecificationKitTests.PlatformContextProvidersTests testLocationPermissionCheck]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.PlatformContextProvidersTests testLocationProximitySpecFactory]' started.
Test Case '-[SpecificationKitTests.PlatformContextProvidersTests testLocationProximitySpecFactory]' passed (0.001 seconds).
Test Case '-[SpecificationKitTests.PlatformContextProvidersTests testPerformanceSpec]' started.
Test Case '-[SpecificationKitTests.PlatformContextProvidersTests testPerformanceSpec]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.PlatformContextProvidersTests testPlatformCapabilityDetection]' started.
Test Case '-[SpecificationKitTests.PlatformContextProvidersTests testPlatformCapabilityDetection]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.PlatformContextProvidersTests testSpecificationUsagePatterns]' started.
Test Case '-[SpecificationKitTests.PlatformContextProvidersTests testSpecificationUsagePatterns]' passed (0.000 seconds).
Test Suite 'PlatformContextProvidersTests' passed at 2025-09-18 22:56:16.303.
	 Executed 17 tests, with 0 failures (0 unexpected) in 0.014 (0.015) seconds
Test Suite 'PlatformProvidersConcurrencyTests' started at 2025-09-18 22:56:16.303.
Test Case '-[SpecificationKitTests.PlatformProvidersConcurrencyTests testConcurrentProviderFactoryAccess]' started.
Test Case '-[SpecificationKitTests.PlatformProvidersConcurrencyTests testConcurrentProviderFactoryAccess]' passed (0.067 seconds).
Test Case '-[SpecificationKitTests.PlatformProvidersConcurrencyTests testDeviceContextProviderConcurrency]' started.
Test Case '-[SpecificationKitTests.PlatformProvidersConcurrencyTests testDeviceContextProviderConcurrency]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.PlatformProvidersConcurrencyTests testLocationContextProviderConcurrency]' started.
Test Case '-[SpecificationKitTests.PlatformProvidersConcurrencyTests testLocationContextProviderConcurrency]' passed (0.012 seconds).
Test Case '-[SpecificationKitTests.PlatformProvidersConcurrencyTests testLocationCoordinateThreadSafety]' started.
Test Case '-[SpecificationKitTests.PlatformProvidersConcurrencyTests testLocationCoordinateThreadSafety]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.PlatformProvidersConcurrencyTests testPlatformSpecificationsConcurrency]' started.
Test Case '-[SpecificationKitTests.PlatformProvidersConcurrencyTests testPlatformSpecificationsConcurrency]' passed (0.118 seconds).
Test Suite 'PlatformProvidersConcurrencyTests' passed at 2025-09-18 22:56:16.500.
	 Executed 5 tests, with 0 failures (0 unexpected) in 0.197 (0.198) seconds
Test Suite 'PlatformProvidersPerformanceTests' started at 2025-09-18 22:56:16.500.
Test Case '-[SpecificationKitTests.PlatformProvidersPerformanceTests testDeviceContextProviderPerformance]' started.
Test Case '-[SpecificationKitTests.PlatformProvidersPerformanceTests testDeviceContextProviderPerformance]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.PlatformProvidersPerformanceTests testLocationContextProviderPerformance]' started.
/Users/egor/Development/GitHub/SpecificationKit/Tests/SpecificationKitTests/PlatformProvidersPerformanceTests.swift:54: Test Case '-[SpecificationKitTests.PlatformProvidersPerformanceTests testLocationContextProviderPerformance]' measured [Time, seconds] average: 0.000, relative standard deviation: 19.579%, values: [0.000159, 0.000128, 0.000121, 0.000213, 0.000216, 0.000215, 0.000216, 0.000217, 0.000215, 0.000215], performanceMetricID:com.apple.XCTPerformanceMetric_WallClockTime, baselineName: "", baselineAverage: , polarity: prefers smaller, maxPercentRegression: 10.000%, maxPercentRelativeStandardDeviation: 10.000%, maxRegression: 0.100, maxStandardDeviation: 0.100
Test Case '-[SpecificationKitTests.PlatformProvidersPerformanceTests testLocationContextProviderPerformance]' passed (0.254 seconds).
Test Case '-[SpecificationKitTests.PlatformProvidersPerformanceTests testPlatformSpecificationPerformance]' started.
2025-09-18 22:56:25.182 xctest[11320:88929] WARNING Supported CoreLocation API call rate exceeded, behavior undefined.
/Users/egor/Development/GitHub/SpecificationKit/Tests/SpecificationKitTests/PlatformProvidersPerformanceTests.swift:72: Test Case '-[SpecificationKitTests.PlatformProvidersPerformanceTests testPlatformSpecificationPerformance]' measured [Time, seconds] average: 1.419, relative standard deviation: 1.330%, values: [1.399066, 1.415850, 1.417765, 1.388876, 1.400795, 1.411121, 1.433019, 1.444408, 1.431266, 1.448282], performanceMetricID:com.apple.XCTPerformanceMetric_WallClockTime, baselineName: "", baselineAverage: , polarity: prefers smaller, maxPercentRegression: 10.000%, maxPercentRelativeStandardDeviation: 10.000%, maxRegression: 0.100, maxStandardDeviation: 0.100
Test Case '-[SpecificationKitTests.PlatformProvidersPerformanceTests testPlatformSpecificationPerformance]' passed (14.441 seconds).
Test Case '-[SpecificationKitTests.PlatformProvidersPerformanceTests testSingleSpecificationEvaluationTime]' started.
Test Case '-[SpecificationKitTests.PlatformProvidersPerformanceTests testSingleSpecificationEvaluationTime]' passed (0.000 seconds).
Test Suite 'PlatformProvidersPerformanceTests' passed at 2025-09-18 22:56:31.196.
	 Executed 4 tests, with 0 failures (0 unexpected) in 14.696 (14.696) seconds
Test Suite 'SatisfiesMacroTests' started at 2025-09-18 22:56:31.196.
Test Case '-[SpecificationKitTests.SatisfiesMacroTests testMacroEnhancementBenefits]' started.
Test Case '-[SpecificationKitTests.SatisfiesMacroTests testMacroEnhancementBenefits]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SatisfiesMacroTests testMacroImplementationExists]' started.
Test Case '-[SpecificationKitTests.SatisfiesMacroTests testMacroImplementationExists]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SatisfiesMacroTests testMacroUsageDocumentation]' started.
Test Case '-[SpecificationKitTests.SatisfiesMacroTests testMacroUsageDocumentation]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SatisfiesMacroTests testParameterMetadataForKnownSpecs]' started.
Test Case '-[SpecificationKitTests.SatisfiesMacroTests testParameterMetadataForKnownSpecs]' passed (0.001 seconds).
Test Case '-[SpecificationKitTests.SatisfiesMacroTests testParameterParserLogic]' started.
Test Case '-[SpecificationKitTests.SatisfiesMacroTests testParameterParserLogic]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SatisfiesMacroTests testSatisfiesPropertyWrapperStillWorks]' started.
Test Case '-[SpecificationKitTests.SatisfiesMacroTests testSatisfiesPropertyWrapperStillWorks]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SatisfiesMacroTests testSpecificationTypesAreCorrect]' started.
Test Case '-[SpecificationKitTests.SatisfiesMacroTests testSpecificationTypesAreCorrect]' passed (0.000 seconds).
Test Suite 'SatisfiesMacroTests' passed at 2025-09-18 22:56:31.197.
	 Executed 7 tests, with 0 failures (0 unexpected) in 0.001 (0.001) seconds
Test Suite 'SpecificationKitTests' started at 2025-09-18 22:56:31.197.
Test Case '-[SpecificationKitTests.SpecificationKitTests testAdvancedCompositeSpec_BasicComposition]' started.
Test Case '-[SpecificationKitTests.SpecificationKitTests testAdvancedCompositeSpec_BasicComposition]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SpecificationKitTests testAdvancedCompositeSpec_WithBusinessHours]' started.
Test Case '-[SpecificationKitTests.SpecificationKitTests testAdvancedCompositeSpec_WithBusinessHours]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SpecificationKitTests testAdvancedCompositeSpec_WithBusinessHours_FailsOutsideHours]' started.
Test Case '-[SpecificationKitTests.SpecificationKitTests testAdvancedCompositeSpec_WithBusinessHours_FailsOutsideHours]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SpecificationKitTests testAdvancedCompositeSpec_WithMinimumEngagement]' started.
Test Case '-[SpecificationKitTests.SpecificationKitTests testAdvancedCompositeSpec_WithMinimumEngagement]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SpecificationKitTests testAdvancedCompositeSpec_WithMinimumEngagement_FailsLowEngagement]' started.
Test Case '-[SpecificationKitTests.SpecificationKitTests testAdvancedCompositeSpec_WithMinimumEngagement_FailsLowEngagement]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SpecificationKitTests testAdvancedCompositeSpec_WithWeekdays]' started.
Test Case '-[SpecificationKitTests.SpecificationKitTests testAdvancedCompositeSpec_WithWeekdays]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SpecificationKitTests testAnySpecification_Always]' started.
Test Case '-[SpecificationKitTests.SpecificationKitTests testAnySpecification_Always]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SpecificationKitTests testAnySpecification_Never]' started.
Test Case '-[SpecificationKitTests.SpecificationKitTests testAnySpecification_Never]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SpecificationKitTests testAnySpecification_TypeErasure]' started.
Test Case '-[SpecificationKitTests.SpecificationKitTests testAnySpecification_TypeErasure]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SpecificationKitTests testCompositeSpec_CustomConfiguration]' started.
Test Case '-[SpecificationKitTests.SpecificationKitTests testCompositeSpec_CustomConfiguration]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SpecificationKitTests testCompositeSpec_CustomConfiguration_FailsInsufficientTime]' started.
Test Case '-[SpecificationKitTests.SpecificationKitTests testCompositeSpec_CustomConfiguration_FailsInsufficientTime]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SpecificationKitTests testCompositeSpec_DefaultConfiguration]' started.
Test Case '-[SpecificationKitTests.SpecificationKitTests testCompositeSpec_DefaultConfiguration]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SpecificationKitTests testCompositeSpec_FailsWhenCountExceedsLimit]' started.
Test Case '-[SpecificationKitTests.SpecificationKitTests testCompositeSpec_FailsWhenCountExceedsLimit]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SpecificationKitTests testCompositeSpec_FeatureAnnouncement]' started.
Test Case '-[SpecificationKitTests.SpecificationKitTests testCompositeSpec_FeatureAnnouncement]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SpecificationKitTests testCompositeSpec_FeatureAnnouncement_FailsMaxCount]' started.
Test Case '-[SpecificationKitTests.SpecificationKitTests testCompositeSpec_FeatureAnnouncement_FailsMaxCount]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SpecificationKitTests testCompositeSpec_OnboardingTip]' started.
Test Case '-[SpecificationKitTests.SpecificationKitTests testCompositeSpec_OnboardingTip]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SpecificationKitTests testCompositeSpec_OnboardingTip_FailsCooldown]' started.
Test Case '-[SpecificationKitTests.SpecificationKitTests testCompositeSpec_OnboardingTip_FailsCooldown]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SpecificationKitTests testCompositeSpec_PromoBanner]' started.
Test Case '-[SpecificationKitTests.SpecificationKitTests testCompositeSpec_PromoBanner]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SpecificationKitTests testCompositeSpec_PromoBanner_FailsMaxCount]' started.
Test Case '-[SpecificationKitTests.SpecificationKitTests testCompositeSpec_PromoBanner_FailsMaxCount]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SpecificationKitTests testCompositeSpec_RatingPrompt]' started.
Test Case '-[SpecificationKitTests.SpecificationKitTests testCompositeSpec_RatingPrompt]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SpecificationKitTests testCompositeSpec_RatingPrompt_FailsInsufficientTime]' started.
Test Case '-[SpecificationKitTests.SpecificationKitTests testCompositeSpec_RatingPrompt_FailsInsufficientTime]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SpecificationKitTests testCooldownIntervalSpec_WhenCooldownActive_ReturnFalse]' started.
Test Case '-[SpecificationKitTests.SpecificationKitTests testCooldownIntervalSpec_WhenCooldownActive_ReturnFalse]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SpecificationKitTests testCooldownIntervalSpec_WhenCooldownComplete_ReturnTrue]' started.
Test Case '-[SpecificationKitTests.SpecificationKitTests testCooldownIntervalSpec_WhenCooldownComplete_ReturnTrue]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SpecificationKitTests testCooldownIntervalSpec_WhenNoPreviousEvent_ReturnTrue]' started.
Test Case '-[SpecificationKitTests.SpecificationKitTests testCooldownIntervalSpec_WhenNoPreviousEvent_ReturnTrue]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SpecificationKitTests testDefaultContextProvider_CounterManagement]' started.
Test Case '-[SpecificationKitTests.SpecificationKitTests testDefaultContextProvider_CounterManagement]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SpecificationKitTests testDefaultContextProvider_EventManagement]' started.
Test Case '-[SpecificationKitTests.SpecificationKitTests testDefaultContextProvider_EventManagement]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SpecificationKitTests testDefaultContextProvider_FlagManagement]' started.
Test Case '-[SpecificationKitTests.SpecificationKitTests testDefaultContextProvider_FlagManagement]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SpecificationKitTests testECommercePromoBannerSpec_AllConditionsMet]' started.
Test Case '-[SpecificationKitTests.SpecificationKitTests testECommercePromoBannerSpec_AllConditionsMet]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SpecificationKitTests testECommercePromoBannerSpec_FailsInsufficientActivity]' started.
Test Case '-[SpecificationKitTests.SpecificationKitTests testECommercePromoBannerSpec_FailsInsufficientActivity]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SpecificationKitTests testECommercePromoBannerSpec_FailsInsufficientProductViews]' started.
Test Case '-[SpecificationKitTests.SpecificationKitTests testECommercePromoBannerSpec_FailsInsufficientProductViews]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SpecificationKitTests testECommercePromoBannerSpec_FailsOutsideShoppingHours]' started.
Test Case '-[SpecificationKitTests.SpecificationKitTests testECommercePromoBannerSpec_FailsOutsideShoppingHours]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SpecificationKitTests testEvaluationContext_CounterAccess]' started.
Test Case '-[SpecificationKitTests.SpecificationKitTests testEvaluationContext_CounterAccess]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SpecificationKitTests testEvaluationContext_EventAccess]' started.
Test Case '-[SpecificationKitTests.SpecificationKitTests testEvaluationContext_EventAccess]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SpecificationKitTests testEvaluationContext_FlagAccess]' started.
Test Case '-[SpecificationKitTests.SpecificationKitTests testEvaluationContext_FlagAccess]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SpecificationKitTests testEvaluationContext_TimeSinceLaunch]' started.
Test Case '-[SpecificationKitTests.SpecificationKitTests testEvaluationContext_TimeSinceLaunch]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SpecificationKitTests testMaxCountSpec_WhenCountAboveLimit_ReturnFalse]' started.
Test Case '-[SpecificationKitTests.SpecificationKitTests testMaxCountSpec_WhenCountAboveLimit_ReturnFalse]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SpecificationKitTests testMaxCountSpec_WhenCountAtLimit_ReturnFalse]' started.
Test Case '-[SpecificationKitTests.SpecificationKitTests testMaxCountSpec_WhenCountAtLimit_ReturnFalse]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SpecificationKitTests testMaxCountSpec_WhenCountBelowLimit_ReturnTrue]' started.
Test Case '-[SpecificationKitTests.SpecificationKitTests testMaxCountSpec_WhenCountBelowLimit_ReturnTrue]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SpecificationKitTests testMaxCountSpec_WhenCounterNotExists_ReturnTrue]' started.
Test Case '-[SpecificationKitTests.SpecificationKitTests testMaxCountSpec_WhenCounterNotExists_ReturnTrue]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SpecificationKitTests testMockContextProvider_BasicUsage]' started.
Test Case '-[SpecificationKitTests.SpecificationKitTests testMockContextProvider_BasicUsage]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SpecificationKitTests testMockContextProvider_RequestTracking]' started.
Test Case '-[SpecificationKitTests.SpecificationKitTests testMockContextProvider_RequestTracking]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SpecificationKitTests testPredicateSpec_AlwaysFalse]' started.
Test Case '-[SpecificationKitTests.SpecificationKitTests testPredicateSpec_AlwaysFalse]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SpecificationKitTests testPredicateSpec_AlwaysTrue]' started.
Test Case '-[SpecificationKitTests.SpecificationKitTests testPredicateSpec_AlwaysTrue]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SpecificationKitTests testPredicateSpec_WithCustomPredicate]' started.
Test Case '-[SpecificationKitTests.SpecificationKitTests testPredicateSpec_WithCustomPredicate]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SpecificationKitTests testSpecificationOperators_And]' started.
Test Case '-[SpecificationKitTests.SpecificationKitTests testSpecificationOperators_And]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SpecificationKitTests testSpecificationOperators_Not]' started.
Test Case '-[SpecificationKitTests.SpecificationKitTests testSpecificationOperators_Not]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SpecificationKitTests testSpecificationOperators_Or]' started.
Test Case '-[SpecificationKitTests.SpecificationKitTests testSpecificationOperators_Or]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SpecificationKitTests testSubscriptionUpgradeSpec_AllConditionsMet]' started.
Test Case '-[SpecificationKitTests.SpecificationKitTests testSubscriptionUpgradeSpec_AllConditionsMet]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SpecificationKitTests testSubscriptionUpgradeSpec_FailsInsufficientAppOpens]' started.
Test Case '-[SpecificationKitTests.SpecificationKitTests testSubscriptionUpgradeSpec_FailsInsufficientAppOpens]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SpecificationKitTests testSubscriptionUpgradeSpec_FailsInsufficientPremiumUsage]' started.
Test Case '-[SpecificationKitTests.SpecificationKitTests testSubscriptionUpgradeSpec_FailsInsufficientPremiumUsage]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SpecificationKitTests testSubscriptionUpgradeSpec_FailsPremiumSubscriber]' started.
Test Case '-[SpecificationKitTests.SpecificationKitTests testSubscriptionUpgradeSpec_FailsPremiumSubscriber]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SpecificationKitTests testTimeSinceEventSpec_ConvenienceInitializers]' started.
Test Case '-[SpecificationKitTests.SpecificationKitTests testTimeSinceEventSpec_ConvenienceInitializers]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SpecificationKitTests testTimeSinceEventSpec_WhenEnoughTimePassed_ReturnTrue]' started.
Test Case '-[SpecificationKitTests.SpecificationKitTests testTimeSinceEventSpec_WhenEnoughTimePassed_ReturnTrue]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SpecificationKitTests testTimeSinceEventSpec_WhenEventNeverOccurred_ReturnTrue]' started.
Test Case '-[SpecificationKitTests.SpecificationKitTests testTimeSinceEventSpec_WhenEventNeverOccurred_ReturnTrue]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SpecificationKitTests testTimeSinceEventSpec_WhenNotEnoughTimePassed_ReturnFalse]' started.
Test Case '-[SpecificationKitTests.SpecificationKitTests testTimeSinceEventSpec_WhenNotEnoughTimePassed_ReturnFalse]' passed (0.000 seconds).
Test Suite 'SpecificationKitTests' passed at 2025-09-18 22:56:31.202.
	 Executed 55 tests, with 0 failures (0 unexpected) in 0.003 (0.004) seconds
Test Suite 'SpecificationTracerTests' started at 2025-09-18 22:56:31.202.
Test Case '-[SpecificationKitTests.SpecificationTracerTests testAnalysisReport]' started.
Test Case '-[SpecificationKitTests.SpecificationTracerTests testAnalysisReport]' passed (0.001 seconds).
Test Case '-[SpecificationKitTests.SpecificationTracerTests testAnySpecificationTracing]' started.
Test Case '-[SpecificationKitTests.SpecificationTracerTests testAnySpecificationTracing]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SpecificationTracerTests testBasicSpecificationTracing]' started.
Test Case '-[SpecificationKitTests.SpecificationTracerTests testBasicSpecificationTracing]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SpecificationTracerTests testCompositeSpecificationANDShortCircuit]' started.
Test Case '-[SpecificationKitTests.SpecificationTracerTests testCompositeSpecificationANDShortCircuit]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SpecificationTracerTests testCompositeSpecificationANDTracing]' started.
Test Case '-[SpecificationKitTests.SpecificationTracerTests testCompositeSpecificationANDTracing]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SpecificationTracerTests testCompositeSpecificationORShortCircuit]' started.
Test Case '-[SpecificationKitTests.SpecificationTracerTests testCompositeSpecificationORShortCircuit]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SpecificationTracerTests testCompositeSpecificationORTracing]' started.
Test Case '-[SpecificationKitTests.SpecificationTracerTests testCompositeSpecificationORTracing]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SpecificationTracerTests testConcurrentTracing]' started.
Test Case '-[SpecificationKitTests.SpecificationTracerTests testConcurrentTracing]' passed (0.802 seconds).
Test Case '-[SpecificationKitTests.SpecificationTracerTests testCooldownIntervalSpecTracing]' started.
Test Case '-[SpecificationKitTests.SpecificationTracerTests testCooldownIntervalSpecTracing]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SpecificationTracerTests testDotGraphGeneration]' started.
Test Case '-[SpecificationKitTests.SpecificationTracerTests testDotGraphGeneration]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SpecificationTracerTests testEmptyTraceSession]' started.
Test Case '-[SpecificationKitTests.SpecificationTracerTests testEmptyTraceSession]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SpecificationTracerTests testExecutionTimingAccuracy]' started.
Test Case '-[SpecificationKitTests.SpecificationTracerTests testExecutionTimingAccuracy]' passed (0.001 seconds).
Test Case '-[SpecificationKitTests.SpecificationTracerTests testInvalidParentIdHandling]' started.
Test Case '-[SpecificationKitTests.SpecificationTracerTests testInvalidParentIdHandling]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SpecificationTracerTests testJSONExport]' started.
Test Case '-[SpecificationKitTests.SpecificationTracerTests testJSONExport]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SpecificationTracerTests testMaxCountSpecTracing]' started.
Test Case '-[SpecificationKitTests.SpecificationTracerTests testMaxCountSpecTracing]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SpecificationTracerTests testMultipleSpecificationTracing]' started.
Test Case '-[SpecificationKitTests.SpecificationTracerTests testMultipleSpecificationTracing]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SpecificationTracerTests testMultipleStartsOverwriteSession]' started.
Test Case '-[SpecificationKitTests.SpecificationTracerTests testMultipleStartsOverwriteSession]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SpecificationTracerTests testNestedSpecificationTracing]' started.
Test Case '-[SpecificationKitTests.SpecificationTracerTests testNestedSpecificationTracing]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SpecificationTracerTests testPrintTreeOutput]' started.
Test Case '-[SpecificationKitTests.SpecificationTracerTests testPrintTreeOutput]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SpecificationTracerTests testSessionLifecycle]' started.
Test Case '-[SpecificationKitTests.SpecificationTracerTests testSessionLifecycle]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SpecificationTracerTests testSessionTotalExecutionTime]' started.
Test Case '-[SpecificationKitTests.SpecificationTracerTests testSessionTotalExecutionTime]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SpecificationTracerTests testStopTracingWhenNotActive]' started.
Test Case '-[SpecificationKitTests.SpecificationTracerTests testStopTracingWhenNotActive]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SpecificationTracerTests testTraceEntryIDUniqueness]' started.
Test Case '-[SpecificationKitTests.SpecificationTracerTests testTraceEntryIDUniqueness]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SpecificationTracerTests testTracerSingletonAccess]' started.
Test Case '-[SpecificationKitTests.SpecificationTracerTests testTracerSingletonAccess]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SpecificationTracerTests testTraceTreeBuilding]' started.
Test Case '-[SpecificationKitTests.SpecificationTracerTests testTraceTreeBuilding]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SpecificationTracerTests testTraceTreeWithMultipleRoots]' started.
Test Case '-[SpecificationKitTests.SpecificationTracerTests testTraceTreeWithMultipleRoots]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SpecificationTracerTests testTracingWithMetadata]' started.
Test Case '-[SpecificationKitTests.SpecificationTracerTests testTracingWithMetadata]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SpecificationTracerTests testTracingWithoutActiveSession]' started.
Test Case '-[SpecificationKitTests.SpecificationTracerTests testTracingWithoutActiveSession]' passed (0.000 seconds).
Test Suite 'SpecificationTracerTests' passed at 2025-09-18 22:56:32.010.
	 Executed 28 tests, with 0 failures (0 unexpected) in 0.807 (0.808) seconds
Test Suite 'SpecsMacroDiagnosticsTests' started at 2025-09-18 22:56:32.010.
Test Case '-[SpecificationKitTests.SpecsMacroDiagnosticsTests test_specs_argumentLiteral_emitsError]' started.
Test Case '-[SpecificationKitTests.SpecsMacroDiagnosticsTests test_specs_argumentLiteral_emitsError]' passed (0.012 seconds).
Test Case '-[SpecificationKitTests.SpecsMacroDiagnosticsTests test_specs_asyncArgument_emitsError]' started.
Test Case '-[SpecificationKitTests.SpecsMacroDiagnosticsTests test_specs_asyncArgument_emitsError]' passed (0.007 seconds).
Test Case '-[SpecificationKitTests.SpecsMacroDiagnosticsTests test_specs_emptyArgs_emitsErrorDiagnostic]' started.
Test Case '-[SpecificationKitTests.SpecsMacroDiagnosticsTests test_specs_emptyArgs_emitsErrorDiagnostic]' passed (0.001 seconds).
Test Case '-[SpecificationKitTests.SpecsMacroDiagnosticsTests test_specs_mixedContexts_errorsWhenConfident]' started.
Test Case '-[SpecificationKitTests.SpecsMacroDiagnosticsTests test_specs_mixedContexts_errorsWhenConfident]' passed (0.009 seconds).
Test Case '-[SpecificationKitTests.SpecsMacroDiagnosticsTests test_specs_mixedContexts_warnsWhenNotConfident]' started.
Test Case '-[SpecificationKitTests.SpecsMacroDiagnosticsTests test_specs_mixedContexts_warnsWhenNotConfident]' passed (0.009 seconds).
Test Case '-[SpecificationKitTests.SpecsMacroDiagnosticsTests test_specs_mustBeAppliedToSpecificationType]' started.
Test Case '-[SpecificationKitTests.SpecsMacroDiagnosticsTests test_specs_mustBeAppliedToSpecificationType]' passed (0.001 seconds).
Test Case '-[SpecificationKitTests.SpecsMacroDiagnosticsTests test_specs_warnsWhenMissingTypealiasT]' started.
Test Case '-[SpecificationKitTests.SpecsMacroDiagnosticsTests test_specs_warnsWhenMissingTypealiasT]' passed (0.006 seconds).
Test Suite 'SpecsMacroDiagnosticsTests' passed at 2025-09-18 22:56:32.056.
	 Executed 7 tests, with 0 failures (0 unexpected) in 0.045 (0.045) seconds
Test Suite 'SpecsMacroIntegrationTests' started at 2025-09-18 22:56:32.056.
Test Case '-[SpecificationKitTests.SpecsMacroIntegrationTests test_specsMacro_asyncMethod]' started.
Test Case '-[SpecificationKitTests.SpecsMacroIntegrationTests test_specsMacro_asyncMethod]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SpecsMacroIntegrationTests test_specsMacro_autoContext_asyncComputed]' started.
Test Case '-[SpecificationKitTests.SpecsMacroIntegrationTests test_specsMacro_autoContext_asyncComputed]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SpecsMacroIntegrationTests test_specsMacro_generatesAndChainsTwoSpecifications]' started.
Test Case '-[SpecificationKitTests.SpecsMacroIntegrationTests test_specsMacro_generatesAndChainsTwoSpecifications]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SpecsMacroIntegrationTests test_specsMacro_singleSpecification]' started.
Test Case '-[SpecificationKitTests.SpecsMacroIntegrationTests test_specsMacro_singleSpecification]' passed (0.000 seconds).
Test Suite 'SpecsMacroIntegrationTests' passed at 2025-09-18 22:56:32.056.
	 Executed 4 tests, with 0 failures (0 unexpected) in 0.000 (0.001) seconds
Test Suite 'SpecsMacroTests' started at 2025-09-18 22:56:32.056.
Test Case '-[SpecificationKitTests.SpecsMacroTests testSpecsMacroFunctionality_EmptyChain]' started.
Test Case '-[SpecificationKitTests.SpecsMacroTests testSpecsMacroFunctionality_EmptyChain]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SpecsMacroTests testSpecsMacroFunctionality_SingleSpecification]' started.
Test Case '-[SpecificationKitTests.SpecsMacroTests testSpecsMacroFunctionality_SingleSpecification]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SpecsMacroTests testSpecsMacroFunctionality_ThreeSpecifications]' started.
Test Case '-[SpecificationKitTests.SpecsMacroTests testSpecsMacroFunctionality_ThreeSpecifications]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SpecsMacroTests testSpecsMacroFunctionality_TwoSpecifications]' started.
Test Case '-[SpecificationKitTests.SpecsMacroTests testSpecsMacroFunctionality_TwoSpecifications]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SpecsMacroTests testSpecsMacroFunctionality_TypeSafety]' started.
Test Case '-[SpecificationKitTests.SpecsMacroTests testSpecsMacroFunctionality_TypeSafety]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SpecsMacroTests testSpecsMacroFunctionality_WithConvenienceMethods]' started.
Test Case '-[SpecificationKitTests.SpecsMacroTests testSpecsMacroFunctionality_WithConvenienceMethods]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.SpecsMacroTests testSpecsMacroFunctionality_WithPredicateSpec]' started.
Test Case '-[SpecificationKitTests.SpecsMacroTests testSpecsMacroFunctionality_WithPredicateSpec]' passed (0.000 seconds).
Test Suite 'SpecsMacroTests' passed at 2025-09-18 22:56:32.057.
	 Executed 7 tests, with 0 failures (0 unexpected) in 0.000 (0.001) seconds
Test Suite 'SubscriptionStatusSpecTests' started at 2025-09-18 22:56:32.057.
Test Case '-[SpecificationKitTests.SubscriptionStatusSpecTests test_SubscriptionStatusSpec_matchesExpectedStatus]' started.
Test Case '-[SpecificationKitTests.SubscriptionStatusSpecTests test_SubscriptionStatusSpec_matchesExpectedStatus]' passed (0.000 seconds).
Test Suite 'SubscriptionStatusSpecTests' passed at 2025-09-18 22:56:32.057.
	 Executed 1 test, with 0 failures (0 unexpected) in 0.000 (0.000) seconds
Test Suite 'ThresholdSpecTests' started at 2025-09-18 22:56:32.057.
Test Case '-[SpecificationKitTests.ThresholdSpecTests testThresholdSpec_adaptive_convenience]' started.
Test Case '-[SpecificationKitTests.ThresholdSpecTests testThresholdSpec_adaptive_convenience]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.ThresholdSpecTests testThresholdSpec_adaptiveThreshold_calculatesCorrectly]' started.
Test Case '-[SpecificationKitTests.ThresholdSpecTests testThresholdSpec_adaptiveThreshold_calculatesCorrectly]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.ThresholdSpecTests testThresholdSpec_below_convenience]' started.
Test Case '-[SpecificationKitTests.ThresholdSpecTests testThresholdSpec_below_convenience]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.ThresholdSpecTests testThresholdSpec_contextualThreshold_extractsFromContext]' started.
Test Case '-[SpecificationKitTests.ThresholdSpecTests testThresholdSpec_contextualThreshold_extractsFromContext]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.ThresholdSpecTests testThresholdSpec_customThreshold_calculatesCorrectly]' started.
Test Case '-[SpecificationKitTests.ThresholdSpecTests testThresholdSpec_customThreshold_calculatesCorrectly]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.ThresholdSpecTests testThresholdSpec_equal_operator_withTolerance]' started.
Test Case '-[SpecificationKitTests.ThresholdSpecTests testThresholdSpec_equal_operator_withTolerance]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.ThresholdSpecTests testThresholdSpec_exceeds_convenience]' started.
Test Case '-[SpecificationKitTests.ThresholdSpecTests testThresholdSpec_exceeds_convenience]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.ThresholdSpecTests testThresholdSpec_fixedThreshold_greaterThanOrEqual_returnsFalse]' started.
Test Case '-[SpecificationKitTests.ThresholdSpecTests testThresholdSpec_fixedThreshold_greaterThanOrEqual_returnsFalse]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.ThresholdSpecTests testThresholdSpec_fixedThreshold_greaterThanOrEqual_returnsTrue]' started.
Test Case '-[SpecificationKitTests.ThresholdSpecTests testThresholdSpec_fixedThreshold_greaterThanOrEqual_returnsTrue]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.ThresholdSpecTests testThresholdSpec_fixedThreshold_lessThan_returnsTrue]' started.
Test Case '-[SpecificationKitTests.ThresholdSpecTests testThresholdSpec_fixedThreshold_lessThan_returnsTrue]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.ThresholdSpecTests testThresholdSpec_greaterThan_operator]' started.
Test Case '-[SpecificationKitTests.ThresholdSpecTests testThresholdSpec_greaterThan_operator]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.ThresholdSpecTests testThresholdSpec_initWithClosure_succeeds]' started.
Test Case '-[SpecificationKitTests.ThresholdSpecTests testThresholdSpec_initWithClosure_succeeds]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.ThresholdSpecTests testThresholdSpec_initWithKeyPath_succeeds]' started.
Test Case '-[SpecificationKitTests.ThresholdSpecTests testThresholdSpec_initWithKeyPath_succeeds]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.ThresholdSpecTests testThresholdSpec_nilValueExtraction_returnsFalse]' started.
Test Case '-[SpecificationKitTests.ThresholdSpecTests testThresholdSpec_nilValueExtraction_returnsFalse]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.ThresholdSpecTests testThresholdSpec_notEqual_operator]' started.
Test Case '-[SpecificationKitTests.ThresholdSpecTests testThresholdSpec_notEqual_operator]' passed (0.000 seconds).
Test Suite 'ThresholdSpecTests' passed at 2025-09-18 22:56:32.058.
	 Executed 15 tests, with 0 failures (0 unexpected) in 0.001 (0.001) seconds
Test Suite 'UserSegmentSpecTests' started at 2025-09-18 22:56:32.058.
Test Case '-[SpecificationKitTests.UserSegmentSpecTests test_UserSegmentSpec_checksMembership]' started.
Test Case '-[SpecificationKitTests.UserSegmentSpecTests test_UserSegmentSpec_checksMembership]' passed (0.000 seconds).
Test Suite 'UserSegmentSpecTests' passed at 2025-09-18 22:56:32.058.
	 Executed 1 test, with 0 failures (0 unexpected) in 0.000 (0.000) seconds
Test Suite 'WatchOSContextProvidersTests' started at 2025-09-18 22:56:32.058.
Test Case '-[SpecificationKitTests.WatchOSContextProvidersTests testHealthContextProviderCacheManagement]' started.
Test Case '-[SpecificationKitTests.WatchOSContextProvidersTests testHealthContextProviderCacheManagement]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.WatchOSContextProvidersTests testHealthContextProviderConfigurations]' started.
Test Case '-[SpecificationKitTests.WatchOSContextProvidersTests testHealthContextProviderConfigurations]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.WatchOSContextProvidersTests testHealthContextProviderContextGeneration]' started.
Test Case '-[SpecificationKitTests.WatchOSContextProvidersTests testHealthContextProviderContextGeneration]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.WatchOSContextProvidersTests testHealthContextProviderFallbackValues]' started.
Test Case '-[SpecificationKitTests.WatchOSContextProvidersTests testHealthContextProviderFallbackValues]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.WatchOSContextProvidersTests testHealthContextProviderInitialization]' started.
Test Case '-[SpecificationKitTests.WatchOSContextProvidersTests testHealthContextProviderInitialization]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.WatchOSContextProvidersTests testWatchContextProviderBasicValues]' started.
Test Case '-[SpecificationKitTests.WatchOSContextProvidersTests testWatchContextProviderBasicValues]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.WatchOSContextProvidersTests testWatchContextProviderContextGeneration]' started.
Test Case '-[SpecificationKitTests.WatchOSContextProvidersTests testWatchContextProviderContextGeneration]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.WatchOSContextProvidersTests testWatchContextProviderCrownOrientationSpec]' started.
Test Case '-[SpecificationKitTests.WatchOSContextProvidersTests testWatchContextProviderCrownOrientationSpec]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.WatchOSContextProvidersTests testWatchContextProviderInitialization]' started.
Test Case '-[SpecificationKitTests.WatchOSContextProvidersTests testWatchContextProviderInitialization]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.WatchOSContextProvidersTests testWatchContextProviderScreenSizeSpec]' started.
Test Case '-[SpecificationKitTests.WatchOSContextProvidersTests testWatchContextProviderScreenSizeSpec]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.WatchOSContextProvidersTests testWatchContextProviderWaterLockSpec]' started.
Test Case '-[SpecificationKitTests.WatchOSContextProvidersTests testWatchContextProviderWaterLockSpec]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.WatchOSContextProvidersTests testWatchContextProviderWristLocationSpec]' started.
Test Case '-[SpecificationKitTests.WatchOSContextProvidersTests testWatchContextProviderWristLocationSpec]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.WatchOSContextProvidersTests testWatchOSProvidersPerformance]' started.
/Users/egor/Development/GitHub/SpecificationKit/Tests/SpecificationKitTests/WatchOSContextProvidersTests.swift:384: Test Case '-[SpecificationKitTests.WatchOSContextProvidersTests testWatchOSProvidersPerformance]' measured [Time, seconds] average: 0.000, relative standard deviation: 43.690%, values: [0.000058, 0.000022, 0.000022, 0.000022, 0.000022, 0.000021, 0.000021, 0.000021, 0.000021, 0.000021], performanceMetricID:com.apple.XCTPerformanceMetric_WallClockTime, baselineName: "", baselineAverage: , polarity: prefers smaller, maxPercentRegression: 10.000%, maxPercentRelativeStandardDeviation: 10.000%, maxRegression: 0.100, maxStandardDeviation: 0.100
Test Case '-[SpecificationKitTests.WatchOSContextProvidersTests testWatchOSProvidersPerformance]' passed (0.257 seconds).
Test Case '-[SpecificationKitTests.WatchOSContextProvidersTests testWatchOSProviderStubsOnOtherPlatforms]' started.
Test Case '-[SpecificationKitTests.WatchOSContextProvidersTests testWatchOSProviderStubsOnOtherPlatforms]' passed (0.103 seconds).
Test Case '-[SpecificationKitTests.WatchOSContextProvidersTests testWatchOSProvidersWithPropertyWrappers]' started.
Test Case '-[SpecificationKitTests.WatchOSContextProvidersTests testWatchOSProvidersWithPropertyWrappers]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.WatchOSContextProvidersTests testWatchScreenSizeEnum]' started.
Test Case '-[SpecificationKitTests.WatchOSContextProvidersTests testWatchScreenSizeEnum]' passed (0.000 seconds).
Test Suite 'WatchOSContextProvidersTests' passed at 2025-09-18 22:56:32.421.
	 Executed 16 tests, with 0 failures (0 unexpected) in 0.362 (0.362) seconds
Test Suite 'WeightedSpecTests' started at 2025-09-18 22:56:32.421.
Test Case '-[SpecificationKitTests.WeightedSpecTests testWeightedSpec_builder_createsCorrectSpec]' started.
Test Case '-[SpecificationKitTests.WeightedSpecTests testWeightedSpec_builder_createsCorrectSpec]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.WeightedSpecTests testWeightedSpec_builderWithInvalidWeight_throws]' started.
Test Case '-[SpecificationKitTests.WeightedSpecTests testWeightedSpec_builderWithInvalidWeight_throws]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.WeightedSpecTests testWeightedSpec_decide_withNoSatisfiedSpecs_returnsNil]' started.
Test Case '-[SpecificationKitTests.WeightedSpecTests testWeightedSpec_decide_withNoSatisfiedSpecs_returnsNil]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.WeightedSpecTests testWeightedSpec_decide_withSingleSatisfiedSpec_returnsResult]' started.
Test Case '-[SpecificationKitTests.WeightedSpecTests testWeightedSpec_decide_withSingleSatisfiedSpec_returnsResult]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.WeightedSpecTests testWeightedSpec_expectedValue_calculatesCorrectly]' started.
Test Case '-[SpecificationKitTests.WeightedSpecTests testWeightedSpec_expectedValue_calculatesCorrectly]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.WeightedSpecTests testWeightedSpec_initWithEmptyCandidates_fails]' started.
Test Case '-[SpecificationKitTests.WeightedSpecTests testWeightedSpec_initWithEmptyCandidates_fails]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.WeightedSpecTests testWeightedSpec_initWithNegativeWeight_fails]' started.
Test Case '-[SpecificationKitTests.WeightedSpecTests testWeightedSpec_initWithNegativeWeight_fails]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.WeightedSpecTests testWeightedSpec_initWithValidCandidates_succeeds]' started.
Test Case '-[SpecificationKitTests.WeightedSpecTests testWeightedSpec_initWithValidCandidates_succeeds]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.WeightedSpecTests testWeightedSpec_initWithZeroWeight_fails]' started.
Test Case '-[SpecificationKitTests.WeightedSpecTests testWeightedSpec_initWithZeroWeight_fails]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.WeightedSpecTests testWeightedSpec_probabilityDistribution_calculatesCorrectly]' started.
Test Case '-[SpecificationKitTests.WeightedSpecTests testWeightedSpec_probabilityDistribution_calculatesCorrectly]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.WeightedSpecTests testWeightedSpec_statisticalDistribution_convergesCorrectly]' started.
Test Case '-[SpecificationKitTests.WeightedSpecTests testWeightedSpec_statisticalDistribution_convergesCorrectly]' passed (0.036 seconds).
Test Case '-[SpecificationKitTests.WeightedSpecTests testWeightedSpec_variance_calculatesCorrectly]' started.
Test Case '-[SpecificationKitTests.WeightedSpecTests testWeightedSpec_variance_calculatesCorrectly]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.WeightedSpecTests testWeightedSpec_withAllZeroWeights_handlesGracefully]' started.
Test Case '-[SpecificationKitTests.WeightedSpecTests testWeightedSpec_withAllZeroWeights_handlesGracefully]' passed (0.000 seconds).
Test Case '-[SpecificationKitTests.WeightedSpecTests testWeightedSpec_withFallback_alwaysReturnsResult]' started.
Test Case '-[SpecificationKitTests.WeightedSpecTests testWeightedSpec_withFallback_alwaysReturnsResult]' passed (0.000 seconds).
Test Suite 'WeightedSpecTests' passed at 2025-09-18 22:56:32.459.
	 Executed 14 tests, with 0 failures (0 unexpected) in 0.038 (0.039) seconds
Test Suite 'SpecificationKitPackageTests.xctest' passed at 2025-09-18 22:56:32.459.
	 Executed 402 tests, with 0 failures (0 unexpected) in 25.254 (25.274) seconds
Test Suite 'All tests' passed at 2025-09-18 22:56:32.459.
	 Executed 402 tests, with 0 failures (0 unexpected) in 25.254 (25.275) seconds
├─ PredicateSpec<Int> → true (0.000ms)
􀟈  Test run started.
􀄵  Testing Library Version: 1085
􀄵  Target Platform: arm64e-apple-macos14.0
􁁛  Test run with 0 tests in 0 suites passed after 0.001 seconds.

```


## Assistant

Great! All tests are passing. Let me check the test count to see our coverage improvement:Perfect! I've successfully added comprehensive tests for the `CompositeSpec.swift` file. Here's a summary of what was accomplished:

## Added Tests for CompositeSpec Coverage

I expanded the test coverage from **only 2 tests** (10% coverage) to **26 tests** covering all functionality:

### Original Coverage (2 tests):
- `CompositeSpec.init()` - Default constructor
- `CompositeSpec.isSatisfiedBy(_:)` - Basic evaluation

### New Comprehensive Coverage (24 additional tests):

#### **CompositeSpec Class (8 tests)**:
- Custom initializer with parameters
- Static predefined specifications: `.promoBanner`, `.onboardingTip`, `.featureAnnouncement`, `.ratingPrompt`
- Edge cases for each predefined spec (failure scenarios)

#### **AdvancedCompositeSpec Class (6 tests)**:
- Basic composition functionality
- Business hours requirements (during/outside hours)
- Weekday requirements
- Minimum engagement level functionality

#### **ECommercePromoBannerSpec Class (4 tests)**:
- All conditions met scenario
- Insufficient activity time failure
- Insufficient product views failure
- Outside shopping hours failure

#### **SubscriptionUpgradeSpec Class (4 tests)**:
- All conditions met scenario
- Already premium subscriber failure
- Insufficient premium usage failure
- Insufficient app opens failure

### Key Improvements:
- **Tests now cover all public methods and properties**
- **Tests include both success and failure scenarios**
- **Tests validate business logic for all predefined composite specifications**
- **Tests verify parameter validation and edge cases**
- **All 26 tests pass successfully**

The test coverage for `CompositeSpec.swift` should now be significantly higher than the original 10%, likely approaching 90-100% coverage for all the business logic and public API surface area.
