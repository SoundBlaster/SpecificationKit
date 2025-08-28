import XCTest
@testable import SpecificationKit

final class EnvironmentContextProviderTests: XCTestCase {

    @MainActor
    func testContextReflectsFlagsCountersEvents() {
        let provider = EnvironmentContextProvider(launchDate: Date(timeIntervalSince1970: 0))
        provider.flags["feature.promo"] = true
        provider.counters["launch_count"] = 5
        let eventDate = Date(timeIntervalSince1970: 100)
        provider.events["last_open"] = eventDate
        provider.segments = ["beta", "vip"]

        let ctx = provider.currentContext()
        XCTAssertTrue(ctx.flag(for: "feature.promo"))
        XCTAssertEqual(ctx.counter(for: "launch_count"), 5)
        XCTAssertEqual(ctx.event(for: "last_open"), eventDate)
        XCTAssertEqual(ctx.segments, ["beta", "vip"])
    }

    @MainActor
    func testEnvironmentSnapshotInjectedIntoUserData() {
        let provider = EnvironmentContextProvider()
        provider.calendar = Calendar(identifier: .iso8601)
        provider.timeZone = TimeZone(secondsFromGMT: 3600) ?? .current
        provider.locale = Locale(identifier: "fr_FR")
        provider.interfaceStyle = "dark"

        let ctx = provider.currentContext()
        XCTAssertEqual(
            ctx.userData(for: "environment.calendar.identifier", as: Calendar.Identifier.self),
            .iso8601
        )
        XCTAssertEqual(
            ctx.userData(for: "environment.locale.identifier", as: String.self),
            "fr_FR"
        )
        XCTAssertEqual(
            ctx.userData(for: "environment.interfaceStyle", as: String.self),
            "dark"
        )
    }
}
