//
//  SpecsMacroTests.swift
//  SpecificationKitTests
//
//  Created by SpecificationKit on 2024.
//

import XCTest

@testable import SpecificationKit

final class SpecsMacroTests: XCTestCase {

    // MARK: - Integration Tests

    /// Test that simulates what the @specs macro should generate for a single specification
    func testSpecsMacroFunctionality_SingleSpecification() {
        // Simulate what @specs(MaxCountSpec(counterKey: "test", limit: 3)) should generate
        struct TestSpec: Specification {
            private let composite: AnySpecification<EvaluationContext>

            init() {
                let specChain = MaxCountSpec(counterKey: "test", limit: 3)
                self.composite = AnySpecification(specChain)
            }

            func isSatisfiedBy(_ candidate: EvaluationContext) -> Bool {
                composite.isSatisfiedBy(candidate)
            }
        }

        let spec = TestSpec()

        // Test with counter below limit
        let context1 = EvaluationContext(counters: ["test": 2])
        XCTAssertTrue(spec.isSatisfiedBy(context1))

        // Test with counter at limit
        let context2 = EvaluationContext(counters: ["test": 3])
        XCTAssertFalse(spec.isSatisfiedBy(context2))

        // Test with counter above limit
        let context3 = EvaluationContext(counters: ["test": 5])
        XCTAssertFalse(spec.isSatisfiedBy(context3))
    }

    /// Test that simulates what the @specs macro should generate for two specifications
    func testSpecsMacroFunctionality_TwoSpecifications() {
        // Simulate what @specs(MaxCountSpec(...), TimeSinceEventSpec(...)) should generate
        struct TestSpec: Specification {
            private let composite: AnySpecification<EvaluationContext>

            init() {
                let specChain = MaxCountSpec(counterKey: "display_count", limit: 3)
                    .and(TimeSinceEventSpec(eventKey: "last_shown", minimumInterval: 3600))
                self.composite = AnySpecification(specChain)
            }

            func isSatisfiedBy(_ candidate: EvaluationContext) -> Bool {
                composite.isSatisfiedBy(candidate)
            }
        }

        let spec = TestSpec()
        let currentDate = Date()

        // Test case 1: Both conditions satisfied (count below limit, no previous event)
        let context1 = EvaluationContext(
            currentDate: currentDate,
            counters: ["display_count": 2],
            events: [:]
        )
        XCTAssertTrue(spec.isSatisfiedBy(context1))

        // Test case 2: Count at limit, no previous event (should fail)
        let context2 = EvaluationContext(
            currentDate: currentDate,
            counters: ["display_count": 3],
            events: [:]
        )
        XCTAssertFalse(spec.isSatisfiedBy(context2))

        // Test case 3: Count below limit, recent event (should fail)
        let recentEvent = currentDate.addingTimeInterval(-1800)  // 30 minutes ago
        let context3 = EvaluationContext(
            currentDate: currentDate,
            counters: ["display_count": 2],
            events: ["last_shown": recentEvent]
        )
        XCTAssertFalse(spec.isSatisfiedBy(context3))

        // Test case 4: Count below limit, old event (should pass)
        let oldEvent = currentDate.addingTimeInterval(-7200)  // 2 hours ago
        let context4 = EvaluationContext(
            currentDate: currentDate,
            counters: ["display_count": 2],
            events: ["last_shown": oldEvent]
        )
        XCTAssertTrue(spec.isSatisfiedBy(context4))
    }

