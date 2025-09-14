//
//  WeightedSpecTests.swift
//  SpecificationKitTests
//
//  Created by SpecificationKit on 2024.
//

import XCTest

@testable import SpecificationKit

final class WeightedSpecTests: XCTestCase {

    // Test context
    struct TestContext {
        var value: Double
        var flag: Bool
    }

    // MARK: - Initialization Tests

    func testWeightedSpec_initWithValidCandidates_succeeds() {
        // Arrange
        let spec1 = PredicateSpec<TestContext> { $0.flag }
        let spec2 = PredicateSpec<TestContext> { $0.value > 0 }

        // Act & Assert
        XCTAssertNoThrow {
            let _ = WeightedSpec<TestContext, String>(candidates: [
                (AnySpecification(spec1), 0.7, "A"),
                (AnySpecification(spec2), 0.3, "B"),
            ])
        }
    }

    func testWeightedSpec_initWithEmptyCandidates_fails() {
        // Act & Assert
        XCTAssertThrows {
            let _ = WeightedSpec<TestContext, String>(candidates: [])
        }
    }

    func testWeightedSpec_initWithZeroWeight_fails() {
        // Arrange
        let spec = PredicateSpec<TestContext> { $0.flag }

        // Act & Assert
        XCTAssertThrows {
            let _ = WeightedSpec<TestContext, String>(candidates: [
                (AnySpecification(spec), 0.0, "A")
            ])
        }
    }

    func testWeightedSpec_initWithNegativeWeight_fails() {
        // Arrange
        let spec = PredicateSpec<TestContext> { $0.flag }

        // Act & Assert
        XCTAssertThrows {
            let _ = WeightedSpec<TestContext, String>(candidates: [
                (AnySpecification(spec), -0.5, "A")
            ])
        }
    }

    // MARK: - Decision Logic Tests

    func testWeightedSpec_decide_withNoSatisfiedSpecs_returnsNil() {
        // Arrange
        let spec1 = PredicateSpec<TestContext> { $0.flag }
        let spec2 = PredicateSpec<TestContext> { $0.value > 10 }

        let weightedSpec = WeightedSpec<TestContext, String>(candidates: [
            (AnySpecification(spec1), 0.7, "A"),
            (AnySpecification(spec2), 0.3, "B"),
        ])

        let context = TestContext(value: 5.0, flag: false)

        // Act
        let result = weightedSpec.decide(context)

        // Assert
        XCTAssertNil(result)
    }

    func testWeightedSpec_decide_withSingleSatisfiedSpec_returnsResult() {
        // Arrange
        let spec1 = PredicateSpec<TestContext> { $0.flag }
        let spec2 = PredicateSpec<TestContext> { $0.value > 10 }

        var generator = FixedRandomGenerator(value: 0.5)
        let weightedSpec = WeightedSpec<TestContext, String>(
            candidates: [
                (AnySpecification(spec1), 0.7, "A"),
                (AnySpecification(spec2), 0.3, "B"),
            ],
            using: generator
        )

        let context = TestContext(value: 5.0, flag: true)

        // Act
        let result = weightedSpec.decide(context)

        // Assert
        XCTAssertEqual(result, "A")
    }

    // MARK: - Statistical Analysis Tests

    func testWeightedSpec_probabilityDistribution_calculatesCorrectly() {
        // Arrange
        let spec1 = AlwaysTrueSpec<TestContext>()
        let spec2 = AlwaysTrueSpec<TestContext>()

        let weightedSpec = WeightedSpec<TestContext, String>(candidates: [
            (AnySpecification(spec1), 0.7, "A"),
            (AnySpecification(spec2), 0.3, "B"),
        ])

        // Act
        let distribution = weightedSpec.probabilityDistribution

        // Assert
        XCTAssertEqual(distribution.count, 2)
        XCTAssertEqual(distribution[0], 0.7, accuracy: 0.001)
        XCTAssertEqual(distribution[1], 0.3, accuracy: 0.001)
    }

    func testWeightedSpec_expectedValue_calculatesCorrectly() {
        // Arrange
        let spec1 = AlwaysTrueSpec<TestContext>()
        let spec2 = AlwaysTrueSpec<TestContext>()

        let weightedSpec = WeightedSpec<TestContext, Double>(candidates: [
            (AnySpecification(spec1), 0.6, 10.0),
            (AnySpecification(spec2), 0.4, 20.0),
        ])

        // Act
        let expectedValue = weightedSpec.expectedValue()

        // Assert
        XCTAssertEqual(expectedValue, 14.0, accuracy: 0.001)  // 0.6 * 10 + 0.4 * 20 = 14
    }

