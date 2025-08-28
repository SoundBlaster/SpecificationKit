# SpecificationKit v0.3.0 — Prioritized TODO (from 08_)

## P0 — Critical Path
- [x] Create `SpecificationKitMacros` SwiftPM target for code generation.
- [x] Implement attached macro `@specs` accepting types conforming to `Specification`.
- [x] Generate private `composite: AnySpecification` and initializer using `.and()`/`.or()`.
- [x] Add `isSatisfiedBy(_:)` delegating to `composite` in generated type.
- [ ] Validate all `@specs` arguments conform to `Specification` and share the same `Context`.
- [x] Emit helpful compile-time diagnostics on `@specs` validation failure.
- [x] Add macro tests verifying generation output for `@specs` (integration tests added).
- [x] Implement attached macro `@AutoContext` to convert plain spec into auto-context spec.
- [x] Inject `static contextProvider` with default provider in `@AutoContext`.
- [x] Synthesize default initializer in `@AutoContext` when missing.
- [ ] Ensure provider `Context` matches spec `Context` for `@AutoContext`. (blocked by toolchain: conformance macro not available)
- [ ] Provide tests showing `@AutoContext` works with `@Satisfies` without manual context. (blocked by toolchain; provider-based path covered by tests)
- [ ] Add negative tests for `@AutoContext` type mismatches.
- [x] Implement `DateRangeSpec` using `EvaluationContext.currentDate` within range.
- [x] Implement `FeatureFlagSpec` using `EvaluationContext.flags` matching expected value.
- [x] Implement `UserSegmentSpec` with `UserSegment` enum and `EvaluationContext.segments`.
- [x] Implement `SubscriptionStatusSpec` using `EvaluationContext.userData` state.
- [x] Implement `DateComparisonSpec` using `EvaluationContext.events` with `.before`/`.after` ops.
- [x] For each new spec, conform to `Specification` with explicit `Context` type.
- [x] Add unit tests for typical and edge cases for each new spec.
- [x] Add GitHub Actions workflows to build library, macros, and run tests on macOS (added CI; can extend to iOS/tvOS/watchOS later).

## P1 — Important Enhancements
- [ ] Leave hooks for future flags (environment/infer) per AutoContext design.
- [x] Extend `ContextProviding` with `func currentContext() async throws -> Context`. (implemented as `currentContextAsync()` to avoid overload ambiguity)
- [x] Provide default synchronous and asynchronous implementations for context providers. (async bridges to sync by default)
- [x] Define `AsyncSpecification` with `associatedtype Context` and `isSatisfiedBy(_:) async throws -> Bool`.
- [x] Implement type-erased `AnyAsyncSpecification` wrapper.
- [x] Add async-capable property wrapper (`@AsyncSatisfies` or async API to `Satisfies`) that awaits context and evaluation. (`@AsyncSatisfies` + `Satisfies.evaluateAsync()`)
- [x] Write tests covering async behavior, delays, successes, and thrown errors.
- [x] Implement `EnvironmentContextProvider` reading SwiftUI `@Environment`/`@AppStorage` into `EvaluationContext`.
- [x] Add SwiftUI example integrating `EnvironmentContextProvider` in a view.
- [x] Support DI: allow global provider and initializer injection; document the pattern. (code complete; docs pending)
- [ ] Provide observation (Combine or `AsyncSequence`) to re-evaluate when context changes.
- [ ] Add `@Satisfies` variant that publishes changes so SwiftUI updates automatically.
- [ ] Support constructing specs via wrapper parameters, e.g. `@Satisfies(using: CooldownIntervalSpec.self, interval: 10)`.
- [x] Ensure `@Satisfies` works with any `ContextProviding` implementation.
- [x] Update `README.md` with macro system (`@specs`, `@AutoContext`), new specs, and async features.
- [ ] Generate DocC documentation for all public APIs, including macros and examples.
- [x] Extend or create DemoApp showcasing macros, AutoContext, and async context retrieval in SwiftUI.
- [ ] Prepare for Swift Package Index: metadata, license confirmation, and semantic tag `2.0.0`.
- [ ] Maintain `CHANGELOG.md` describing new features and breaking changes for 2.0.0.

## P2 — Polish and Performance
- [ ] Prototype one experimental macro: `@specsIf(condition:)` or `#composed(...)` or `@deriveSpec(from:)`.
- [ ] Include a brief usage example for the chosen experimental macro.
- [ ] Add performance benchmarks for specification composition and macro-generated code; optimize as needed.
- [ ] Ensure adherence to Swift API Design Guidelines and existing naming conventions.
- [ ] Investigate potential bottlenecks in `AnySpecification`; consider `@inlinable` where appropriate.
- [ ] Measure macro compilation impact and optimize macro code to minimize build times.
- [ ] Refactor existing code for clarity and maintainability; ensure consistent use of generics and extensions.
