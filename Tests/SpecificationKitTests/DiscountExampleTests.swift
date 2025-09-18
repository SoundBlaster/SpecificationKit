//
//  SpecificationKitTests.swift
//  SpecificationKitTests
//
//  Created by SpecificationKit on 2025.
//

import XCTest

@testable import SpecificationKit

final class DiscountExampleTests: XCTestCase {

    func testDiscountExample_UserContext_Initialization() {
        // Given & When
        let defaultUser = DiscountExample.UserContext()
        let vipUser = DiscountExample.UserContext(isVip: true)
        let promoUser = DiscountExample.UserContext(isInPromo: true)
        let birthdayUser = DiscountExample.UserContext(isBirthday: true)
        let fullUser = DiscountExample.UserContext(isVip: true, isInPromo: true, isBirthday: true)

        // Then
        XCTAssertFalse(defaultUser.isVip)
        XCTAssertFalse(defaultUser.isInPromo)
        XCTAssertFalse(defaultUser.isBirthday)

        XCTAssertTrue(vipUser.isVip)
        XCTAssertFalse(vipUser.isInPromo)
        XCTAssertFalse(vipUser.isBirthday)

        XCTAssertFalse(promoUser.isVip)
        XCTAssertTrue(promoUser.isInPromo)
        XCTAssertFalse(promoUser.isBirthday)

        XCTAssertFalse(birthdayUser.isVip)
        XCTAssertFalse(birthdayUser.isInPromo)
        XCTAssertTrue(birthdayUser.isBirthday)

        XCTAssertTrue(fullUser.isVip)
        XCTAssertTrue(fullUser.isInPromo)
        XCTAssertTrue(fullUser.isBirthday)
    }

    func testDiscountExample_BasicSpecifications() {
        // Given
        let vipUser = DiscountExample.UserContext(isVip: true)
        let promoUser = DiscountExample.UserContext(isInPromo: true)
        let birthdayUser = DiscountExample.UserContext(isBirthday: true)
        let regularUser = DiscountExample.UserContext()

        // When & Then - VIP Spec
        XCTAssertTrue(DiscountExample.vipSpec.isSatisfiedBy(vipUser))
        XCTAssertFalse(DiscountExample.vipSpec.isSatisfiedBy(promoUser))
        XCTAssertFalse(DiscountExample.vipSpec.isSatisfiedBy(birthdayUser))
        XCTAssertFalse(DiscountExample.vipSpec.isSatisfiedBy(regularUser))

        // When & Then - Promo Spec
        XCTAssertFalse(DiscountExample.promoSpec.isSatisfiedBy(vipUser))
        XCTAssertTrue(DiscountExample.promoSpec.isSatisfiedBy(promoUser))
        XCTAssertFalse(DiscountExample.promoSpec.isSatisfiedBy(birthdayUser))
        XCTAssertFalse(DiscountExample.promoSpec.isSatisfiedBy(regularUser))

        // When & Then - Birthday Spec
        XCTAssertFalse(DiscountExample.birthdaySpec.isSatisfiedBy(vipUser))
        XCTAssertFalse(DiscountExample.birthdaySpec.isSatisfiedBy(promoUser))
        XCTAssertTrue(DiscountExample.birthdaySpec.isSatisfiedBy(birthdayUser))
        XCTAssertFalse(DiscountExample.birthdaySpec.isSatisfiedBy(regularUser))
    }

    func testDiscountExample_GetVipDiscount() {
        // Given
        let vipUser = DiscountExample.UserContext(isVip: true)
        let regularUser = DiscountExample.UserContext()

        // When & Then
        XCTAssertEqual(DiscountExample.getVipDiscount(user: vipUser), 50)
        XCTAssertNil(DiscountExample.getVipDiscount(user: regularUser))
    }

    func testDiscountExample_DiscountDecisionSpec() {
        // Given
        let spec = DiscountExample.DiscountDecisionSpec()
        let vipUser = DiscountExample.UserContext(isVip: true)
        let promoUser = DiscountExample.UserContext(isInPromo: true)
        let birthdayUser = DiscountExample.UserContext(isBirthday: true)
        let regularUser = DiscountExample.UserContext()

        // When & Then
        XCTAssertEqual(spec.decide(vipUser), 50)
        XCTAssertEqual(spec.decide(promoUser), 20)
        XCTAssertEqual(spec.decide(birthdayUser), 10)
        XCTAssertEqual(spec.decide(regularUser), 0)
    }

