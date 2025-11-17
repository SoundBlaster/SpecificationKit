import XCTest
@testable import SpecificationKit

final class ConditionalSpecificationTests: XCTestCase {

    // MARK: - Test Specifications

    /// A simple always-true spec for testing
    struct AlwaysTrueSpec: Specification {
        typealias T = EvaluationContext
        func isSatisfiedBy(_ candidate: EvaluationContext) -> Bool { true }
    }

    /// A simple always-false spec for testing
    struct AlwaysFalseSpec: Specification {
        typealias T = EvaluationContext
        func isSatisfiedBy(_ candidate: EvaluationContext) -> Bool { false }
    }

    /// A spec that checks a feature flag
    struct FeatureFlagSpec: Specification {
        typealias T = EvaluationContext
        let flagKey: String
        func isSatisfiedBy(_ candidate: EvaluationContext) -> Bool {
            candidate.flag(for: flagKey)
        }
    }

    // MARK: - Basic Functionality Tests

    func testConditionalSpec_WhenConditionTrue_EvaluatesWrappedSpec() {
        // Given
        let wrappedSpec = AlwaysTrueSpec()
        let conditionalSpec = ConditionalSpecification(
            condition: { _ in true },
            wrapping: wrappedSpec
        )
        let context = EvaluationContext()

        // When
        let result = conditionalSpec.isSatisfiedBy(context)

        // Then
        XCTAssertTrue(result, "Should evaluate wrapped spec when condition is true")
    }

    func testConditionalSpec_WhenConditionFalse_ShortCircuits() {
        // Given
        let wrappedSpec = AlwaysTrueSpec()
        let conditionalSpec = ConditionalSpecification(
            condition: { _ in false },
            wrapping: wrappedSpec
        )
        let context = EvaluationContext()

        // When
        let result = conditionalSpec.isSatisfiedBy(context)

        // Then
        XCTAssertFalse(result, "Should return false without evaluating wrapped spec when condition is false")
    }

    func testConditionalSpec_ConditionFalse_WrappedSpecTrue_ReturnsFalse() {
        // Given
        let wrappedSpec = AlwaysTrueSpec()
        let conditionalSpec = ConditionalSpecification(
            condition: { _ in false },
            wrapping: wrappedSpec
        )
        let context = EvaluationContext()

        // When
        let result = conditionalSpec.isSatisfiedBy(context)

        // Then
        XCTAssertFalse(result, "Condition takes precedence over wrapped spec")
    }

    func testConditionalSpec_ConditionTrue_WrappedSpecFalse_ReturnsFalse() {
        // Given
        let wrappedSpec = AlwaysFalseSpec()
        let conditionalSpec = ConditionalSpecification(
            condition: { _ in true },
            wrapping: wrappedSpec
        )
        let context = EvaluationContext()

        // When
        let result = conditionalSpec.isSatisfiedBy(context)

        // Then
        XCTAssertFalse(result, "Should return wrapped spec result when condition is true")
    }

    // MARK: - Context-Based Condition Tests

    func testConditionalSpec_WithFeatureFlagCondition() {
        // Given
        let provider = DefaultContextProvider.shared
        provider.clearAll()
        provider.setFlag("premium", to: false)

        let wrappedSpec = AlwaysTrueSpec()
        let conditionalSpec = ConditionalSpecification(
            condition: { ctx in ctx.flag(for: "premium") },
            wrapping: wrappedSpec
        )

        // When: flag is false
        var context = provider.currentContext()
        var result = conditionalSpec.isSatisfiedBy(context)

        // Then
        XCTAssertFalse(result, "Should be false when feature flag is disabled")

        // When: flag is enabled
        provider.setFlag("premium", to: true)
        context = provider.currentContext()
        result = conditionalSpec.isSatisfiedBy(context)

        // Then
        XCTAssertTrue(result, "Should be true when feature flag is enabled")
    }

