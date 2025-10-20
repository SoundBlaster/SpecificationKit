import Foundation
import SpecificationKit

// A simple User model
struct User {
    let name: String
    var age: Int
    var isPremium: Bool
}

// Check if user is old enough
struct MinimumAgeSpec: Specification {
    typealias T = User
    let minimumAge: Int

    func isSatisfiedBy(_ candidate: User) -> Bool {
        return candidate.age >= minimumAge
    }
}

// Check if user has premium subscription
struct IsPremiumSpec: Specification {
    typealias T = User

    func isSatisfiedBy(_ candidate: User) -> Bool {
        return candidate.isPremium
    }
}

// Combine specs with logical operators
let ageSpec = MinimumAgeSpec(minimumAge: 18)
let premiumSpec = IsPremiumSpec()

// User is eligible if they're premium OR old enough
let eligibilitySpec = premiumSpec.or(ageSpec)

// Test it
let alice = User(name: "Alice", age: 16, isPremium: true)
let bob = User(name: "Bob", age: 25, isPremium: false)
let charlie = User(name: "Charlie", age: 16, isPremium: false)

print(eligibilitySpec.isSatisfiedBy(alice))    // true (premium)
print(eligibilitySpec.isSatisfiedBy(bob))      // true (old enough)
print(eligibilitySpec.isSatisfiedBy(charlie))  // false (neither)
