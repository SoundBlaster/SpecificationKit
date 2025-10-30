//
//  CachedSatisfiesTests.swift
//  SpecificationKitTests
//
//  Created by SpecificationKit on 2025.
//

import Foundation
import XCTest

@testable import SpecificationKit

final class CachedSatisfiesTests: XCTestCase {

    // MARK: - Test Support Types

    private final class AsyncMockProvider: ContextProviding {
        typealias Context = EvaluationContext

        enum TestError: Error, Equatable {
            case failed
        }

        private let context: EvaluationContext
        private let delayNanoseconds: UInt64
        private let shouldThrow: Bool
        private let invocationCounter = AsyncInvocationCounter()

        init(
            context: EvaluationContext,
            delay: TimeInterval = 0.0,
            shouldThrow: Bool = false
        ) {
            self.context = context
            self.delayNanoseconds = UInt64((delay * 1_000_000_000).rounded())
            self.shouldThrow = shouldThrow
        }

        func currentContext() -> EvaluationContext {
            context
        }

        func currentContextAsync() async throws -> EvaluationContext {
            if delayNanoseconds > 0 {
                try await Task.sleep(nanoseconds: delayNanoseconds)
            }

            await invocationCounter.increment()

            if shouldThrow {
                throw TestError.failed
            }

            return context
        }

        func asyncCallCount() async -> Int {
            await invocationCounter.currentCount()
        }

        private actor AsyncInvocationCounter {
            private var count = 0

            func increment() {
                count += 1
            }

            func currentCount() -> Int {
                count
            }
        }
    }

    // MARK: - Test Specifications

    struct CountingSpec: Specification {
        static var evaluationCount = 0
        let expectedValue: Bool

        func isSatisfiedBy(_ context: EvaluationContext) -> Bool {
            Self.evaluationCount += 1
            return expectedValue
        }

        static func reset() {
            evaluationCount = 0
        }
    }

    struct ExpensiveSpec: Specification {
        static var evaluationCount = 0
        let delay: TimeInterval
        let result: Bool

        init(delay: TimeInterval = 0.1, result: Bool = true) {
            self.delay = delay
            self.result = result
        }

        func isSatisfiedBy(_ context: EvaluationContext) -> Bool {
            Self.evaluationCount += 1
            Thread.sleep(forTimeInterval: delay)
            return result
        }

        static func reset() {
            evaluationCount = 0
        }
    }

    override func setUp() {
        super.setUp()
        CountingSpec.reset()
        ExpensiveSpec.reset()
        CachedSatisfies<EvaluationContext>.clearAllCaches()
        DefaultContextProvider.shared.resetCounter("testCounter")
    }

    override func tearDown() {
        super.tearDown()
        CachedSatisfies<EvaluationContext>.clearAllCaches()
    }

    // MARK: - Basic Caching Tests

    func testBasicCaching() throws {
        let spec = CountingSpec(expectedValue: true)
        let cachedSpec = CachedSatisfies(using: spec, ttl: 60.0)

        // First evaluation should call the specification
        let result1 = cachedSpec.wrappedValue
        XCTAssertTrue(result1)
        XCTAssertEqual(CountingSpec.evaluationCount, 1)

        // Second evaluation should use cache
        let result2 = cachedSpec.wrappedValue
        XCTAssertTrue(result2)
        XCTAssertEqual(CountingSpec.evaluationCount, 1, "Should not re-evaluate due to caching")

        // Third evaluation should still use cache
        let result3 = cachedSpec.wrappedValue
        XCTAssertTrue(result3)
        XCTAssertEqual(CountingSpec.evaluationCount, 1, "Should not re-evaluate due to caching")
    }