    func testConditionalSpec_WithComplexCondition() {
        // Given
        let provider = DefaultContextProvider.shared
        provider.clearAll()
        provider.setFlag("beta_program", to: true)
        provider.setFlag("admin", to: false)

        let wrappedSpec = AlwaysTrueSpec()
        let conditionalSpec = ConditionalSpecification(
            condition: { ctx in
                ctx.flag(for: "beta_program") && ctx.flag(for: "admin")
            },
            wrapping: wrappedSpec
        )

        // When: only beta flag is true
        var context = provider.currentContext()
        var result = conditionalSpec.isSatisfiedBy(context)

        // Then
        XCTAssertFalse(result, "Should require both flags")

        // When: both flags are true
        provider.setFlag("admin", to: true)
        context = provider.currentContext()
        result = conditionalSpec.isSatisfiedBy(context)

        // Then
        XCTAssertTrue(result, "Should pass when both flags are enabled")
    }

    // MARK: - Convenience Method Tests

    func testWhenConvenienceMethod() {
        // Given
        let provider = DefaultContextProvider.shared
        provider.clearAll()
        provider.setFlag("enabled", to: false)

        let spec = AlwaysTrueSpec()
        let conditionalSpec = spec.when { ctx in ctx.flag(for: "enabled") }

        // When: flag is false
        var context = provider.currentContext()
        var result = conditionalSpec.isSatisfiedBy(context)

        // Then
        XCTAssertFalse(result)

        // When: flag is enabled
        provider.setFlag("enabled", to: true)
        context = provider.currentContext()
        result = conditionalSpec.isSatisfiedBy(context)

        // Then
        XCTAssertTrue(result)
    }

    func testUnlessConvenienceMethod() {
        // Given
        let provider = DefaultContextProvider.shared
        provider.clearAll()
        provider.setFlag("disabled", to: false)

        let spec = AlwaysTrueSpec()
        let conditionalSpec = spec.unless { ctx in ctx.flag(for: "disabled") }

        // When: flag is false (spec should be enabled)
        var context = provider.currentContext()
        var result = conditionalSpec.isSatisfiedBy(context)

        // Then
        XCTAssertTrue(result, "Should pass when 'unless' condition is false")

        // When: flag is true (spec should be disabled)
        provider.setFlag("disabled", to: true)
        context = provider.currentContext()
        result = conditionalSpec.isSatisfiedBy(context)

        // Then
        XCTAssertFalse(result, "Should fail when 'unless' condition is true")
    }

    // MARK: - Composition Tests

    func testConditionalSpec_ComposedWithAnd() {
        // Given
        let provider = DefaultContextProvider.shared
        provider.clearAll()
        provider.setFlag("feature_a", to: true)
        provider.setFlag("feature_b", to: true)

        let specA = FeatureFlagSpec(flagKey: "feature_a")
        let specB = FeatureFlagSpec(flagKey: "feature_b")

        let conditionalSpec = ConditionalSpecification(
            condition: { _ in true },
            wrapping: specA
        ).and(specB)

        // When: both flags are true
        var context = provider.currentContext()
        var result = conditionalSpec.isSatisfiedBy(context)

        // Then
        XCTAssertTrue(result)

        // When: one flag is false
        provider.setFlag("feature_b", to: false)
        context = provider.currentContext()
        result = conditionalSpec.isSatisfiedBy(context)

        // Then
        XCTAssertFalse(result)
    }

    func testConditionalSpec_ComposedWithOr() {
        // Given
        let provider = DefaultContextProvider.shared
        provider.clearAll()
        provider.setFlag("gate", to: true)
        provider.setFlag("feature_a", to: false)
        provider.setFlag("feature_b", to: true)

        let specA = FeatureFlagSpec(flagKey: "feature_a")
        let specB = FeatureFlagSpec(flagKey: "feature_b")

        let conditionalSpec = ConditionalSpecification(
            condition: { ctx in ctx.flag(for: "gate") },
            wrapping: specA
        ).or(specB)

        // When: gate is true and specB is true
        let context = provider.currentContext()
        let result = conditionalSpec.isSatisfiedBy(context)

        // Then
        XCTAssertTrue(result, "Should pass when OR'ed spec is true")
    }

