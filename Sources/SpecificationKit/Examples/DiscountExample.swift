//
//  DiscountExample.swift
//  SpecificationKit
//
//  Created by SpecificationKit on 2024.
//

import Foundation

/// A simple example showing how to use DecisionSpec and FirstMatchSpec for determining discounts
public enum DiscountExample {

    /// A user context for discount determination
    public struct UserContext {
        /// Whether the user is a VIP
        public let isVip: Bool
        /// Whether the user is in a promotional campaign
        public let isInPromo: Bool
        /// Whether it's the user's birthday
        public let isBirthday: Bool

        /// Creates a new user context
        public init(isVip: Bool = false, isInPromo: Bool = false, isBirthday: Bool = false) {
            self.isVip = isVip
            self.isInPromo = isInPromo
            self.isBirthday = isBirthday
        }
    }

    // MARK: - Basic Specifications

    /// Specification for VIP users
    public static let vipSpec = PredicateSpec<UserContext> { $0.isVip }

    /// Specification for users in a promotional campaign
    public static let promoSpec = PredicateSpec<UserContext> { $0.isInPromo }

    /// Specification for users on their birthday
    public static let birthdaySpec = PredicateSpec<UserContext> { $0.isBirthday }

    // MARK: - DecisionSpec Usage

    /// Convert a boolean specification to a decision specification with a result
    public static func getVipDiscount(user: UserContext) -> Int? {
        vipSpec.returning(50).decide(user)
    }

    /// A custom decision specification that returns a discount percentage
    public struct DiscountDecisionSpec: DecisionSpec {
        public typealias Context = UserContext
        public typealias Result = Int

        public func decide(_ context: Context) -> Int? {
            if context.isVip {
                return 50
            } else if context.isInPromo {
                return 20
            } else if context.isBirthday {
                return 10
            }
            return 0
        }
    }

    // MARK: - FirstMatchSpec Usage

    /// A first-match specification that determines the appropriate discount
    public static let discountSpec = FirstMatchSpec<UserContext, Int>.withFallback([
        (vipSpec, 50),
        (promoSpec, 20),
        (birthdaySpec, 10)
    ], fallback: 0)

    /// Gets the discount percentage for a user
    public static func getDiscount(for user: UserContext) -> Int {
        // The ?? 0 is actually unnecessary because we have a fallback,
        // but it's included for clarity
        return discountSpec.decide(user) ?? 0
    }

    /// Gets the discount message for a user
    public static func getDiscountMessage(for user: UserContext) -> String {
        let discount = getDiscount(for: user)

        switch discount {
        case 50:
            return "VIP Exclusive: 50% discount!"
        case 20:
            return "Special Promotion: 20% discount!"
        case 10:
            return "Birthday Special: 10% discount!"
        default:
            return "Standard pricing"
        }
    }

    // MARK: - Using the Builder Pattern

    /// Creates a discount specification using the builder pattern
    public static func createDiscountSpec() -> FirstMatchSpec<UserContext, Int> {
        FirstMatchSpec<UserContext, Int>.builder()
            .add(vipSpec, result: 50)
            .add(promoSpec, result: 20)
            .add(birthdaySpec, result: 10)
            .add(AlwaysTrueSpec<UserContext>(), result: 0)
            .build()
    }

    // MARK: - Usage Example

    /// Example of how to use these specifications
    public static func example() {
        // Create a VIP user
        let vipUser = UserContext(isVip: true)

        // Get the discount using FirstMatchSpec
        let discount = getDiscount(for: vipUser)
        print("Discount: \(discount)%")

        // Get the discount message
        let message = getDiscountMessage(for: vipUser)
        print(message)

        // Try different user types
        let promoUser = UserContext(isInPromo: true)
        let birthdayUser = UserContext(isBirthday: true)
        let regularUser = UserContext()

        print("Promo user discount: \(getDiscount(for: promoUser))%")
        print("Birthday user discount: \(getDiscount(for: birthdayUser))%")
        print("Regular user discount: \(getDiscount(for: regularUser))%")
    }
}
