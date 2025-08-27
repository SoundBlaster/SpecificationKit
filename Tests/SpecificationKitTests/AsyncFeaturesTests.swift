import XCTest
@testable import SpecificationKit

final class AsyncFeaturesTests: XCTestCase {

    func test_ContextProviding_asyncDefault_returnsContext() async throws {
        let provider = DefaultContextProvider.shared
        provider.clearAll()
        provider.setFlag("async_flag", to: true)

        let ctx = try await provider.currentContextAsync()
        XCTAssertTrue(ctx.flag(for: "async_flag"))
    }

    func test_AnyAsyncSpecification_canThrow_andDelay() async {
        enum TestError: Error { case failed }

        let throwingSpec = AnyAsyncSpecification<EvaluationContext> { ctx in
            if ctx.flag(for: "fail") { throw TestError.failed }
            return true
        }

        let delayedSpec = AnyAsyncSpecification<EvaluationContext> { ctx in
            _ = ctx // use ctx
            try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
            return true
        }

        // Throws when flag is set
        let failingCtx = EvaluationContext(flags: ["fail": true])
        do {
            _ = try await throwingSpec.isSatisfiedBy(failingCtx)
            XCTFail("Expected throw")
        } catch {
            // ok
        }

        // Succeeds when flag is false
        let okCtx = EvaluationContext(flags: ["fail": false])
        do {
            let v = try await throwingSpec.isSatisfiedBy(okCtx)
            XCTAssertTrue(v)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        // Delay completes and returns true
        let v2 = try? await delayedSpec.isSatisfiedBy(EvaluationContext())
        XCTAssertEqual(v2, true)
    }

    func test_AnyAsyncSpecification_predicate() async throws {
        let asyncSpec = AnyAsyncSpecification<EvaluationContext> { ctx in
            // Simulate async work
            return ctx.flag(for: "feature")
        }

        let ctx1 = EvaluationContext(flags: ["feature": true])
        let ctx2 = EvaluationContext(flags: ["feature": false])

        do {
            let r1 = try await asyncSpec.isSatisfiedBy(ctx1)
            let r2 = try await asyncSpec.isSatisfiedBy(ctx2)
            XCTAssertTrue(r1)
            XCTAssertFalse(r2)
        }
    }

    func test_Satisfies_evaluateAsync_usesProvider() async throws {
        let provider = DefaultContextProvider.shared
        provider.clearAll()

        struct Harness {
            @Satisfies(provider: DefaultContextProvider.shared,
                       predicate: { $0.flag(for: "gate") })
            var gated: Bool

            func evaluate() async throws -> Bool {
                try await _gated.evaluateAsync()
            }
        }

        var h = Harness()
        // Initially false via async evaluation on wrapper
        let v1 = try await h.evaluate()
        XCTAssertFalse(v1)

        provider.setFlag("gate", to: true)
        h = Harness() // refresh wrapper capture
        let v2 = try await h.evaluate()
        XCTAssertTrue(v2)
    }
}
