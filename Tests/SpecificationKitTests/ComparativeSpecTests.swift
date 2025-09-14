//
//  ComparativeSpecTests.swift
//  SpecificationKitTests
//
//  Created by SpecificationKit on 2024.
//

import XCTest

@testable import SpecificationKit

final class ComparativeSpecTests: XCTestCase {

    // Test context
    struct ComparisonContext {
        var currentValue: Double
        var threshold: Double
        var historicalData: [Double]
    }

    // MARK: - Initialization Tests

    func testComparativeSpec_initWithDecisionSpec_succeeds() {
        // Arrange
        let valueSpec = KeyPathDecisionSpec(keyPath: \ComparisonContext.currentValue)

        // Act & Assert
        XCTAssertNoThrow {
            let _ = ComparativeSpec<ComparisonContext, Double>(
                comparing: valueSpec,
                to: .greaterThan(10.0)
            )
        }
    }

    func testComparativeSpec_initWithKeyPath_succeeds() {
        // Act & Assert
        XCTAssertNoThrow {
            let _ = ComparativeSpec<ComparisonContext, Double>(
                keyPath: \.currentValue,
                to: .greaterThan(10.0)
            )
        }
    }

    // MARK: - Fixed Value Comparison Tests

    func testComparativeSpec_greaterThan_fixedValue_returnsTrue() {
        // Arrange
        let spec = ComparativeSpec<ComparisonContext, Double>(
            keyPath: \.currentValue,
            to: .greaterThan(10.0)
        )
        let context = ComparisonContext(currentValue: 15.0, threshold: 0, historicalData: [])

        // Act
        let result = spec.isSatisfiedBy(context)

        // Assert
        XCTAssertTrue(result)
    }

    func testComparativeSpec_greaterThan_fixedValue_returnsFalse() {
        // Arrange
        let spec = ComparativeSpec<ComparisonContext, Double>(
            keyPath: \.currentValue,
            to: .greaterThan(10.0)
        )
        let context = ComparisonContext(currentValue: 5.0, threshold: 0, historicalData: [])

        // Act
        let result = spec.isSatisfiedBy(context)

        // Assert
        XCTAssertFalse(result)
    }

    func testComparativeSpec_lessThan_fixedValue_returnsTrue() {
        // Arrange
        let spec = ComparativeSpec<ComparisonContext, Double>(
            keyPath: \.currentValue,
            to: .lessThan(10.0)
        )
        let context = ComparisonContext(currentValue: 5.0, threshold: 0, historicalData: [])

        // Act
        let result = spec.isSatisfiedBy(context)

        // Assert
        XCTAssertTrue(result)
    }

    func testComparativeSpec_equalTo_fixedValue_returnsTrue() {
        // Arrange
        let spec = ComparativeSpec<ComparisonContext, Double>(
            keyPath: \.currentValue,
            to: .equalTo(10.0)
        )
        let context = ComparisonContext(currentValue: 10.0, threshold: 0, historicalData: [])

        // Act
        let result = spec.isSatisfiedBy(context)

        // Assert
        XCTAssertTrue(result)
    }

    func testComparativeSpec_between_fixedValues_returnsTrue() {
        // Arrange
        let spec = ComparativeSpec<ComparisonContext, Double>(
            keyPath: \.currentValue,
            to: .between(5.0, 15.0)
        )
        let context = ComparisonContext(currentValue: 10.0, threshold: 0, historicalData: [])

        // Act
        let result = spec.isSatisfiedBy(context)

        // Assert
        XCTAssertTrue(result)
    }

    func testComparativeSpec_between_fixedValues_returnsFalse() {
        // Arrange
        let spec = ComparativeSpec<ComparisonContext, Double>(
            keyPath: \.currentValue,
            to: .between(5.0, 15.0)
        )
        let context = ComparisonContext(currentValue: 20.0, threshold: 0, historicalData: [])

        // Act
        let result = spec.isSatisfiedBy(context)

        // Assert
        XCTAssertFalse(result)
    }

