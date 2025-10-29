import XCTest
@testable import SpecificationKit

final class SatisfiesWrapperTests: XCTestCase {
    private struct ManualContext {
        var isEnabled: Bool
        var threshold: Int
        var count: Int
    }

    private struct EnabledSpec: Specification {
        func isSatisfiedBy(_ candidate: ManualContext) -> Bool { candidate.isEnabled }
    }

    func test_manualContext_withSpecificationInstance() {
        // Given
        struct Harness {
            @Satisfies(context: ManualContext(isEnabled: true, threshold: 3, count: 0),
                       using: EnabledSpec())
            var isEnabled: Bool
        }

        // When
        let harness = Harness()

        // Then
        XCTAssertTrue(harness.isEnabled)
    }

    func test_manualContext_withPredicate() {
        // Given
        struct Harness {
            @Satisfies(context: ManualContext(isEnabled: false, threshold: 2, count: 1)) { context in
                context.count < context.threshold
            }
            var canIncrement: Bool
        }

        // When
        let harness = Harness()

        // Then
        XCTAssertTrue(harness.canIncrement)
    }

    func test_manualContext_evaluateAsync_returnsManualValue() async throws {
        // Given
        struct Harness {
            @Satisfies(context: ManualContext(isEnabled: true, threshold: 1, count: 0),
                       using: EnabledSpec())
            var isEnabled: Bool
        }

        let harness = Harness()

        // When
        let result = try await harness.$isEnabled.evaluateAsync()

        // Then
        XCTAssertTrue(result)
    }
}
