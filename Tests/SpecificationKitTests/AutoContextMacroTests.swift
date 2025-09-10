import XCTest
@testable import SpecificationKit

final class AutoContextMacroTests: XCTestCase {

    // A simple spec that checks a feature flag in EvaluationContext
    // The @AutoContext macro should inject a static contextProvider = DefaultContextProvider.shared
    @AutoContext
    struct FeatureFlagCheck: Specification {
        typealias T = EvaluationContext

        func isSatisfiedBy(_ context: EvaluationContext) -> Bool {
            context.flag(for: "auto_flag")
        }
    }

    func testAutoContext_InjectsDefaultProviderAndWorksWithSatisfies() {
        // Given
        let provider = DefaultContextProvider.shared
        provider.clearAll()

        // When: flag initially false
        provider.setFlag("auto_flag", to: false)

        struct Harness {
            @Satisfies(provider: FeatureFlagCheck.contextProvider, using: FeatureFlagCheck())
            var isEnabled: Bool
        }

        var h = Harness()

        // Then
        XCTAssertFalse(h.isEnabled)

        // When: flip the flag
        provider.setFlag("auto_flag", to: true)
        h = Harness() // re-evaluate through wrapper

        // Then
        XCTAssertTrue(h.isEnabled)
    }

    func testAutoContext_ProvidesStaticContextProvider() {
        // This compiles only if macro provided a static contextProvider of type DefaultContextProvider
        _ = FeatureFlagCheck.contextProvider
        XCTAssertTrue(type(of: FeatureFlagCheck.contextProvider) == DefaultContextProvider.self)
    }

    func testAutoContext_ExposesProviderTypealias_andContextType() {
        // Ensure the injected Provider typealias exists and is DefaultContextProvider
        _ = FeatureFlagCheck.Provider.self
        XCTAssertTrue(FeatureFlagCheck.Provider.self == DefaultContextProvider.self)

        // Ensure provider yields EvaluationContext for this spec
        let ctx: EvaluationContext = FeatureFlagCheck.contextProvider.currentContext()
        _ = ctx
    }
}
