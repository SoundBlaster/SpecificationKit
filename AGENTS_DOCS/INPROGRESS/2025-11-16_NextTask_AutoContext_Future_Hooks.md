# Next Task — AutoContext Future Hooks

## Selection Metadata
- **Selection Date:** 2025-11-16
- **Chosen Task:** Leave hooks for future flags (environment/infer) per AutoContext design
- **Source Backlog Entries:**
  - `AGENTS_DOCS/markdown/3.0.0/00_3.0.0_TODO_SpecificationKit.md` lines 17
  - `AGENTS_DOCS/INPROGRESS/next_tasks.md` lines 5-11
  - `AGENTS_DOCS/markdown/0.3.0/09_SpecificationKit_v0.3.0_EN_TODO_Prioritized.md` line 27
  - `AGENTS_DOCS/markdown/0.3.0/00_SpecificationKit_v0.3.0_EN_TODO.md` line 28
- **Status:** Selected / Ready to plan implementation
- **Blocking Issues:** None

## Candidate Review
- **Evaluated Options:**
  - **GitHub Actions workflow (P0)** — Already implemented as `.github/workflows/ci.yml` and `documentation.yml`; can be marked complete in base TODO. Not selected because already done.
  - **AutoContext Future Hooks (P1)** — Only remaining P1 item for v3.0.0; ready to implement with clear design document; no blockers. **SELECTED**
  - **Benchmark baselines (P2)** — Blocked by macOS hardware requirement; tracked in `AGENTS_DOCS/INPROGRESS/blocked.md`. Not selected due to blocker.
  - **Experimental macros (P2)** — Lower priority; can be deferred to post-3.0.0. Not selected due to priority.
  - **Enhanced property wrappers (P3)** — Lower priority; can be deferred to post-3.0.0. Not selected due to priority.

- **Why this task now:**
  - Highest priority unblocked item (P1 for v3.0.0 milestone)
  - Clear design document exists (`AGENTS_DOCS/markdown/05_AutoContext.md`)
  - Prepares macro infrastructure for future Swift toolchain enhancements
  - Minimal implementation risk; primarily documentation and infrastructure
  - Completing this closes out all P1 items for v3.0.0 (except toolchain-blocked items)

## Implementation Notes
- **Entry Points / Files to Inspect:**
  - `Sources/SpecificationKitMacros/AutoContextMacro.swift` — Current macro implementation; needs to parse optional arguments and prepare for future flags
  - `Sources/SpecificationKitMacros/MacroPlugin.swift` — Macro registration; may need updates for new macro signatures
  - `AGENTS_DOCS/markdown/05_AutoContext.md` — Design document describing future extension points (environment, infer, provider override)
  - `Tests/SpecificationKitTests/MacroTests/` — Test infrastructure for macro behavior

- **Acceptance Thoughts:**
  - Macro can parse optional arguments (even if not fully implemented)
  - Documentation clearly describes reserved/planned parameters
  - Code comments mark extension points for future implementation
  - No breaking changes to existing `@AutoContext` usage
  - Tests demonstrate that existing usage continues to work
  - Infrastructure exists for future flags: `environment`, `infer`, and custom provider type

- **Open Questions / Risks:**
  - Should we implement parameter parsing now or just document the planned syntax? (Decision: Parse arguments but provide graceful "not yet implemented" diagnostics)
  - Do we need tests for future flag syntax even if they're not implemented? (Decision: Add tests that verify parsing works and appropriate diagnostics are emitted)
  - Should we add a diagnostic warning for future flags that aren't yet supported? (Decision: Yes, emit informative diagnostics)

## Immediate Next Actions
1. Review current `AutoContextMacro.swift` implementation and identify extension points
2. Design argument parsing structure for `@AutoContext(...)` with optional parameters
3. Add infrastructure for parsing future flags: `environment`, `infer`, and custom provider
4. Document planned parameters in code comments and macro documentation
5. Add tests verifying that future flag syntax can be parsed (with appropriate diagnostics)
6. Update `AGENTS_DOCS/markdown/05_AutoContext.md` with implementation status
7. Archive this selection record and create implementation tracking document
