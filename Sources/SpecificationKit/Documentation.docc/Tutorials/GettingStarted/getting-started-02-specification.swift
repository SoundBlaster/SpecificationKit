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
