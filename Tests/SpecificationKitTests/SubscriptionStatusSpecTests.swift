import XCTest
@testable import SpecificationKit

final class SubscriptionStatusSpecTests: XCTestCase {
    func test_SubscriptionStatusSpec_matchesExpectedStatus() {
        let premiumCtx = EvaluationContext(userData: ["subscription_status": "premium"]) 
        let trialCtx = EvaluationContext(userData: ["subscription_status": "trial"]) 
        let missingCtx = EvaluationContext(userData: [:])

        XCTAssertTrue(SubscriptionStatusSpec(.premium).isSatisfiedBy(premiumCtx))
        XCTAssertFalse(SubscriptionStatusSpec(.premium).isSatisfiedBy(trialCtx))
        XCTAssertFalse(SubscriptionStatusSpec(.premium).isSatisfiedBy(missingCtx))
    }
}

