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
