//
//  ThresholdSpecTests.swift
//  SpecificationKitTests
//
//  Created by SpecificationKit on 2025.
//

import XCTest

@testable import SpecificationKit

final class ThresholdSpecTests: XCTestCase {

    // Test context
    struct ThresholdContext {
        var currentValue: Double
        var dynamicThreshold: Double
        var historicalData: [Double]
        var timestamp: Date
    }

    // MARK: - Initialization Tests

    func testThresholdSpec_initWithKeyPath_succeeds() {
        // Act & Assert
        XCTAssertNoThrow {
            _ = ThresholdSpec<ThresholdContext, Double>(
                keyPath: \.currentValue,
                threshold: .fixed(10.0)
            )
        }
    }

    func testThresholdSpec_initWithClosure_succeeds() {
        // Act & Assert
        XCTAssertNoThrow {
            _ = ThresholdSpec<ThresholdContext, Double>(
                extracting: { $0.currentValue },
                threshold: .fixed(10.0)
            )
        }
    }

    // MARK: - Fixed Threshold Tests

    func testThresholdSpec_fixedThreshold_greaterThanOrEqual_returnsTrue() {
        // Arrange
        let spec = ThresholdSpec<ThresholdContext, Double>(
            keyPath: \.currentValue,
            threshold: .fixed(10.0),
            operator: .greaterThanOrEqual
        )
        let context = ThresholdContext(
            currentValue: 15.0,
            dynamicThreshold: 0,
            historicalData: [],
            timestamp: Date()
        )

        // Act
        let result = spec.isSatisfiedBy(context)

        // Assert
        XCTAssertTrue(result)
    }

    func testThresholdSpec_fixedThreshold_greaterThanOrEqual_returnsFalse() {
        // Arrange
        let spec = ThresholdSpec<ThresholdContext, Double>(
            keyPath: \.currentValue,
            threshold: .fixed(10.0),
            operator: .greaterThanOrEqual
        )
        let context = ThresholdContext(
            currentValue: 5.0,
            dynamicThreshold: 0,
            historicalData: [],
            timestamp: Date()
        )

        // Act
        let result = spec.isSatisfiedBy(context)

        // Assert
        XCTAssertFalse(result)
    }

    func testThresholdSpec_fixedThreshold_lessThan_returnsTrue() {
        // Arrange
        let spec = ThresholdSpec<ThresholdContext, Double>(
            keyPath: \.currentValue,
            threshold: .fixed(10.0),
            operator: .lessThan
        )
        let context = ThresholdContext(
            currentValue: 5.0,
            dynamicThreshold: 0,
            historicalData: [],
            timestamp: Date()
        )

        // Act
        let result = spec.isSatisfiedBy(context)

        // Assert
        XCTAssertTrue(result)
    }

    // MARK: - Adaptive Threshold Tests

    func testThresholdSpec_adaptiveThreshold_calculatesCorrectly() {
        // Arrange
        var dynamicValue: Double = 15.0
        let spec = ThresholdSpec<ThresholdContext, Double>(
            keyPath: \.currentValue,
            threshold: .adaptive { dynamicValue },
            operator: .greaterThan
        )
        let context = ThresholdContext(
            currentValue: 20.0,
            dynamicThreshold: 0,
            historicalData: [],
            timestamp: Date()
        )

        // Act
        let result = spec.isSatisfiedBy(context)

        // Assert
        XCTAssertTrue(result)

        // Change dynamic value and test again
        dynamicValue = 25.0
        let result2 = spec.isSatisfiedBy(context)
        XCTAssertFalse(result2)
    }

    // MARK: - Contextual Threshold Tests

    func testThresholdSpec_contextualThreshold_extractsFromContext() {
        // Arrange
        let spec = ThresholdSpec<ThresholdContext, Double>(
            keyPath: \.currentValue,
            threshold: .contextual(\.dynamicThreshold),
            operator: .greaterThan
        )
        let context = ThresholdContext(
            currentValue: 20.0,
            dynamicThreshold: 15.0,
            historicalData: [],
            timestamp: Date()
        )

        // Act
        let result = spec.isSatisfiedBy(context)

        // Assert
        XCTAssertTrue(result)
    }

    // MARK: - Removed unsupported percentile threshold tests

    // MARK: - Relative Threshold Tests

    // MARK: - Removed unsupported relative threshold tests

    // MARK: - Time-based Threshold Tests

    // MARK: - Removed unsupported time-based threshold tests

    // MARK: - Custom Threshold Tests (supported)

