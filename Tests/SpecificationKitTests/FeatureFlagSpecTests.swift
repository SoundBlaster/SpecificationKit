import XCTest
@testable import SpecificationKit

final class FeatureFlagSpecTests: XCTestCase {
    func test_FeatureFlagSpec_matchesExpectedValue() {
        let specTrue = FeatureFlagSpec(flagKey: "feature_enabled", expected: true)
        let specFalse = FeatureFlagSpec(flagKey: "feature_enabled", expected: false)

        let ctxTrue = EvaluationContext(flags: ["feature_enabled": true])
        let ctxFalse = EvaluationContext(flags: ["feature_enabled": false])
        let ctxMissing = EvaluationContext(flags: [:])

        XCTAssertTrue(specTrue.isSatisfiedBy(ctxTrue))
        XCTAssertFalse(specTrue.isSatisfiedBy(ctxFalse))
        XCTAssertFalse(specTrue.isSatisfiedBy(ctxMissing))

        XCTAssertTrue(specFalse.isSatisfiedBy(ctxFalse))
        XCTAssertFalse(specFalse.isSatisfiedBy(ctxTrue))
        XCTAssertFalse(specFalse.isSatisfiedBy(ctxMissing))
    }
}

