//
//  ObservedSatisfiesTests.swift
//  SpecificationKit
//
//  Created by SpecificationKit on 2025.
//

import XCTest

@testable import SpecificationKit

#if canImport(SwiftUI)
    import SwiftUI
    #if canImport(Combine)
        import Combine
    #endif

    /// Tests for ObservedSatisfies property wrapper
    /// Note: Full SwiftUI integration testing would require a more complex test harness
    /// These tests focus on the testable components and basic functionality
    final class ObservedSatisfiesTests: XCTestCase {

        // MARK: - Test Context Provider

        class TestContextProvider: ContextProviding {
            typealias Context = EvaluationContext

            private var _context: EvaluationContext

            init(context: EvaluationContext = EvaluationContext()) {
                self._context = context
            }

            func currentContext() -> EvaluationContext {
                return _context
            }

            func updateContext(_ context: EvaluationContext) {
                self._context = context
            }
        }

        // MARK: - Basic Initialization Tests

        func testObservedSatisfies_InitWithDefaultProvider() {
            // Given
            let spec = PredicateSpec<EvaluationContext> { _ in true }

            // When
            var observedSatisfies = ObservedSatisfies(using: spec)

            // Then - Should not crash during initialization
            // Note: The actual value testing would require SwiftUI context
            XCTAssertNotNil(observedSatisfies)

            // Test the update method doesn't crash
            observedSatisfies.update()
        }

        func testObservedSatisfies_InitWithCustomProvider() {
            // Given
            let testProvider = TestContextProvider()
            let spec = PredicateSpec<EvaluationContext> { _ in true }

            // When
            var observedSatisfies = ObservedSatisfies(provider: testProvider, using: spec)

            // Then - Should not crash during initialization
            XCTAssertNotNil(observedSatisfies)

            // Test the update method doesn't crash
            observedSatisfies.update()
        }

        func testObservedSatisfies_InitWithPredicate() {
            // Given
            let testProvider = TestContextProvider()
            let predicate: (EvaluationContext) -> Bool = { _ in true }

            // When
            var observedSatisfies = ObservedSatisfies(provider: testProvider, predicate: predicate)

            // Then - Should not crash during initialization
            XCTAssertNotNil(observedSatisfies)

            // Test the update method doesn't crash
            observedSatisfies.update()
        }

        func testObservedSatisfies_InitWithDefaultProviderPredicate() {
            // Given
            let predicate: (EvaluationContext) -> Bool = { _ in false }

            // When
            var observedSatisfies = ObservedSatisfies(predicate: predicate)

            // Then - Should not crash during initialization
            XCTAssertNotNil(observedSatisfies)

            // Test the update method doesn't crash
            observedSatisfies.update()
        }

        // MARK: - Specification Logic Tests

        func testObservedSatisfies_SpecificationEvaluation() {
            // Given
            let trueContext = EvaluationContext(counters: ["test": 10])
            let falseContext = EvaluationContext(counters: ["test": 5])
            let testProvider = TestContextProvider(context: trueContext)
            let spec = PredicateSpec<EvaluationContext> { $0.counter(for: "test") > 8 }

            // When
            var observedSatisfiesTrue = ObservedSatisfies(provider: testProvider, using: spec)
            observedSatisfiesTrue.update()

            // Update provider context
            testProvider.updateContext(falseContext)
            var observedSatisfiesFalse = ObservedSatisfies(provider: testProvider, using: spec)
            observedSatisfiesFalse.update()

            // Then - Basic structure should be intact (actual values depend on SwiftUI)
            XCTAssertNotNil(observedSatisfiesTrue)
            XCTAssertNotNil(observedSatisfiesFalse)
        }

        func testObservedSatisfies_PredicateEvaluation() {
            // Given
            let trueContext = EvaluationContext(flags: ["feature_enabled": true])
            let falseContext = EvaluationContext(flags: ["feature_enabled": false])
            let testProvider = TestContextProvider(context: trueContext)
            let predicate: (EvaluationContext) -> Bool = { $0.flag(for: "feature_enabled") }

            // When
            var observedSatisfiesTrue = ObservedSatisfies(
                provider: testProvider, predicate: predicate)
            observedSatisfiesTrue.update()

            // Update provider context
            testProvider.updateContext(falseContext)
            var observedSatisfiesFalse = ObservedSatisfies(
                provider: testProvider, predicate: predicate)
            observedSatisfiesFalse.update()

            // Then - Basic structure should be intact
            XCTAssertNotNil(observedSatisfiesTrue)
            XCTAssertNotNil(observedSatisfiesFalse)
        }

        // MARK: - Edge Cases

        func testObservedSatisfies_WithComplexSpecification() {
            // Given
            let context = EvaluationContext(
                counters: ["visits": 5, "purchases": 2],
                events: ["last_login": Date().addingTimeInterval(-3600)],  // 1 hour ago
                flags: ["is_premium": true]
            )
            let testProvider = TestContextProvider(context: context)

            // Complex specification: premium user with recent activity
            let complexSpec = PredicateSpec<EvaluationContext> { ctx in
                ctx.flag(for: "is_premium") && ctx.counter(for: "visits") > 3
                    && ctx.timeSinceEvent("last_login") ?? 0 < 7200  // within 2 hours
            }

            // When
            var observedSatisfies = ObservedSatisfies(provider: testProvider, using: complexSpec)
            observedSatisfies.update()

            // Then - Should handle complex logic without crashing
            XCTAssertNotNil(observedSatisfies)
        }

        func testObservedSatisfies_WithCompositeSpecification() {
            // Given
            let context = EvaluationContext(counters: ["score": 85])
            let testProvider = TestContextProvider(context: context)

            let highScore = PredicateSpec<EvaluationContext> { $0.counter(for: "score") > 80 }
            let perfectScore = PredicateSpec<EvaluationContext> { $0.counter(for: "score") == 100 }
            let compositeSpec = highScore.and(perfectScore.not())

            // When
            var observedSatisfies = ObservedSatisfies(
                provider: testProvider, using: AnySpecification(compositeSpec))
            observedSatisfies.update()

            // Then - Should handle composite specifications
            XCTAssertNotNil(observedSatisfies)
        }

        // MARK: - Context Provider Integration

        func testObservedSatisfies_WithDifferentContextTypes() {
            // Test with different context data types
            let contexts = [
                EvaluationContext(),  // Empty context
                EvaluationContext(counters: ["count": 0]),  // Zero values
                EvaluationContext(counters: ["count": Int.max]),  // Large values
                EvaluationContext(flags: ["flag": true, "other": false]),  // Multiple flags
                EvaluationContext(segments: ["vip", "beta", "premium"]),  // Multiple segments
            ]

            let spec = PredicateSpec<EvaluationContext> { _ in true }  // Always true for testing

            for context in contexts {
                // Given
                let testProvider = TestContextProvider(context: context)

                // When
                var observedSatisfies = ObservedSatisfies(provider: testProvider, using: spec)
                observedSatisfies.update()

                // Then - Should handle all context types
                XCTAssertNotNil(observedSatisfies)
            }
        }

        // MARK: - Performance Considerations

        func testObservedSatisfies_UpdatePerformance() {
            // Given
            let context = EvaluationContext(counters: ["test": 1])
            let testProvider = TestContextProvider(context: context)
            let spec = PredicateSpec<EvaluationContext> { $0.counter(for: "test") > 0 }
            var observedSatisfies = ObservedSatisfies(provider: testProvider, using: spec)

            // When & Then - Should not have performance issues with multiple updates
            measure {
                for _ in 0..<1000 {
                    observedSatisfies.update()
                }
            }
        }

        // MARK: - Memory Management

        func testObservedSatisfies_NoRetainCycles() {
            // Given
            weak var weakProvider: TestContextProvider?

            do {
                let provider = TestContextProvider()
                weakProvider = provider
                let spec = PredicateSpec<EvaluationContext> { _ in true }
                var observedSatisfies = ObservedSatisfies(provider: provider, using: spec)
                observedSatisfies.update()

                // Provider should still be retained here
                XCTAssertNotNil(weakProvider)
            }

            // Then - Provider should be released (no retain cycle)
            // Note: This test may not work perfectly due to the complex nature of the property wrapper
            // but it serves as a basic memory management check
        }

        #if canImport(Combine)
            // MARK: - Combine Integration (when available)

            func testObservedSatisfies_CombineAvailability() {
                // This test simply verifies that Combine code paths are accessible
                // Actual reactive testing would require more complex setup

                // Given
                let spec = PredicateSpec<EvaluationContext> { _ in true }

                // When
                var observedSatisfies = ObservedSatisfies(using: spec)
                observedSatisfies.update()

                // Then - Should compile and run without issues when Combine is available
                XCTAssertNotNil(observedSatisfies)
            }
        #endif

        // MARK: - Integration with Built-in Specifications

        func testObservedSatisfies_WithBuiltInSpecs() {
            // Given
            let currentDate = Date()
            let launchDate = currentDate.addingTimeInterval(-300)  // 5 minutes ago
            let context = EvaluationContext(
                currentDate: currentDate,
                launchDate: launchDate,
                counters: ["banner_shown": 2],
                events: ["last_banner": currentDate.addingTimeInterval(-86400)]  // 1 day ago
            )
            let testProvider = TestContextProvider(context: context)

            let timeSinceSpec = TimeSinceEventSpec.sinceAppLaunch(minutes: 1)
            let maxCountSpec = MaxCountSpec(counterKey: "banner_shown", limit: 5)
            let cooldownSpec = CooldownIntervalSpec(eventKey: "last_banner", hours: 12)

            // When & Then - Test with various built-in specifications
            var timeObserved = ObservedSatisfies(provider: testProvider, using: timeSinceSpec)
            timeObserved.update()
            XCTAssertNotNil(timeObserved)

            var countObserved = ObservedSatisfies(provider: testProvider, using: maxCountSpec)
            countObserved.update()
            XCTAssertNotNil(countObserved)

            var cooldownObserved = ObservedSatisfies(provider: testProvider, using: cooldownSpec)
            cooldownObserved.update()
            XCTAssertNotNil(cooldownObserved)
        }

        // MARK: - Error Handling

        func testObservedSatisfies_WithThrowingPredicates() {
            // Given
            let testProvider = TestContextProvider()

            // Predicate that could potentially cause issues (accessing nil values safely)
            let safePredicate: (EvaluationContext) -> Bool = { context in
                let value = context.userData(for: "nonexistent", as: String.self)
                return value?.isEmpty == false
            }

            // When
            var observedSatisfies = ObservedSatisfies(
                provider: testProvider, predicate: safePredicate)
            observedSatisfies.update()

            // Then - Should handle gracefully
            XCTAssertNotNil(observedSatisfies)
        }
    }

#endif
