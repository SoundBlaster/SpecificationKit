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

struct MinimumAgeSpec: Specification {
    typealias T = User
    let minimumAge: Int

    func isSatisfiedBy(_ candidate: User) -> Bool {
        candidate.age >= minimumAge
    }
}

struct ReferralRequirementSpec: Specification {
    typealias T = User
    let minimumReferrals: Int

    func isSatisfiedBy(_ candidate: User) -> Bool {
        candidate.referralCount >= minimumReferrals
    }
}

struct ActiveSubscriptionSpec: Specification {
    typealias T = User

    func isSatisfiedBy(_ candidate: User) -> Bool {
        candidate.isPremiumSubscriber
    }
}

struct OnboardingCompleteSpec: Specification {
    typealias T = User

    func isSatisfiedBy(_ candidate: User) -> Bool {
        candidate.isOnboardingComplete
    }
}

struct DelinquentPaymentsSpec: Specification {
    typealias T = User

    func isSatisfiedBy(_ candidate: User) -> Bool {
        candidate.hasDelinquentPayments
    }
}
