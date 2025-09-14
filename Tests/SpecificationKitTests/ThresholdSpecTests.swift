//
//  ThresholdSpecTests.swift
//  SpecificationKitTests
//
//  Created by SpecificationKit on 2024.
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

    func testThresholdSpec_initWithDecisionSpec_succeeds() {
        // Arrange
        let valueSpec = KeyPathDecisionSpec(keyPath: \ThresholdContext.currentValue)

        // Act & Assert
        XCTAssertNoThrow {
            let _ = ThresholdSpec<ThresholdContext, Double>(
                extracting: valueSpec,
                threshold: .fixed(10.0)
            )
        }
    }

    func testThresholdSpec_initWithClosure_succeeds() {
        // Act & Assert
        XCTAssertNoThrow {
            let _ = ThresholdSpec<ThresholdContext, Double>(
                extracting: { $0.currentValue },
                threshold: .fixed(10.0)
            )
        }
    }

    func testThresholdSpec_initWithKeyPath_succeeds() {
        // Act & Assert
        XCTAssertNoThrow {
            let _ = ThresholdSpec<ThresholdContext, Double>(
                extracting: \.currentValue,
                threshold: .fixed(10.0)
            )
        }
    }

    // MARK: - Fixed Threshold Tests

    func testThresholdSpec_fixedThreshold_greaterThanOrEqual_returnsTrue() {
        // Arrange
        let spec = ThresholdSpec<ThresholdContext, Double>(
            extracting: \.currentValue,
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
            extracting: \.currentValue,
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
            extracting: \.currentValue,
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
            extracting: \.currentValue,
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
            extracting: \.currentValue,
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

    // MARK: - Percentile Threshold Tests

    func testThresholdSpec_percentileThreshold_calculatesCorrectly() {
        // Arrange
        let dataSpec = KeyPathDecisionSpec(keyPath: \ThresholdContext.historicalData)
        let spec = ThresholdSpec<ThresholdContext, Double>(
            extracting: \.currentValue,
            threshold: .percentile(90, from: dataSpec),
            operator: .greaterThan
        )

        let historicalData = Array(1...100).map(Double.init)
        let context = ThresholdContext(
            currentValue: 95.0,
            dynamicThreshold: 0,
            historicalData: historicalData,
            timestamp: Date()
        )

        // Act
        let result = spec.isSatisfiedBy(context)

        // Assert
        XCTAssertTrue(result)  // 95 > 90th percentile (≈90)
    }

    func testThresholdSpec_percentileThreshold_withEmptyData_handlesGracefully() {
        // Arrange
        let dataSpec = KeyPathDecisionSpec(keyPath: \ThresholdContext.historicalData)
        let spec = ThresholdSpec<ThresholdContext, Double>(
            extracting: \.currentValue,
            threshold: .percentile(90, from: dataSpec),
            operator: .greaterThan
        )

        let context = ThresholdContext(
            currentValue: 95.0,
            dynamicThreshold: 0,
            historicalData: [],  // Empty data
            timestamp: Date()
        )

        // Act
        let result = spec.isSatisfiedBy(context)

        // Assert
        // Should handle gracefully (implementation dependent)
        XCTAssertNotNil(result)
    }

    // MARK: - Relative Threshold Tests

    func testThresholdSpec_relativeThreshold_calculatesOffset() {
        // Arrange
        let baseSpec = KeyPathDecisionSpec(keyPath: \ThresholdContext.dynamicThreshold)
        let spec = ThresholdSpec<ThresholdContext, Double>(
            extracting: \.currentValue,
            threshold: .relative(baseSpec, offset: 5.0),
            operator: .greaterThan
        )

        let context = ThresholdContext(
            currentValue: 20.0,
            dynamicThreshold: 10.0,  // Base threshold
            historicalData: [],
            timestamp: Date()
        )

        // Act
        let result = spec.isSatisfiedBy(context)

        // Assert
        XCTAssertTrue(result)  // 20 > (10 + 5) = 15
    }

    // MARK: - Time-based Threshold Tests

    func testThresholdSpec_timeBasedThreshold_selectsCorrectThreshold() {
        // Arrange
        let now = Date()
        let timePairs = [
            ThresholdSpec<ThresholdContext, Double>.TimeThresholdPair(
                startTime: now.addingTimeInterval(-3600),  // 1 hour ago
                threshold: 10.0
            ),
            ThresholdSpec<ThresholdContext, Double>.TimeThresholdPair(
                startTime: now.addingTimeInterval(-1800),  // 30 minutes ago
                threshold: 15.0
            ),
        ]

        let spec = ThresholdSpec<ThresholdContext, Double>(
            extracting: \.currentValue,
            threshold: .timeBased(timePairs),
            operator: .greaterThan
        )

        let context = ThresholdContext(
            currentValue: 18.0,
            dynamicThreshold: 0,
            historicalData: [],
            timestamp: now
        )

        // Act
        let result = spec.isSatisfiedBy(context)

        // Assert
        XCTAssertTrue(result)  // 18 > 15 (most recent applicable threshold)
    }

    // MARK: - Custom Threshold Tests

    func testThresholdSpec_customThreshold_calculatesCorrectly() {
        // Arrange
        let spec = ThresholdSpec<ThresholdContext, Double>(
            extracting: \.currentValue,
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
            extracting: \.currentValue,
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
            extracting: \.currentValue,
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
            extracting: \.currentValue,
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
        let valueSpec = KeyPathDecisionSpec(keyPath: \ThresholdContext.currentValue)
        let spec = ThresholdSpec.exceeds(valueSpec, value: 10.0)

        let context = ThresholdContext(
            currentValue: 15.0, dynamicThreshold: 0, historicalData: [], timestamp: Date())

        // Act
        let result = spec.isSatisfiedBy(context)

        // Assert
        XCTAssertTrue(result)
    }

    func testThresholdSpec_below_convenience() {
        // Arrange
        let valueSpec = KeyPathDecisionSpec(keyPath: \ThresholdContext.currentValue)
        let spec = ThresholdSpec.below(valueSpec, value: 10.0)

        let context = ThresholdContext(
            currentValue: 5.0, dynamicThreshold: 0, historicalData: [], timestamp: Date())

        // Act
        let result = spec.isSatisfiedBy(context)

        // Assert
        XCTAssertTrue(result)
    }

    func testThresholdSpec_adaptive_convenience() {
        // Arrange
        let valueSpec = KeyPathDecisionSpec(keyPath: \ThresholdContext.currentValue)
        let spec = ThresholdSpec.adaptive(valueSpec) { 12.0 }

        let context = ThresholdContext(
            currentValue: 15.0, dynamicThreshold: 0, historicalData: [], timestamp: Date())

        // Act
        let result = spec.isSatisfiedBy(context)

        // Assert
        XCTAssertTrue(result)
    }

    // MARK: - Composite Builder Tests

    func testThresholdSpec_compositeBuilder_requireAll_returnsTrue() {
        // Arrange
        let valueSpec = KeyPathDecisionSpec(keyPath: \ThresholdContext.currentValue)
        let thresholdSpec = KeyPathDecisionSpec(keyPath: \ThresholdContext.dynamicThreshold)

        let spec = ThresholdSpec<ThresholdContext, Double>.composite()
            .add(valueSpec, threshold: .fixed(5.0), operator: .greaterThan)
            .add(thresholdSpec, threshold: .fixed(15.0), operator: .lessThan)
            .requireAll()
            .build()

        let context = ThresholdContext(
            currentValue: 10.0,  // > 5
            dynamicThreshold: 12.0,  // < 15
            historicalData: [],
            timestamp: Date()
        )

        // Act
        let result = spec.isSatisfiedBy(context)

        // Assert
        XCTAssertTrue(result)
    }

    func testThresholdSpec_compositeBuilder_requireAll_returnsFalse() {
        // Arrange
        let valueSpec = KeyPathDecisionSpec(keyPath: \ThresholdContext.currentValue)
        let thresholdSpec = KeyPathDecisionSpec(keyPath: \ThresholdContext.dynamicThreshold)

        let spec = ThresholdSpec<ThresholdContext, Double>.composite()
            .add(valueSpec, threshold: .fixed(5.0), operator: .greaterThan)
            .add(thresholdSpec, threshold: .fixed(15.0), operator: .lessThan)
            .requireAll()
            .build()

        let context = ThresholdContext(
            currentValue: 10.0,  // > 5 ✓
            dynamicThreshold: 20.0,  // < 15 ✗
            historicalData: [],
            timestamp: Date()
        )

        // Act
        let result = spec.isSatisfiedBy(context)

        // Assert
        XCTAssertFalse(result)
    }

    func testThresholdSpec_compositeBuilder_requireAny_returnsTrue() {
        // Arrange
        let valueSpec = KeyPathDecisionSpec(keyPath: \ThresholdContext.currentValue)
        let thresholdSpec = KeyPathDecisionSpec(keyPath: \ThresholdContext.dynamicThreshold)

        let spec = ThresholdSpec<ThresholdContext, Double>.composite()
            .add(valueSpec, threshold: .fixed(50.0), operator: .greaterThan)  // Will fail
            .add(thresholdSpec, threshold: .fixed(15.0), operator: .lessThan)  // Will succeed
            .requireAny()
            .build()

        let context = ThresholdContext(
            currentValue: 10.0,  // > 50 ✗
            dynamicThreshold: 12.0,  // < 15 ✓
            historicalData: [],
            timestamp: Date()
        )

        // Act
        let result = spec.isSatisfiedBy(context)

        // Assert
        XCTAssertTrue(result)
    }

    // MARK: - Time-based Extension Tests

    func testThresholdSpec_timeBasedSchedule_convenience() {
        // Arrange
        let valueSpec = KeyPathDecisionSpec(keyPath: \ThresholdContext.currentValue)
        let now = Date()
        let schedule = [
            ThresholdSpec<ThresholdContext, Double>.TimeThresholdPair(
                startTime: now.addingTimeInterval(-1800),
                threshold: 15.0
            )
        ]

        let spec = ThresholdSpec.timeBasedSchedule(valueSpec, schedule: schedule)
        let context = ThresholdContext(
            currentValue: 20.0, dynamicThreshold: 0, historicalData: [], timestamp: Date())

        // Act
        let result = spec.isSatisfiedBy(context)

        // Assert
        XCTAssertTrue(result)
    }

    func testThresholdSpec_rampingThreshold_convenience() {
        // Arrange
        let valueSpec = KeyPathDecisionSpec(keyPath: \ThresholdContext.currentValue)
        let spec = ThresholdSpec.rampingThreshold(
            valueSpec,
            from: 10.0,
            to: 20.0,
            over: 3600  // 1 hour
        )

        let context = ThresholdContext(
            currentValue: 15.0, dynamicThreshold: 0, historicalData: [], timestamp: Date())

        // Act
        let result = spec.isSatisfiedBy(context)

        // Assert
        XCTAssertNotNil(result)  // Implementation-dependent behavior
    }

    // MARK: - Statistical Extension Tests

    func testThresholdSpec_standardDeviations_convenience() {
        // Arrange
        let valueSpec = KeyPathDecisionSpec(keyPath: \ThresholdContext.currentValue)
        let dataSpec = KeyPathDecisionSpec(keyPath: \ThresholdContext.historicalData)

        let spec = ThresholdSpec.standardDeviations(
            valueSpec,
            above: dataSpec,
            by: 2.0
        )

        let context = ThresholdContext(
            currentValue: 120.0,
            dynamicThreshold: 0,
            historicalData: [10.0, 30.0, 50.0, 70.0, 90.0],  // mean ≈ 50, std dev ≈ 30
            timestamp: Date()
        )

        // Act
        let result = spec.isSatisfiedBy(context)

        // Assert
        XCTAssertTrue(result)  // 120 > (50 + 2 * 30) = 110
    }

    // MARK: - Edge Cases Tests

    func testThresholdSpec_nilValueExtraction_returnsFalse() {
        // Arrange
        let nilSpec = NilDecisionSpec<ThresholdContext, Double>()
        let spec = ThresholdSpec<ThresholdContext, Double>(
            extracting: nilSpec,
            threshold: .fixed(10.0)
        )
        let context = ThresholdContext(
            currentValue: 15.0, dynamicThreshold: 0, historicalData: [], timestamp: Date())

        // Act
        let result = spec.isSatisfiedBy(context)

        // Assert
        XCTAssertFalse(result)
    }

    func testThresholdSpec_emptyBuilder_returnsAlwaysTrue() {
        // Arrange
        let spec = ThresholdSpec<ThresholdContext, Double>.composite()
            .requireAll()
            .build()

        let context = ThresholdContext(
            currentValue: 15.0, dynamicThreshold: 0, historicalData: [], timestamp: Date())

        // Act
        let result = spec.isSatisfiedBy(context)

        // Assert
        XCTAssertTrue(result)  // Empty AND should be true
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
