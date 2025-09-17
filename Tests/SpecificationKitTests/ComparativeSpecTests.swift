//
//  ComparativeSpecTests.swift
//  SpecificationKitTests
//
//  Created by SpecificationKit on 2025.
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

    func testComparativeSpec_initWithExtracting_succeeds() {
        // Act & Assert
        XCTAssertNoThrow {
            _ = ComparativeSpec<ComparisonContext, Double>(
                extracting: { $0.currentValue },
                comparison: .greaterThan(10.0)
            )
        }
    }

    func testComparativeSpec_initWithKeyPath_succeeds() {
        // Act & Assert
        XCTAssertNoThrow {
            _ = ComparativeSpec<ComparisonContext, Double>(
                keyPath: \.currentValue,
                comparison: .greaterThan(10.0)
            )
        }
    }

    // MARK: - Fixed Value Comparison Tests

    func testComparativeSpec_greaterThan_fixedValue_returnsTrue() {
        // Arrange
        let spec = ComparativeSpec<ComparisonContext, Double>(
            keyPath: \.currentValue,
            comparison: .greaterThan(10.0)
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
            comparison: .greaterThan(10.0)
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
            comparison: .lessThan(10.0)
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
            comparison: .equalTo(10.0)
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
            comparison: .between(5.0, 15.0)
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
            comparison: .between(5.0, 15.0)
        )
        let context = ComparisonContext(currentValue: 20.0, threshold: 0, historicalData: [])

        // Act
        let result = spec.isSatisfiedBy(context)

        // Assert
        XCTAssertFalse(result)
    }

    // MARK: - Dynamic Comparison via Custom

    func testComparativeSpec_greaterThan_dynamicThreshold_returnsTrue() {
        // Arrange
        let spec = ComparativeSpec<ComparisonContext, Double>(
            keyPath: \.currentValue,
            comparison: .custom { value, context in
                value > context.threshold
            }
        )
        let context = ComparisonContext(currentValue: 15.0, threshold: 10.0, historicalData: [])

        // Act
        let result = spec.isSatisfiedBy(context)

        // Assert
        XCTAssertTrue(result)
    }

    func testComparativeSpec_greaterThan_dynamicThreshold_returnsFalse() {
        // Arrange
        let spec = ComparativeSpec<ComparisonContext, Double>(
            keyPath: \.currentValue,
            comparison: .custom { value, context in
                value > context.threshold
            }
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
            comparison: .equalTo(10.0),
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
            comparison: .equalTo(10.0),
            tolerance: 0.5
        )
        let context = ComparisonContext(currentValue: 11.0, threshold: 0, historicalData: [])

        // Act
        let result = spec.isSatisfiedBy(context)

        // Assert
        XCTAssertFalse(result)
    }

    // MARK: - Custom Comparison Tests

    func testComparativeSpec_custom_returnsTrue() {
        // Arrange
        let spec = ComparativeSpec<ComparisonContext, Double>(
            keyPath: \.currentValue,
            comparison: .custom { value, context in
                value > context.threshold * 2
            }
        )
        let context = ComparisonContext(currentValue: 25.0, threshold: 10.0, historicalData: [])

        // Act
        let result = spec.isSatisfiedBy(context)

        // Assert
        XCTAssertTrue(result)
    }

    // MARK: - Convenience Extensions Tests

    func testComparativeSpec_withinTolerance_returnsTrue() {
        // Arrange
        let spec = ComparativeSpec.withinTolerance(
            of: 10.0,
            tolerance: 2.0,
            keyPath: \ComparisonContext.currentValue
        )

        let context = ComparisonContext(currentValue: 11.5, threshold: 0, historicalData: [])

        // Act
        let result = spec.isSatisfiedBy(context)

        // Assert
        XCTAssertTrue(result)
    }

    func testComparativeSpec_approximatelyEqual_returnsTrue() {
        // Arrange
        let spec = ComparativeSpec.approximatelyEqual(
            to: 100.0,
            relativeError: 0.05,  // 5% tolerance
            keyPath: \ComparisonContext.currentValue
        )

        let context = ComparisonContext(currentValue: 103.0, threshold: 0, historicalData: [])

        // Act
        let result = spec.isSatisfiedBy(context)

        // Assert
        XCTAssertTrue(result)
    }

    // MARK: - Edge Cases Tests

    func testComparativeSpec_nilValueExtraction_returnsFalse() {
        // Arrange
        let spec = ComparativeSpec<ComparisonContext, Double>(
            extracting: { _ in nil },
            comparison: .greaterThan(10.0)
        )
        let context = ComparisonContext(currentValue: 15.0, threshold: 0, historicalData: [])

        // Act
        let result = spec.isSatisfiedBy(context)

        // Assert
        XCTAssertFalse(result)
    }
}