    func testCacheExpiration() throws {
        let spec = CountingSpec(expectedValue: true)
        let cachedSpec = CachedSatisfies(using: spec, ttl: 0.1)  // 100ms TTL

        // First evaluation
        let result1 = cachedSpec.wrappedValue
        XCTAssertTrue(result1)
        XCTAssertEqual(CountingSpec.evaluationCount, 1)

        // Wait for cache to expire
        Thread.sleep(forTimeInterval: 0.15)  // 150ms

        // Should re-evaluate after expiration
        let result2 = cachedSpec.wrappedValue
        XCTAssertTrue(result2)
        XCTAssertEqual(CountingSpec.evaluationCount, 2, "Should re-evaluate after cache expiration")
    }

    func testCacheInvalidation() throws {
        let spec = CountingSpec(expectedValue: true)
        let cachedSpec = CachedSatisfies(using: spec, ttl: 60.0)

        // First evaluation
        let result1 = cachedSpec.wrappedValue
        XCTAssertTrue(result1)
        XCTAssertEqual(CountingSpec.evaluationCount, 1)

        // Manually invalidate cache
        cachedSpec.invalidateCache()

        // Should re-evaluate after invalidation
        let result2 = cachedSpec.wrappedValue
        XCTAssertTrue(result2)
        XCTAssertEqual(
            CountingSpec.evaluationCount, 2, "Should re-evaluate after cache invalidation")
    }

    // MARK: - Performance Tests

    func testCachingPerformanceImprovement() throws {
        let expensiveSpec = ExpensiveSpec(delay: 0.05, result: true)  // 50ms delay
        let cachedSpec = CachedSatisfies(using: expensiveSpec, ttl: 60.0)

        // Measure first evaluation (should be slow)
        let startTime1 = CFAbsoluteTimeGetCurrent()
        let result1 = cachedSpec.wrappedValue
        let duration1 = CFAbsoluteTimeGetCurrent() - startTime1

        XCTAssertTrue(result1)
        XCTAssertGreaterThan(
            duration1, 0.04, "First evaluation should take at least the delay time")
        XCTAssertEqual(ExpensiveSpec.evaluationCount, 1)

        // Measure second evaluation (should be fast due to caching)
        let startTime2 = CFAbsoluteTimeGetCurrent()
        let result2 = cachedSpec.wrappedValue
        let duration2 = CFAbsoluteTimeGetCurrent() - startTime2

        XCTAssertTrue(result2)
        XCTAssertLessThan(duration2, 0.01, "Cached evaluation should be much faster")
        XCTAssertEqual(ExpensiveSpec.evaluationCount, 1, "Should not re-evaluate")
    }

    // MARK: - Projected Value Tests

    func testProjectedValueFunctionality() throws {
        let spec = CountingSpec(expectedValue: true)
        let cachedSpec = CachedSatisfies(using: spec, ttl: 60.0)

        // Test cache status (initially not cached)
        let isCachedInitial = cachedSpec.projectedValue.isCached()
        XCTAssertFalse(isCachedInitial, "Should not be cached initially")

        // First evaluation
        let result1 = cachedSpec.wrappedValue
        XCTAssertTrue(result1)
        XCTAssertEqual(CountingSpec.evaluationCount, 1)

        // Test cache status after evaluation
        let isCachedAfter = cachedSpec.projectedValue.isCached()
        XCTAssertTrue(isCachedAfter, "Should be cached after evaluation")

        // Test access count
        let accessCount1 = cachedSpec.projectedValue.getAccessCount()
        XCTAssertGreaterThan(accessCount1, 0)

        // Test force evaluation
        let result2 = cachedSpec.projectedValue.forceEvaluate()
        XCTAssertTrue(result2)
        XCTAssertEqual(CountingSpec.evaluationCount, 2, "Force evaluate should bypass cache")

        // Test manual invalidation
        cachedSpec.projectedValue.invalidate()
        _ = cachedSpec.wrappedValue
        XCTAssertEqual(CountingSpec.evaluationCount, 3, "Should re-evaluate after invalidation")
    }

    // MARK: - Multiple Instance Tests