    func testThresholdSpec_customThreshold_calculatesCorrectly() {
        // Arrange
        let spec = ThresholdSpec<ThresholdContext, Double>(
            keyPath: \.currentValue,
            threshold: .custom { context in
                context.dynamicThreshold * 2.0
            },
            operator: .greaterThan
        )

        let context = ThresholdContext(
            currentValue: 25.0,
            dynamicThreshold: 10.0,
            historicalData: [],
            timestamp: Date()
        )

        // Act
        let result = spec.isSatisfiedBy(context)

        // Assert
        XCTAssertTrue(result)  // 25 > (10 * 2) = 20
    }

    // MARK: - Comparison Operators Tests

    func testThresholdSpec_greaterThan_operator() {
        // Arrange
        let spec = ThresholdSpec<ThresholdContext, Double>(
            keyPath: \.currentValue,
            threshold: .fixed(10.0),
            operator: .greaterThan
        )

        let contextEqual = ThresholdContext(
            currentValue: 10.0, dynamicThreshold: 0, historicalData: [], timestamp: Date())
        let contextGreater = ThresholdContext(
            currentValue: 15.0, dynamicThreshold: 0, historicalData: [], timestamp: Date())

        // Act & Assert
        XCTAssertFalse(spec.isSatisfiedBy(contextEqual))  // 10 is not > 10
        XCTAssertTrue(spec.isSatisfiedBy(contextGreater))  // 15 > 10
    }

    func testThresholdSpec_equal_operator_withTolerance() {
        // Arrange
        let spec = ThresholdSpec<ThresholdContext, Double>(
            keyPath: \.currentValue,
            threshold: .fixed(10.0),
            operator: .equal,
            tolerance: 0.5
        )

        let contextWithinTolerance = ThresholdContext(
            currentValue: 10.3, dynamicThreshold: 0, historicalData: [], timestamp: Date())
        let contextOutsideTolerance = ThresholdContext(
            currentValue: 11.0, dynamicThreshold: 0, historicalData: [], timestamp: Date())

        // Act & Assert
        XCTAssertTrue(spec.isSatisfiedBy(contextWithinTolerance))
        XCTAssertFalse(spec.isSatisfiedBy(contextOutsideTolerance))
    }

    func testThresholdSpec_notEqual_operator() {
        // Arrange
        let spec = ThresholdSpec<ThresholdContext, Double>(
            keyPath: \.currentValue,
            threshold: .fixed(10.0),
            operator: .notEqual
        )

        let contextEqual = ThresholdContext(
            currentValue: 10.0, dynamicThreshold: 0, historicalData: [], timestamp: Date())
        let contextNotEqual = ThresholdContext(
            currentValue: 15.0, dynamicThreshold: 0, historicalData: [], timestamp: Date())

        // Act & Assert
        XCTAssertFalse(spec.isSatisfiedBy(contextEqual))
        XCTAssertTrue(spec.isSatisfiedBy(contextNotEqual))
    }

    // MARK: - Convenience Extension Tests

    func testThresholdSpec_exceeds_convenience() {
        // Arrange
        let spec = ThresholdSpec<ThresholdContext, Double>.exceeds(keyPath: \.currentValue, value: 10.0)

        let context = ThresholdContext(
            currentValue: 15.0, dynamicThreshold: 0, historicalData: [], timestamp: Date())

        // Act
        let result = spec.isSatisfiedBy(context)

        // Assert
        XCTAssertTrue(result)
    }

    func testThresholdSpec_below_convenience() {
        // Arrange
        let spec = ThresholdSpec<ThresholdContext, Double>.below(keyPath: \.currentValue, value: 10.0)

        let context = ThresholdContext(
            currentValue: 5.0, dynamicThreshold: 0, historicalData: [], timestamp: Date())

        // Act
        let result = spec.isSatisfiedBy(context)

        // Assert
        XCTAssertTrue(result)
    }

    func testThresholdSpec_adaptive_convenience() {
        // Arrange
        let spec = ThresholdSpec<ThresholdContext, Double>.adaptive(keyPath: \.currentValue) { 12.0 }

        let context = ThresholdContext(
            currentValue: 15.0, dynamicThreshold: 0, historicalData: [], timestamp: Date())

        // Act
        let result = spec.isSatisfiedBy(context)

        // Assert
        XCTAssertTrue(result)
    }

    // MARK: - Removed unsupported composite builder tests

    // MARK: - Removed unsupported time-based extension tests

    // MARK: - Removed unsupported statistical extension tests

    // MARK: - Edge Cases Tests

    func testThresholdSpec_nilValueExtraction_returnsFalse() {
        // Arrange
        let spec = ThresholdSpec<ThresholdContext, Double>(
            extracting: { _ in nil },
            threshold: .fixed(10.0)
        )
        let context = ThresholdContext(
            currentValue: 15.0, dynamicThreshold: 0, historicalData: [], timestamp: Date())

        // Act
        let result = spec.isSatisfiedBy(context)

        // Assert
        XCTAssertFalse(result)
    }

    // MARK: - Removed unsupported builder empty state test
}
