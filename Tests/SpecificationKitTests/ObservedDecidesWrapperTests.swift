import XCTest

@testable import SpecificationKit

#if canImport(SwiftUI)
    import SwiftUI
    import Combine

    @MainActor
    final class ObservedDecidesWrapperTests: XCTestCase {

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

        func test_ObservedDecides_initialFallback_and_reactsToProviderChange() {
            // Given: a provider with disabled feature flags
            let provider = DefaultContextProvider.shared
            provider.clearAll()
            provider.setFlag("premium_flag", to: false)
            provider.setFlag("standard_flag", to: false)

            // And: an ObservedDecides with decision pairs
            var wrapper = ObservedDecides<EvaluationContext, String>(
                provider: provider,
                decisions: [
                    (FeatureFlagSpec(flagKey: "premium_flag"), "premium_tier"),
                    (FeatureFlagSpec(flagKey: "standard_flag"), "standard_tier"),
                ],
                or: "basic_tier"
            )

            // When: the wrapper updates (wires Combine and computes initial value)
            wrapper.update()

            // Then: initially returns fallback
            XCTAssertEqual(wrapper.wrappedValue, "basic_tier")

            // When: premium flag is enabled
            provider.setFlag("premium_flag", to: true)

            // Then: wrapper should react and return premium tier
            waitUntil { wrapper.wrappedValue == "premium_tier" }
            XCTAssertEqual(wrapper.wrappedValue, "premium_tier")
        }

        func test_ObservedDecides_priorityOrder() {
            // Given: a provider with multiple flags enabled
            let provider = DefaultContextProvider.shared
            provider.clearAll()
            provider.setFlag("premium_flag", to: true)
            provider.setFlag("standard_flag", to: true)

            // And: an ObservedDecides with ordered decision pairs
            var wrapper = ObservedDecides<EvaluationContext, String>(
                provider: provider,
                decisions: [
                    (FeatureFlagSpec(flagKey: "premium_flag"), "premium_tier"),
                    (FeatureFlagSpec(flagKey: "standard_flag"), "standard_tier"),
                ],
                or: "basic_tier"
            )

            wrapper.update()

            // Then: should return the first matching tier (premium)
            XCTAssertEqual(wrapper.wrappedValue, "premium_tier")

            // When: premium flag is disabled
            provider.setFlag("premium_flag", to: false)

            // Then: should fall back to standard tier
            waitUntil { wrapper.wrappedValue == "standard_tier" }
            XCTAssertEqual(wrapper.wrappedValue, "standard_tier")

            // When: standard flag is also disabled
            provider.setFlag("standard_flag", to: false)

            // Then: should fall back to basic tier
            waitUntil { wrapper.wrappedValue == "basic_tier" }
            XCTAssertEqual(wrapper.wrappedValue, "basic_tier")
        }

        func test_ObservedDecides_projectedValue_publisher() {
            // Given: a provider with a feature flag
            let provider = DefaultContextProvider.shared
            provider.clearAll()
            provider.setFlag("test_flag", to: false)

            var wrapper = ObservedDecides<EvaluationContext, String>(
                provider: provider,
                decisions: [(FeatureFlagSpec(flagKey: "test_flag"), "enabled")],
                or: "disabled"
            )
            wrapper.update()

            // When: subscribing to projected value publisher
            var receivedValues: [String] = []
            let cancellable = wrapper.projectedValue.publisher
                .sink { value in
                    receivedValues.append(value)
                }

            // Then: should receive initial value
            waitUntil { receivedValues.count >= 1 }
            XCTAssertEqual(receivedValues.last, "disabled")

            // When: context changes
            provider.setFlag("test_flag", to: true)

            // Then: should receive updated value
            waitUntil { receivedValues.count >= 2 }
            XCTAssertEqual(receivedValues.last, "enabled")

            cancellable.cancel()
        }

        func test_ObservedDecides_projectedValue_binding() {
            // Given: a provider with a feature flag
            let provider = DefaultContextProvider.shared
            provider.clearAll()
            provider.setFlag("binding_test", to: true)

            var wrapper = ObservedDecides<EvaluationContext, Int>(
                provider: provider,
                decisions: [(FeatureFlagSpec(flagKey: "binding_test"), 42)],
                or: 0
            )
            wrapper.update()

            // When: accessing projected value binding
            let binding = wrapper.projectedValue.binding

            // Then: binding should reflect current value
            XCTAssertEqual(binding.wrappedValue, 42)

            // When: context changes
            provider.setFlag("binding_test", to: false)

            // Then: binding should update
            waitUntil { binding.wrappedValue == 0 }
            XCTAssertEqual(binding.wrappedValue, 0)
        }

        func test_ObservedDecides_with_DecisionSpec() {
            // Given: a custom decision spec
            struct TestDecisionSpec: DecisionSpec {
                typealias Context = EvaluationContext
                typealias Result = String

                func decide(_ context: EvaluationContext) -> String? {
                    let count = context.counter(for: "test_counter")
                    switch count {
                    case 3...: return "high"
                    case 1...2: return "medium"
                    default: return nil
                    }
                }
            }

            let provider = DefaultContextProvider.shared
            provider.clearAll()

            var wrapper = ObservedDecides(
                provider: provider,
                using: TestDecisionSpec(),
                or: "low"
            )
            wrapper.update()

            // Then: initially should return fallback
            XCTAssertEqual(wrapper.wrappedValue, "low")

            // When: counter is incremented to 1
            provider.incrementCounter("test_counter")

            // Then: should return medium
            waitUntil { wrapper.wrappedValue == "medium" }
            XCTAssertEqual(wrapper.wrappedValue, "medium")

            // When: counter is incremented to 3
            provider.incrementCounter("test_counter")  // 2
            provider.incrementCounter("test_counter")  // 3

            // Then: should return high
            waitUntil { wrapper.wrappedValue == "high" }
            XCTAssertEqual(wrapper.wrappedValue, "high")
        }

        func test_ObservedDecides_with_custom_decide_function() {
            // Given: a provider with counters
            let provider = DefaultContextProvider.shared
            provider.clearAll()

            var wrapper = ObservedDecides<EvaluationContext, String>(
                provider: provider,
                decide: { context in
                    let score = context.counter(for: "score")
                    if score >= 100 { return "excellent" }
                    if score >= 50 { return "good" }
                    return nil  // Falls back to "fair"
                },
                or: "fair"
            )
            wrapper.update()

            // Then: initially should return fallback
            XCTAssertEqual(wrapper.wrappedValue, "fair")

            // When: score is set to 75
            for _ in 0..<75 {
                provider.incrementCounter("score")
            }

            // Then: should return good
            waitUntil { wrapper.wrappedValue == "good" }
            XCTAssertEqual(wrapper.wrappedValue, "good")

            // When: score reaches 100
            for _ in 75..<100 {
                provider.incrementCounter("score")
            }

            // Then: should return excellent
            waitUntil { wrapper.wrappedValue == "excellent" }
            XCTAssertEqual(wrapper.wrappedValue, "excellent")
        }

        func test_ObservedDecides_with_builder_pattern() {
            // Given: a provider
            let provider = DefaultContextProvider.shared
            provider.clearAll()

            var wrapper = ObservedDecides<EvaluationContext, String>(
                build: { builder in
                    builder
                        .add(FeatureFlagSpec(flagKey: "premium"), result: "premium_content")
                        .add(
                            MaxCountSpec(counterKey: "visits", maximumCount: 5),
                            result: "welcome_content")
                },
                or: "default_content"
            )
            wrapper.update()

            // Then: initially should return default content (visits is 0, so MaxCountSpec is satisfied)
            XCTAssertEqual(wrapper.wrappedValue, "welcome_content")

            // When: visits exceed 5
            for _ in 0..<6 {
                provider.incrementCounter("visits")
            }

            // Then: should return default content
            waitUntil { wrapper.wrappedValue == "default_content" }
            XCTAssertEqual(wrapper.wrappedValue, "default_content")

            // When: premium flag is enabled
            provider.setFlag("premium", to: true)

            // Then: should return premium content (higher priority)
            waitUntil { wrapper.wrappedValue == "premium_content" }
            XCTAssertEqual(wrapper.wrappedValue, "premium_content")
        }

        func test_ObservedDecides_performance_with_multiple_updates() {
            // Given: a provider
            let provider = DefaultContextProvider.shared
            provider.clearAll()

            var wrapper = ObservedDecides<EvaluationContext, String>(
                provider: provider,
                decisions: [
                    (FeatureFlagSpec(flagKey: "flag1"), "result1"),
                    (FeatureFlagSpec(flagKey: "flag2"), "result2"),
                ],
                or: "default"
            )
            wrapper.update()

            // Measure performance of rapid updates
            measure {
                for i in 0..<100 {
                    provider.setFlag("flag1", to: i % 2 == 0)
                    provider.setFlag("flag2", to: i % 3 == 0)
                }
            }
        }

        func test_ObservedDecides_enum_result_type() {
            enum UserTier: String, Equatable {
                case premium = "premium"
                case standard = "standard"
                case basic = "basic"
            }

            let provider = DefaultContextProvider.shared
            provider.clearAll()

            var wrapper = ObservedDecides<EvaluationContext, UserTier>(
                provider: provider,
                decisions: [
                    (FeatureFlagSpec(flagKey: "premium_user"), .premium),
                    (FeatureFlagSpec(flagKey: "standard_user"), .standard),
                ],
                or: .basic
            )
            wrapper.update()

            // Then: initially should return basic tier
            XCTAssertEqual(wrapper.wrappedValue, .basic)

            // When: standard flag is enabled
            provider.setFlag("standard_user", to: true)

            // Then: should return standard tier
            waitUntil { wrapper.wrappedValue == .standard }
            XCTAssertEqual(wrapper.wrappedValue, .standard)

            // When: premium flag is also enabled
            provider.setFlag("premium_user", to: true)

            // Then: should return premium tier (higher priority)
            waitUntil { wrapper.wrappedValue == .premium }
            XCTAssertEqual(wrapper.wrappedValue, .premium)
        }

        func test_ObservedDecides_numeric_result_type() {
            let provider = DefaultContextProvider.shared
            provider.clearAll()

            var wrapper = ObservedDecides<EvaluationContext, Double>(
                provider: provider,
                decisions: [
                    (FeatureFlagSpec(flagKey: "premium_discount"), 0.25),  // 25%
                    (FeatureFlagSpec(flagKey: "member_discount"), 0.15),  // 15%
                    (FeatureFlagSpec(flagKey: "first_time_discount"), 0.10),  // 10%
                ],
                or: 0.0
            )
            wrapper.update()

            // Then: initially should return no discount
            XCTAssertEqual(wrapper.wrappedValue, 0.0)

            // When: first time discount is enabled
            provider.setFlag("first_time_discount", to: true)

            // Then: should return 10% discount
            waitUntil { wrapper.wrappedValue == 0.10 }
            XCTAssertEqual(wrapper.wrappedValue, 0.10)

            // When: member discount is also enabled
            provider.setFlag("member_discount", to: true)

            // Then: should return 15% discount (higher priority)
            waitUntil { wrapper.wrappedValue == 0.15 }
            XCTAssertEqual(wrapper.wrappedValue, 0.15)
        }

        func test_ObservedDecides_without_provider_updates() {
            // Given: a mock provider that doesn't conform to ContextUpdatesProviding
            class NonReactiveProvider: ContextProviding {
                typealias Context = EvaluationContext
                var mockFlag = false

                func currentContext() -> EvaluationContext {
                    return EvaluationContext(flags: ["mock_flag": mockFlag])
                }
            }

            let provider = NonReactiveProvider()
            provider.mockFlag = false

            var wrapper = ObservedDecides<EvaluationContext, String>(
                provider: provider,
                decisions: [(FeatureFlagSpec(flagKey: "mock_flag"), "enabled")],
                or: "disabled"
            )
            wrapper.update()

            // Then: should work with initial value
            XCTAssertEqual(wrapper.wrappedValue, "disabled")

            // Note: Without ContextUpdatesProviding conformance,
            // the wrapper won't update reactively, but should still
            // function for the initial evaluation
        }
    }

#endif
