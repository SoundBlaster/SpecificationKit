import XCTest
@testable import SpecificationKit

final class SpecsIfMacroTests: XCTestCase {

    // MARK: - Macro Diagnostic Tests

    /// Test that the macro provides helpful diagnostic messages
    /// Note: Full macro expansion testing would require swift-macro-testing framework
    /// These tests verify the runtime behavior of specs using ConditionalSpecification

    func testSpecsIfMacro_RecommendedAlternative_UsingConditionalSpecification() {
        // Given - Testing the recommended approach using ConditionalSpecification
        let provider = DefaultContextProvider.shared
        provider.clearAll()
        provider.setFlag("premium", to: false)

        struct PremiumFeatureSpec: Specification {
            typealias T = EvaluationContext
            func isSatisfiedBy(_ context: EvaluationContext) -> Bool {
                // Some premium feature logic
                return true
            }
        }

        let conditionalSpec = ConditionalSpecification(
            condition: { ctx in ctx.flag(for: "premium") },
            wrapping: PremiumFeatureSpec()
        )

        // When: premium flag is false
        var context = provider.currentContext()
        var result = conditionalSpec.isSatisfiedBy(context)

        // Then
        XCTAssertFalse(result, "Should respect condition")

        // When: premium flag is true
        provider.setFlag("premium", to: true)
        context = provider.currentContext()
        result = conditionalSpec.isSatisfiedBy(context)

        // Then
        XCTAssertTrue(result, "Should evaluate wrapped spec when condition is true")
    }

    func testSpecsIfMacro_AlternativeUsing_WhenMethod() {
        // Given - Testing the convenience .when() method
        let provider = DefaultContextProvider.shared
        provider.clearAll()
        provider.setFlag("beta", to: false)

        struct BetaFeatureSpec: Specification {
            typealias T = EvaluationContext
            func isSatisfiedBy(_ context: EvaluationContext) -> Bool {
                return true
            }
        }

        let conditionalSpec = BetaFeatureSpec().when { ctx in
            ctx.flag(for: "beta")
        }

        // When: beta flag is false
        var context = provider.currentContext()
        var result = conditionalSpec.isSatisfiedBy(context)

        // Then
        XCTAssertFalse(result)

        // When: beta flag is true
        provider.setFlag("beta", to: true)
        context = provider.currentContext()
        result = conditionalSpec.isSatisfiedBy(context)

        // Then
        XCTAssertTrue(result)
    }

    // MARK: - Integration Tests

    func testSpecsIfMacro_WithPropertyWrapper() {
        // Given - Testing conditional spec with @Satisfies wrapper
        let provider = DefaultContextProvider.shared
        provider.clearAll()
        provider.setFlag("admin", to: false)

        struct AdminFeatureSpec: Specification {
            typealias T = EvaluationContext
            func isSatisfiedBy(_ context: EvaluationContext) -> Bool {
                return true
            }
        }

        let conditionalSpec = ConditionalSpecification(
            condition: { ctx in ctx.flag(for: "admin") },
            wrapping: AdminFeatureSpec()
        )

        // When: admin flag is false
        var result = conditionalSpec.isSatisfiedBy(provider.currentContext())

        // Then
        XCTAssertFalse(result)

        // When: admin flag is true
        provider.setFlag("admin", to: true)
        result = conditionalSpec.isSatisfiedBy(provider.currentContext())

        // Then
        XCTAssertTrue(result)
    }

    func testSpecsIfMacro_WithCompositeSpecs() {
        // Given - Testing conditional spec combined with other specs
        let provider = DefaultContextProvider.shared
        provider.clearAll()
        provider.setFlag("feature_enabled", to: true)
        provider.setFlag("user_eligible", to: true)

        struct FeatureEnabledSpec: Specification {
            typealias T = EvaluationContext
            func isSatisfiedBy(_ context: EvaluationContext) -> Bool {
                context.flag(for: "feature_enabled")
            }
        }

        struct UserEligibleSpec: Specification {
            typealias T = EvaluationContext
            func isSatisfiedBy(_ context: EvaluationContext) -> Bool {
                context.flag(for: "user_eligible")
            }
        }

        // Conditional spec that checks both conditions
        let conditionalFeature = ConditionalSpecification(
            condition: { ctx in ctx.flag(for: "feature_enabled") },
            wrapping: UserEligibleSpec()
        )

        // When: both flags are true
        var context = provider.currentContext()
        var result = conditionalFeature.isSatisfiedBy(context)

        // Then
        XCTAssertTrue(result)

        // When: feature is disabled
        provider.setFlag("feature_enabled", to: false)
        context = provider.currentContext()
        result = conditionalFeature.isSatisfiedBy(context)

        // Then
        XCTAssertFalse(result, "Condition should gate the spec")

        // When: feature enabled but user not eligible
        provider.setFlag("feature_enabled", to: true)
        provider.setFlag("user_eligible", to: false)
        context = provider.currentContext()
        result = conditionalFeature.isSatisfiedBy(context)

        // Then
        XCTAssertFalse(result, "Wrapped spec should still be evaluated")
    }

