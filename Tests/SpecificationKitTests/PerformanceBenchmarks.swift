//
//  PerformanceBenchmarks.swift
//  SpecificationKitTests
//
//  Performance benchmarking infrastructure for SpecificationKit v3.0.0
//

import Foundation
import XCTest

@testable import SpecificationKit

/// Performance baseline requirements for SpecificationKit v3.0.0
struct PerformanceBaseline {
    static let specificationEvaluation: TimeInterval = 0.001  // 1ms target
    static let macroCompilationOverhead: Double = 0.10  // 10% max overhead
    static let memoryUsageIncrease: Double = 0.10  // 10% max increase
    static let wrapperOverhead: Double = 0.05  // 5% max overhead
    static let contextProviderLatency: TimeInterval = 0.010  // 10ms target
}

/// Comprehensive performance benchmark suite for SpecificationKit
final class PerformanceBenchmarks: XCTestCase {

    // MARK: - Specification Evaluation Performance

    func testSpecificationEvaluationPerformance() {
        let spec = CooldownIntervalSpec(eventKey: "test_action", cooldownInterval: 10.0)
        let context = EvaluationContext(
            currentDate: Date(),
            events: ["test_action": Date().addingTimeInterval(-15)]
        )

        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            for _ in 1...1000 {
                _ = spec.isSatisfiedBy(context)
            }
        }
    }

    func testComplexSpecificationPerformance() {
        let userAgeSpec = PredicateSpec<EvaluationContext> { $0.counter(for: "user_age") >= 18 }
        let subscriptionSpec = PredicateSpec<EvaluationContext> { $0.flag(for: "is_subscribed") }
        let timeSinceSpec = TimeSinceEventSpec(eventKey: "last_login", minimumInterval: 86400)

        let complexSpec = userAgeSpec.and(subscriptionSpec).and(timeSinceSpec)

        let context = EvaluationContext(
            currentDate: Date(),
            counters: ["user_age": 25],
            events: ["last_login": Date().addingTimeInterval(-90000)],
            flags: ["is_subscribed": true]
        )

        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            for _ in 1...1000 {
                _ = complexSpec.isSatisfiedBy(context)
            }
        }
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

        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            for i in 1...1000 {
                let counter = provider.getCounter("counter_\(i % 100 + 1)")
                let flag = provider.getFlag("flag_\(i % 100 + 1)")
                let event = provider.getEvent("event_\(i % 100 + 1)")

                // Use values to prevent optimization
                _ = counter + (flag ? 1 : 0) + Int(event?.timeIntervalSince1970 ?? 0)
            }
        }
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

    // MARK: - Concurrent Access Performance

    func testConcurrentContextProviderAccess() {
        let provider = DefaultContextProvider()
        let operationCount = 100

        measure(metrics: [XCTClockMetric()]) {
            let group = DispatchGroup()

            // Spawn multiple concurrent operations
            for i in 1...operationCount {
                group.enter()
                DispatchQueue.global(qos: .background).async {
                    provider.setCounter("concurrent_\(i)", to: i)
                    _ = provider.getCounter("concurrent_\(i)")
                    group.leave()
                }
            }

            group.wait()
        }
    }

    // MARK: - Cache Performance Testing

    func testContextCachePerformance() {
        let provider = DefaultContextProvider()
        let cacheKeys = Array(1...100).map { "cache_key_\($0)" }

        // Warm up cache
        for key in cacheKeys {
            provider.setFlag(key, to: true)
        }

        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            // Test cache hit performance
            for _ in 1...10000 {
                let randomKey = cacheKeys.randomElement()!
                _ = provider.getFlag(randomKey)
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
}

/// Performance validation utilities
extension PerformanceBenchmarks {

    /// Validates that performance metrics meet baseline requirements
    func validatePerformanceBaseline(executionTime: TimeInterval, baseline: TimeInterval) {
        XCTAssertLessThan(
            executionTime, baseline,
            "Performance regression detected: \(executionTime)s exceeds baseline of \(baseline)s")
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