    /// Test that simulates what the @specs macro should generate for three specifications
    func testSpecsMacroFunctionality_ThreeSpecifications() {
        // Simulate what @specs(MaxCountSpec(...), TimeSinceEventSpec(...), CooldownIntervalSpec(...)) should generate
        struct TestSpec: Specification {
            private let composite: AnySpecification<EvaluationContext>

            init() {
                let specChain = MaxCountSpec(counterKey: "display_count", limit: 5)
                    .and(TimeSinceEventSpec(eventKey: "last_shown", minimumInterval: 86400))
                    .and(CooldownIntervalSpec(eventKey: "user_dismissed", cooldownInterval: 604800))
                self.composite = AnySpecification(specChain)
            }

            func isSatisfiedBy(_ candidate: EvaluationContext) -> Bool {
                composite.isSatisfiedBy(candidate)
            }
        }

        let spec = TestSpec()
        let currentDate = Date()

        // Test case 1: All conditions satisfied
        let oldShowEvent = currentDate.addingTimeInterval(-172800)  // 2 days ago
        let oldDismissEvent = currentDate.addingTimeInterval(-1_209_600)  // 2 weeks ago
        let context1 = EvaluationContext(
            currentDate: currentDate,
            counters: ["display_count": 3],
            events: [
                "last_shown": oldShowEvent,
                "user_dismissed": oldDismissEvent,
            ]
        )
        XCTAssertTrue(spec.isSatisfiedBy(context1))

        // Test case 2: Count exceeds limit
        let context2 = EvaluationContext(
            currentDate: currentDate,
            counters: ["display_count": 5],
            events: [
                "last_shown": oldShowEvent,
                "user_dismissed": oldDismissEvent,
            ]
        )
        XCTAssertFalse(spec.isSatisfiedBy(context2))

        // Test case 3: Recent show event
        let recentShowEvent = currentDate.addingTimeInterval(-3600)  // 1 hour ago
        let context3 = EvaluationContext(
            currentDate: currentDate,
            counters: ["display_count": 3],
            events: [
                "last_shown": recentShowEvent,
                "user_dismissed": oldDismissEvent,
            ]
        )
        XCTAssertFalse(spec.isSatisfiedBy(context3))

        // Test case 4: Recent dismiss event
        let recentDismissEvent = currentDate.addingTimeInterval(-86400)  // 1 day ago
        let context4 = EvaluationContext(
            currentDate: currentDate,
            counters: ["display_count": 3],
            events: [
                "last_shown": oldShowEvent,
                "user_dismissed": recentDismissEvent,
            ]
        )
        XCTAssertFalse(spec.isSatisfiedBy(context4))
    }

    /// Test the macro functionality with PredicateSpec
    func testSpecsMacroFunctionality_WithPredicateSpec() {
        // Simulate what @specs(MaxCountSpec(...), PredicateSpec(...)) should generate
        struct TestSpec: Specification {
            private let composite: AnySpecification<EvaluationContext>

            init() {
                let specChain = MaxCountSpec(counterKey: "attempts", limit: 3)
                    .and(
                        PredicateSpec<EvaluationContext> { context in
                            context.flag(for: "feature_enabled")
                        })
                self.composite = AnySpecification(specChain)
            }

            func isSatisfiedBy(_ candidate: EvaluationContext) -> Bool {
                composite.isSatisfiedBy(candidate)
            }
        }

        let spec = TestSpec()

        // Test case 1: Both conditions satisfied
        let context1 = EvaluationContext(
            counters: ["attempts": 2],
            flags: ["feature_enabled": true]
        )
        XCTAssertTrue(spec.isSatisfiedBy(context1))

        // Test case 2: Counter satisfied but flag disabled
        let context2 = EvaluationContext(
            counters: ["attempts": 2],
            flags: ["feature_enabled": false]
        )
        XCTAssertFalse(spec.isSatisfiedBy(context2))

        // Test case 3: Flag enabled but counter at limit
        let context3 = EvaluationContext(
            counters: ["attempts": 3],
            flags: ["feature_enabled": true]
        )
        XCTAssertFalse(spec.isSatisfiedBy(context3))

        // Test case 4: Neither condition satisfied
        let context4 = EvaluationContext(
            counters: ["attempts": 5],
            flags: ["feature_enabled": false]
        )
        XCTAssertFalse(spec.isSatisfiedBy(context4))
    }