    func testDiscountExample_DiscountDecisionSpec_VipPriority() {
        // Given
        let spec = DiscountExample.DiscountDecisionSpec()
        let vipPromoUser = DiscountExample.UserContext(isVip: true, isInPromo: true)
        let vipBirthdayUser = DiscountExample.UserContext(isVip: true, isBirthday: true)
        let allUser = DiscountExample.UserContext(isVip: true, isInPromo: true, isBirthday: true)

        // When & Then - VIP should take priority
        XCTAssertEqual(spec.decide(vipPromoUser), 50)
        XCTAssertEqual(spec.decide(vipBirthdayUser), 50)
        XCTAssertEqual(spec.decide(allUser), 50)
    }

    func testDiscountExample_DiscountDecisionSpec_PromoPriority() {
        // Given
        let spec = DiscountExample.DiscountDecisionSpec()
        let promoBirthdayUser = DiscountExample.UserContext(isInPromo: true, isBirthday: true)

        // When & Then - Promo should take priority over birthday
        XCTAssertEqual(spec.decide(promoBirthdayUser), 20)
    }

    func testDiscountExample_FirstMatchSpecWithFallback() {
        // Given
        let spec = DiscountExample.discountSpec
        let vipUser = DiscountExample.UserContext(isVip: true)
        let promoUser = DiscountExample.UserContext(isInPromo: true)
        let birthdayUser = DiscountExample.UserContext(isBirthday: true)
        let regularUser = DiscountExample.UserContext()

        // When & Then
        XCTAssertEqual(spec.decide(vipUser), 50)
        XCTAssertEqual(spec.decide(promoUser), 20)
        XCTAssertEqual(spec.decide(birthdayUser), 10)
        XCTAssertEqual(spec.decide(regularUser), 0)
    }

    func testDiscountExample_FirstMatchSpec_Priority() {
        // Given
        let spec = DiscountExample.discountSpec
        let vipPromoUser = DiscountExample.UserContext(isVip: true, isInPromo: true)
        let vipBirthdayUser = DiscountExample.UserContext(isVip: true, isBirthday: true)
        let promoBirthdayUser = DiscountExample.UserContext(isInPromo: true, isBirthday: true)
        let allUser = DiscountExample.UserContext(isVip: true, isInPromo: true, isBirthday: true)

        // When & Then - Should respect order: VIP > Promo > Birthday
        XCTAssertEqual(spec.decide(vipPromoUser), 50)
        XCTAssertEqual(spec.decide(vipBirthdayUser), 50)
        XCTAssertEqual(spec.decide(promoBirthdayUser), 20)
        XCTAssertEqual(spec.decide(allUser), 50)
    }

    func testDiscountExample_GetDiscount() {
        // Given
        let vipUser = DiscountExample.UserContext(isVip: true)
        let promoUser = DiscountExample.UserContext(isInPromo: true)
        let birthdayUser = DiscountExample.UserContext(isBirthday: true)
        let regularUser = DiscountExample.UserContext()

        // When & Then
        XCTAssertEqual(DiscountExample.getDiscount(for: vipUser), 50)
        XCTAssertEqual(DiscountExample.getDiscount(for: promoUser), 20)
        XCTAssertEqual(DiscountExample.getDiscount(for: birthdayUser), 10)
        XCTAssertEqual(DiscountExample.getDiscount(for: regularUser), 0)
    }

    func testDiscountExample_GetDiscountMessage() {
        // Given
        let vipUser = DiscountExample.UserContext(isVip: true)
        let promoUser = DiscountExample.UserContext(isInPromo: true)
        let birthdayUser = DiscountExample.UserContext(isBirthday: true)
        let regularUser = DiscountExample.UserContext()

        // When & Then
        XCTAssertEqual(
            DiscountExample.getDiscountMessage(for: vipUser), "VIP Exclusive: 50% discount!")
        XCTAssertEqual(
            DiscountExample.getDiscountMessage(for: promoUser), "Special Promotion: 20% discount!")
        XCTAssertEqual(
            DiscountExample.getDiscountMessage(for: birthdayUser), "Birthday Special: 10% discount!"
        )
        XCTAssertEqual(DiscountExample.getDiscountMessage(for: regularUser), "Standard pricing")
    }

    func testDiscountExample_CreateDiscountSpecWithBuilder() {
        // Given
        let spec = DiscountExample.createDiscountSpec()
        let vipUser = DiscountExample.UserContext(isVip: true)
        let promoUser = DiscountExample.UserContext(isInPromo: true)
        let birthdayUser = DiscountExample.UserContext(isBirthday: true)
        let regularUser = DiscountExample.UserContext()

        // When & Then
        XCTAssertEqual(spec.decide(vipUser), 50)
        XCTAssertEqual(spec.decide(promoUser), 20)
        XCTAssertEqual(spec.decide(birthdayUser), 10)
        XCTAssertEqual(spec.decide(regularUser), 0)
    }