    // MARK: - Specification Comparison Tests

    func testComparativeSpec_greaterThan_specification_returnsTrue() {
        // Arrange
        let valueSpec = KeyPathDecisionSpec(keyPath: \ComparisonContext.currentValue)
        let thresholdSpec = KeyPathDecisionSpec(keyPath: \ComparisonContext.threshold)

        let spec = ComparativeSpec<ComparisonContext, Double>(
            comparing: valueSpec,
            to: .greaterThan(thresholdSpec)
        )
        let context = ComparisonContext(currentValue: 15.0, threshold: 10.0, historicalData: [])

        // Act
        let result = spec.isSatisfiedBy(context)

        // Assert
        XCTAssertTrue(result)
    }

    func testComparativeSpec_greaterThan_specification_returnsFalse() {
        // Arrange
        let valueSpec = KeyPathDecisionSpec(keyPath: \ComparisonContext.currentValue)
        let thresholdSpec = KeyPathDecisionSpec(keyPath: \ComparisonContext.threshold)

        let spec = ComparativeSpec<ComparisonContext, Double>(
            comparing: valueSpec,
            to: .greaterThan(thresholdSpec)
        )
        let context = ComparisonContext(currentValue: 5.0, threshold: 10.0, historicalData: [])

        // Act
        let result = spec.isSatisfiedBy(context)

        // Assert
        XCTAssertFalse(result)
    }

    // MARK: - Tolerance Tests

    func testComparativeSpec_equalTo_withTolerance_returnsTrue() {
        // Arrange
        let spec = ComparativeSpec<ComparisonContext, Double>(
            keyPath: \.currentValue,
            to: .equalTo(10.0),
            tolerance: 0.5
        )
        let context = ComparisonContext(currentValue: 10.3, threshold: 0, historicalData: [])

        // Act
        let result = spec.isSatisfiedBy(context)

        // Assert
        XCTAssertTrue(result)
    }

    func testComparativeSpec_equalTo_withTolerance_returnsFalse() {
        // Arrange
        let spec = ComparativeSpec<ComparisonContext, Double>(
            keyPath: \.currentValue,
            to: .equalTo(10.0),
            tolerance: 0.5
        )
        let context = ComparisonContext(currentValue: 11.0, threshold: 0, historicalData: [])

        // Act
        let result = spec.isSatisfiedBy(context)

        // Assert
        XCTAssertFalse(result)
    }

    // MARK: - Statistical Comparison Tests

    func testComparativeSpec_aboveAverage_returnsTrue() {
        // Arrange
        let valueSpec = KeyPathDecisionSpec(keyPath: \ComparisonContext.currentValue)
        let dataSpec = KeyPathDecisionSpec(keyPath: \ComparisonContext.historicalData)

        let spec = ComparativeSpec<ComparisonContext, Double>(
            comparing: valueSpec,
            to: .aboveAverage(dataSpec)
        )
        let context = ComparisonContext(
            currentValue: 15.0,
            threshold: 0,
            historicalData: [5.0, 10.0, 15.0]  // average = 10.0
        )

        // Act
        let result = spec.isSatisfiedBy(context)

        // Assert
        XCTAssertTrue(result)
    }

    func testComparativeSpec_belowAverage_returnsTrue() {
        // Arrange
        let valueSpec = KeyPathDecisionSpec(keyPath: \ComparisonContext.currentValue)
        let dataSpec = KeyPathDecisionSpec(keyPath: \ComparisonContext.historicalData)

        let spec = ComparativeSpec<ComparisonContext, Double>(
            comparing: valueSpec,
            to: .belowAverage(dataSpec)
        )
        let context = ComparisonContext(
            currentValue: 5.0,
            threshold: 0,
            historicalData: [10.0, 20.0, 30.0]  // average = 20.0
        )

        // Act
        let result = spec.isSatisfiedBy(context)

        // Assert
        XCTAssertTrue(result)
    }

