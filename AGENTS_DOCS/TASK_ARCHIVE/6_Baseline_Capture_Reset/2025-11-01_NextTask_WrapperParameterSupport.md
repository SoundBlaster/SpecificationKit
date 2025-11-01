# Next Task — Parameterized @Satisfies Initializers

## Selection Metadata
- **Selection Date:** 2025-11-01
- **Chosen Task:** Enable `@Satisfies` to construct specifications from a type reference plus labeled parameters without relying on macros.
- **Source Backlog Entries:**
  - `AGENTS_DOCS/markdown/3.0.0/00_3.0.0_TODO_SpecificationKit.md` lines 16–22
  - `AGENTS_DOCS/markdown/3.0.0/01_3.0.0_TODO_GPT5.md` lines 65–76
- **Status:** Selected / Ready to plan implementation
- **Blocking Issues:** None

## Candidate Review
- **Evaluated Options:**
  - **Implement parameterized `@Satisfies` initializers.** High-priority roadmap item calling for wrapper syntax like `@Satisfies(using: CooldownIntervalSpec.self, interval: 10)` so that specs with required arguments can be expressed without macros or manual instances.【F:AGENTS_DOCS/markdown/3.0.0/00_3.0.0_TODO_SpecificationKit.md†L16-L22】【F:AGENTS_DOCS/markdown/3.0.0/01_3.0.0_TODO_GPT5.md†L65-L76】
  - **Add GitHub Actions workflow `.github/workflows/test.yml`.** Listed in the base backlog but the repository already ships a macOS CI workflow that builds, tests, and benchmarks the package, making the additional workflow redundant unless Linux coverage is restaged.【F:AGENTS_DOCS/markdown/00_SpecificationKit_TODO.md†L99-L103】【F:.github/workflows/ci.yml†L1-L61】【F:AGENTS_DOCS/TASK_ARCHIVE/3_PropertyWrapperEdgeCases/2025-10-29_NextTask_PropertyWrapperEdgeCases.md†L12-L21】
  - **Capture macOS release benchmark baselines.** Remains a top-level backlog item, but execution is blocked on macOS hardware availability documented in the active blocker log, so it cannot progress immediately.【F:AGENTS_DOCS/markdown/00_SpecificationKit_TODO.md†L107-L110】【F:AGENTS_DOCS/INPROGRESS/blocked.md†L1-L5】【F:AGENTS_DOCS/INPROGRESS/next_tasks.md†L1-L16】
  - **Prepare for Swift Package Index metadata and tagging.** Still important, but it depends on locking 3.0 deliverables and coordinating a new semantic tag; previous release planning notes framed it as a release-phase task rather than an unblocker for current development.【F:AGENTS_DOCS/markdown/3.0.0/01_3.0.0_TODO_GPT5.md†L71-L76】
- **Why this task now:** Wrapper parameterization remains the only P1 macro enhancement without active blockers. Earlier agents deferred it until wrapper edge-case coverage improved; that work is now archived, leaving this item free to unlock parity between macro-generated and hand-authored specs and to simplify API ergonomics.【F:AGENTS_DOCS/TASK_ARCHIVE/3_PropertyWrapperEdgeCases/2025-10-29_NextTask_PropertyWrapperEdgeCases.md†L12-L37】

## Implementation Notes
- **Entry Points / Files to Inspect:**
  - `Sources/SpecificationKit/Wrappers/Satisfies.swift` — current type-based initializers only support `ExpressibleByNilLiteral`, preventing parameter forwarding.【F:Sources/SpecificationKit/Wrappers/Satisfies.swift†L163-L193】
  - `Sources/SpecificationKitMacros/SatisfiesMacro.swift` — freestanding macro already builds parameterized spec instances; new wrapper APIs should interoperate with its emitted code.【F:Sources/SpecificationKitMacros/SatisfiesMacro.swift†L276-L323】
  - `Tests/SpecificationKitTests/SatisfiesWrapperTests.swift` — existing coverage focuses on manual spec instances and predicates, leaving gaps for the proposed syntax.【F:Tests/SpecificationKitTests/SatisfiesWrapperTests.swift†L4-L63】
  - `Tests/SpecificationKitTests/SatisfiesMacroComprehensiveTests.swift` — macro expansion assertions verify parameter handling and can guide acceptance scenarios for direct wrapper usage.【F:Tests/SpecificationKitTests/SatisfiesMacroComprehensiveTests.swift†L20-L105】
- **Acceptance Thoughts:**
  - Wrapper attribute syntax allows labeled parameters when passing a spec type, with compiler inference ensuring argument forwarding works for multiple spec initializers.
  - Unit tests cover representative specs (e.g., `CooldownIntervalSpec`, `MaxCountSpec`) using the new syntax with both provider and manual context paths.
  - Macro expansions continue to compile, either by emitting the new initializer or by constructing explicit instances if we keep backward compatibility paths.
  - Documentation examples (README or DocC) reflect the streamlined attribute usage where appropriate.
- **Open Questions / Risks:**
  - Designing a generic initializer that can accept variadic labeled arguments may require leveraging `@autoclosure` or builder patterns; we need to ensure type inference remains ergonomic.
  - Interaction with `AutoContext` and other wrappers: confirm no ambiguous overloads arise when combining parameterized specs with context-providing protocols.
  - Evaluate whether macros should pivot to the new initializer to avoid duplicate construction paths and ensure diagnostics stay accurate.

## Immediate Next Actions
1. Audit existing `@Satisfies` overload set and prototype an initializer that forwards arbitrary labeled arguments to a provided spec type while preserving context constraints.
2. Extend unit and macro tests to cover the new syntax, update documentation samples, and verify the macOS CI workflow exercises the new code paths.
