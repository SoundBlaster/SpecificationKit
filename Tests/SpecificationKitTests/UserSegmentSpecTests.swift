import XCTest
@testable import SpecificationKit

final class UserSegmentSpecTests: XCTestCase {
    func test_UserSegmentSpec_checksMembership() {
        let ctxA = EvaluationContext(segments: ["vip", "beta"])
        let ctxB = EvaluationContext(segments: ["control"]) 

        XCTAssertTrue(UserSegmentSpec(.vip).isSatisfiedBy(ctxA))
        XCTAssertFalse(UserSegmentSpec(.vip).isSatisfiedBy(ctxB))
        XCTAssertFalse(UserSegmentSpec(.vip).isSatisfiedBy(EvaluationContext()))
    }
}