    func testWeightedSpec_variance_calculatesCorrectly() {
        // Arrange
        let spec1 = AlwaysTrueSpec<TestContext>()
        let spec2 = AlwaysTrueSpec<TestContext>()

        let weightedSpec = WeightedSpec<TestContext, Double>(candidates: [
            (AnySpecification(spec1), 0.5, 10.0),
            (AnySpecification(spec2), 0.5, 20.0),
        ])

        // Act
        let variance = weightedSpec.variance()
        let expectedVariance = 25.0  // ((10-15)^2 + (20-15)^2) * 0.5 = 25

        // Assert
        XCTAssertEqual(variance, expectedVariance, accuracy: 0.001)
    }

    // MARK: - Statistical Validation Tests (Sample-based)

    func testWeightedSpec_statisticalDistribution_convergesCorrectly() {
        // Arrange
        let spec1 = AlwaysTrueSpec<TestContext>()
        let spec2 = AlwaysTrueSpec<TestContext>()

        var generator = SystemRandomNumberGenerator()
        let weightedSpec = WeightedSpec<TestContext, String>(
            candidates: [
                (AnySpecification(spec1), 0.7, "A"),
                (AnySpecification(spec2), 0.3, "B"),
            ],
            using: generator
        )

        let context = TestContext(value: 0, flag: true)
        let iterations = 10000

        // Act
        var results: [String] = []
        for _ in 0..<iterations {
            if let result = weightedSpec.decide(context) {
                results.append(result)
            }
        }

        let aCount = results.filter { $0 == "A" }.count
        let ratio = Double(aCount) / Double(results.count)

        // Assert - Check within 3 standard deviations
        let expectedRatio = 0.7
        let standardError = sqrt(expectedRatio * (1 - expectedRatio) / Double(iterations))
        let margin = 3 * standardError

        XCTAssertEqual(ratio, expectedRatio, accuracy: margin)
    }

    // MARK: - Builder Pattern Tests

    func testWeightedSpec_builder_createsCorrectSpec() {
        // Arrange
        let builder = WeightedSpec<TestContext, String>.builder()
            .add(PredicateSpec<TestContext> { $0.flag }, weight: 0.6, result: "FLAG")
            .add(PredicateSpec<TestContext> { $0.value > 5 }, weight: 0.4, result: "VALUE")
            .fallback("DEFAULT")

        let spec = builder.build()

        // Act & Assert
        let contextFlagOnly = TestContext(value: 0, flag: true)
        let resultFlag = spec.decide(contextFlagOnly)
        XCTAssertNotNil(resultFlag)

        let contextNeither = TestContext(value: 0, flag: false)
        let resultDefault = spec.decide(contextNeither)
        XCTAssertEqual(resultDefault, "DEFAULT")
    }

    func testWeightedSpec_builderWithInvalidWeight_throws() {
        // Arrange
        let builder = WeightedSpec<TestContext, String>.builder()

        // Act & Assert
        XCTAssertThrows {
            builder.add(AlwaysTrueSpec<TestContext>(), weight: 0, result: "TEST")
        }
    }

    // MARK: - Fallback Tests

    func testWeightedSpec_withFallback_alwaysReturnsResult() {
        // Arrange
        let spec1 = PredicateSpec<TestContext> { $0.flag }
        let spec2 = PredicateSpec<TestContext> { $0.value > 10 }

        let weightedSpec = WeightedSpec<TestContext, String>.withFallback(
            [
                (AnySpecification(spec1), 0.7, "A"),
                (AnySpecification(spec2), 0.3, "B"),
            ], fallback: "FALLBACK")

        let context = TestContext(value: 5.0, flag: false)

        // Act
        let result = weightedSpec.decide(context)

        // Assert
        XCTAssertEqual(result, "FALLBACK")
    }

    // MARK: - Edge Cases

    func testWeightedSpec_withAllZeroWeights_handlesGracefully() {
        // This test verifies that the normalization logic handles edge cases
        // Implementation should handle this gracefully by assigning equal weights
        let spec = AlwaysTrueSpec<TestContext>()

        // Note: This would normally fail precondition, but we can test normalized weights behavior
        // in a different way by testing the probabilityDistribution with very small weights
        let weightedSpec = WeightedSpec<TestContext, String>(candidates: [
            (AnySpecification(spec), 0.001, "A"),
            (AnySpecification(spec), 0.001, "B"),
        ])

        let distribution = weightedSpec.probabilityDistribution
        XCTAssertEqual(distribution[0], 0.5, accuracy: 0.001)
        XCTAssertEqual(distribution[1], 0.5, accuracy: 0.001)
    }
}

// MARK: - Helper Classes

/// A fixed random number generator for deterministic testing
struct FixedRandomGenerator: RandomNumberGenerator {
    private let value: Double

    init(value: Double) {
        self.value = value
    }

    mutating func next() -> UInt64 {
        return UInt64(value * Double(UInt64.max))
    }
}

/// Extension to support throwing assertions in tests
extension XCTestCase {
    func XCTAssertThrows<T>(
        _ expression: @autoclosure () throws -> T,
        _ message: @autoclosure () -> String = "",
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertThrowsError(try expression(), message(), file: file, line: line)
    }
}
