//
//  DecidesWrapperTests.swift
//  SpecificationKitTests
//

import XCTest
@testable import SpecificationKit

final class DecidesWrapperTests: XCTestCase {

    override func setUp() {
        super.setUp()
        DefaultContextProvider.shared.clearAll()
    }

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

    func test_Decides_projectedValue_reflectsOptionalMatch() {
        // Given
        let vip = PredicateSpec<EvaluationContext> { $0.flag(for: "vip") }

        // When: no match
        DefaultContextProvider.shared.setFlag("vip", to: false)
        @Decides(FirstMatchSpec([(vip, 11)]), or: 0) var value: Int

        // Then: projected optional is nil
        XCTAssertNil($value)

        // When: now a match
        DefaultContextProvider.shared.setFlag("vip", to: true)

        // Then: projected optional contains match
        XCTAssertEqual($value, 11)
        XCTAssertEqual(value, 11)
    }

    func test_Decides_pairsInitializer_and_fallbackLabel() {
        // Given
        let vip = PredicateSpec<EvaluationContext> { $0.flag(for: "vip") }
        let promo = PredicateSpec<EvaluationContext> { $0.flag(for: "promo") }
        DefaultContextProvider.shared.setFlag("vip", to: false)
        DefaultContextProvider.shared.setFlag("promo", to: true)

        // When: use pairs convenience with explicit fallback label
        @Decides([(vip, 10), (promo, 20)], fallback: 0) var discount: Int

        // Then
        XCTAssertEqual(discount, 20)
    }

    func test_Decides_withDecideClosure_orLabel() {
        // Given
        DefaultContextProvider.shared.setFlag("featureA", to: true)

        // When
        @Decides(decide: { ctx in
            ctx.flag(for: "featureA") ? 123 : nil
        }, or: 0) var value: Int

        // Then
        XCTAssertEqual(value, 123)
    }

    func test_Decides_builderInitializer_withFallback() {
        // Given
        DefaultContextProvider.shared.setFlag("vip", to: false)
        DefaultContextProvider.shared.setFlag("promo", to: false)

        // When: build rules, none match -> fallback
        @Decides(build: { builder in
            builder
                .add(PredicateSpec<EvaluationContext> { $0.flag(for: "vip") }, result: 50)
                .add(PredicateSpec<EvaluationContext> { $0.flag(for: "promo") }, result: 20)
        }, fallback: 7) var value: Int

        // Then
        XCTAssertEqual(value, 7)
    }

    func test_Decides_wrappedValueDefault_withPairs() {
        // Given
        let vip = PredicateSpec<EvaluationContext> { $0.flag(for: "vip") }
        DefaultContextProvider.shared.setFlag("vip", to: true)

        // When: default value shorthand with pairs
        @Decides([(vip, 9)]) var result: Int = 1

        // Then: match beats default
        XCTAssertEqual(result, 9)
    }
}

// MARK: - Generic Context Provider coverage

private struct SimpleContext { let value: Int }

private struct IsPositiveSpec: Specification {
    typealias T = SimpleContext
    func isSatisfiedBy(_ candidate: SimpleContext) -> Bool { candidate.value > 0 }
}

final class DecidesGenericContextTests: XCTestCase {
    func test_Decides_withGenericProvider_andPredicate() {
        // Given
        let provider = staticContext(SimpleContext(value: -1))

        // When: construct Decides directly using generic provider initializer
        var decides = Decides<SimpleContext, Int>(
            provider: provider,
            firstMatch: [(IsPositiveSpec(), 1)],
            fallback: 0
        )
        // Then: initial value should be fallback
        XCTAssertEqual(decides.wrappedValue, 0)

        // And when provider returns positive context, we expect match
        let positiveProvider = staticContext(SimpleContext(value: 5))
        decides = Decides<SimpleContext, Int>(
            provider: positiveProvider,
            using: FirstMatchSpec([(IsPositiveSpec(), 2)]),
            fallback: 0
        )
        XCTAssertEqual(decides.wrappedValue, 2)
    }
}
