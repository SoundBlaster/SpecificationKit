//
//  FirstMatchSpecTests.swift
//  SpecificationKitTests
//
//  Created by SpecificationKit on 2025.
//

import XCTest

@testable import SpecificationKit

final class FirstMatchSpecTests: XCTestCase {

    // Test context
    struct UserContext {
        var isVip: Bool
        var isInPromo: Bool
        var isBirthday: Bool
    }

    // MARK: - Single match tests

    func test_firstMatch_returnsPayload_whenSingleSpecMatches() {
        // Arrange
        let vipSpec = PredicateSpec<UserContext> { $0.isVip }
        let spec = FirstMatchSpec<UserContext, Int>([
            (vipSpec, 50)
        ])
        let context = UserContext(isVip: true, isInPromo: false, isBirthday: false)

        // Act
        let result = spec.decide(context)

        // Assert
        XCTAssertEqual(result, 50)
    }

    // MARK: - Multiple matches tests

    func test_firstMatch_returnsFirstPayload_whenMultipleSpecsMatch() {
        // Arrange
        let vipSpec = PredicateSpec<UserContext> { $0.isVip }
        let promoSpec = PredicateSpec<UserContext> { $0.isInPromo }

        let spec = FirstMatchSpec<UserContext, Int>([
            (vipSpec, 50),
            (promoSpec, 20),
        ])

        let context = UserContext(isVip: true, isInPromo: true, isBirthday: false)

        // Act
        let result = spec.decide(context)

        // Assert
        XCTAssertEqual(result, 50, "Should return the result of the first matching spec")
    }

    // MARK: - No match tests

    func test_firstMatch_returnsNil_whenNoSpecsMatch() {
        // Arrange
        let vipSpec = PredicateSpec<UserContext> { $0.isVip }
        let promoSpec = PredicateSpec<UserContext> { $0.isInPromo }

        let spec = FirstMatchSpec<UserContext, Int>([
            (vipSpec, 50),
            (promoSpec, 20),
        ])

        let context = UserContext(isVip: false, isInPromo: false, isBirthday: true)

        // Act
        let result = spec.decide(context)

        // Assert
        XCTAssertNil(result, "Should return nil when no specs match")
    }

    // MARK: - Fallback tests

    func test_firstMatch_withFallbackSpec_returnsFallbackPayload() {
        // Arrange
        let vipSpec = PredicateSpec<UserContext> { $0.isVip }
        let promoSpec = PredicateSpec<UserContext> { $0.isInPromo }
        let spec = FirstMatchSpec<UserContext, Int>.withFallback([
            (vipSpec, 50),
            (promoSpec, 20)
        ], fallback: 0)

        let context = UserContext(isVip: false, isInPromo: false, isBirthday: false)

        // Act
        let result = spec.decide(context)

        // Assert
        XCTAssertEqual(result, 0, "Should return fallback value when no other specs match")
    }

    // MARK: - Builder pattern

    func test_builder_createsCorrectFirstMatchSpec() {
        // Arrange
        let builder = FirstMatchSpec<UserContext, Int>.builder()
            .add(PredicateSpec<UserContext> { $0.isVip }, result: 50)
            .add(PredicateSpec<UserContext> { $0.isInPromo }, result: 20)
            .add(AlwaysTrueSpec<UserContext>(), result: 0)

        let spec = builder.build()

        // Act & Assert
        let vipContext = UserContext(isVip: true, isInPromo: false, isBirthday: false)
        XCTAssertEqual(spec.decide(vipContext), 50)

        let promoContext = UserContext(isVip: false, isInPromo: true, isBirthday: false)
        XCTAssertEqual(spec.decide(promoContext), 20)

        let noneContext = UserContext(isVip: false, isInPromo: false, isBirthday: false)
        XCTAssertEqual(spec.decide(noneContext), 0)
    }
}