    func testConditionalSpec_Negated() {
        // Given
        let provider = DefaultContextProvider.shared
        provider.clearAll()
        provider.setFlag("enabled", to: true)

        let spec = AlwaysTrueSpec()
        let conditionalSpec = ConditionalSpecification(
            condition: { ctx in ctx.flag(for: "enabled") },
            wrapping: spec
        ).not()

        // When: both condition and spec are true
        let context = provider.currentContext()
        let result = conditionalSpec.isSatisfiedBy(context)

        // Then
        XCTAssertFalse(result, "Negation should invert the result")
    }

    // MARK: - Edge Cases

    func testConditionalSpec_WithNilableContext() {
        // Given - Testing that the condition can handle context properties
        let provider = DefaultContextProvider.shared
        provider.clearAll()

        let spec = AlwaysTrueSpec()
        let conditionalSpec = ConditionalSpecification(
            condition: { ctx in
                // Access context properties safely
                ctx.flag(for: "nonexistent") == false
            },
            wrapping: spec
        )

        // When
        let context = provider.currentContext()
        let result = conditionalSpec.isSatisfiedBy(context)

        // Then
        XCTAssertTrue(result, "Should handle non-existent flags gracefully")
    }

    func testConditionalSpec_MultipleWrappings() {
        // Given - Test wrapping a conditional spec in another conditional spec
        let provider = DefaultContextProvider.shared
        provider.clearAll()
        provider.setFlag("outer", to: true)
        provider.setFlag("inner", to: true)

        let baseSpec = AlwaysTrueSpec()
        let innerConditional = ConditionalSpecification(
            condition: { ctx in ctx.flag(for: "inner") },
            wrapping: baseSpec
        )
        let outerConditional = ConditionalSpecification(
            condition: { ctx in ctx.flag(for: "outer") },
            wrapping: innerConditional
        )

        // When: both conditions are true
        var context = provider.currentContext()
        var result = outerConditional.isSatisfiedBy(context)

        // Then
        XCTAssertTrue(result)

        // When: outer is false
        provider.setFlag("outer", to: false)
        context = provider.currentContext()
        result = outerConditional.isSatisfiedBy(context)

        // Then
        XCTAssertFalse(result, "Outer condition should gate inner condition")

        // When: outer is true but inner is false
        provider.setFlag("outer", to: true)
        provider.setFlag("inner", to: false)
        context = provider.currentContext()
        result = outerConditional.isSatisfiedBy(context)

        // Then
        XCTAssertFalse(result, "Both conditions must be true")
    }

    // MARK: - Real-World Scenario Tests

    func testConditionalSpec_PremiumFeatureGating() {
        // Given - A realistic scenario: premium users get higher limits
        let provider = DefaultContextProvider.shared
        provider.clearAll()
        provider.setFlag("is_premium", to: false)
        provider.setCounter("api_calls", to: 50)

        let premiumLimit = MaxCountSpec(counterKey: "api_calls", maximumCount: 100)
        let gatedPremiumLimit = ConditionalSpecification(
            condition: { (ctx: EvaluationContext) in ctx.flag(for: "is_premium") },
            wrapping: premiumLimit
        )

        // When: free user with 50 calls
        var context = provider.currentContext()
        var result = gatedPremiumLimit.isSatisfiedBy(context)

        // Then
        XCTAssertFalse(result, "Free users don't get premium limits")

        // When: premium user with 50 calls
        provider.setFlag("is_premium", to: true)
        context = provider.currentContext()
        result = gatedPremiumLimit.isSatisfiedBy(context)

        // Then
        XCTAssertTrue(result, "Premium users get higher limits")

        // When: premium user exceeds limit
        provider.setCounter("api_calls", to: 101)
        context = provider.currentContext()
        result = gatedPremiumLimit.isSatisfiedBy(context)

        // Then
        XCTAssertFalse(result, "Even premium users have limits")
    }
}
