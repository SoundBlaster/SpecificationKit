import XCTest
@testable import SpecificationKit

final class AsyncSatisfiesWrapperTests: XCTestCase {
    func test_AsyncSatisfies_evaluate_withPredicate() async throws {
        let provider = DefaultContextProvider.shared
        provider.clearAll()
        provider.setFlag("async_flag", to: true)

        struct Harness {
            @AsyncSatisfies(provider: DefaultContextProvider.shared,
                            predicate: { $0.flag(for: "async_flag") })
            var on: Bool?
        }

        let h = Harness()
        let value = try await h.$on.evaluate()
        XCTAssertTrue(value)
        XCTAssertNil(h.on) // wrapper does not update lastValue automatically
    }

    func test_AsyncSatisfies_evaluate_withSyncSpec() async throws {
        let provider = DefaultContextProvider.shared
        provider.clearAll()
        provider.setCounter("attempts", to: 0)

        struct Harness {
            @AsyncSatisfies(provider: DefaultContextProvider.shared,
                            using: MaxCountSpec(counterKey: "attempts", limit: 1))
            var canProceed: Bool?
        }

        let h = Harness()
        let value = try await h.$canProceed.evaluate()
        XCTAssertTrue(value)
    }
}