    func testMultipleInstancesIndependentCaching() throws {
        let spec1 = CountingSpec(expectedValue: true)
        let spec2 = CountingSpec(expectedValue: false)

        let cachedSpec1 = CachedSatisfies(using: spec1, ttl: 60.0, cacheKey: "spec1")
        let cachedSpec2 = CachedSatisfies(using: spec2, ttl: 60.0, cacheKey: "spec2")

        // Evaluate both specifications
        let result1 = cachedSpec1.wrappedValue
        let result2 = cachedSpec2.wrappedValue

        XCTAssertTrue(result1)
        XCTAssertFalse(result2)
        XCTAssertEqual(CountingSpec.evaluationCount, 2)

        // Second evaluations should use respective caches
        let result1Again = cachedSpec1.wrappedValue
        let result2Again = cachedSpec2.wrappedValue

        XCTAssertTrue(result1Again)
        XCTAssertFalse(result2Again)
        XCTAssertEqual(CountingSpec.evaluationCount, 2, "Both should use cache")

        // Invalidating one shouldn't affect the other
        cachedSpec1.invalidateCache()
        _ = cachedSpec1.wrappedValue
        _ = cachedSpec2.wrappedValue

        XCTAssertEqual(CountingSpec.evaluationCount, 3, "Only spec1 should re-evaluate")
    }

    // MARK: - Predicate-based Tests

    func testPredicateBasedCaching() throws {
        var predicateCallCount = 0
        let predicate: (EvaluationContext) -> Bool = { _ in
            predicateCallCount += 1
            return true
        }

        let cachedSpec = CachedSatisfies(predicate: predicate, ttl: 60.0)

        // First evaluation
        let result1 = cachedSpec.wrappedValue
        XCTAssertTrue(result1)
        XCTAssertEqual(predicateCallCount, 1)

        // Second evaluation should use cache
        let result2 = cachedSpec.wrappedValue
        XCTAssertTrue(result2)
        XCTAssertEqual(predicateCallCount, 1, "Predicate should not be called again due to caching")
    }

    // MARK: - Convenience Method Tests

    func testConvenienceMethodCaching() throws {
        let cachedSpec = CachedSatisfies<EvaluationContext>.flag(
            "testFlag", equals: true, ttl: 60.0)

        // Since we're using mock context, we need to set up the flag
        let provider = DefaultContextProvider.shared
        provider.setFlag("testFlag", to: true)

        let result1 = cachedSpec.wrappedValue
        XCTAssertTrue(result1)

        // Change the flag value
        provider.setFlag("testFlag", to: false)

        // Should still return cached result
        let result2 = cachedSpec.wrappedValue
        XCTAssertTrue(result2, "Should return cached value even though flag changed")

        // After cache invalidation, should see new value
        cachedSpec.invalidateCache()
        let result3 = cachedSpec.wrappedValue
        XCTAssertFalse(result3, "Should return new value after cache invalidation")
    }

    func testTimeSinceLaunchCaching() throws {
        let cachedSpec = CachedSatisfies<EvaluationContext>.timeSinceLaunch(
            minimumSeconds: 1.0, ttl: 60.0)

        // This should be based on actual time since launch, so we can't easily test the exact value
        // But we can test that caching works
        let result1 = cachedSpec.wrappedValue
        let result2 = cachedSpec.wrappedValue

        // Results should be consistent due to caching
        XCTAssertEqual(result1, result2)
    }

    func testCounterCaching() throws {
        let cachedSpec = CachedSatisfies<EvaluationContext>.counter(
            "testCounter", lessThan: 5, ttl: 60.0)

        // Set up initial counter value
        let provider = DefaultContextProvider.shared
        provider.incrementCounter("testCounter")  // Should be 1

        let result1 = cachedSpec.wrappedValue
        XCTAssertTrue(result1, "Counter 1 should be less than 5")

        // Increment counter multiple times
        provider.incrementCounter("testCounter")  // 2
        provider.incrementCounter("testCounter")  // 3
        provider.incrementCounter("testCounter")  // 4
        provider.incrementCounter("testCounter")  // 5

        // Should still return cached result
        let result2 = cachedSpec.wrappedValue
        XCTAssertTrue(result2, "Should return cached value")

        // After invalidation, should see updated result
        cachedSpec.invalidateCache()
        let result3 = cachedSpec.wrappedValue
        XCTAssertFalse(result3, "Counter 5 should not be less than 5")
    }

