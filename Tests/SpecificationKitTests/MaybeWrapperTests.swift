//
//  MaybeWrapperTests.swift
//  SpecificationKitTests
//

import XCTest
@testable import SpecificationKit

final class MaybeWrapperTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Ensure a clean provider state before each test
        DefaultContextProvider.shared.clearAll()
    }

    func test_Maybe_returnsNil_whenNoMatch() {
        // Given
        let vip = PredicateSpec<EvaluationContext> { $0.flag(for: "vip") }
        let promo = PredicateSpec<EvaluationContext> { $0.flag(for: "promo") }

        DefaultContextProvider.shared.setFlag("vip", to: false)
        DefaultContextProvider.shared.setFlag("promo", to: false)

        // When
        @Maybe([
            (vip, 1),
            (promo, 2)
        ]) var value: Int?

        // Then
        XCTAssertNil(value)
    }

    func test_Maybe_returnsMatchedValue_whenMatchExists() {
        // Given
        let vip = PredicateSpec<EvaluationContext> { $0.flag(for: "vip") }
        DefaultContextProvider.shared.setFlag("vip", to: true)

        // When
        @Maybe([
            (vip, 42)
        ]) var value: Int?

        // Then
        XCTAssertEqual(value, 42)
    }

    func test_Maybe_projectedValue_matchesWrappedValue() {
        // Given
        let vip = PredicateSpec<EvaluationContext> { $0.flag(for: "vip") }
        DefaultContextProvider.shared.setFlag("vip", to: true)

        // When
        @Maybe([
            (vip, 7)
        ]) var value: Int?

        // Then: $value should equal wrapped optional value
        XCTAssertEqual(value, $value)
    }

    func test_Maybe_withDecideClosure() {
        // Given
        DefaultContextProvider.shared.setFlag("featureX", to: true)

        // When
        @Maybe(decide: { context in
            context.flag(for: "featureX") ? 100 : nil
        }) var value: Int?

        // Then
        XCTAssertEqual(value, 100)
    }

    func test_Maybe_builder_buildsOptionalSpec() {
        // Given
        DefaultContextProvider.shared.setFlag("vip", to: false)
        DefaultContextProvider.shared.setFlag("promo", to: true)

        let maybe = Maybe<EvaluationContext, Int>
            .builder(provider: DefaultContextProvider.shared)
            .with(PredicateSpec<EvaluationContext> { $0.flag(for: "vip") }, result: 50)
            .with(PredicateSpec<EvaluationContext> { $0.flag(for: "promo") }, result: 20)
            .build()

        // When
        let result = maybe.wrappedValue

        // Then
        XCTAssertEqual(result, 20)
    }
}
