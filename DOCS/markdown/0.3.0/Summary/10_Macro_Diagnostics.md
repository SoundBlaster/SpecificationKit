# Macro Diagnostics

## Step 1

codex
All set — I implemented the P0 validation, updated tests, and synced the TODOs.

What I changed
- Macro diagnostics:
  - Mixed contexts: Emits an error when all argument contexts are confidently in
ferred and differ; otherwise a warning stays.
  - Async spec args: Emits an error if an argument looks like an async spec (e.g
., `AnyAsyncSpecification<...>` or `AsyncSpecification`), since `@specs` expects
 sync `Specification`s.
  - Existing checks remain: empty args (error), non-instance/literal args (error
), `.self` type references (warning), missing `typealias T` (warning), non-`Spec
ification` host (error).

- Implementation details (`Sources/SpecificationKitMacros/SpecMacro.swift`):
  - Added `MixedContextsError` (error severity) and `AsyncSpecArgumentMessage` (
error).
  - Upgraded logic to count inferred contexts; error if all are inferred and mix
ed, otherwise warn.

- Tests:
  - Updated mixed-contexts test to expect an error when inference is confident.
  - Added a new test to reject async spec argument usage.
  - Fixed actor isolation in environment provider tests by annotating them with
`@MainActor` (test-only change).
  - Verified diagnostics via `SpecsMacroDiagnosticsTests` filter; they pass.

- Docs/TODOs:
  - Marked P0 item as complete:
    - `DOCS/markdown/0.3.0/09_SpecificationKit_v0.3.0_EN_TODO_Prioritized.md`: c
hecked “Validate all @specs arguments…share the same Context.”
    - `DOCS/markdown/0.3.0/11_SpecificationKit_v0.3.0_TODO.md`: moved the item t
o Completed with a brief note about heuristic checks and error policy.

Notes
- Tests run required elevated permissions to access system SDKs and caches; I us
ed escalated execution for `swift test`.
- I added `@MainActor` to the EnvironmentContextProvider tests to respect the pr
ovider’s actor isolation. If you prefer a different isolation model for `Environ
mentContextProvider`, we can revisit (but this keeps UI-centric behavior clear).

Next suggestions
- Add a non-confident mixed-contexts test (still warns) to document behavior.
- Consider expanding the context inference map for more specs or add a simple pr
otocol marker in comments to guide the heuristic (optional).
- If you want, I can mirror a short note in README’s macros section describing t
he new diagnostics for `@specs`.

## Step 2

codex
Added the non-confident mixed-contexts test and verified it passes.

What I added
- New test in `Tests/SpecificationKitTests/SpecsMacroDiagnosticsTests.swift`:
  - test_specs_mixedContexts_warnsWhenNotConfident: Uses three args where two co
ntexts are inferred (`CustomContext`, `EvaluationContext`) and one is unknown (`
UnknownSpec()`), asserting a warning diagnostic:
    - “@specs arguments appear to use mixed Context types (CustomContext, Evalua
tionContext). Ensure all specs share the same Context.”

Why this matters
- Documents the intended behavior: when the macro can’t confidently infer all co
ntexts, it warns rather than errors, guiding the user without over-blocking.

Validation
- Ran diagnostics tests: all pass.
- The rest of the suite remains green.

Optional next step
- Add a README note under macros diagnostics explaining confident vs non-confide
nt mixed-context behavior. Want me to add that?

## Next

codex
Next highest-priority open task: P1 — Provide observation (Combine or AsyncSeque
nce) to re-evaluate when context changes.

Why this one
- It unblocks the adjacent P1: “Add @Satisfies variant that publishes changes so
 SwiftUI updates automatically.”
- It’s not toolchain-blocked and delivers clear UX value.

Quick approach
- Add optional observation API to `ContextProviding` (e.g., `var contextUpdates:
 AnyPublisher<Context, Never>` and/or `var contextStream: AsyncStream<Context>`)
.
- Implement publishers/streams in `DefaultContextProvider` and `EnvironmentConte
xtProvider` (emit on state changes).
- Add a new wrapper (e.g., `@SatisfiesPublished`) that subscribes to updates and
 refreshes `wrappedValue`.

Want me to implement the observation API and the publishing wrapper next?
