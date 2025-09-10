# SpecificationKit v0.3.0 — Continuous TODO Checklist

## Macro System
- [ ] Create `SpecificationKitMacros` SwiftPM target for code generation.
- [ ] Implement attached macro `@specs` accepting types conforming to `Specification`.
- [ ] Generate private `composite: AnySpecification` and initializer using `.and()`/`.or()`.
- [ ] Add `isSatisfiedBy(_:)` delegating to `composite` in generated type.
- [ ] Validate all `@specs` arguments conform to `Specification` and share the same `Context`.
- [ ] Emit helpful compile-time diagnostics on `@specs` validation failure.
- [ ] Add macro tests verifying generation output and diagnostics for `@specs`.
- [ ] Implement attached macro `@AutoContext` to convert plain spec into auto-context spec.
- [ ] Inject `static contextProvider` with default provider in `@AutoContext`.
- [ ] Synthesize default initializer in `@AutoContext` when missing.
- [ ] Ensure provider `Context` matches spec `Context` for `@AutoContext`.
- [ ] Support optional override `@AutoContext(MyProvider.self)`.
- [ ] Leave hooks for future flags (environment/infer) per AutoContext design.
- [ ] Provide tests showing `@AutoContext` works with `@Satisfies` without manual context.
- [ ] Add negative tests for `@AutoContext` type mismatches.
- [ ] Prototype one experimental macro: `@specsIf(condition:)` or `#composed(...)` or `@deriveSpec(from:)`.
- [ ] Include a brief usage example for the chosen experimental macro.

## Built-in Specifications
- [ ] Implement `DateRangeSpec` using `EvaluationContext.currentDate` within range.
- [ ] Implement `FeatureFlagSpec` using `EvaluationContext.flags` matching expected value.
- [ ] Implement `UserSegmentSpec` with `UserSegment` enum and `EvaluationContext.segments`.
- [ ] Implement `SubscriptionStatusSpec` using `EvaluationContext.userData` state.
- [ ] Implement `DateComparisonSpec` using `EvaluationContext.events` with `.before`/`.after` ops.
- [ ] For each new spec, conform to `Specification` with explicit `Context` type.
- [ ] Add convenience factory methods and optional description strings for each spec.
- [ ] Add unit tests for typical and edge cases for each new spec.

## Asynchronous and Reactive Support
- [ ] Extend `ContextProviding` with `func currentContext() async throws -> Context`.
- [ ] Provide default synchronous and asynchronous implementations for context providers.
- [ ] Define `AsyncSpecification` with `associatedtype Context` and `isSatisfiedBy(_:) async throws -> Bool`.
- [ ] Implement type-erased `AnyAsyncSpecification` wrapper.
- [ ] Add async-capable property wrapper (`@AsyncSatisfies` or async API to `Satisfies`) that awaits context and evaluation.
- [ ] Write tests covering async behavior, delays, successes, and thrown errors.

## Context Providers
- [ ] Implement `EnvironmentContextProvider` reading SwiftUI `@Environment`/`@AppStorage` into `EvaluationContext`.
- [ ] Add SwiftUI example integrating `EnvironmentContextProvider` in a view.
- [x] Support DI: allow global provider and initializer injection; document the pattern. (code complete; docs pending)
- [ ] Provide observation (Combine or `AsyncSequence`) to re-evaluate when context changes.

## Property Wrappers
- [ ] Add `@Satisfies` variant that publishes changes so SwiftUI updates automatically.
- [ ] Support constructing specs via wrapper parameters, e.g. `@Satisfies(using: CooldownIntervalSpec.self, interval: 10)`.
- [x] Ensure `@Satisfies` works with any `ContextProviding` implementation.

## Documentation and Examples
- [ ] Update `README.md` with macro system (`@specs`, `@AutoContext`), new specs, and async features.
- [ ] Generate DocC documentation for all public APIs, including macros and examples.
- [ ] Extend or create DemoApp showcasing macros, AutoContext, and async context retrieval in SwiftUI.

## Infrastructure and CI
- [ ] Add GitHub Actions workflows to build library, macros, and run tests on macOS/iOS/tvOS/watchOS.
- [ ] Prepare for Swift Package Index: metadata, license confirmation, and semantic tag `2.0.0`.
- [ ] Maintain `CHANGELOG.md` describing new features and breaking changes for 2.0.0.

## Testing and QA
- [ ] Cover all new macros with unit tests verifying code generation and failure cases.
- [ ] Write comprehensive tests for every new specification introduced above.
- [ ] Add performance benchmarks for specification composition and macro-generated code; optimize as needed.
- [ ] Ensure adherence to Swift API Design Guidelines and existing naming conventions.

## Performance and Refactoring
- [ ] Investigate potential bottlenecks in `AnySpecification`; consider `@inlinable` where appropriate.
- [ ] Measure macro compilation impact and optimize macro code to minimize build times.
- [ ] Refactor existing code for clarity and maintainability; ensure consistent use of generics and extensions.