    func testComparativeSpec_percentile_returnsTrue() {
        // Arrange
        let valueSpec = KeyPathDecisionSpec(keyPath: \ComparisonContext.currentValue)
        let dataSpec = KeyPathDecisionSpec(keyPath: \ComparisonContext.historicalData)

        let spec = ComparativeSpec<ComparisonContext, Double>(
            comparing: valueSpec,
            to: .percentile(90, from: dataSpec)
        )
        let context = ComparisonContext(
            currentValue: 95.0,
            threshold: 0,
            historicalData: Array(1...100).map(Double.init)  // 90th percentile is 90
        )

        // Act
        let result = spec.isSatisfiedBy(context)

        // Assert
        XCTAssertTrue(result)
    }

    // MARK: - Custom Comparison Tests

    func testComparativeSpec_custom_returnsTrue() {
        // Arrange
        let spec = ComparativeSpec<ComparisonContext, Double>(
            keyPath: \.currentValue,
            to: .custom { value, context in
                value > context.threshold * 2
            }
        )
        let context = ComparisonContext(currentValue: 25.0, threshold: 10.0, historicalData: [])

        // Act
        let result = spec.isSatisfiedBy(context)

        // Assert
        XCTAssertTrue(result)
    }

    // MARK: - Multi-Criteria Builder Tests

    func testComparativeSpec_multiCriteriaBuilderAnd_returnsTrue() {
        // Arrange
        let valueSpec = KeyPathDecisionSpec(keyPath: \ComparisonContext.currentValue)
        let thresholdSpec = KeyPathDecisionSpec(keyPath: \ComparisonContext.threshold)

        let spec = ComparativeSpec<ComparisonContext, Double>.builder()
            .compare(valueSpec, to: .greaterThan(5.0))
            .compare(thresholdSpec, to: .lessThan(15.0))
            .buildAnd()

        let context = ComparisonContext(currentValue: 10.0, threshold: 12.0, historicalData: [])

        // Act
        let result = spec.isSatisfiedBy(context)

        // Assert
        XCTAssertTrue(result)
    }

    func testComparativeSpec_multiCriteriaBuilderAnd_returnsFalse() {
        // Arrange
        let valueSpec = KeyPathDecisionSpec(keyPath: \ComparisonContext.currentValue)
        let thresholdSpec = KeyPathDecisionSpec(keyPath: \ComparisonContext.threshold)

        let spec = ComparativeSpec<ComparisonContext, Double>.builder()
            .compare(valueSpec, to: .greaterThan(5.0))
            .compare(thresholdSpec, to: .lessThan(15.0))
            .buildAnd()

        let context = ComparisonContext(currentValue: 10.0, threshold: 20.0, historicalData: [])

        // Act
        let result = spec.isSatisfiedBy(context)

        // Assert
        XCTAssertFalse(result)  // Second condition fails
    }

    func testComparativeSpec_multiCriteriaBuilderOr_returnsTrue() {
        // Arrange
        let valueSpec = KeyPathDecisionSpec(keyPath: \ComparisonContext.currentValue)
        let thresholdSpec = KeyPathDecisionSpec(keyPath: \ComparisonContext.threshold)

        let spec = ComparativeSpec<ComparisonContext, Double>.builder()
            .compare(valueSpec, to: .greaterThan(50.0))  // This will fail
            .compare(thresholdSpec, to: .lessThan(15.0))  // This will succeed
            .buildOr()

        let context = ComparisonContext(currentValue: 10.0, threshold: 12.0, historicalData: [])

        // Act
        let result = spec.isSatisfiedBy(context)

        // Assert
        XCTAssertTrue(result)  // Second condition passes
    }

    // MARK: - Convenience Extensions Tests

    func testComparativeSpec_withinTolerance_returnsTrue() {
        // Arrange
        let valueSpec = KeyPathDecisionSpec(keyPath: \ComparisonContext.currentValue)

        let spec = ComparativeSpec.withinTolerance(
            of: 10.0,
            tolerance: 2.0,
            extracting: valueSpec
        )

        let context = ComparisonContext(currentValue: 11.5, threshold: 0, historicalData: [])

        // Act
        let result = spec.isSatisfiedBy(context)

        // Assert
        XCTAssertTrue(result)
    }

