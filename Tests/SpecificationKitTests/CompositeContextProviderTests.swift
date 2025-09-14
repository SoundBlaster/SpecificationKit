import XCTest
@testable import SpecificationKit

final class CompositeContextProviderTests: XCTestCase {

    private func ctx(
        launch: Date = Date(timeIntervalSince1970: 0),
        user: [String: Any] = [:],
        counters: [String: Int] = [:],
        events: [String: Date] = [:],
        flags: [String: Bool] = [:],
        segments: Set<String> = []
    ) -> EvaluationContext {
        EvaluationContext(
            currentDate: Date(),
            launchDate: launch,
            userData: user,
            counters: counters,
            events: events,
            flags: flags,
            segments: segments
        )
    }

    func testPreferLast_overridesConflicts_andUnionsSegments() {
        let p1 = GenericContextProvider { self.ctx(
            launch: Date(timeIntervalSince1970: 10),
            user: ["k": "v1", "only1": 1],
            counters: ["c": 1],
            events: ["e": Date(timeIntervalSince1970: 100)],
            flags: ["f": false],
            segments: ["a"]
        )}
        let p2 = GenericContextProvider { self.ctx(
            launch: Date(timeIntervalSince1970: 20),
            user: ["k": "v2", "only2": 2],
            counters: ["c": 2],
            events: ["e": Date(timeIntervalSince1970: 200)],
            flags: ["f": true],
            segments: ["b"]
        )}

        let composite = CompositeContextProvider(providers: [p1, p2], strategy: .preferLast)
        let result = composite.currentContext()

        XCTAssertEqual(result.userData["k"] as? String, "v2")
        XCTAssertEqual(result.userData["only1"] as? Int, 1)
        XCTAssertEqual(result.userData["only2"] as? Int, 2)
        XCTAssertEqual(result.counter(for: "c"), 2)
        XCTAssertEqual(result.event(for: "e"), Date(timeIntervalSince1970: 200))
        XCTAssertEqual(result.flag(for: "f"), true)
        XCTAssertEqual(result.segments, ["a", "b"])
        XCTAssertEqual(result.launchDate, Date(timeIntervalSince1970: 20))
    }

    func testPreferFirst_preservesFirst_onConflicts() {
        let p1 = GenericContextProvider { self.ctx(
            launch: Date(timeIntervalSince1970: 30),
            user: ["k": "v1"],
            counters: ["c": 1],
            events: ["e": Date(timeIntervalSince1970: 300)],
            flags: ["f": false]
        )}
        let p2 = GenericContextProvider { self.ctx(
            launch: Date(timeIntervalSince1970: 40),
            user: ["k": "v2"],
            counters: ["c": 2],
            events: ["e": Date(timeIntervalSince1970: 400)],
            flags: ["f": true]
        )}

        let composite = CompositeContextProvider(providers: [p1, p2], strategy: .preferFirst)
        let result = composite.currentContext()

        XCTAssertEqual(result.userData["k"] as? String, "v1")
        XCTAssertEqual(result.counter(for: "c"), 1)
        XCTAssertEqual(result.event(for: "e"), Date(timeIntervalSince1970: 300))
        XCTAssertEqual(result.flag(for: "f"), false)
        XCTAssertEqual(result.launchDate, Date(timeIntervalSince1970: 30))
    }
}

