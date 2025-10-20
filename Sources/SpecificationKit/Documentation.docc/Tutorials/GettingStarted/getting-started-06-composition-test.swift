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

// Combine specs: eligible if premium OR old enough
let ageSpec = MinimumAgeSpec(minimumAge: 18)
let premiumSpec = IsPremiumSpec()
let eligibilitySpec = premiumSpec.or(ageSpec)

// Test different scenarios
let testCases = [
    User(name: "Premium teen", age: 16, isPremium: true),
    User(name: "Adult", age: 25, isPremium: false),
    User(name: "Teen", age: 16, isPremium: false),
    User(name: "Premium adult", age: 25, isPremium: true)
]

for user in testCases {
    let result = eligibilitySpec.isSatisfiedBy(user)
    print("\(user.name): \(result)")
}
