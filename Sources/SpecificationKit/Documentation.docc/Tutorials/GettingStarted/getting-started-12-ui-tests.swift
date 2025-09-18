import XCTest
import SwiftUI
import SpecificationKit

final class PremiumFeatureViewTests: XCTestCase {
    func testViewReadsEligibilityFromContextProvider() {
        // Given
        let rules = PremiumEligibilityRules(minimumAge: 21, minimumReferrals: 3)
        let provider = MockContextProvider()

        let eligibleUser = User(
            id: UUID(),
            age: 27,
            referralCount: 5,
            isPremiumSubscriber: false,
            isOnboardingComplete: true,
            hasDelinquentPayments: false
        )

        provider.setContext(provider.mockContext.withUserData(["user": eligibleUser]))
        var view = PremiumFeatureView(user: eligibleUser, rules: rules, provider: provider)

        // When
        let initialEligibility = view.eligibilityStatus()

        // Then
        XCTAssertTrue(initialEligibility)

        // When
        let delinquentUser = User(
            id: UUID(),
            age: 32,
            referralCount: 6,
            isPremiumSubscriber: false,
            isOnboardingComplete: true,
            hasDelinquentPayments: true
        )
        view.updateUser(delinquentUser)
        let updatedEligibility = view.eligibilityStatus()

        // Then
        XCTAssertFalse(updatedEligibility)
    }
}
