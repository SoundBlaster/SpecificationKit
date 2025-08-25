//
//  DecisionSpecTests.swift
//  SpecificationKitTests
//
//  Created by SpecificationKit on 2024.
//

import XCTest

@testable import SpecificationKit

final class DecisionSpecTests: XCTestCase {

    // Test context for discount decisions
    struct UserContext {
        var isVip: Bool
        var isInPromo: Bool
        var isBirthday: Bool
    }

    // MARK: - Basic DecisionSpec Tests

    func testDecisionSpec_returnsResult_whenSatisfied() {
        // Arrange
        let vipSpec = PredicateSpec<UserContext> { $0.isVip }
        let decision = vipSpec.returning(50)
        let vipContext = UserContext(isVip: true, isInPromo: false, isBirthday: false)

        // Act
        let result = decision.decide(vipContext)

        // Assert
        XCTAssertEqual(result, 50)
    }

    func testDecisionSpec_returnsNil_whenNotSatisfied() {
        // Arrange
        let vipSpec = PredicateSpec<UserContext> { $0.isVip }
        let decision = vipSpec.returning(50)
        let nonVipContext = UserContext(isVip: false, isInPromo: true, isBirthday: false)

        // Act
        let result = decision.decide(nonVipContext)

        // Assert
        XCTAssertNil(result)
    }

    // MARK: - FirstMatchSpec Tests

    func testFirstMatchSpec_returnsFirstMatchingResult() {
        // Arrange
        let vipSpec = PredicateSpec<UserContext> { $0.isVip }
        let promoSpec = PredicateSpec<UserContext> { $0.isInPromo }
        let birthdaySpec = PredicateSpec<UserContext> { $0.isBirthday }

        // Create a specification that evaluates each spec in order
        let discountSpec = FirstMatchSpec<UserContext, Int>([
            (vipSpec, 50),
            (promoSpec, 20),
            (birthdaySpec, 10),
        ])

        // Act & Assert

        // VIP context - should return 50
        let vipContext = UserContext(isVip: true, isInPromo: false, isBirthday: false)
        XCTAssertEqual(discountSpec.decide(vipContext), 50)

        // Promo context - should return 20
        let promoContext = UserContext(isVip: false, isInPromo: true, isBirthday: false)
        XCTAssertEqual(discountSpec.decide(promoContext), 20)

        // Birthday context - should return 10
        let birthdayContext = UserContext(isVip: false, isInPromo: false, isBirthday: true)
        XCTAssertEqual(discountSpec.decide(birthdayContext), 10)

        // None matching - should return nil
        let noMatchContext = UserContext(isVip: false, isInPromo: false, isBirthday: false)
        XCTAssertNil(discountSpec.decide(noMatchContext))
    }

    func testFirstMatchSpec_shortCircuits_atFirstMatch() {
        // Arrange
        var secondSpecEvaluated = false
        var thirdSpecEvaluated = false

        let firstSpec = PredicateSpec<UserContext> { $0.isVip }
        let secondSpec = PredicateSpec<UserContext> { _ in
            secondSpecEvaluated = true
            return true
        }
        let thirdSpec = PredicateSpec<UserContext> { _ in
            thirdSpecEvaluated = true
            return true
        }

        let discountSpec = FirstMatchSpec<UserContext, Int>([
            (firstSpec, 50),
            (secondSpec, 20),
            (thirdSpec, 10),
        ])

        let vipContext = UserContext(isVip: true, isInPromo: false, isBirthday: false)

        // Act
        _ = discountSpec.decide(vipContext)

        // Assert
        XCTAssertFalse(secondSpecEvaluated, "Second spec should not be evaluated")
        XCTAssertFalse(thirdSpecEvaluated, "Third spec should not be evaluated")
    }

    func testFirstMatchSpec_withFallback_alwaysReturnsResult() {
        // Arrange
        let vipSpec = PredicateSpec<UserContext> { $0.isVip }
        let promoSpec = PredicateSpec<UserContext> { $0.isInPromo }
        let birthdaySpec = PredicateSpec<UserContext> { $0.isBirthday }
        let alwaysTrueSpec = AlwaysTrueSpec<UserContext>()

        // Create a specification with fallback
        let discountSpec = FirstMatchSpec<UserContext, Int>([
            (vipSpec, 50),
            (promoSpec, 20),
            (birthdaySpec, 10),
            (alwaysTrueSpec, 0),  // Fallback
        ])

        // None matching - should return fallback value
        let noMatchContext = UserContext(isVip: false, isInPromo: false, isBirthday: false)
        XCTAssertEqual(discountSpec.decide(noMatchContext), 0)
    }

    func testFirstMatchSpec_builder_createsCorrectSpec() {
        // Arrange
        let builder = FirstMatchSpec<UserContext, Int>.builder()
            .add(PredicateSpec<UserContext> { $0.isVip }, result: 50)
            .add(PredicateSpec<UserContext> { $0.isInPromo }, result: 20)
            .add(PredicateSpec<UserContext> { $0.isBirthday }, result: 10)
            .add(AlwaysTrueSpec<UserContext>(), result: 0)

        let discountSpec = builder.build()

        // Act & Assert
        let vipContext = UserContext(isVip: true, isInPromo: false, isBirthday: false)
        XCTAssertEqual(discountSpec.decide(vipContext), 50)

        let noMatchContext = UserContext(isVip: false, isInPromo: false, isBirthday: false)
        XCTAssertEqual(discountSpec.decide(noMatchContext), 0)
    }

    // MARK: - Custom DecisionSpec Tests

    func testCustomDecisionSpec_implementsLogic() {
        // Arrange
        struct RouteDecisionSpec: DecisionSpec {
            typealias Context = String  // URL path
            typealias Result = String  // Route name

            func decide(_ context: String) -> String? {
                if context.starts(with: "/admin") {
                    return "admin"
                } else if context.starts(with: "/user") {
                    return "user"
                } else if context.starts(with: "/api") {
                    return "api"
                } else if context == "/" {
                    return "home"
                }
                return nil
            }
        }

        let routeSpec = RouteDecisionSpec()

        // Act & Assert
        XCTAssertEqual(routeSpec.decide("/admin/dashboard"), "admin")
        XCTAssertEqual(routeSpec.decide("/user/profile"), "user")
        XCTAssertEqual(routeSpec.decide("/api/v1/data"), "api")
        XCTAssertEqual(routeSpec.decide("/"), "home")
        XCTAssertNil(routeSpec.decide("/unknown/path"))
    }
}
