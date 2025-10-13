# PRD: Diagnostics and Tests for `@AutoContext` Type Mismatches

## 1. Overview

### Goal
Provide a focused validation and test suite ensuring the `@AutoContext` macro surfaces clear, actionable diagnostics whenever the synthesized context provider does not match the specification's `Context` (`T`) type.

### Rationale
- The v0.3.0 roadmap explicitly calls for **negative tests for `@AutoContext` type mismatches** to complete the macro QA coverage.【AGENTS_DOCS/markdown/0.3.0/09_SpecificationKit_v0.3.0_EN_TODO_Prioritized.md†L14-L18】
- The `AutoContext` design document emphasizes **compile-time safety** and matching provider/context types as a core promise of the macro.【AGENTS_DOCS/markdown/05_AutoContext.md†L32-L58】
- Current unit coverage (`AutoContextMacroTests`) only validates the happy path; no regression guard exists for misuse, leading to unfriendly compiler errors if a mismatch slips in.

### Background
`@AutoContext` currently injects a `DefaultContextProvider`-backed static provider and typealias for specs, enabling seamless use with `@Satisfies`. The macro must defend against:
- Specs whose `typealias T` is not compatible with `DefaultContextProvider.Context` (or any override once implemented).
- Misapplied attributes (e.g., missing `Specification` conformance) that should emit macro diagnostics rather than cryptic compiler messages.

## 2. Problem Statement
Without targeted negative tests, future changes could silently regress type validation logic. Developers would receive Swift compiler mismatch errors instead of the intentional `@AutoContext` diagnostics promised in the roadmap. We need deterministic macro tests that assert the right error message, location, and severity for each misuse scenario.

## 3. Scope & Objectives
- Cover **macro-level diagnostics** using `SwiftSyntaxMacrosTestSupport` (`assertMacroExpansion`) so the failure mode is exercised without compiling the whole package.
- Focus on mismatches between the generated provider type and the specification's `Context` type, aligning with the roadmap item.
- Document the intended error messages to guide macro implementation and provide regression safety.

## 4. Non-Goals
- Implementing the underlying provider/context validation logic (tracked separately as a blocked task). This PRD defines the diagnostics contract and accompanying tests that the implementation must satisfy once unblocked.
- Extending `@AutoContext` to support provider overrides, environment hooks, or async helpers (covered by other roadmap items).

## 5. User Stories
1. **Macro Author**: “When I apply `@AutoContext` to a spec whose `typealias T` is not `EvaluationContext`, I want a clear macro error explaining the mismatch so I can correct the context or supply a compatible provider.”
2. **Library Maintainer**: “When refactoring the macro, I want unit tests that fail if I accidentally remove context validation so regressions are caught immediately.”

## 6. Functional Requirements
- The macro must emit a **single `.error` diagnostic** that:
  - States that the provider’s `Context` does not satisfy the specification’s `T` type.
  - Points to the `@AutoContext` attribute (line/column 1,1 in fixtures).
- Tests must cover at least:
  1. `typealias T = CustomContext` (non-EvaluationContext) with default provider → error diagnostic.
  2. Missing `typealias T` leading to ambiguous context → either dedicated diagnostic or reuse of existing “missing typealias” warning in combination with a new mismatch error.
  3. (Forward-looking) Override scenario stub: ensure the harness anticipates `@AutoContext(MyProvider.self)` emitting a mismatch error when `MyProvider.Context != T`. Test should be gated via `#if canImport(SwiftSyntaxMacrosTestSupport)` guard to avoid compile failures until override support lands.
- Diagnostics strings should live in `AutoContextMacro.swift` as static constants to keep wording stable.

## 7. Test Strategy
- Add a new `AutoContextMacroDiagnosticsTests.swift` alongside existing macro test suites.
- Use inline source snippets to assert both expanded source (when expansion still occurs) and diagnostics array.
- Verify no additional diagnostics are produced (exact-match assertions) to prevent noise.

## 8. Dependencies & Risks
- **Dependency**: Provider/context validation logic (separate task) must exist for the tests to pass. Until then, mark tests with `#expectFailure` (or `XCTExpectFailure`) or `XCTSkip` with TODO referencing the implementation task.
- **Risk**: SwiftSyntax diagnostic APIs can shift between toolchain versions; mitigate by keeping fixtures minimal and leveraging helper utilities already used in `SpecsMacroDiagnosticsTests`.

## 9. Implementation Outline
1. Define diagnostic identifiers/messages in `AutoContextMacro` (e.g., `Diagnostics.mismatchedContext`).
2. Teach the macro expansion to inspect the decorated type’s `typealias T` (and future provider argument) to determine compatibility.
3. Emit diagnostics before returning generated members; bail out early if fatal.
4. Create `AutoContextMacroDiagnosticsTests` covering scenarios listed above using `assertMacroExpansion`.
5. For blocked validation logic, temporarily mark tests with `XCTExpectFailure` referencing the blocking task ID, then remove once feature implemented.

## 10. Acceptance Criteria
- All new diagnostic tests compile and (once validation lands) pass without `XCTExpectFailure` guards.
- Error messages exactly match the contract defined above, and snapshots are checked into version control.
- The PR updates project documentation (e.g., CHANGELOG/Test README) only if necessary—focus remains on diagnostics coverage.

## 11. Open Questions
- Should the macro expansion abort (emit no members) after a fatal diagnostic, or continue emitting placeholders? Recommend aborting to prevent cascading type errors once diagnostic support is ready.
- Do we need separate diagnostics for “missing `typealias T`” vs. “mismatch”? Current `@specs` macro emits a warning; consider aligning severity and wording for consistency.
