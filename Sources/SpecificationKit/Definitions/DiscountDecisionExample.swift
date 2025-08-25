//
//  DiscountDecisionExample.swift
//  SpecificationKit
//
//  Created by SpecificationKit on 2024.
//

import Foundation

/// An example demonstrating how to use DecisionSpec and FirstMatchSpec for a discount system.
public enum DiscountDecisionExample {

    /// A user context containing information needed for discount decisions
    public struct UserContext {
        /// Whether the user is a VIP
        public let isVip: Bool
        /// Whether the user is participating in a promotion
        public let isInPromo: Bool
        /// Whether it's the user's birthday
        public let isBirthday: Bool
        /// The user's purchase count
        public let purchaseCount: Int

        /// Creates a new user context
        /// - Parameters:
        ///   - isVip: Whether the user is a VIP
        ///   - isInPromo: Whether the user is in a promotion
        ///   - isBirthday: Whether it's the user's birthday
        ///   - purchaseCount: The user's purchase count
        public init(
            isVip: Bool = false,
            isInPromo: Bool = false,
            isBirthday: Bool = false,
            purchaseCount: Int = 0
        ) {
            self.isVip = isVip
            self.isInPromo = isInPromo
            self.isBirthday = isBirthday
            self.purchaseCount = purchaseCount
        }
    }

    /// A discount tier representing the percentage discount a user receives
    public enum DiscountTier: Int, Comparable {
        case none = 0
        case basic = 5
        case birthday = 10
        case promo = 20
        case loyal = 25
        case vip = 50

        /// The discount percentage
        public var percentage: Int { rawValue }

        /// Implements Comparable for DiscountTier
        public static func < (lhs: DiscountTier, rhs: DiscountTier) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    // MARK: - Individual Specifications

    /// Specification for VIP users
    public static let isVipSpec = PredicateSpec<UserContext> { $0.isVip }

    /// Specification for users in a promotion
    public static let isInPromoSpec = PredicateSpec<UserContext> { $0.isInPromo }

    /// Specification for users on their birthday
    public static let isBirthdaySpec = PredicateSpec<UserContext> { $0.isBirthday }

    /// Specification for loyal customers (10+ purchases)
    public static let isLoyalCustomerSpec = PredicateSpec<UserContext> { $0.purchaseCount >= 10 }

    /// Specification for basic customers (at least 1 purchase)
    public static let isBasicCustomerSpec = PredicateSpec<UserContext> { $0.purchaseCount >= 1 }

    // MARK: - FirstMatchSpec Implementation

    /// A specification that determines the appropriate discount tier for a user
    public static let discountTierSpec = FirstMatchSpec<UserContext, DiscountTier>([
        (isVipSpec, .vip),  // 50%
        (isInPromoSpec, .promo),  // 20%
        (isLoyalCustomerSpec, .loyal),  // 25%
        (isBirthdaySpec, .birthday),  // 10%
        (isBasicCustomerSpec, .basic),  // 5%
        (AlwaysTrueSpec<UserContext>(), .none),  // 0%
    ])

    // MARK: - Example Usage Methods

    /// Gets the appropriate discount tier for a user
    /// - Parameter user: The user context
    /// - Returns: The discount tier
    public static func getDiscountTier(for user: UserContext) -> DiscountTier {
        // Use the first-match spec to determine the tier
        return discountTierSpec.decide(user) ?? .none
    }

    /// Calculates the final price after applying the appropriate discount
    /// - Parameters:
    ///   - originalPrice: The original price
    ///   - user: The user context
    /// - Returns: The discounted price
    public static func calculateFinalPrice(originalPrice: Double, for user: UserContext) -> Double {
        let tier = getDiscountTier(for: user)
        let discountAmount = originalPrice * Double(tier.percentage) / 100.0
        return originalPrice - discountAmount
    }

    // MARK: - Custom DecisionSpec Implementation

    /// A custom DecisionSpec implementation for determining the discount message
    public struct DiscountMessageSpec: DecisionSpec {
        public typealias Context = UserContext
        public typealias Result = String

        public func decide(_ context: Context) -> String? {
            if context.isVip {
                return "VIP Exclusive Discount: 50% off!"
            } else if context.isInPromo {
                return "Special Promotion: 20% off your purchase!"
            } else if context.purchaseCount >= 10 {
                return "Loyal Customer Reward: 25% off!"
            } else if context.isBirthday {
                return "Happy Birthday! 10% off today!"
            } else if context.purchaseCount >= 1 {
                return "Thanks for shopping with us! 5% off!"
            } else {
                return "Welcome! Shop with us to earn discounts."
            }
        }
    }

    // MARK: - Property Wrapper Example

    /// A service that demonstrates using @Spec for discount determination
    public final class DiscountService {
        /// The current user context
        public var userContext: UserContext

        /// The discount tier determined by the first-match spec
        @Spec(
            FirstMatchSpec([
                (isVipSpec, DiscountTier.vip),
                (isInPromoSpec, DiscountTier.promo),
                (isLoyalCustomerSpec, DiscountTier.loyal),
                (isBirthdaySpec, DiscountTier.birthday),
                (isBasicCustomerSpec, DiscountTier.basic),
                (AlwaysTrueSpec<UserContext>(), DiscountTier.none),
            ]))
        public var discountTier: DiscountTier

        /// The discount message determined by a custom DecisionSpec
        public var discountMessage: String {
            DiscountMessageSpec().decide(userContext) ?? "No discount available"
        }

        /// Creates a new discount service with the given user context
        /// - Parameter userContext: The user context to use for discount determination
        public init(userContext: UserContext) {
            self.userContext = userContext

            // Register the context with the default provider
            DefaultContextProvider.shared.register(
                contextKey: "UserContext",
                provider: { [weak self] in self?.userContext ?? UserContext() }
            )
        }

        /// Calculates the final price after applying the discount
        /// - Parameter originalPrice: The original price
        /// - Returns: The discounted price
        public func calculatePrice(originalPrice: Double) -> Double {
            let discountPercentage = Double(discountTier.percentage)
            let discountAmount = originalPrice * discountPercentage / 100.0
            return originalPrice - discountAmount
        }
    }
}
