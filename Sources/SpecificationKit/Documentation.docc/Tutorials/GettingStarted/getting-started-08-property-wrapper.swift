import SwiftUI
import SpecificationKit

// A simple User model
struct User {
    let name: String
    var age: Int
    var isPremium: Bool
}

// Check eligibility: premium OR old enough
struct EligibilitySpec: Specification {
    typealias T = EvaluationContext

    func isSatisfiedBy(_ context: EvaluationContext) -> Bool {
        guard let user = context.userData(for: "currentUser", as: User.self) else {
            return false
        }
        return user.isPremium || user.age >= 18
    }
}

// Using @Satisfies property wrapper
struct PremiumFeatureView: View {
    let user: User

    // Declarative specification evaluation
    @Satisfies(using: EligibilitySpec())
    private var isEligible: Bool

    init(user: User) {
        self.user = user

        // Setup context with user data
        let context = EvaluationContext(userData: ["currentUser": user])
        self._isEligible = Satisfies(
            provider: staticContext(context),
            using: EligibilitySpec()
        )
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("Premium Features")
                .font(.title)

            // Use the property wrapper result
            if isEligible {
                Text("Welcome, \(user.name)!")
                    .foregroundColor(.green)
            } else {
                Text("Access denied")
                    .foregroundColor(.orange)
            }
        }
        .padding()
    }
}
