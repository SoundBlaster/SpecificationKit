import XCTest
@testable import SpecificationKit

final class SpecsMacroIntegrationTests: XCTestCase {

    @specs(
        MaxCountSpec(counterKey: "display_count", limit: 3),
        TimeSinceEventSpec(eventKey: "last_shown", minimumInterval: 3600)
    )
    struct BannerSpec: Specification {
        typealias T = EvaluationContext
    }

    func test_specsMacro_generatesAndChainsTwoSpecifications() {
        let now = Date()
        let old = now.addingTimeInterval(-7200)

        let ok = EvaluationContext(
            currentDate: now,
            counters: ["display_count": 2],
            events: ["last_shown": old]
        )
        XCTAssertTrue(BannerSpec().isSatisfiedBy(ok))

        let countAtLimit = EvaluationContext(
            currentDate: now,
            counters: ["display_count": 3],
            events: ["last_shown": old]
        )
        XCTAssertFalse(BannerSpec().isSatisfiedBy(countAtLimit))

        let recent = EvaluationContext(
            currentDate: now,
            counters: ["display_count": 2],
            events: ["last_shown": now.addingTimeInterval(-1800)]
        )
        XCTAssertFalse(BannerSpec().isSatisfiedBy(recent))
    }

    @specs(MaxCountSpec(counterKey: "attempts", limit: 1))
    struct SingleSpec: Specification {
        typealias T = EvaluationContext
    }

    func test_specsMacro_singleSpecification() {
        let ok = EvaluationContext(counters: ["attempts": 0])
        let fail = EvaluationContext(counters: ["attempts": 1])
        XCTAssertTrue(SingleSpec().isSatisfiedBy(ok))
        XCTAssertFalse(SingleSpec().isSatisfiedBy(fail))
    }
}

