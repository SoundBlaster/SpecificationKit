//
//  DecisionsDemoLogicTests.swift
//  SpecificationKitTests
//

import XCTest
@testable import SpecificationKit

final class DecisionsDemoLogicTests: XCTestCase {

    override func setUp() {
        super.setUp()
        DefaultContextProvider.shared.clearAll()
    }

    private struct DecisionsHarness {
        // Mirror the demo view’s rules: VIP 50, Promo 20, fallback 0
        @Maybe([
            (PredicateSpec<EvaluationContext> { $0.flag(for: "vip") }, 50),
            (PredicateSpec<EvaluationContext> { $0.flag(for: "promo") }, 20)
        ]) var discountOptional: Int?

        @Decides([
            (PredicateSpec<EvaluationContext> { $0.flag(for: "vip") }, 50),
            (PredicateSpec<EvaluationContext> { $0.flag(for: "promo") }, 20)
        ], or: 0) var discountRequired: Int
    }

    func test_noneSelected_returnsNilAndZero() {
        // Given
        let provider = DefaultContextProvider.shared
        provider.setFlag("vip", to: false)
        provider.setFlag("promo", to: false)
        let harness = DecisionsHarness()

        // Then
        XCTAssertNil(harness.discountOptional)
        XCTAssertEqual(harness.discountRequired, 0)
    }

    func test_vipOnly_returns50() {
        let provider = DefaultContextProvider.shared
        provider.setFlag("vip", to: true)
        provider.setFlag("promo", to: false)
        let harness = DecisionsHarness()

        XCTAssertEqual(harness.discountOptional, 50)
        XCTAssertEqual(harness.discountRequired, 50)
    }

    func test_promoOnly_returns20() {
        let provider = DefaultContextProvider.shared
        provider.setFlag("vip", to: false)
        provider.setFlag("promo", to: true)
        let harness = DecisionsHarness()

        XCTAssertEqual(harness.discountOptional, 20)
        XCTAssertEqual(harness.discountRequired, 20)
    }

    func test_bothSelected_prefersVip50() {
        let provider = DefaultContextProvider.shared
        provider.setFlag("vip", to: true)
        provider.setFlag("promo", to: true)
        let harness = DecisionsHarness()

        XCTAssertEqual(harness.discountOptional, 50)
        XCTAssertEqual(harness.discountRequired, 50)
    }
}

