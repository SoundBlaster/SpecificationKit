import Foundation
import SpecificationKit

struct User {
    let id: UUID
    var age: Int
    var referralCount: Int
    var isPremiumSubscriber: Bool
    var isOnboardingComplete: Bool
    var hasDelinquentPayments: Bool
}

struct PremiumEligibilitySpec: Specification {
    typealias T = User

    let minimumAge: Int
    let minimumReferrals: Int

    func isSatisfiedBy(_ candidate: User) -> Bool {
        guard candidate.isOnboardingComplete else { return false }
        guard candidate.hasDelinquentPayments == false else { return false }

        if candidate.isPremiumSubscriber {
            return true
        }

        let meetsAgeRequirement = candidate.age >= minimumAge
        let meetsReferralRequirement = candidate.referralCount >= minimumReferrals
        return meetsAgeRequirement && meetsReferralRequirement
    }
}

struct PremiumEligibilityExamples {
    private let spec = PremiumEligibilitySpec(minimumAge: 21, minimumReferrals: 3)

    func evaluateSampleUsers() -> [String: Bool] {
        let premiumSubscriber = User(
            id: UUID(),
            age: 25,
            referralCount: 1,
            isPremiumSubscriber: true,
            isOnboardingComplete: true,
            hasDelinquentPayments: false
        )

        let engagedUser = User(
            id: UUID(),
            age: 29,
            referralCount: 4,
            isPremiumSubscriber: false,
            isOnboardingComplete: true,
            hasDelinquentPayments: false
        )

        let blockedUser = User(
            id: UUID(),
            age: 31,
            referralCount: 6,
            isPremiumSubscriber: false,
            isOnboardingComplete: true,
            hasDelinquentPayments: true
        )

        return [
            "PremiumSubscriber": spec.isSatisfiedBy(premiumSubscriber),
            "EngagedUser": spec.isSatisfiedBy(engagedUser),
            "BlockedUser": spec.isSatisfiedBy(blockedUser)
        ]
    }
}
