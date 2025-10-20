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

struct PremiumEligibilityRules {
    private let subscription = ActiveSubscriptionSpec()
    private let onboarding = OnboardingCompleteSpec()
    private let delinquent = DelinquentPaymentsSpec()
    private let referrals: ReferralRequirementSpec
    private let minimumAge: MinimumAgeSpec

    init(minimumAge: Int = 21, minimumReferrals: Int = 3) {
        self.referrals = ReferralRequirementSpec(minimumReferrals: minimumReferrals)
        self.minimumAge = MinimumAgeSpec(minimumAge: minimumAge)
    }

    func evaluate(_ user: User) -> Bool {
        let subscriberPath = subscription.and(delinquent.not())
        let referralPath = referrals.and(minimumAge)
        let combinedEligibility = subscriberPath.or(referralPath)
        return combinedEligibility.and(onboarding).isSatisfiedBy(user)
    }
}

struct PremiumEligibilityExamples {
    private let rules = PremiumEligibilityRules()

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
            "PremiumSubscriber": rules.evaluate(premiumSubscriber),
            "EngagedUser": rules.evaluate(engagedUser),
            "BlockedUser": rules.evaluate(blockedUser)
        ]
    }
}