    /// Test the macro functionality with convenience static methods
    func testSpecsMacroFunctionality_WithConvenienceMethods() {
        // Simulate what @specs(MaxCountSpec.onlyOnce(...), TimeSinceEventSpec(...)) should generate
        struct TestSpec: Specification {
            private let composite: AnySpecification<EvaluationContext>

            init() {
                let specChain = MaxCountSpec.onlyOnce("first_time")
                    .and(TimeSinceEventSpec(eventKey: "app_launch", seconds: 30))
                self.composite = AnySpecification(specChain)
            }

            func isSatisfiedBy(_ candidate: EvaluationContext) -> Bool {
                composite.isSatisfiedBy(candidate)
            }
        }

        let spec = TestSpec()
        let currentDate = Date()
        let launchTime = currentDate.addingTimeInterval(-60)  // 1 minute ago

        // Test case 1: Never done before, enough time since launch
        let context1 = EvaluationContext(
            currentDate: currentDate,
            launchDate: launchTime,
            counters: ["first_time": 0],
            events: ["app_launch": launchTime]
        )
        XCTAssertTrue(spec.isSatisfiedBy(context1))

        // Test case 2: Already done once
        let context2 = EvaluationContext(
            currentDate: currentDate,
            launchDate: launchTime,
            counters: ["first_time": 1],
            events: ["app_launch": launchTime]
        )
        XCTAssertFalse(spec.isSatisfiedBy(context2))

        // Test case 3: Never done before, but not enough time since launch
        let recentLaunch = currentDate.addingTimeInterval(-15)  // 15 seconds ago
        let context3 = EvaluationContext(
            currentDate: currentDate,
            launchDate: recentLaunch,
            counters: ["first_time": 0],
            events: ["app_launch": recentLaunch]
        )
        XCTAssertFalse(spec.isSatisfiedBy(context3))
    }

    /// Test error conditions that the macro should handle
    func testSpecsMacroFunctionality_EmptyChain() {
        // While the macro should prevent this, test what happens with an empty chain
        // This simulates the error case where no specifications are provided

        // We can't actually test the macro error directly, but we can verify that
        // our specification pattern works correctly with a single always-true spec
        struct TestSpec: Specification {
            private let composite: AnySpecification<EvaluationContext>

            init() {
                let specChain = PredicateSpec<EvaluationContext>.alwaysTrue()
                self.composite = AnySpecification(specChain)
            }

            func isSatisfiedBy(_ candidate: EvaluationContext) -> Bool {
                composite.isSatisfiedBy(candidate)
            }
        }

        let spec = TestSpec()
        let context = EvaluationContext()

        XCTAssertTrue(spec.isSatisfiedBy(context))
    }

    /// Test that the generated pattern is type-safe and works with the Specification protocol
    func testSpecsMacroFunctionality_TypeSafety() {
        // Test that the generated code maintains type safety
        struct TestSpec: Specification {
            private let composite: AnySpecification<EvaluationContext>

            init() {
                let specChain = MaxCountSpec(counterKey: "test", limit: 1)
                self.composite = AnySpecification(specChain)
            }

            func isSatisfiedBy(_ candidate: EvaluationContext) -> Bool {
                composite.isSatisfiedBy(candidate)
            }
        }

        let spec = TestSpec()

        // Verify it conforms to Specification protocol
        XCTAssertTrue(spec is Specification)

        // Verify it can be used in specification operations
        let combinedSpec = spec.and(MaxCountSpec(counterKey: "other", limit: 2))
        let context = EvaluationContext(counters: ["test": 0, "other": 1])

        XCTAssertTrue(combinedSpec.isSatisfiedBy(context))

        // Verify it can be wrapped in AnySpecification
        let anySpec = AnySpecification(spec)
        XCTAssertTrue(anySpec.isSatisfiedBy(context))
    }
}
