# Next Task — Implement manual context support for `@Satisfies`

## Selection Metadata
- **Selection Date:** 2025-10-13
- **Chosen Task:** Add a manual `context:` entry point and validation coverage for the `@Satisfies` property wrapper.
- **Source Backlog Entries:**
  - `AGENTS_DOCS/markdown/00_SpecificationKit_TODO.md` lines 49-53
  - `AGENTS_DOCS/markdown/00_SpecificationKit_TODO.md` lines 81-85
- **Status:** Selected / Ready to plan implementation
- **Blocking Issues:** None identified; requires API design + test harness work.

## Candidate Review
- **Evaluated Options:**
  - Implement manual context support for `@Satisfies` so callers can inject a `Context` instance instead of a provider (priority gap called out in the TODO tracker).
  - Author `SatisfiesWrapperTests.swift` to cover the property wrapper surface, including async evaluation and manual context paths (currently missing coverage).
  - Add the SwiftPM GitHub Actions workflow to restore CI validation for the package.
- **Why this task now:** Manual context injection is the remaining unchecked requirement inside the property wrapper layer and it is a prerequisite for writing meaningful wrapper tests. Tackling it first unlocks the pending test work and keeps the API aligned with the project roadmap before expanding CI automation.

## Implementation Notes
- **Entry Points / Files to Inspect:**
  - `Sources/SpecificationKit/Wrappers/Satisfies.swift` lines 25-62 — only provider-based initialisers exist today; need an overload that accepts a `Context` value or closure.
  - `Tests/SpecificationKitTests` target — determine the best location for new wrapper tests and reusable fixtures.
- **Acceptance Thoughts:**
  - Provide an ergonomically named `init(context:using:)` (and optional predicate helper) that stores the supplied context and reuses existing evaluation logic.
  - Ensure async evaluation still functions when manual contexts are used by bridging into the existing async path.
  - Add unit tests verifying manual context usage, async evaluation, and interactions with decision specs or builder utilities.
- **Open Questions / Risks:**
  - Confirm thread-safety expectations for cached contexts vs. provider factories.
  - Decide whether manual contexts should participate in builder APIs or remain a dedicated initializer.

## Immediate Next Actions
1. Prototype the manual context initializer inside `Satisfies.swift`, reusing `AnySpecification` wrapping logic.
2. Draft a `SatisfiesWrapperTests` skeleton covering manual context, async evaluation, and builder integrations.