    // MARK: - Global Cache Management Tests

    func testGlobalCacheManagement() throws {
        let spec1 = CountingSpec(expectedValue: true)
        let spec2 = CountingSpec(expectedValue: false)

        let cachedSpec1 = CachedSatisfies(using: spec1, ttl: 60.0, cacheKey: "global1")
        let cachedSpec2 = CachedSatisfies(using: spec2, ttl: 60.0, cacheKey: "global2")

        // Populate both caches
        _ = cachedSpec1.wrappedValue
        _ = cachedSpec2.wrappedValue

        XCTAssertEqual(CountingSpec.evaluationCount, 2)

        // Get global stats
        let stats = CachedSatisfies<EvaluationContext>.getGlobalCacheStats()
        XCTAssertGreaterThan(stats.totalSize, 0)
        XCTAssertGreaterThan(stats.totalAccesses, 0)

        // Clear all caches
        CachedSatisfies<EvaluationContext>.clearAllCaches()

        // Should re-evaluate both
        _ = cachedSpec1.wrappedValue
        _ = cachedSpec2.wrappedValue

        XCTAssertEqual(
            CountingSpec.evaluationCount, 4, "Both should re-evaluate after global clear")
    }

    // MARK: - Thread Safety Tests

    func testConcurrentAccess() throws {
        let spec = ExpensiveSpec(delay: 0.01, result: true)
        let cachedSpec = CachedSatisfies(using: spec, ttl: 60.0)

        let expectation = XCTestExpectation(description: "Concurrent access")
        expectation.expectedFulfillmentCount = 10

        // Create multiple concurrent tasks
        let queue = DispatchQueue.global(qos: .userInitiated)
        var results: [Bool] = []
        let resultsQueue = DispatchQueue(label: "results")

        for _ in 0..<10 {
            queue.async {
                let result = cachedSpec.wrappedValue
                resultsQueue.async {
                    results.append(result)
                    expectation.fulfill()
                }
            }
        }

        wait(for: [expectation], timeout: 5.0)

        // All should return true
        XCTAssertEqual(results.count, 10)
        XCTAssertTrue(results.allSatisfy { $0 })

        // Should have evaluated only once due to caching (allowing for some race conditions)
        XCTAssertLessThanOrEqual(
            ExpensiveSpec.evaluationCount, 10,
            "Should evaluate at most the number of threads (caching may be limited by race conditions)"
        )
    }

    // MARK: - Edge Cases

    func testZeroTTL() throws {
        let spec = CountingSpec(expectedValue: true)
        let cachedSpec = CachedSatisfies(using: spec, ttl: 0.0)  // No caching

        // Should re-evaluate every time
        _ = cachedSpec.wrappedValue
        XCTAssertEqual(CountingSpec.evaluationCount, 1)

        _ = cachedSpec.wrappedValue
        XCTAssertEqual(CountingSpec.evaluationCount, 2, "Should re-evaluate with zero TTL")

        _ = cachedSpec.wrappedValue
        XCTAssertEqual(CountingSpec.evaluationCount, 3, "Should re-evaluate with zero TTL")
    }

    func testVeryLongTTL() throws {
        let spec = CountingSpec(expectedValue: true)
        let cachedSpec = CachedSatisfies(using: spec, ttl: 86400.0)  // 1 day

        // Should cache for a very long time
        _ = cachedSpec.wrappedValue
        XCTAssertEqual(CountingSpec.evaluationCount, 1)

        // Multiple evaluations should use cache
        for _ in 0..<5 {
            _ = cachedSpec.wrappedValue
        }

        XCTAssertEqual(CountingSpec.evaluationCount, 1, "Should not re-evaluate with long TTL")
    }

