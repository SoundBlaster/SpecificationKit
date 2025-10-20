import XCTest
@testable import SpecificationKit

#if canImport(SwiftUI)
import SwiftUI
import Combine

@MainActor
final class ObservedMaybeAdditionalTests: XCTestCase {

    // Reuse small polling helper
    func waitUntil(timeout: TimeInterval = 1.5, check: @escaping () -> Bool) {
        let exp = expectation(description: "condition satisfied")
        let deadline = Date().addingTimeInterval(timeout)
        func tick() {
            if check() { exp.fulfill(); return }
            if Date() > deadline { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { tick() }
        }
        tick()
        wait(for: [exp], timeout: timeout + 0.2)
    }

    func test_ObservedMaybe_convenience_usingSpec_reactive() {
        // Uses DefaultContextProvider.shared convenience init
        let provider = DefaultContextProvider.shared
        provider.clearAll()
        provider.setFlag("conv_flag", to: false)

        var wrapper = ObservedMaybe<EvaluationContext, String>(
            using: FeatureFlagSpec(flagKey: "conv_flag").erasedToMaybeResult("on")
        )

        // Need initial wiring
        wrapper.update()
        XCTAssertNil(wrapper.wrappedValue)

        provider.setFlag("conv_flag", to: true)
        waitUntil { wrapper.wrappedValue == "on" }
    }

    func test_ObservedMaybe_convenience_pairs_and_decide() {
        let provider = DefaultContextProvider.shared
        provider.clearAll()

        // pairs convenience
        var pairsWrapper = ObservedMaybe<EvaluationContext, Int>([
            (FeatureFlagSpec(flagKey: "pair_flag"), 42)
        ])
        pairsWrapper.update()
        XCTAssertNil(pairsWrapper.wrappedValue)
        provider.setFlag("pair_flag", to: true)
        waitUntil { pairsWrapper.wrappedValue == 42 }

        // decide convenience
        provider.clearAll()
        var decideWrapper = ObservedMaybe<EvaluationContext, String>(decide: { ctx in
            ctx.flag(for: "d_flag") ? "d_on" : nil
        })
        decideWrapper.update()
        XCTAssertNil(decideWrapper.wrappedValue)
        provider.setFlag("d_flag", to: true)
        waitUntil { decideWrapper.wrappedValue == "d_on" }
    }

    func test_ObservedMaybe_bindingProjectsCurrentValue() {
        let provider = DefaultContextProvider.shared
        provider.clearAll()
        provider.setFlag("bind_flag", to: false)

        var wrapper = ObservedMaybe<EvaluationContext, String>(
            provider: provider,
            firstMatch: [(FeatureFlagSpec(flagKey: "bind_flag"), "yes")]
        )
        wrapper.update()
        XCTAssertNil(wrapper.wrappedValue)
        XCTAssertNil(wrapper.projectedValue.wrappedValue)

        provider.setFlag("bind_flag", to: true)
        waitUntil { wrapper.projectedValue.wrappedValue == "yes" && wrapper.wrappedValue == "yes" }
    }

    func test_ObservedMaybe_environmentProvider_reactsToPublished() {
        let env = EnvironmentContextProvider()
        env.flags["env_flag"] = false

        var wrapper = ObservedMaybe<EvaluationContext, String>(
            provider: env,
            firstMatch: [(FeatureFlagSpec(flagKey: "env_flag"), "enabled")]
        )
        wrapper.update()
        XCTAssertNil(wrapper.wrappedValue)

        env.flags["env_flag"] = true
        waitUntil { wrapper.wrappedValue == "enabled" }
    }
}

private extension FeatureFlagSpec {
    func erasedToMaybeResult(_ value: String) -> FirstMatchSpec<EvaluationContext, String> {
        FirstMatchSpec([(self, value)])
    }
}

#endif

