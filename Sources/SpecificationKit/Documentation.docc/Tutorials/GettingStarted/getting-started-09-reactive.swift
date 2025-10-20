import SwiftUI
import SpecificationKit

// A simple User model
struct User {
    let name: String
    var age: Int
    var isPremium: Bool
}

// Check eligibility from context
struct EligibilitySpec: Specification {
    typealias T = EvaluationContext

    func isSatisfiedBy(_ context: EvaluationContext) -> Bool {
        guard let user = context.userData(for: "currentUser", as: User.self) else {
            return false
        }
        return user.isPremium || user.age >= 18
    }
}

// Using @ObservedSatisfies for reactive updates
struct PremiumFeatureView: View {
    @ObservedObject var contextProvider: DefaultContextProvider

    // Automatically updates when context changes
    @ObservedSatisfies(using: EligibilitySpec())
    private var isEligible: Bool

    init(user: User, contextProvider: DefaultContextProvider = .shared) {
        self.contextProvider = contextProvider

        // Setup reactive context
        let context = EvaluationContext(userData: ["currentUser": user])
        contextProvider.setContext(context)

        self._isEligible = ObservedSatisfies(
            provider: contextProvider,
            using: EligibilitySpec()
        )
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("Premium Features")
                .font(.title)

            // UI updates automatically when context changes
            if isEligible {
                Text("Access granted!")
                    .foregroundColor(.green)
            } else {
                Text("Access denied")
                    .foregroundColor(.orange)
            }

            Button("Toggle Premium") {
                updateUserStatus()
            }
        }
        .padding()
    }

    func updateUserStatus() {
        // Update context - UI will refresh automatically
        if let user = contextProvider.context.userData(for: "currentUser", as: User.self) {
            let updated = User(name: user.name, age: user.age, isPremium: !user.isPremium)
            let newContext = EvaluationContext(userData: ["currentUser": updated])
            contextProvider.setContext(newContext)
        }
    }
}