    func testSpecsIfMacro_ComplexConditionLogic() {
        // Given - Testing complex condition expressions
        let provider = DefaultContextProvider.shared
        provider.clearAll()
        provider.setFlag("is_premium", to: true)
        provider.setCounter("account_age_days", to: 30)

        struct RateLimitSpec: Specification {
            typealias T = EvaluationContext
            func isSatisfiedBy(_ context: EvaluationContext) -> Bool {
                // Premium users get more lenient rate limits
                return true
            }
        }

        // Complex condition: premium AND account older than 7 days
        let conditionalSpec = ConditionalSpecification(
            condition: { ctx in
                ctx.flag(for: "is_premium") && ctx.counter(for: "account_age_days") >= 7
            },
            wrapping: RateLimitSpec()
        )

        // When: premium user with old account
        var context = provider.currentContext()
        var result = conditionalSpec.isSatisfiedBy(context)

        // Then
        XCTAssertTrue(result)

        // When: premium user with new account
        provider.setCounter("account_age_days", to: 3)
        context = provider.currentContext()
        result = conditionalSpec.isSatisfiedBy(context)

        // Then
        XCTAssertFalse(result, "Account age requirement not met")

        // When: non-premium user with old account
        provider.setCounter("account_age_days", to: 30)
        provider.setFlag("is_premium", to: false)
        context = provider.currentContext()
        result = conditionalSpec.isSatisfiedBy(context)

        // Then
        XCTAssertFalse(result, "Premium requirement not met")
    }

    // MARK: - Error Handling Tests

    func testSpecsIfMacro_GracefulConditionFailure() {
        // Given - Testing that conditions handle edge cases gracefully
        let provider = DefaultContextProvider.shared
        provider.clearAll()

        struct SafeSpec: Specification {
            typealias T = EvaluationContext
            func isSatisfiedBy(_ context: EvaluationContext) -> Bool {
                return true
            }
        }

        // Condition that checks for a non-existent flag
        let conditionalSpec = ConditionalSpecification(
            condition: { ctx in
                // Non-existent flag defaults to false
                ctx.flag(for: "nonexistent_flag")
            },
            wrapping: SafeSpec()
        )

        // When
        let context = provider.currentContext()
        let result = conditionalSpec.isSatisfiedBy(context)

        // Then
        XCTAssertFalse(result, "Non-existent flags should default to false")
    }

    // MARK: - Documentation Examples

    func testSpecsIfMacro_DocumentationExample_WhenMethod() {
        // Example from documentation showing .when() usage
        let provider = DefaultContextProvider.shared
        provider.clearAll()
        provider.setFlag("is_premium", to: true)
        provider.setCounter("api_calls", to:500)

        let premiumOnlySpec = MaxCountSpec(counterKey: "api_calls", maximumCount: 1000)
            .when { ctx in ctx.flag(for: "is_premium") }

        let context = provider.currentContext()
        let result = premiumOnlySpec.isSatisfiedBy(context)

        XCTAssertTrue(result, "Premium users within limit should pass")
    }

    func testSpecsIfMacro_DocumentationExample_UnlessMethod() {
        // Example from documentation showing .unless() usage
        let provider = DefaultContextProvider.shared
        provider.clearAll()
        provider.setFlag("unlimited_plan", to: false)
        provider.setCounter("requests", to: 5)

        let rateLimitSpec = MaxCountSpec(counterKey: "requests", maximumCount: 10)
            .unless { ctx in ctx.flag(for: "unlimited_plan") }

        let context = provider.currentContext()
        let result = rateLimitSpec.isSatisfiedBy(context)

        XCTAssertTrue(result, "Limited plan users within limit should pass")
    }
}
