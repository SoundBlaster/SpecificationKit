//
//  DecidesOrWrapperTests.swift
//  SpecificationKitTests
//

import XCTest
@testable import SpecificationKit

final class DecidesOrWrapperTests: XCTestCase {

    func test_DecidesOr_returnsFallback_whenNoMatch() {
        // Given
        let vip = PredicateSpec<EvaluationContext> { $0.flag(for: "vip") }
        let promo = PredicateSpec<EvaluationContext> { $0.flag(for: "promo") }

        let provider = DefaultContextProvider.shared
        provider.setFlag("vip", to: false)
        provider.setFlag("promo", to: false)

        // When
        @DecidesOr(FirstMatchSpec([
            (vip, 1),
            (promo, 2)
        ]), fallback: 0) var value: Int

        // Then
        XCTAssertEqual(value, 0)
    }

    func test_DecidesOr_returnsMatchedValue_whenMatchExists() {
        // Given
        let vip = PredicateSpec<EvaluationContext> { $0.flag(for: "vip") }
        DefaultContextProvider.shared.setFlag("vip", to: true)

        // When
        @DecidesOr(FirstMatchSpec([
            (vip, 42)
        ]), fallback: 0) var value: Int

        // Then
        XCTAssertEqual(value, 42)
    }

    func test_DecidesOr_wrappedValueDefault_initializesFallback() {
        // Given
        let vip = PredicateSpec<EvaluationContext> { $0.flag(for: "vip") }
        DefaultContextProvider.shared.setFlag("vip", to: false)

        // When: use default value shorthand for fallback
        @DecidesOr(FirstMatchSpec([
            (vip, 99)
        ])) var discount: Int = 0

        // Then: no match -> returns default value
        XCTAssertEqual(discount, 0)
    }
}
