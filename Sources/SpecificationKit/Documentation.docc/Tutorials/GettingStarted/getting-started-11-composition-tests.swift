import XCTest
import SpecificationKit

// A simple User model
struct User {
    let name: String
    var age: Int
    var isPremium: Bool
}

// Specifications
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

// Test composed specifications
final class CompositionTests: XCTestCase {
    let ageSpec = MinimumAgeSpec(minimumAge: 18)
    let premiumSpec = IsPremiumSpec()

    func testOrComposition() {
        // Eligible if premium OR old enough
        let eligibilitySpec = premiumSpec.or(ageSpec)

        let premiumTeen = User(name: "Alice", age: 16, isPremium: true)
        let regularAdult = User(name: "Bob", age: 25, isPremium: false)
        let regularTeen = User(name: "Charlie", age: 16, isPremium: false)

        XCTAssertTrue(eligibilitySpec.isSatisfiedBy(premiumTeen))
        XCTAssertTrue(eligibilitySpec.isSatisfiedBy(regularAdult))
        XCTAssertFalse(eligibilitySpec.isSatisfiedBy(regularTeen))
    }

    func testAndComposition() {
        // Eligible if premium AND old enough
        let vipSpec = premiumSpec.and(ageSpec)

        let premiumAdult = User(name: "Alice", age: 25, isPremium: true)
        let premiumTeen = User(name: "Bob", age: 16, isPremium: true)
        let regularAdult = User(name: "Charlie", age: 25, isPremium: false)

        XCTAssertTrue(vipSpec.isSatisfiedBy(premiumAdult))
        XCTAssertFalse(vipSpec.isSatisfiedBy(premiumTeen))
        XCTAssertFalse(vipSpec.isSatisfiedBy(regularAdult))
    }

    func testNotComposition() {
        // Not premium (free users only)
        let freeUserSpec = premiumSpec.not()

        let premium = User(name: "Alice", age: 25, isPremium: true)
        let regular = User(name: "Bob", age: 25, isPremium: false)

        XCTAssertFalse(freeUserSpec.isSatisfiedBy(premium))
        XCTAssertTrue(freeUserSpec.isSatisfiedBy(regular))
    }
}
