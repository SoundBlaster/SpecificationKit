//
//  DecidesWrapperTests.swift
//  SpecificationKitTests
//
//  Created by SpecificationKit on 2024.
//

import XCTest
@testable import SpecificationKit

final class DecidesWrapperTests: XCTestCase {

    func test_Decides_returnsExpectedResult_withEvaluationContext() {
        // Given
        let vip = PredicateSpec<EvaluationContext> { $0.flag(for: "vip") }
        let promo = PredicateSpec<EvaluationContext> { $0.flag(for: "promo") }

        // Prepare context
        let provider = DefaultContextProvider.shared
        provider.setFlag("vip", to: false)
        provider.setFlag("promo", to: true)

        // When
        @Decides(FirstMatchSpec([
            (vip, 1),
            (promo, 2)
        ])) var value: Int?

        // Then
        XCTAssertEqual(value, 2)
    }

    func test_Spec_alias_compiles_and_returnsResult() {
        // Given
        let pred = PredicateSpec<EvaluationContext> { _ in true }

        // When: Using deprecated alias @Spec
        @Spec(FirstMatchSpec([
            (pred, 7)
        ])) var result: Int?

        // Then: Use default provider
        DefaultContextProvider.shared.setFlag("__test_flag__", to: true)
        XCTAssertEqual(result, 7)
    }
}
