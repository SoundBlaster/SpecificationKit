import XCTest
import SpecificationKit

final class UserEligibilitySpecTests: XCTestCase {
    private let spec = PremiumEligibilitySpec(minimumAge: 21, minimumReferrals: 3)
    private let rules = PremiumEligibilityRules(minimumAge: 21, minimumReferrals: 3)

    func testPremiumSubscriberIsEligible() {
        // Given
        let user = User(
            id: UUID(),
            age: 25,
            referralCount: 0,
            isPremiumSubscriber: true,
            isOnboardingComplete: true,
            hasDelinquentPayments: false
        )

        // When
        let result = spec.isSatisfiedBy(user)

        // Then
        XCTAssertTrue(result)
    }

    func testUserWithoutOnboardingIsRejected() {
        // Given
        let user = User(
            id: UUID(),
            age: 30,
            referralCount: 5,
            isPremiumSubscriber: false,
            isOnboardingComplete: false,
            hasDelinquentPayments: false
        )

        // When
        let result = spec.isSatisfiedBy(user)

        // Then
        XCTAssertFalse(result)
    }

    func testReferralPathUnlocksEligibility() {
        // Given
        let user = User(
            id: UUID(),
            age: 28,
            referralCount: 5,
            isPremiumSubscriber: false,
            isOnboardingComplete: true,
            hasDelinquentPayments: false
        )

        // When
        let compositeResult = rules.evaluate(user)

        // Then
        XCTAssertTrue(compositeResult)
    }

    func testDelinquentPaymentsBlockAccess() {
        // Given
        let user = User(
            id: UUID(),
            age: 35,
            referralCount: 8,
            isPremiumSubscriber: false,
            isOnboardingComplete: true,
            hasDelinquentPayments: true
        )

        // When
        let compositeResult = rules.evaluate(user)

        // Then
        XCTAssertFalse(compositeResult)
    }
}
