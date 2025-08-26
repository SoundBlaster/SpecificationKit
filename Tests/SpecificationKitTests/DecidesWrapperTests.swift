//
//  DecidesWrapperTests.swift
//  SpecificationKitTests
//

import XCTest
@testable import SpecificationKit

final class DecidesWrapperTests: XCTestCase {

    func test_Decides_returnsFallback_whenNoMatch() {
        // Given
        let vip = PredicateSpec<EvaluationContext> { $0.flag(for: "vip") }
        let promo = PredicateSpec<EvaluationContext> { $0.flag(for: "promo") }

        let provider = DefaultContextProvider.shared
        provider.setFlag("vip", to: false)
        provider.setFlag("promo", to: false)

        // When
        @Decides(FirstMatchSpec([
            (vip, 1),
            (promo, 2)
        ]), or: 0) var value: Int

        // Then
        XCTAssertEqual(value, 0)
    }

    func test_Decides_returnsMatchedValue_whenMatchExists() {
        // Given
        let vip = PredicateSpec<EvaluationContext> { $0.flag(for: "vip") }
        DefaultContextProvider.shared.setFlag("vip", to: true)

        // When
        @Decides(FirstMatchSpec([
            (vip, 42)
        ]), or: 0) var value: Int

        // Then
        XCTAssertEqual(value, 42)
    }

    func test_Decides_wrappedValueDefault_initializesFallback() {
        // Given
        let vip = PredicateSpec<EvaluationContext> { $0.flag(for: "vip") }
        DefaultContextProvider.shared.setFlag("vip", to: false)

        // When: use default value shorthand for fallback
        @Decides(FirstMatchSpec([
            (vip, 99)
        ])) var discount: Int = 0

        // Then: no match -> returns default value
        XCTAssertEqual(discount, 0)
    }
}

