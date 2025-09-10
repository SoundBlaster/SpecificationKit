# SpecificationKit v0.3.0 — Clarified TODO

This document restructures the prioritized TODO into clearer sections with status groupings. It mirrors the scope and items from the existing 09_* list without changing intent.

Legend: [x] Completed • [ ] Pending • (blocked) indicates an external/toolchain blocker

## P0 — Critical Path

### Completed
- [x] Create `SpecificationKitMacros` SwiftPM target for code generation.
- [x] Implement attached macro `@specs` accepting types conforming to `Specification`.
- [x] Generate private `composite: AnySpecification` and initializer using `.and()`/`.or()`.
- [x] Add `isSatisfiedBy(_:)` delegating to `composite` in generated type.
- [x] Make `@specs` generated members use associated type `T` (e.g., `AnySpecification<T>`, `isSatisfiedBy(_ candidate: T)`).
- [x] Diagnostics: warn when attached type is missing `typealias T` with a friendly suggestion.
- [x] Diagnostics: error when `@specs` is applied to a non-`Specification` type.
- [x] Add async bridge `isSatisfiedByAsync(_:)` to `@specs` output.
- [x] Add tests for the async bridge in `@specs` and update diagnostics tests' expected expansions.
- [x] Emit helpful compile-time diagnostics on `@specs` validation failure.
- [x] Add macro tests verifying generation output for `@specs` (integration tests added).
- [x] Implement attached macro `@AutoContext` to convert plain spec into auto-context spec.
- [x] Inject `static contextProvider` with default provider in `@AutoContext`.
- [x] Synthesize default initializer in `@AutoContext` when missing.
- [x] Implement `DateRangeSpec` using `EvaluationContext.currentDate` within range.
- [x] Implement `FeatureFlagSpec` using `EvaluationContext.flags` matching expected value.
- [x] Bugfix: Treat missing feature flags as failure in `FeatureFlagSpec`; added dedicated test.
- [x] Implement `UserSegmentSpec` with `UserSegment` enum and `EvaluationContext.segments`.
- [x] Implement `SubscriptionStatusSpec` using `EvaluationContext.userData` state.
- [x] Implement `DateComparisonSpec` using `EvaluationContext.events` with `.before`/`.after` ops.
- [x] For each new spec, conform to `Specification` with explicit `Context` type.
- [x] Add unit tests for typical and edge cases for each new spec.
- [x] Add GitHub Actions workflows to build library, macros, and run tests on macOS (added CI; can extend to iOS/tvOS/watchOS later).
- [x] Validate all `@specs` arguments conform to `Specification` and share the same `Context` (heuristic compile-time checks; error on mixed contexts when confidently inferred; diagnostics tests added).

### Pending / Blocked
- [ ] Ensure provider `Context` matches spec `Context` for `@AutoContext`. (blocked by toolchain: conformance macro not available)
- [ ] Provide tests showing `@AutoContext` works with `@Satisfies` without manual context. (blocked by toolchain; provider-based path covered by tests)
- [ ] Add negative tests for `@AutoContext` type mismatches.

## P1 — Important Enhancements

