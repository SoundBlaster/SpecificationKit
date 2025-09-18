import SwiftUI
import SpecificationKit

struct PremiumFeatureView: View {
    private let user: User
    private let spec: PremiumEligibilitySpec

    init(
        user: User,
        spec: PremiumEligibilitySpec = PremiumEligibilitySpec(minimumAge: 21, minimumReferrals: 3)
    ) {
        self.user = user
        self.spec = spec
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Premium Hub")
                .font(.title)

            if spec.isSatisfiedBy(user) {
                PremiumContentView(user: user)
            } else {
                LockedContentView()
            }
        }
        .padding()
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
