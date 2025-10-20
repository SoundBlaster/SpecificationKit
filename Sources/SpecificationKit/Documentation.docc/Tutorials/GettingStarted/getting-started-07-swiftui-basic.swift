import SwiftUI
import SpecificationKit

// A simple User model
struct User {
    let name: String
    var age: Int
    var isPremium: Bool
}

// Check if eligible for premium features
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

// Basic SwiftUI view with specification
struct PremiumFeatureView: View {
    let user: User
    let eligibilitySpec: any Specification<User>

    var body: some View {
        VStack(spacing: 20) {
            Text("Premium Features")
                .font(.title)

            if eligibilitySpec.isSatisfiedBy(user) {
                Text("Welcome, \(user.name)!")
                    .foregroundColor(.green)
                Text("You have access to premium features")
                    .font(.caption)
            } else {
                Text("Premium access required")
                    .foregroundColor(.orange)
                Text("Upgrade to unlock all features")
                    .font(.caption)
            }
        }
        .padding()
    }
}
