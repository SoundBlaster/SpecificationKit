import XCTest

@testable import SpecificationKit

final class BenchmarkBaselineTests: XCTestCase {
    func testDefaultBaselineUsesTargetThresholds() {
        let baseline = BenchmarkBaseline.default

        XCTAssertEqual(baseline.specificationEvaluation, 0.001, accuracy: 0.0001)
        XCTAssertEqual(baseline.macroCompilationOverhead, 0.10, accuracy: 0.0001)
        XCTAssertEqual(baseline.wrapperOverhead, 0.05, accuracy: 0.0001)
        XCTAssertEqual(baseline.memoryUsageIncrease, 0.10, accuracy: 0.0001)
        XCTAssertEqual(baseline.contextProviderLatency, 0.010, accuracy: 0.0001)
    }

    func testValidatorDetectsRegressionWhenMetricExceedsBaseline() {
        let validator = BaselineValidator(baseline: .default)
        let result = validator.validate(.specificationEvaluation(0.005))

        guard case let .regression(regressions) = result else {
            XCTFail("Expected regression to be detected")
            return
        }

        XCTAssertEqual(regressions.count, 1)
        XCTAssertEqual(regressions.first?.metricName, "Specification Evaluation")
        XCTAssertEqual(regressions.first?.observedValue, 0.005, accuracy: 0.0001)
        XCTAssertEqual(regressions.first?.threshold, 0.001, accuracy: 0.0001)
    }

    func testValidatorPassesWhenMetricWithinBaseline() {
        let validator = BaselineValidator(baseline: .default)
        let result = validator.validate(.specificationEvaluation(0.0005))

        if case let .regression(regressions) = result {
            XCTFail("Unexpected regression detected: \(regressions)")
        }
    }
}
