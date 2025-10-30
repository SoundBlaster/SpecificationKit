//
//  PerformanceBenchmarks.swift
//  SpecificationKitBenchmarks
//
//  Performance benchmarking infrastructure for SpecificationKit v3.0.0
//

import Foundation
import XCTest

@testable import SpecificationKit

/// Comprehensive performance benchmark suite for SpecificationKit
final class PerformanceBenchmarks: XCTestCase {
    private var baselineValidator: BaselineValidator { BaselineValidator(baseline: .default) }

    // MARK: - Specification Evaluation Performance

    func testSpecificationEvaluationPerformance() {
        let spec = CooldownIntervalSpec(eventKey: "test_action", cooldownInterval: 10.0)
        let context = createPerformanceTestContext()

        let startTime = CFAbsoluteTimeGetCurrent()
        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            for _ in 1...1000 {
                _ = spec.isSatisfiedBy(context)
            }
        }
        let executionTime = (CFAbsoluteTimeGetCurrent() - startTime) / 1000

        assertBenchmarkMetric(.specificationEvaluation(executionTime))
    }

    func testComplexSpecificationPerformance() {
        let userAgeSpec = PredicateSpec<EvaluationContext> { $0.counter(for: "user_age") >= 18 }
        let subscriptionSpec = PredicateSpec<EvaluationContext> { $0.flag(for: "is_premium") }
        let timeSinceSpec = TimeSinceEventSpec(eventKey: "last_login", minimumInterval: 86400)

        let complexSpec = userAgeSpec.and(subscriptionSpec).and(timeSinceSpec)
        let context = createPerformanceTestContext()

        let startTime = CFAbsoluteTimeGetCurrent()
        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            for _ in 1...1000 {
                _ = complexSpec.isSatisfiedBy(context)
            }
        }
        let executionTime = (CFAbsoluteTimeGetCurrent() - startTime) / 1000

        assertBenchmarkMetric(.specificationEvaluation(executionTime))
    }

    // MARK: - Property Wrapper Performance

    func testDirectSpecificationPerformance() {
        let spec = PredicateSpec<String> { $0.count > 5 }
        let testString = "Hello World"

        measure(metrics: [XCTClockMetric()]) {
            for _ in 1...10000 {
                _ = spec.isSatisfiedBy(testString)
            }
        }
    }

    // MARK: - Context Provider Performance

    func testContextProviderPerformance() {
        let provider = DefaultContextProvider()

        // Pre-populate with test data
        for i in 1...100 {
            provider.setCounter("counter_\(i)", to: i)
            provider.setFlag("flag_\(i)", to: i % 2 == 0)
            provider.recordEvent("event_\(i)", at: Date().addingTimeInterval(-Double(i)))
        }

        let startTime = CFAbsoluteTimeGetCurrent()
        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            for i in 1...1000 {
                let counter = provider.getCounter("counter_\(i % 100 + 1)")
                let flag = provider.getFlag("flag_\(i % 100 + 1)")
                let event = provider.getEvent("event_\(i % 100 + 1)")

                // Use values to prevent optimization
                _ = counter + (flag ? 1 : 0) + Int(event?.timeIntervalSince1970 ?? 0)
            }
        }
        let executionTime = (CFAbsoluteTimeGetCurrent() - startTime) / 1000

        assertBenchmarkMetric(.contextProviderLatency(executionTime))
    }

    // MARK: - AnySpecification Performance

    func testAnySpecificationPerformance() {
        let originalSpec = PredicateSpec<Int> { $0 > 50 }
        let erasedSpec = AnySpecification(originalSpec)
        let testValue = 75

        measure(metrics: [XCTClockMetric()]) {
            for _ in 1...10000 {
                _ = erasedSpec.isSatisfiedBy(testValue)
            }
        }
    }

    // MARK: - Memory Allocation Profiling

    func testSpecificationMemoryUsage() {
        measure(metrics: [XCTMemoryMetric()]) {
            var specs: [AnySpecification<EvaluationContext>] = []

            for i in 1...1000 {
                let spec = MaxCountSpec(counterKey: "test_\(i)", limit: i)
                specs.append(AnySpecification(spec))
            }

            let context = EvaluationContext(counters: ["test_500": 250])
            for spec in specs {
                _ = spec.isSatisfiedBy(context)
            }
        }
    }

    // MARK: - Profiler Integration Tests

    func testProfilerIntegration() {
        let profiler = SpecificationProfiler.shared
        profiler.reset()

        let spec = PredicateSpec<Int> { $0 > 10 }

        measure(metrics: [XCTClockMetric()]) {
            for i in 1...1000 {
                _ = profiler.profile(spec, context: i)
            }
        }

        let profileData = profiler.getProfileData()
        XCTAssertFalse(profileData.isEmpty, "Profiler should have collected data")

        let report = profiler.generateReport()
        XCTAssertTrue(report.contains("PredicateSpec"), "Report should contain specification type")
    }

    // MARK: - CachedSatisfies Performance

    /// Tests CachedSatisfies performance against baseline requirements
    func testCachedSatisfiesPerformance() {
        // Create an expensive specification that takes time to evaluate
        struct ExpensiveSpec: Specification {
            func isSatisfiedBy(_ context: EvaluationContext) -> Bool {
                // Simulate expensive computation
                usleep(100)  // 0.1ms delay
                return context.counter(for: "test") < 100
            }
        }

        let expensiveSpec = ExpensiveSpec()
        let cachedSpec = CachedSatisfies(using: expensiveSpec, ttl: 60.0)

        _ = EvaluationContext(
            currentDate: Date(),
            counters: ["test": 50]
        )

        // Prime the cache with first evaluation
        _ = cachedSpec.wrappedValue

        // Measure cached evaluation performance
        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            for _ in 1...1000 {
                _ = cachedSpec.wrappedValue
            }
        }
    }

    /// Tests CachedSatisfies cache miss performance
    func testCachedSatisfiesCacheMissPerformance() {
        struct ExpensiveSpec: Specification {
            func isSatisfiedBy(_ context: EvaluationContext) -> Bool {
                usleep(50)  // 0.05ms simulated computation
                return context.counter(for: "value") > 10
            }
        }

        let expensiveSpec = ExpensiveSpec()
        let cachedSpec = CachedSatisfies(using: expensiveSpec, ttl: 60.0)

        measure(metrics: [XCTClockMetric()]) {
            // Clear cache to force miss on each iteration
            for _ in 1...10 {
                CachedSatisfies<EvaluationContext>.clearAllCaches()
                _ = cachedSpec.wrappedValue
            }
        }
    }

    /// Tests CachedSatisfies cache hit performance
    func testCachedSatisfiesCacheHitPerformance() {
        let fastSpec = PredicateSpec<EvaluationContext> { $0.counter(for: "value") > 10 }
        let cachedSpec = CachedSatisfies(using: fastSpec, ttl: 60.0)

        // Prime the cache
        _ = cachedSpec.wrappedValue

        let startTime = CFAbsoluteTimeGetCurrent()
        measure(metrics: [XCTClockMetric()]) {
            for _ in 1...1000 {
                _ = cachedSpec.wrappedValue
            }
        }
        let avgCacheHitTime = (CFAbsoluteTimeGetCurrent() - startTime) / 1000

        assertBenchmarkMetric(
            .custom(
                name: "CachedSatisfies Cache Hit",
                value: avgCacheHitTime,
                threshold: BenchmarkBaseline.default.specificationEvaluation * 0.1,
                unit: .seconds
            )
        )
    }

    /// Tests CachedSatisfies memory usage and cleanup
    func testCachedSatisfiesMemoryPerformance() {
        let spec = PredicateSpec<EvaluationContext> { _ in true }

        // Create many cached specifications to test memory usage
        var cachedSpecs: [CachedSatisfies<EvaluationContext>] = []

        measure(metrics: [XCTMemoryMetric()]) {
            for i in 1...100 {
                let cachedSpec = CachedSatisfies(using: spec, ttl: 60.0, cacheKey: "test_\(i)")
                cachedSpecs.append(cachedSpec)
                _ = cachedSpec.wrappedValue
            }
        }

        // Test global cache cleanup
        CachedSatisfies<EvaluationContext>.clearAllCaches()
        let stats = CachedSatisfies<EvaluationContext>.getGlobalCacheStats()
        XCTAssertEqual(stats.totalSize, 0, "Cache should be empty after clearAllCaches()")
    }
}

// MARK: - Performance validation utilities
extension PerformanceBenchmarks {
    func assertBenchmarkMetric(
        _ metric: BenchmarkMetric,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let result = baselineValidator.validate(metric)
        if case let .regression(regressions) = result {
            let message = regressions
                .map { $0.localizedDescription }
                .joined(separator: "\n")
            XCTFail(message, file: file, line: line)
        }
    }

    /// Creates a standardized performance context for consistent testing
    func createPerformanceTestContext() -> EvaluationContext {
        return EvaluationContext(
            currentDate: Date(),
            launchDate: Date().addingTimeInterval(-3600),  // 1 hour ago
            counters: [
                "user_age": 25,
                "login_count": 15,
                "feature_usage": 8,
            ],
            events: [
                "last_login": Date().addingTimeInterval(-1800),  // 30 minutes ago
                "last_purchase": Date().addingTimeInterval(-86400),  // 1 day ago
                "app_opened": Date().addingTimeInterval(-300),  // 5 minutes ago
            ],
            flags: [
                "is_premium": true,
                "dark_mode": false,
                "notifications_enabled": true,
            ]
        )
    }
}
