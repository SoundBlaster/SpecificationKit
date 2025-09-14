//
//  ConditionalSatisfiesTests.swift
//  SpecificationKitTests
//
//  Created by SpecificationKit on 2025.
//

import Foundation
import XCTest

@testable import SpecificationKit

final class ConditionalSatisfiesTests: XCTestCase {

    // MARK: - Test Specifications

    struct MockSpec: Specification {
        let shouldSatisfy: Bool
        let identifier: String

        init(_ shouldSatisfy: Bool, id: String = "") {
            self.shouldSatisfy = shouldSatisfy
            self.identifier = id
        }

        func isSatisfiedBy(_ context: EvaluationContext) -> Bool {
            return shouldSatisfy
        }
    }

    // MARK: - Basic Functionality Tests

    func testBasicConditionalSelection() {
        var shouldUseFirstSpec = true

        @ConditionalSatisfies(
            conditions: [
                ({ shouldUseFirstSpec }, MockSpec(true, id: "first")),
                ({ true }, MockSpec(false, id: "second")),
            ],
            fallback: MockSpec(false, id: "fallback")
        )
        var result: Bool

        // First condition should be selected
        XCTAssertTrue(result)

        // Change condition
        shouldUseFirstSpec = false

        // Second condition should be selected
        XCTAssertFalse(result)
    }

    func testFallbackSpecificationUsed() {
        @ConditionalSatisfies(
            conditions: [
                ({ false }, MockSpec(true)),
                ({ false }, MockSpec(true)),
            ],
            fallback: MockSpec(true, id: "fallback")
        )
        var result: Bool

        // Fallback should be used when no conditions match
        XCTAssertTrue(result)
    }

    func testPredicateFunctionConditions() {
        var flag = true

        @ConditionalSatisfies(
            conditions: [
                ({ flag }, { _ in true }),
                ({ true }, { _ in false }),
            ],
            fallback: { _ in false }
        )
        var result: Bool

        // First condition should be selected
        XCTAssertTrue(result)

        flag = false

        // Second condition should be selected
        XCTAssertFalse(result)
    }

    // MARK: - Provider Tests

    func testCustomContextProvider() {
        let mockProvider = MockContextProvider()
            .withFlag("test_flag", value: true)

        @ConditionalSatisfies(
            provider: mockProvider,
            conditions: [
                ({ true }, { context in context.flag(for: "test_flag") })
            ],
            fallback: { _ in false }
        )
        var result: Bool

        XCTAssertTrue(result)
    }

    // MARK: - Builder Pattern Tests

    func testBuilderPattern() {
        var deviceIsTablet = false
        var accessibilityEnabled = false

        let conditional = ConditionalSatisfies<EvaluationContext>.builder(
            provider: DefaultContextProvider.shared
        )
        .when({ deviceIsTablet }, use: MockSpec(true))
        .when({ accessibilityEnabled }, use: MockSpec(false))
        .otherwise(MockSpec(true))

        // Should use fallback initially
        XCTAssertTrue(conditional.wrappedValue)

        deviceIsTablet = true
        XCTAssertTrue(conditional.wrappedValue)

        deviceIsTablet = false
        accessibilityEnabled = true
        XCTAssertFalse(conditional.wrappedValue)
    }

    func testBuilderWithPredicateFunctions() {
        var flag = false

        let conditional = ConditionalSatisfies<EvaluationContext>.builder(
            provider: DefaultContextProvider.shared
        )
        .when({ flag }, use: { _ in true })
        .otherwise({ _ in false })

        XCTAssertFalse(conditional.wrappedValue)

        flag = true
        XCTAssertTrue(conditional.wrappedValue)
    }

    // MARK: - Integration Tests

    func testIntegrationWithEvaluationContext() {
        let provider = MockContextProvider()
            .withFlag("feature_enabled", value: false)
            .withCounter("usage_count", value: 5)

        @ConditionalSatisfies(
            provider: provider,
            conditions: [
                (
                    { false },
                    { context in
                        context.flag(for: "feature_enabled")
                            && context.counter(for: "usage_count") > 10
                    }
                ),
                (
                    { true },
                    { context in
                        context.counter(for: "usage_count") > 3
                    }
                ),
            ],
            fallback: { _ in false }
        )
        var wrapper: Bool

        // First condition should fail, second should succeed
        XCTAssertTrue(wrapper)
    }

    func testDynamicConditionChanges() {
        var environmentCondition = "development"

        @ConditionalSatisfies(
            conditions: [
                ({ environmentCondition == "production" }, MockSpec(false)),
                ({ environmentCondition == "staging" }, MockSpec(true)),
                ({ environmentCondition == "development" }, MockSpec(true)),
            ],
            fallback: MockSpec(false)
        )
        var wrapper: Bool

        // Development condition should be active
        XCTAssertTrue(wrapper)

        environmentCondition = "production"
        XCTAssertFalse(wrapper)

        environmentCondition = "staging"
        XCTAssertTrue(wrapper)

        environmentCondition = "unknown"
        XCTAssertFalse(wrapper)  // Should use fallback
    }

    // MARK: - Platform-Specific Tests

    #if os(iOS) || os(tvOS)
        func testDeviceAdaptiveSpecifications() {
            let conditional = ConditionalSatisfies<EvaluationContext>.deviceAdaptive(
                ipad: MockSpec(true, id: "ipad"),
                iphone: MockSpec(false, id: "iphone"),
                fallback: MockSpec(true, id: "fallback")
            )

            // Result depends on actual device, but should not crash
            let result = conditional.wrappedValue
            XCTAssertTrue(result is Bool)  // Just verify it returns a valid result
        }

        func testAccessibilityAdaptiveSpecifications() {
            let conditional = ConditionalSatisfies<EvaluationContext>.accessibilityAdaptive(
                voiceOver: MockSpec(true, id: "voiceOver"),
                reducedMotion: MockSpec(false, id: "reducedMotion"),
                fallback: MockSpec(true, id: "fallback")
            )

            // Result depends on accessibility settings, but should not crash
            let result = conditional.wrappedValue
            XCTAssertTrue(result is Bool)
        }
    #endif

    // MARK: - Projected Value Tests

    func testProjectedValueAsyncEvaluation() async throws {
        let conditionalSatisfies = ConditionalSatisfies(
            conditions: [
                ({ true }, MockSpec(true))
            ],
            fallback: MockSpec(false)
        )

        let result = try await conditionalSatisfies.projectedValue.evaluateAsync()
        XCTAssertTrue(result)
    }

    func testProjectedValueConditionAnalysis() {
        var useFirst = false
        var useSecond = true

        let conditionalSatisfies = ConditionalSatisfies(
            conditions: [
                ({ useFirst }, MockSpec(true, id: "first")),
                ({ useSecond }, MockSpec(true, id: "second")),
            ],
            fallback: MockSpec(true, id: "fallback")
        )

        // Second condition should be active
        XCTAssertEqual(conditionalSatisfies.projectedValue.getActiveConditionIndex(), 1)
        XCTAssertFalse(conditionalSatisfies.projectedValue.isUsingFallback())

        // Change to use first
        useFirst = true
        XCTAssertEqual(conditionalSatisfies.projectedValue.getActiveConditionIndex(), 0)

        // Use fallback
        useFirst = false
        useSecond = false
        XCTAssertNil(conditionalSatisfies.projectedValue.getActiveConditionIndex())
        XCTAssertTrue(conditionalSatisfies.projectedValue.isUsingFallback())
    }
}
