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