### Completed
- [x] Extend `ContextProviding` with async context access (implemented as `currentContextAsync()` to avoid overload ambiguity).
- [x] Provide default synchronous and asynchronous implementations for context providers (async bridges to sync by default).
- [x] Define `AsyncSpecification` with `associatedtype Context` and `isSatisfiedBy(_:) async throws -> Bool`.
- [x] Implement type-erased `AnyAsyncSpecification` wrapper.
- [x] Add async-capable API: `@AsyncSatisfies` wrapper and `Satisfies.evaluateAsync()` that awaits context and evaluation.
- [x] Write tests covering async behavior, delays, successes, and thrown errors.
- [x] Support DI: allow global provider and initializer injection; document the pattern. (code complete; docs pending)
- [x] Ensure `@Satisfies` works with any `ContextProviding` implementation.
- [x] Update `README.md` with macro system (`@specs`, `@AutoContext`), new specs, and async features.
- [x] Extend or create DemoApp showcasing macros, AutoContext, and async context retrieval in SwiftUI.
- [x] For `@AutoContext` + `@specs` types, generate async computed property `isSatisfied` using `contextProvider.currentContextAsync()`.
- [x] Add Async Demo screen (`AsyncDemoView`) with delay/error toggles and navigation entry.
- [x] Expand README with Async Specs Quick Start and macro diagnostics section.
- [x] Add unit tests for `EnvironmentContextProvider` mapping to `EvaluationContext`.
- [x] Implement `EnvironmentContextProvider` reading SwiftUI `@Environment`/`@AppStorage` into `EvaluationContext`.
- [x] Add SwiftUI example integrating `EnvironmentContextProvider` in a view.

### Completed
- [x] Provide observation (Combine or `AsyncSequence`) to re-evaluate when context changes.
- [x] Add `@Satisfies` variant that publishes changes so SwiftUI updates automatically.
- [x] Add DemoApp screen showcasing observation and live updates.
- [x] Generate DocC documentation for all public APIs, including macros and examples.
- [x] Maintain `CHANGELOG.md` describing new features and breaking changes for 2.0.0.

### Pending
- [ ] Leave hooks for future flags (environment/infer) per AutoContext design.
- [ ] Support constructing specs via wrapper parameters, e.g. `@Satisfies(using: CooldownIntervalSpec.self, interval: 10)`.
- [ ] Prepare for Swift Package Index: metadata, license confirmation, and semantic tag `2.0.0`.

## P2 — Polish and Performance

### Pending
- [ ] Prototype one experimental macro: `@specsIf(condition:)` or `#composed(...)` or `@deriveSpec(from:)`.
- [ ] Include a brief usage example for the chosen experimental macro.
- [ ] Add performance benchmarks for specification composition and macro-generated code; optimize as needed.
- [ ] Ensure adherence to Swift API Design Guidelines and existing naming conventions.
- [ ] Investigate potential bottlenecks in `AnySpecification`; consider `@inlinable` where appropriate.
- [ ] Measure macro compilation impact and optimize macro code to minimize build times.
- [ ] Refactor existing code for clarity and maintainability; ensure consistent use of generics and extensions.

## Notes
- Items labeled “blocked” are deferred pending toolchain support (e.g., conformance macros) or external constraints. Where feasible, tests cover provider-based or runtime paths.
- CI currently targets macOS; consider extending to iOS/tvOS/watchOS via `xcodebuild` destinations.

### Observation Completion Notes
- Introduced `ContextUpdatesProviding` (optional) for providers to publish update signals via Combine and an `AsyncStream` bridge.
- `DefaultContextProvider` now emits updates on all state mutations (counters/flags/events/userData and registrations).
- `EnvironmentContextProvider` forwards `objectWillChange` to observation hooks.
- Added `@ObservedSatisfies` (`DynamicProperty`) for SwiftUI that re-evaluates on provider updates.
- DemoApp now includes an “Observation” screen demonstrating flags, counters, cooldowns, and a composite spec updating live.
- Follow-ups (not done): observed variants for `@Decides` and `@Maybe`; unit tests for Combine bridge could be added if we include Combine in test target.

### DocC Documentation Completion Notes
- Comprehensive DocC documentation implemented for SpecificationKit v2.0.0 with detailed API documentation, usage examples, and deployment automation.
- GitHub Pages deployment setup with Swift-DocC plugin integration and automated workflow.
- Enhanced documentation for all public APIs including property wrappers, macro system, context providers, and built-in specifications.
- Rich code examples, cross-references using DocC linking syntax, and modern Swift patterns (async/await, SwiftUI, macros).
- Professional presentation suitable for Swift Package Index with automated deployment pipeline.
