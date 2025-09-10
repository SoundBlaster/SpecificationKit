codex
Nice — I implemented @AsyncSatisfies as a first-class wrapper and updated the RE
ADME Quick Start with async samples. Everything is tested and green.

What’s new

- @AsyncSatisfies wrapper
  - File: Sources/SpecificationKit/Wrappers/AsyncSatisfies.swift
  - Purpose: Evaluate specs asynchronously without calling _spec.evaluateAsync()
 directly.
  - API:
    - wrappedValue: Bool? (last known value; not auto-updated)
    - projectedValue.evaluate() async throws -> Bool (computes current value)
  - Initializers:
    - provider + sync Specification
    - provider + predicate
    - provider + AsyncSpecification (via AnyAsyncSpecification)

- Tests
  - File: Tests/SpecificationKitTests/AsyncSatisfiesWrapperTests.swift
  - Cases:
    - Evaluating with a predicate (uses provider flag).
    - Evaluating with a sync Specification (MaxCountSpec), bridged to async.
  - Also extended async tests to include throws + delay.

- Async core already in place
  - AsyncSpecification protocol and AnyAsyncSpecification<T> (type erasure).
  - ContextProviding.currentContextAsync() default bridge.
  - Satisfies.evaluateAsync() helper for the existing sync wrapper.

- Demo app
  - New screen: AsyncDemoView showing AnyAsyncSpecification with delay and error
 toggles.
  - Added to sidebar navigation.

- README improvements
  - Added “Async capable” to Features.
  - Added “Async Specs (Quick Start)” code samples.
  - Added macro diagnostics section.
  - Mentioned the new “Async Specs” demo screen.

Usage examples

- Wrapper style (no direct evaluateAsync call on internal storage)
  - @AsyncSatisfies(provider: DefaultContextProvider.shared,
                   predicate: { $0.flag(for: "feature_async") })
    var isOn: Bool?
  - let ok = try await $isOn.evaluate()

- Async spec style
  - let asyncSpec = AnyAsyncSpecification<EvaluationContext> { ctx in
      try? await Task.sleep(nanoseconds: 50_000_000)
      return ctx.flag(for: "feature_enabled")
    }
  - let ok = try await asyncSpec.isSatisfiedBy(ctx)

Next suggestions

- Macro path: extend @specs to emit async members
  - public func isSatisfiedByAsync(_ candidate: T) async throws -> Bool
  - For AutoContext specs: public var isSatisfied: Bool { get async throws }

- Optional: Add a variant of @AsyncSatisfies that updates wrappedValue or provid
es an AsyncStream/Combine publisher for SwiftUI auto-refresh.
  - I can add $isOn.stream to consume in a View.task, or a convenience refreshOn
Appear().