    func testComparativeSpec_approximatelyEqual_returnsTrue() {
        // Arrange
        let valueSpec = KeyPathDecisionSpec(keyPath: \ComparisonContext.currentValue)

        let spec = ComparativeSpec.approximatelyEqual(
            to: 100.0,
            relativeError: 0.05,  // 5% tolerance
            extracting: valueSpec
        )

        let context = ComparisonContext(currentValue: 103.0, threshold: 0, historicalData: [])

        // Act
        let result = spec.isSatisfiedBy(context)

        // Assert
        XCTAssertTrue(result)
    }

    // MARK: - Statistical Extensions Tests

    func testComparativeSpec_isOutlier_returnsTrue() {
        // Arrange
        let valueSpec = KeyPathDecisionSpec(keyPath: \ComparisonContext.currentValue)
        let dataSpec = KeyPathDecisionSpec(keyPath: \ComparisonContext.historicalData)

        let spec = ComparativeSpec.isOutlier(
            comparing: valueSpec,
            from: dataSpec,
            beyondStandardDeviations: 2.0
        )

        // Data with mean ~50 and std dev ~30
        let context = ComparisonContext(
            currentValue: 150.0,  // This should be an outlier
            threshold: 0,
            historicalData: [10.0, 30.0, 50.0, 70.0, 90.0]
        )

        // Act
        let result = spec.isSatisfiedBy(context)

        // Assert
        XCTAssertTrue(result)
    }

    func testComparativeSpec_isOutlier_returnsFalse() {
        // Arrange
        let valueSpec = KeyPathDecisionSpec(keyPath: \ComparisonContext.currentValue)
        let dataSpec = KeyPathDecisionSpec(keyPath: \ComparisonContext.historicalData)

        let spec = ComparativeSpec.isOutlier(
            comparing: valueSpec,
            from: dataSpec,
            beyondStandardDeviations: 2.0
        )

        let context = ComparisonContext(
            currentValue: 55.0,  // This should not be an outlier
            threshold: 0,
            historicalData: [10.0, 30.0, 50.0, 70.0, 90.0]
        )

        // Act
        let result = spec.isSatisfiedBy(context)

        // Assert
        XCTAssertFalse(result)
    }

    // MARK: - Edge Cases Tests

    func testComparativeSpec_nilValueExtraction_returnsFalse() {
        // Arrange
        let nilSpec = NilDecisionSpec<ComparisonContext, Double>()
        let spec = ComparativeSpec<ComparisonContext, Double>(
            comparing: nilSpec,
            to: .greaterThan(10.0)
        )
        let context = ComparisonContext(currentValue: 15.0, threshold: 0, historicalData: [])

        // Act
        let result = spec.isSatisfiedBy(context)

        // Assert
        XCTAssertFalse(result)
    }

    func testComparativeSpec_emptyHistoricalData_returnsFalse() {
        // Arrange
        let valueSpec = KeyPathDecisionSpec(keyPath: \ComparisonContext.currentValue)
        let dataSpec = KeyPathDecisionSpec(keyPath: \ComparisonContext.historicalData)

        let spec = ComparativeSpec<ComparisonContext, Double>(
            comparing: valueSpec,
            to: .aboveAverage(dataSpec)
        )
        let context = ComparisonContext(currentValue: 15.0, threshold: 0, historicalData: [])

        // Act
        let result = spec.isSatisfiedBy(context)

        // Assert
        XCTAssertFalse(result)
    }
}

// MARK: - Helper Decision Specs

private struct KeyPathDecisionSpec<Context, Value>: DecisionSpec {
    let keyPath: KeyPath<Context, Value>

    func decide(_ context: Context) -> Value? {
        return context[keyPath: keyPath]
    }
}

private struct NilDecisionSpec<Context, Value>: DecisionSpec {
    func decide(_ context: Context) -> Value? {
        return nil
    }
}
