//
//  MockSpecificationBuilderTests.swift
//  SpecificationKitTests
//
//  Tests for the MockSpecificationBuilder utilities.
//

import XCTest
import Dispatch

@testable import SpecificationKit

final class MockSpecificationBuilderTests: XCTestCase {

    private struct TestContext {
        let flag: Bool
        let value: Int
    }

    func testAlwaysReturnsTrue() {
        // Given
        let specification = MockSpecificationBuilder<TestContext>()
            .alwaysReturns(true)
            .build()

        // When
        let result = specification.isSatisfiedBy(TestContext(flag: false, value: 1))

        // Then
        XCTAssertTrue(result)
        XCTAssertEqual(specification.callCount, 1)
        XCTAssertEqual(specification.allResults, [true])
    }

    func testAlwaysReturnsFalse() {
        // Given
        let specification = MockSpecificationBuilder<TestContext>()
            .alwaysReturns(false)
            .build()

        // When
        let result = specification.isSatisfiedBy(TestContext(flag: true, value: 10))

        // Then
        XCTAssertFalse(result)
        XCTAssertEqual(specification.callCount, 1)
        XCTAssertEqual(specification.allResults, [false])
    }

    func testConditionalBehaviorEvaluatesPredicate() {
        // Given
        let specification = MockSpecificationBuilder<TestContext>()
            .returns { $0.value > 5 }
            .build()

        // When
        let lowerResult = specification.isSatisfiedBy(TestContext(flag: false, value: 2))
        let higherResult = specification.isSatisfiedBy(TestContext(flag: true, value: 8))

        // Then
        XCTAssertFalse(lowerResult)
        XCTAssertTrue(higherResult)
        XCTAssertEqual(specification.callCount, 2)
        XCTAssertEqual(specification.allResults, [false, true])
    }

    func testSequenceBehaviorCyclesThroughResults() {
        // Given
        let specification = MockSpecificationBuilder<TestContext>()
            .withSequence([true, false])
            .build()

        // When
        let first = specification.isSatisfiedBy(TestContext(flag: true, value: 1))
        let second = specification.isSatisfiedBy(TestContext(flag: true, value: 2))
        let third = specification.isSatisfiedBy(TestContext(flag: false, value: 3))

        // Then
        XCTAssertTrue(first)
        XCTAssertFalse(second)
        XCTAssertTrue(third)
        XCTAssertEqual(specification.allResults, [true, false, true])
    }

    func testContextDependentBehaviorUsesKeyPath() {
        // Given
        let specification = MockSpecificationBuilder<TestContext>()
            .withContextBoolean(\.flag)
            .build()

        // When
        let falseResult = specification.isSatisfiedBy(TestContext(flag: false, value: 1))
        let trueResult = specification.isSatisfiedBy(TestContext(flag: true, value: 2))

        // Then
        XCTAssertFalse(falseResult)
        XCTAssertTrue(trueResult)
    }

    func testExecutionTimeAddsSyntheticDelay() {
        // Given
        let specification = MockSpecificationBuilder<TestContext>()
            .withExecutionTime(0.02)
            .alwaysReturns(true)
            .build()
        let context = TestContext(flag: true, value: 1)

        // When
        let start = Date()
        _ = specification.isSatisfiedBy(context)
        let elapsed = Date().timeIntervalSince(start)

        // Then
        XCTAssertGreaterThanOrEqual(elapsed, 0.015)
    }

    func testRecordedCallsCaptureContextAndTimestamps() {
        // Given
        let context = TestContext(flag: true, value: 99)
        let specification = MockSpecificationBuilder<TestContext>()
            .alwaysReturns(true)
            .build()

        // When
        _ = specification.isSatisfiedBy(context)
        let records = specification.recordedCalls

        // Then
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records.first?.context.flag, true)
        XCTAssertEqual(records.first?.context.value, 99)
        XCTAssertLessThan(abs(records.first?.timestamp.timeIntervalSinceNow ?? 0), 0.1)
    }

    func testResetClearsCallHistory() {
        // Given
        let specification = MockSpecificationBuilder<TestContext>()
            .alwaysReturns(true)
            .build()

        // When
        _ = specification.isSatisfiedBy(TestContext(flag: false, value: 1))
        specification.reset()

        // Then
        XCTAssertEqual(specification.callCount, 0)
        XCTAssertTrue(specification.recordedCalls.isEmpty)
    }

    func testFlakyFactoryUsesProbability() {
        // Given
        let alwaysFailing = MockSpecificationBuilder<TestContext>.flaky(successRate: 0)
        let alwaysPassing = MockSpecificationBuilder<TestContext>.flaky(successRate: 1)

        // When
        let falseResult = alwaysFailing.isSatisfiedBy(TestContext(flag: false, value: 1))
        let trueResult = alwaysPassing.isSatisfiedBy(TestContext(flag: false, value: 1))

        // Then
        XCTAssertFalse(falseResult)
        XCTAssertTrue(trueResult)
    }

    func testSlowFactoryAddsDelay() {
        // Given
        let specification = MockSpecificationBuilder<TestContext>.slow(delay: 0.01)

        // When
        let start = Date()
        _ = specification.isSatisfiedBy(TestContext(flag: true, value: 1))
        let elapsed = Date().timeIntervalSince(start)

        // Then
        XCTAssertGreaterThanOrEqual(elapsed, 0.005)
    }

    func testConcurrentEvaluationsAreThreadSafe() {
        // Given
        let specification = MockSpecificationBuilder<TestContext>()
            .returns { _ in true }
            .build()
        let contexts = (0..<50).map { TestContext(flag: $0 % 2 == 0, value: $0) }
        let queue = DispatchQueue(label: "com.specificationkit.mockSpecTests", attributes: .concurrent)
        let group = DispatchGroup()

        // When
        for context in contexts {
            group.enter()
            queue.async {
                _ = specification.isSatisfiedBy(context)
                group.leave()
            }
        }
        group.wait()

        // Then
        XCTAssertEqual(specification.callCount, contexts.count)
        XCTAssertEqual(specification.allResults.count, contexts.count)
    }
}
