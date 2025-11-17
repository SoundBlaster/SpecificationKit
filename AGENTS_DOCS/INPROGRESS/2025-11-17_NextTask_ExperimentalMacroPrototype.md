# Next Task — Prototype Experimental Macro for Conditional Specification Composition

## Selection Metadata
- **Selection Date:** 2025-11-17
- **Chosen Task:** Prototype one experimental macro from the P2 enhancement set, evaluating `@specsIf(condition:)`, `#composed(...)`, or `@deriveSpec(from:)` syntax options and providing usage examples
- **Source Backlog Entries:**
  - `AGENTS_DOCS/markdown/3.0.0/00_3.0.0_TODO_SpecificationKit.md` lines 25–27 (Experimental Features, P2)
- **Status:** Selected / Ready to plan implementation
- **Blocking Issues:** None

## Candidate Review

### Evaluated Options
1. **Benchmark Baseline Capture** (P2.2 Performance Optimization)
   - Referenced: `AGENTS_DOCS/markdown/00_SpecificationKit_TODO.md` line 110
   - Status: **Blocked** — requires macOS hardware for CoreData-dependent tests
   - Mitigation: Can be triggered via GitHub Actions when hardware access is scheduled
   - Decision: Defer until macOS CI access available

2. **Prototype Experimental Macro** (P2 Experimental Features)
   - Referenced: `AGENTS_DOCS/markdown/3.0.0/00_3.0.0_TODO_SpecificationKit.md` lines 25–27
   - Status: **Unblocked** — self-contained, requires no external resources
   - Scope: Three concrete macro options to evaluate
   - Decision: **SELECTED** for implementation

3. **Performance Optimization Investigation** (P2 Performance Optimization)
   - Referenced: `AGENTS_DOCS/markdown/3.0.0/00_3.0.0_TODO_SpecificationKit.md` lines 29–32
   - Status: Unblocked but requires baseline metrics first
   - Dependency: Benchmark baseline capture (currently blocked)
   - Decision: Defer until benchmarks are available for comparison

### Why This Task Now

1. **No external blockers** — Can proceed independently without waiting for macOS hardware or other infrastructure
2. **Demonstrates macro evolution** — Extends the existing macro system (`@specs`, `@AutoContext`) with a new, more advanced capability
3. **Clear evaluation criteria** — Three specific macro options with concrete semantics to compare
4. **High visibility** — Experimental features are often showcased in release notes and documentation
5. **Unblocks future design** — Results inform future macro system roadmap (v3.1.0+)
6. **Library maturity indicator** — Shows SpecificationKit is actively evolving with advanced patterns

## Implementation Notes

### Entry Points / Files to Inspect
- `Sources/SpecificationKitMacros/MacroPlugin.swift` — Macro registration entry point
- `Sources/SpecificationKitMacros/AutoContextMacro.swift` — Example of advanced macro implementation with diagnostics
- `Sources/SpecificationKitMacros/SpecsMacro.swift` — Example of composite specification macro
- `Tests/SpecificationKitMacrosTests/` — Macro test patterns using swift-macro-testing
- `CONTRIBUTING.md` — Macro development guidelines
- `CLAUDE.md` — Build and test commands for macro validation

### Macro Options to Evaluate

**Option 1: `@specsIf(condition:)`**
- Syntax: `@specsIf(condition: { context in context.isSubscribed })`
- Behavior: Wraps a specification to conditionally enable/disable based on a closure
- Pros: Simple, closure-based approach
- Cons: May require runtime evaluation overhead

**Option 2: `#composed(...)`**
- Syntax: `#composed([spec1, spec2, spec3], operator: .all)` or similar
- Behavior: Compile-time composition of multiple specs with operator selection
- Pros: Explicit operator choice, potential for compile-time optimizations
- Cons: Declarative syntax may feel inconsistent with attribute macros

**Option 3: `@deriveSpec(from:)`**
- Syntax: `@deriveSpec(from: MyComposableProtocol.self)`
- Behavior: Generate specification from a protocol conformance
- Pros: Protocol-driven, extensible pattern
- Cons: Complex implementation, may require protocol synthesis

### Acceptance Thoughts
- Fully working prototype of one chosen macro syntax
- Comprehensive test coverage (at minimum 5 test cases) demonstrating:
  - Basic usage
  - Edge cases (empty specs, nil conditions, etc.)
  - Error handling and diagnostics
  - Integration with existing specs (`@Satisfies`, `@Decides`)
- Usage example in documentation or README
- Diagnostic messages that guide users on correct usage
- No breaking changes to existing macros
- Builds without warnings on Swift 5.9+

### Open Questions / Risks
1. **Macro complexity** — Does the chosen syntax require advanced macro capabilities, or can it be implemented with current Swift 5.9 macro system?
2. **Performance impact** — Does the generated code add overhead compared to manual composition?
3. **User ergonomics** — Is the syntax intuitive for the intended use case?
4. **Maintenance burden** — Can the macro be documented and maintained alongside existing macros?

## Immediate Next Actions
1. Read macro implementation examples in `Sources/SpecificationKitMacros/` to understand existing patterns
2. Design the chosen macro's syntax and semantics (evaluation criteria needed before selection)
3. Implement macro in `MacroPlugin.swift` with diagnostic support
4. Write 5+ comprehensive test cases in `SpecificationKitMacrosTests/`
5. Add usage documentation to `CONTRIBUTING.md` or create a new macro guide
6. Run full test suite and validate build with `swift build -v`
7. Update CHANGELOG.md with new P2 feature entry
8. Archive this selection record and document results in a new task archive

## Reference Documents
- **Base TODO**: `AGENTS_DOCS/markdown/00_SpecificationKit_TODO.md`
- **v3.0.0 TODO**: `AGENTS_DOCS/markdown/3.0.0/00_3.0.0_TODO_SpecificationKit.md`
- **Blockers**: `AGENTS_DOCS/INPROGRESS/blocked.md`
- **Archive Summary**: `AGENTS_DOCS/TASK_ARCHIVE/ARCHIVE_SUMMARY.md`
- **Macro Examples**: `Sources/SpecificationKitMacros/*.swift`
