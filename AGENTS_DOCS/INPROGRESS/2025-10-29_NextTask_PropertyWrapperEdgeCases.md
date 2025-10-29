# Next Task — Expand Property Wrapper Edge-Case Coverage

## Selection Metadata
- **Selection Date:** 2025-10-29
- **Chosen Task:** Design and implement additional stress and edge-case tests for SpecificationKit's property wrappers.
- **Source Backlog Entries:**
  - `AGENTS_DOCS/markdown/00_SpecificationKit_TODO.md` lines 79–109
- **Status:** Selected / Ready to plan implementation
- **Blocking Issues:** None

## Candidate Review
- **Evaluated Options:**
  - Expand edge-case and stress coverage for property wrappers to exercise new wrappers such as `@CachedSatisfies` under concurrency, cache eviction, and async scenarios. References: `AGENTS_DOCS/markdown/00_SpecificationKit_TODO.md` lines 79–109; existing coverage limited to manual-context happy paths in `Tests/SpecificationKitTests/SatisfiesWrapperTests.swift` lines 1–63.
  - Add GitHub Actions workflow `.github/workflows/test.yml` for CI validation. Reference: `AGENTS_DOCS/markdown/00_SpecificationKit_TODO.md` lines 99–103. Rejected because the repository already ships a macOS CI workflow at `.github/workflows/ci.yml` lines 1–34, so the backlog entry appears stale.
  - Support constructing specifications via wrapper parameters (e.g., passing macro-generated specs into `@Satisfies` directly). Reference: `AGENTS_DOCS/markdown/3.0.0/00_3.0.0_TODO_SpecificationKit.md` lines 14–22. Deferred since it depends on macro design updates and would benefit from stronger wrapper test coverage first.
- **Why this task now:** Property wrappers underpin much of the v3 feature set (e.g., caching, observation, conditional wrappers). Stress scenarios like cache invalidation, concurrent access, and SwiftUI-driven updates are not covered by the existing focused tests (`SatisfiesWrapperTests` only validates manual contexts). Bolstering these tests reduces regression risk before layering more wrapper features and macro conveniences.

## Implementation Notes
- **Entry Points / Files to Inspect:**
  - `Tests/SpecificationKitTests/SatisfiesWrapperTests.swift` lines 1–63 — current coverage focuses on manual contexts; expand to async/provider and failure scenarios.
  - `Tests/SpecificationKitTests/CachedSatisfiesTests.swift` lines 1–120 — ensure TTL expiry, forced refresh, and projected value helpers are exercised under contention.
  - `Tests/SpecificationKitTests/ObservedSatisfiesTests.swift` lines 1–80 — validate reactive updates and Combine/SwiftUI integration assumptions.
  - `Sources/SpecificationKit/Wrappers/CachedSatisfies.swift` lines 14–190 — review cache APIs, async evaluation, and locking behavior for new test targets.
  - `Sources/SpecificationKit/Wrappers/ObservedSatisfies.swift` & related wrappers — confirm exposed behaviors needing regression coverage.
- **Acceptance Thoughts:**
  - Add XCTest cases that simulate concurrent access and cache churn for `@CachedSatisfies`, verifying TTL expiry, manual invalidation, and projected-value helpers.
  - Cover wrapper error paths (e.g., async context failures) and ensure wrapper-provided metrics or projected values behave correctly.
  - Validate observed wrappers (`@ObservedSatisfies`, `@ObservedMaybe`, `@ObservedDecides`) react to provider updates without retaining stale state.
  - Document any helper fixtures introduced so future agents can extend wrapper tests consistently.
- **Open Questions / Risks:**
  - How to best simulate SwiftUI update cycles in XCTest without a runtime UI host?
  - Do cache helpers require platform-specific hooks (memory-pressure notifications) that are hard to trigger in tests?
  - Are there performance regressions that should also be benchmarked once new tests exist?

## Immediate Next Actions
1. Audit existing wrapper tests to map uncovered behaviors (async contexts, projected values, concurrency).
2. Design and implement new XCTest cases (plus any supporting fixtures) that exercise the identified edge cases and document expected outcomes.
