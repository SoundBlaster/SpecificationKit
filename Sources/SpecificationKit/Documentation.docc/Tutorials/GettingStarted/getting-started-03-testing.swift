import Foundation
import SpecificationKit

// A simple User model
struct User {
    let name: String
    var age: Int
    var isPremium: Bool
}

// Check if user is old enough for premium features
struct MinimumAgeSpec: Specification {
    typealias T = User

    let minimumAge: Int

    func isSatisfiedBy(_ candidate: User) -> Bool {
        return candidate.age >= minimumAge
    }
}

// Test with sample users
let ageSpec = MinimumAgeSpec(minimumAge: 18)

let alice = User(name: "Alice", age: 25, isPremium: false)
let bob = User(name: "Bob", age: 16, isPremium: false)

print(ageSpec.isSatisfiedBy(alice))  // true
print(ageSpec.isSatisfiedBy(bob))    // false