    func testDiscountExample_CreateDiscountSpec_Priority() {
        // Given
        let spec = DiscountExample.createDiscountSpec()
        let vipPromoUser = DiscountExample.UserContext(isVip: true, isInPromo: true)
        let vipBirthdayUser = DiscountExample.UserContext(isVip: true, isBirthday: true)
        let promoBirthdayUser = DiscountExample.UserContext(isInPromo: true, isBirthday: true)
        let allUser = DiscountExample.UserContext(isVip: true, isInPromo: true, isBirthday: true)

        // When & Then - Should respect order: VIP > Promo > Birthday > Always True
        XCTAssertEqual(spec.decide(vipPromoUser), 50)
        XCTAssertEqual(spec.decide(vipBirthdayUser), 50)
        XCTAssertEqual(spec.decide(promoBirthdayUser), 20)
        XCTAssertEqual(spec.decide(allUser), 50)
    }

    func testDiscountExample_EdgeCases() {
        // Given
        let spec = DiscountExample.discountSpec
        let vipOnlyUser = DiscountExample.UserContext(
            isVip: true, isInPromo: false, isBirthday: false)
        let promoOnlyUser = DiscountExample.UserContext(
            isVip: false, isInPromo: true, isBirthday: false)
        let birthdayOnlyUser = DiscountExample.UserContext(
            isVip: false, isInPromo: false, isBirthday: true)

        // When & Then - Ensure single condition works correctly
        XCTAssertEqual(spec.decide(vipOnlyUser), 50)
        XCTAssertEqual(spec.decide(promoOnlyUser), 20)
        XCTAssertEqual(spec.decide(birthdayOnlyUser), 10)
    }

    func testDiscountExample_ConsistencyBetweenMethods() {
        // Given
        let users = [
            DiscountExample.UserContext(isVip: true),
            DiscountExample.UserContext(isInPromo: true),
            DiscountExample.UserContext(isBirthday: true),
            DiscountExample.UserContext(),
            DiscountExample.UserContext(isVip: true, isInPromo: true),
            DiscountExample.UserContext(isVip: true, isBirthday: true),
            DiscountExample.UserContext(isInPromo: true, isBirthday: true),
            DiscountExample.UserContext(isVip: true, isInPromo: true, isBirthday: true),
        ]

        // When & Then - All methods should return consistent results
        for user in users {
            let discountFromFirstMatch = DiscountExample.discountSpec.decide(user) ?? 0
            let discountFromGetDiscount = DiscountExample.getDiscount(for: user)
            let discountFromBuilder = DiscountExample.createDiscountSpec().decide(user) ?? 0
            let discountFromDecisionSpec = DiscountExample.DiscountDecisionSpec().decide(user) ?? 0

            XCTAssertEqual(
                discountFromFirstMatch, discountFromGetDiscount,
                "FirstMatch and getDiscount should be consistent")
            XCTAssertEqual(
                discountFromFirstMatch, discountFromBuilder,
                "FirstMatch and builder should be consistent")
            XCTAssertEqual(
                discountFromFirstMatch, discountFromDecisionSpec,
                "FirstMatch and DecisionSpec should be consistent")
        }
    }

    func testDiscountExample_SpecificationComposition() {
        // Given
        let vipAndPromo = DiscountExample.vipSpec.and(DiscountExample.promoSpec)
        let vipOrBirthday = DiscountExample.vipSpec.or(DiscountExample.birthdaySpec)
        let notVip = DiscountExample.vipSpec.not()

        let vipUser = DiscountExample.UserContext(isVip: true)
        let promoUser = DiscountExample.UserContext(isInPromo: true)
        let birthdayUser = DiscountExample.UserContext(isBirthday: true)
        let vipPromoUser = DiscountExample.UserContext(isVip: true, isInPromo: true)
        let vipBirthdayUser = DiscountExample.UserContext(isVip: true, isBirthday: true)

        // When & Then - VIP AND Promo
        XCTAssertFalse(vipAndPromo.isSatisfiedBy(vipUser))
        XCTAssertFalse(vipAndPromo.isSatisfiedBy(promoUser))
        XCTAssertTrue(vipAndPromo.isSatisfiedBy(vipPromoUser))

        // When & Then - VIP OR Birthday
        XCTAssertTrue(vipOrBirthday.isSatisfiedBy(vipUser))
        XCTAssertFalse(vipOrBirthday.isSatisfiedBy(promoUser))
        XCTAssertTrue(vipOrBirthday.isSatisfiedBy(birthdayUser))
        XCTAssertTrue(vipOrBirthday.isSatisfiedBy(vipBirthdayUser))

        // When & Then - NOT VIP
        XCTAssertFalse(notVip.isSatisfiedBy(vipUser))
        XCTAssertTrue(notVip.isSatisfiedBy(promoUser))
        XCTAssertTrue(notVip.isSatisfiedBy(birthdayUser))
    }
}
