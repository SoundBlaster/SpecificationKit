import XCTest
@testable import SpecificationKit

final class SatisfiesWrapperTests: XCTestCase {
    private struct ManualContext {
        var isEnabled: Bool
        var threshold: Int
        var count: Int
    }

    private struct EnabledSpec: Specification {
        func isSatisfiedBy(_ candidate: ManualContext) -> Bool { candidate.isEnabled }
    }

    func test_manualContext_withSpecificationInstance() {
        // Given
        struct Harness {
            @Satisfies(context: ManualContext(isEnabled: true, threshold: 3, count: 0),
                       using: EnabledSpec())
            var isEnabled: Bool
        }

        // When
        let harness = Harness()

        // Then
        XCTAssertTrue(harness.isEnabled)
    }

    func test_manualContext_withPredicate() {
        // Given
        struct Harness {
            @Satisfies(
                context: ManualContext(isEnabled: false, threshold: 2, count: 1),
                predicate: { context in
                    context.count < context.threshold
                }
            )
            var canIncrement: Bool
        }

        // When
        let harness = Harness()

        // Then
        XCTAssertTrue(harness.canIncrement)
    }

    func test_manualContext_evaluateAsync_returnsManualValue() async throws {
        // Given
        let context = ManualContext(isEnabled: true, threshold: 1, count: 0)
        let wrapper = Satisfies(
            context: context,
            asyncContext: { context },
            using: EnabledSpec()
        )

        // When
        let result = try await wrapper.evaluateAsync()

        // Then
        XCTAssertTrue(result)
    }

    // MARK: - Parameterized Wrapper Tests (Factory Pattern)

    func test_parameterizedWrapper_withDefaultProvider_CooldownIntervalSpec() {
        // Given
        let provider = DefaultContextProvider.shared
        provider.recordEvent(for: "banner", at: Date().addingTimeInterval(-20))

        struct Harness {
            @Satisfies(using: CooldownIntervalSpec.self) {
                CooldownIntervalSpec(eventKey: "banner", cooldownInterval: 10)
            }
            var canShowBanner: Bool
        }

        // When
        let harness = Harness()

        // Then - 20 seconds passed, cooldown of 10 seconds should be satisfied
        XCTAssertTrue(harness.canShowBanner)
    }

    func test_parameterizedWrapper_withDefaultProvider_failsWhenCooldownNotMet() {
        // Given
        let provider = DefaultContextProvider.shared
        provider.recordEvent(for: "notification", at: Date().addingTimeInterval(-5))

        struct Harness {
            @Satisfies(using: CooldownIntervalSpec.self) {
                CooldownIntervalSpec(eventKey: "notification", cooldownInterval: 10)
            }
            var canShowNotification: Bool
        }

        // When
        let harness = Harness()

        // Then - Only 5 seconds passed, cooldown of 10 seconds should NOT be satisfied
        XCTAssertFalse(harness.canShowNotification)
    }

    func test_parameterizedWrapper_withCustomProvider() {
        // Given
        let mockProvider = MockContextProvider()
        mockProvider.recordEvent(for: "dialog", at: Date().addingTimeInterval(-30))

        struct Harness {
            @Satisfies(provider: mockProvider, using: CooldownIntervalSpec.self) {
                CooldownIntervalSpec(eventKey: "dialog", cooldownInterval: 20)
            }
            var canShowDialog: Bool
        }

        // When
        let harness = Harness()

        // Then
        XCTAssertTrue(harness.canShowDialog)
    }

    func test_parameterizedWrapper_withMaxCountSpec() {
        // Given
        let provider = DefaultContextProvider.shared
        provider.increment(counter: "attempts")
        provider.increment(counter: "attempts")

        struct Harness {
            @Satisfies(using: MaxCountSpec.self) {
                MaxCountSpec(counterKey: "attempts", maximumCount: 5)
            }
            var canAttempt: Bool
        }

        // When
        let harness = Harness()

        // Then - 2 attempts < 5 max
        XCTAssertTrue(harness.canAttempt)
    }

    func test_parameterizedWrapper_withMaxCountSpec_failsWhenExceeded() {
        // Given
        let provider = DefaultContextProvider.shared
        provider.increment(counter: "retries")
        provider.increment(counter: "retries")
        provider.increment(counter: "retries")
        provider.increment(counter: "retries")
        provider.increment(counter: "retries")

        struct Harness {
            @Satisfies(using: MaxCountSpec.self) {
                MaxCountSpec(counterKey: "retries", maximumCount: 3)
            }
            var canRetry: Bool
        }

        // When
        let harness = Harness()

        // Then - 5 retries >= 3 max
        XCTAssertFalse(harness.canRetry)
    }

    func test_parameterizedWrapper_withTimeSinceEventSpec() {
        // Given
        let provider = DefaultContextProvider.shared
        provider.recordEvent(for: "launch", at: Date().addingTimeInterval(-100))

        struct Harness {
            @Satisfies(using: TimeSinceEventSpec.self) {
                TimeSinceEventSpec(eventKey: "launch", minimumInterval: 50)
            }
            var hasBeenLongEnough: Bool
        }

        // When
        let harness = Harness()

        // Then - 100 seconds passed >= 50 minimum
        XCTAssertTrue(harness.hasBeenLongEnough)
    }

    func test_parameterizedWrapper_withManualContext() {
        // Given
        let context = EvaluationContext(
            counters: ["clicks": 3],
            flags: [:],
            events: [:],
            currentDate: Date(),
            launchDate: Date(),
            calendar: .current
        )

        struct Harness {
            @Satisfies(context: context, using: MaxCountSpec.self) {
                MaxCountSpec(counterKey: "clicks", maximumCount: 5)
            }
            var canClick: Bool
        }

        // When
        let harness = Harness()

        // Then
        XCTAssertTrue(harness.canClick)
    }
}