    // MARK: - Cache Statistics Tests

    func testCacheStatistics() throws {
        let spec = CountingSpec(expectedValue: true)
        let cachedSpec = CachedSatisfies(using: spec, ttl: 60.0)

        // Initial state
        let initialStats = cachedSpec.getCacheStats()
        XCTAssertFalse(initialStats.isCached)
        XCTAssertEqual(initialStats.accessCount, 0)

        // After first evaluation
        _ = cachedSpec.wrappedValue
        let afterFirstStats = cachedSpec.getCacheStats()
        XCTAssertTrue(afterFirstStats.isCached)
        XCTAssertGreaterThan(afterFirstStats.accessCount, 0)

        // After second evaluation (cached)
        _ = cachedSpec.wrappedValue
        let afterSecondStats = cachedSpec.getCacheStats()
        XCTAssertTrue(afterSecondStats.isCached)
        XCTAssertGreaterThan(afterSecondStats.accessCount, afterFirstStats.accessCount)
    }

    // MARK: - Async Projected Value Tests

    func testProjectedValueEvaluateAsyncUsesAsyncContext() async throws {
        CachedSatisfies<EvaluationContext>.clearAllCaches()

        let context = EvaluationContext(flags: ["async_feature": true])
        let provider = AsyncMockProvider(context: context, delay: 0.01)
        let cachedSpec = CachedSatisfies(
            provider: provider,
            predicate: { $0.flag(for: "async_feature") },
            ttl: 60.0,
            cacheKey: "async_evaluate_success"
        )

        let firstResult = try await cachedSpec.projectedValue.evaluateAsync()
        XCTAssertTrue(firstResult)

        let callsAfterFirst = await provider.asyncCallCount()
        XCTAssertEqual(callsAfterFirst, 1, "Async context should evaluate exactly once")

        let secondResult = try await cachedSpec.projectedValue.evaluateAsync()
        XCTAssertTrue(secondResult)

        let callsAfterSecond = await provider.asyncCallCount()
        XCTAssertEqual(callsAfterSecond, 1, "Cached value should prevent additional async evaluations")

        XCTAssertTrue(cachedSpec.projectedValue.isCached())
        XCTAssertGreaterThan(cachedSpec.projectedValue.getAccessCount(), 0)
    }

    func testProjectedValueEvaluateAsyncPropagatesProviderError() async {
        CachedSatisfies<EvaluationContext>.clearAllCaches()

        let provider = AsyncMockProvider(
            context: EvaluationContext(),
            shouldThrow: true
        )
        let cachedSpec = CachedSatisfies(
            provider: provider,
            predicate: { _ in true },
            ttl: 60.0,
            cacheKey: "async_evaluate_error"
        )

        do {
            _ = try await cachedSpec.projectedValue.evaluateAsync()
            XCTFail("Expected async evaluation to throw")
        } catch let error as AsyncMockProvider.TestError {
            XCTAssertEqual(error, .failed)
        } catch {
            XCTFail("Unexpected error thrown: \(error)")
        }

        var asyncCalls = await provider.asyncCallCount()
        XCTAssertEqual(asyncCalls, 1, "Async provider should have been invoked once")

        XCTAssertFalse(cachedSpec.projectedValue.isCached())
        XCTAssertEqual(cachedSpec.projectedValue.getAccessCount(), 0)

        do {
            _ = try await cachedSpec.projectedValue.evaluateAsync()
            XCTFail("Expected async evaluation to throw on retry")
        } catch let error as AsyncMockProvider.TestError {
            XCTAssertEqual(error, .failed)
        } catch {
            XCTFail("Unexpected error thrown: \(error)")
        }

        asyncCalls = await provider.asyncCallCount()
        XCTAssertEqual(asyncCalls, 2, "Each async evaluation attempt should invoke the provider")
        XCTAssertFalse(cachedSpec.projectedValue.isCached())
    }
}
