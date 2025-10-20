import XCTest
@testable import SpecificationKit

#if canImport(SwiftUI)
import SwiftUI
import Combine

@MainActor
final class ObservedMaybeWrapperTests: XCTestCase {

    // Polling helper to wait until a condition is true within timeout.
    func waitUntil(timeout: TimeInterval = 1.5, check: @escaping () -> Bool) {
        let exp = expectation(description: "condition satisfied")
        let deadline = Date().addingTimeInterval(timeout)

        func tick() {
            if check() {
                exp.fulfill()
                return
            }
            if Date() > deadline {
                // Let it time out naturally
                return
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                tick()
            }
        }

        tick()
        wait(for: [exp], timeout: timeout + 0.2)
    }

    func test_ObservedMaybe_initialNil_and_reactsToProviderChange() {
        // Given: a provider with a disabled feature flag
        let provider = DefaultContextProvider.shared
        provider.clearAll()
        provider.setFlag("obs_maybe_flag", to: false)

        // And: an ObservedMaybe bound to that flag
        var wrapper = ObservedMaybe<EvaluationContext, String>(
            provider: provider,
            firstMatch: [(FeatureFlagSpec(flagKey: "obs_maybe_flag"), "enabled")]
        )

        // When: the wrapper updates (wires Combine and computes initial value)
        wrapper.update()

        // Then: initially no match
        XCTAssertNil(wrapper.wrappedValue)

        // When: flip the flag to true
        provider.setFlag("obs_maybe_flag", to: true)

        // Then: wrapper eventually reflects the change without manual reevaluation
        waitUntil {
            wrapper.wrappedValue == "enabled"
        }
    }

    func test_ObservedMaybe_supports_decide_and_pairs_initializers() {
        let provider = DefaultContextProvider.shared
        provider.clearAll()

        // pairs initializer
        var p = ObservedMaybe<EvaluationContext, Int>(
            provider: provider,
            firstMatch: [(MaxCountSpec.exactly(counterKey: "limit", count: 1), 1)]
        )
        p.update()
        XCTAssertNil(p.wrappedValue)
        provider.incrementCounter("limit")
        waitUntil { p.wrappedValue == 1 }

        // decide initializer
        provider.clearAll()
        var d = ObservedMaybe<EvaluationContext, String>(
            provider: provider,
            decide: { ctx in ctx.flag(for: "flag") ? "on" : nil }
        )
        d.update()
        XCTAssertNil(d.wrappedValue)
        provider.setFlag("flag", to: true)
        waitUntil { d.wrappedValue == "on" }
    }
}

#endif
