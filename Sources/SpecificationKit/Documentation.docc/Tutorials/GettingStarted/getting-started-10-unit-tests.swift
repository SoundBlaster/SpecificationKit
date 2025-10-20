import XCTest
import SpecificationKit

// A simple User model
struct User {
    let name: String
    var age: Int
    var isPremium: Bool
}

// Specifications to test
struct MinimumAgeSpec: Specification {
    typealias T = User
    let minimumAge: Int

    func isSatisfiedBy(_ candidate: User) -> Bool {
        return candidate.age >= minimumAge
    }
}

struct IsPremiumSpec: Specification {
    typealias T = User

    func isSatisfiedBy(_ candidate: User) -> Bool {
        return candidate.isPremium
    }
}

// Unit tests for individual specs
final class SpecificationTests: XCTestCase {
    func testMinimumAgeSpec() {
        let spec = MinimumAgeSpec(minimumAge: 18)

        let adult = User(name: "Alice", age: 25, isPremium: false)
        let minor = User(name: "Bob", age: 16, isPremium: false)

        XCTAssertTrue(spec.isSatisfiedBy(adult))
        XCTAssertFalse(spec.isSatisfiedBy(minor))
    }

    func testIsPremiumSpec() {
        let spec = IsPremiumSpec()

        let premium = User(name: "Alice", age: 25, isPremium: true)
        let regular = User(name: "Bob", age: 25, isPremium: false)

        XCTAssertTrue(spec.isSatisfiedBy(premium))
        XCTAssertFalse(spec.isSatisfiedBy(regular))
    }
}
