import SwiftUI
import SpecificationKit

struct PremiumEligibilityContextSpec: Specification {
    typealias T = EvaluationContext

    private let rules: PremiumEligibilityRules

    init(rules: PremiumEligibilityRules) {
        self.rules = rules
    }

    func isSatisfiedBy(_ candidate: EvaluationContext) -> Bool {
        guard let user = candidate.userData(for: "user", as: User.self) else { return false }
        return rules.evaluate(user)
    }
}

struct PremiumFeatureView: View {
    private let user: User
    private let rules: PremiumEligibilityRules

    @Satisfies(provider: staticContext(EvaluationContext()), using: PremiumEligibilityContextSpec(rules: PremiumEligibilityRules()))
    private var isEligible: Bool

    init(user: User, rules: PremiumEligibilityRules = PremiumEligibilityRules()) {
        self.user = user
        self.rules = rules

        let provider = staticContext(EvaluationContext(userData: ["user": user]))
        self._isEligible = Satisfies(provider: provider, using: PremiumEligibilityContextSpec(rules: rules))
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Premium Hub")
                .font(.title)

            if isEligible {
                PremiumContentView(user: user)
            } else {
                LockedContentView()
            }
        }
        .padding()
    }

    func eligibilityStatus() -> Bool {
        isEligible
    }
}

struct PremiumContentView: View {
    let user: User

    var body: some View {
        VStack(spacing: 8) {
            Text("Welcome back, \(user.id.uuidString.prefix(6))!")
                .font(.headline)
            Text("Enjoy premium insights tailored to you.")
                .font(.subheadline)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.green.opacity(0.2))
        .cornerRadius(12)
    }
}

struct LockedContentView: View {
    var body: some View {
        VStack(spacing: 8) {
            Text("Premium content locked")
                .font(.headline)
            Text("Complete onboarding to unlock feature access.")
                .font(.subheadline)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.gray.opacity(0.15))
        .cornerRadius(12)
    }
}
