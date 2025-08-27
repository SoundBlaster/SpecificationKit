import XCTest
@testable import SpecificationKit

final class DateRangeSpecTests: XCTestCase {
    func test_DateRangeSpec_inclusiveRange() {
        let base = ISO8601DateFormatter().date(from: "2024-01-10T12:00:00Z")!
        let start = ISO8601DateFormatter().date(from: "2024-01-01T00:00:00Z")!
        let end = ISO8601DateFormatter().date(from: "2024-01-31T23:59:59Z")!

        let spec = DateRangeSpec(start: start, end: end)

        XCTAssertTrue(spec.isSatisfiedBy(EvaluationContext(currentDate: base)))
        XCTAssertTrue(spec.isSatisfiedBy(EvaluationContext(currentDate: start)))
        XCTAssertTrue(spec.isSatisfiedBy(EvaluationContext(currentDate: end)))

        let before = ISO8601DateFormatter().date(from: "2023-12-31T23:59:59Z")!
        let after = ISO8601DateFormatter().date(from: "2024-02-01T00:00:00Z")!
        XCTAssertFalse(spec.isSatisfiedBy(EvaluationContext(currentDate: before)))
        XCTAssertFalse(spec.isSatisfiedBy(EvaluationContext(currentDate: after)))
    }
}

