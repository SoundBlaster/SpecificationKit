import XCTest
@testable import SpecificationKit

final class DateComparisonSpecTests: XCTestCase {
    func test_DateComparisonSpec_before_after() {
        let now = Date()
        let oneHourAgo = now.addingTimeInterval(-3600)
        let oneHourAhead = now.addingTimeInterval(3600)

        let ctxWithPast = EvaluationContext(currentDate: now, events: ["sample": oneHourAgo])
        let ctxWithFuture = EvaluationContext(currentDate: now, events: ["sample": oneHourAhead])
        let ctxMissing = EvaluationContext(currentDate: now)

        let beforeNow = DateComparisonSpec(eventKey: "sample", comparison: .before, date: now)
        let afterNow = DateComparisonSpec(eventKey: "sample", comparison: .after, date: now)

        XCTAssertTrue(beforeNow.isSatisfiedBy(ctxWithPast))
        XCTAssertFalse(beforeNow.isSatisfiedBy(ctxWithFuture))
        XCTAssertFalse(beforeNow.isSatisfiedBy(ctxMissing))

        XCTAssertTrue(afterNow.isSatisfiedBy(ctxWithFuture))
        XCTAssertFalse(afterNow.isSatisfiedBy(ctxWithPast))
        XCTAssertFalse(afterNow.isSatisfiedBy(ctxMissing))
    }
}

