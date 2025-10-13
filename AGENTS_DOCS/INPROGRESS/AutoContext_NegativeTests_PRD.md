# SpecificationKit v3.0.0 PRD — `@AutoContext` Negative Diagnostics Suite

## 1. Executive Summary
- **Objective**: deliver a deterministic test + diagnostics package that proves `@AutoContext` surfaces compile-time errors whenever a specification's `Context` type does not align with the synthesized provider type.【F:AGENTS_DOCS/markdown/3.0.0/00_3.0.0_TODO_SpecificationKit.md†L7-L17】【F:AGENTS_DOCS/markdown/3.0.0/01_3.0.0_TODO_GPT5.md†L333-L340】
- **Why now**: the v3.0.0 roadmap treats these negative tests as critical-path coverage for the macro workstream, unblocking downstream integration suites and maintaining developer trust in macro diagnostics.【F:AGENTS_DOCS/markdown/3.0.0/tasks/01_phase_breakdown.md†L5-L16】【F:AGENTS_DOCS/markdown/3.0.0/02_3.0.0_AI_IMPLEMENTATION_PLAN.md†L25-L36】
- **Expected outcome**: reusable fixtures, explicit diagnostics contracts, and a gating test target that fails fast if mismatches regress. The suite should be ready to flip from `XCTExpectFailure` to hard asserts once the toolchain exposes the necessary conformance checks.【F:AGENTS_DOCS/markdown/3.0.0/tasks/02_macro_specialist_tasks.md†L100-L197】

## 2. Alignment & Dependencies
- **Roadmap linkage**: completes the "Add negative tests for `@AutoContext` type mismatches" checkbox in the v3.0.0 TODO tracker and satisfies the acceptance criteria captured in the master PRD table.【F:AGENTS_DOCS/markdown/3.0.0/00_3.0.0_TODO_SpecificationKit.md†L9-L18】【F:AGENTS_DOCS/markdown/3.0.0/01_3.0.0_TODO_GPT5.md†L333-L340】
- **Phase planning**: resides in Phase 0 of the program plan; implementation is blocked until the macro validation primitive lands, so tests must be introduced in a skipped/expect-failure state with TODO links to the enabling task.【F:AGENTS_DOCS/markdown/3.0.0/tasks/01_phase_breakdown.md†L5-L18】【F:AGENTS_DOCS/markdown/3.0.0/02_3.0.0_AI_IMPLEMENTATION_PLAN.md†L25-L36】
- **Dependency chain**: depends on the "Context type validation in `@AutoContext`" task and should publish a helper API surface (e.g., static diagnostic identifiers) that that task will satisfy. Integration tests may also reference these helpers later in the phase plan.【F:AGENTS_DOCS/markdown/3.0.0/tasks/01_phase_breakdown.md†L9-L16】【F:AGENTS_DOCS/markdown/3.0.0/02_3.0.0_AI_IMPLEMENTATION_PLAN.md†L29-L36】【F:AGENTS_DOCS/markdown/3.0.0/tasks/02_macro_specialist_tasks.md†L100-L197】

## 3. Problem Statement
Without codified negative coverage, future macro work can silently reintroduce provider/context mismatch regressions, shifting errors from curated diagnostics to opaque compiler output. The program requires a PRD that nails down the misuse scenarios, diagnostic copy, and test harness so agents can land the validation task with confidence and verifiable acceptance criteria.【F:AGENTS_DOCS/markdown/3.0.0/01_3.0.0_TODO_GPT5.md†L333-L340】【F:AGENTS_DOCS/markdown/3.0.0/tasks/02_macro_specialist_tasks.md†L140-L168】

## 4. Scope
### In Scope
1. Authoring fixture sources that intentionally violate `@AutoContext` expectations (wrong `typealias Context`, missing `typealias`, provider overrides) and asserting the emitted diagnostics.
2. Documenting the canonical diagnostic identifiers, severities, and user-facing copy for each misuse case.
3. Establishing XCTest cases that rely on `SwiftSyntaxMacrosTestSupport` (or equivalent) to exercise macro expansion without compiling the full package.
4. Guarding the tests with `XCTSkip`/`XCTExpectFailure` until the blocking validation primitive ships, while ensuring the assertions are ready to flip to strict mode.

### Out of Scope
- Implementing the actual macro changes that perform context validation (tracked separately in the macro enhancement task group).
- Expanding `@AutoContext` feature scope (flags, parameter inference, async helpers) beyond emitting diagnostics for mismatched contexts.
- Runtime validation fallbacks; those remain in the macro specialist backlog and are only referenced here for coordination.【F:AGENTS_DOCS/markdown/3.0.0/tasks/02_macro_specialist_tasks.md†L100-L197】

## 5. Functional Requirements
1. **Diagnostic Coverage** — Each misuse scenario must emit exactly one `.error` diagnostic pinned to the `@AutoContext` attribute usage and include actionable guidance ("expected `EvaluationContext`, found `CustomContext`").【F:AGENTS_DOCS/markdown/3.0.0/tasks/02_macro_specialist_tasks.md†L140-L168】
2. **Scenario Matrix** — Minimum scenarios:
   - `typealias Context = CustomContext` with default provider → mismatch error.
   - Missing `typealias Context` → diagnostic indicating ambiguity and guiding towards explicit declaration.
   - Provider override stub (`@AutoContext(MyProvider.self)`) whose `Context` differs → mismatch error describing both types.
3. **Assertion Strictness** — The test suite must assert the diagnostic identifier, message string, severity, and highlight range; no unexpected diagnostics may remain in the results array.
4. **Future Compatibility** — Diagnostics and fixture builders should expose reusable helpers so integration tests and documentation examples can share the same error expectations when the validation implementation lands.【F:AGENTS_DOCS/markdown/3.0.0/01_3.0.0_TODO_GPT5.md†L333-L340】【F:AGENTS_DOCS/markdown/3.0.0/tasks/02_macro_specialist_tasks.md†L140-L186】

## 6. Non-Functional Requirements
1. **Macro Test Performance** — Macro expansion checks should execute within existing CI time budgets and adhere to the <10% compilation overhead guideline for macro work.【F:AGENTS_DOCS/markdown/3.0.0/tasks/02_macro_specialist_tasks.md†L140-L168】
2. **Diagnostic Quality** — Messages must follow the documented structure (clear message, severity, optional fix-it) and remain stable via centralized constants inside `AutoContextMacro`.【F:AGENTS_DOCS/markdown/3.0.0/tasks/02_macro_specialist_tasks.md†L146-L168】
3. **Documentation Hooks** — Tests should double as living examples referenced by DocC/Troubleshooting materials managed by the documentation specialist team.【F:AGENTS_DOCS/markdown/3.0.0/tasks/02_macro_specialist_tasks.md†L169-L186】【F:AGENTS_DOCS/markdown/3.0.0/tasks/09_documentation_tasks.md†L40-L88】

## 7. Test Plan
1. **Harness** — Extend `SpecificationKitMacrosTests` with a dedicated `AutoContextMacroDiagnosticsTests` case leveraging `assertMacroExpansion` (or equivalent) to capture generated members and diagnostics without full compilation.
2. **Fixtures** — Encode inline Swift snippets representing each misuse case; ensure line/column data place the attribute at `(line: 1, column: 1)` for deterministic comparisons.
3. **Expectations** — For each fixture, assert the returned diagnostics array matches exactly; use helper assertions to verify identifier, message, severity, and range.
4. **Blocking Guard** — Wrap assertions in `XCTExpectFailure("Blocked by @AutoContext validation task")` until the macro validation feature is implemented, aligning with the phase plan's blocked status.【F:AGENTS_DOCS/markdown/3.0.0/tasks/01_phase_breakdown.md†L5-L18】【F:AGENTS_DOCS/markdown/3.0.0/02_3.0.0_AI_IMPLEMENTATION_PLAN.md†L25-L36】
5. **Continuous Integration** — Integrate the suite into the existing macro test target to keep coverage above the >95% target for error paths.【F:AGENTS_DOCS/markdown/3.0.0/tasks/02_macro_specialist_tasks.md†L140-L168】

## 8. Implementation Guidelines
- **Diagnostics API**: Introduce a nested `enum Diagnostics` within `AutoContextMacro` providing static identifiers and formatted messages to prevent string drift and to support DocC references.【F:AGENTS_DOCS/markdown/3.0.0/tasks/02_macro_specialist_tasks.md†L140-L186】
- **Failure Handling**: Macro expansion should bail out after emitting a fatal diagnostic to avoid cascaded errors once validation logic is active; document this behavior for the macro specialist team.
- **Coordination**: Sync with the testing tools specialist when integrating new assertion helpers so future debugging utilities can consume the same primitives.【F:AGENTS_DOCS/markdown/3.0.0/tasks/01_phase_breakdown.md†L38-L47】【F:AGENTS_DOCS/markdown/3.0.0/tasks/02_macro_specialist_tasks.md†L175-L197】

## 9. Deliverables & Timeline
- **Iteration 1 (Blocked State)**: Land the fixture sources, diagnostics contract documentation, and expect-failing tests referenced in the Phase 0 backlog. Include TODO comments linking to the validation task ID.【F:AGENTS_DOCS/markdown/3.0.0/02_3.0.0_AI_IMPLEMENTATION_PLAN.md†L29-L36】【F:AGENTS_DOCS/markdown/3.0.0/tasks/01_phase_breakdown.md†L5-L18】
- **Iteration 2 (Unblocked)**: Once the macro validation task completes, remove `XCTExpectFailure`, enable strict assertions, and update documentation to mark the roadmap item as done.【F:AGENTS_DOCS/markdown/3.0.0/00_3.0.0_TODO_SpecificationKit.md†L9-L17】【F:AGENTS_DOCS/markdown/3.0.0/01_3.0.0_TODO_GPT5.md†L333-L340】

## 10. Risks & Mitigations
- **Toolchain Drift** — Swift macro diagnostics APIs may evolve; mitigate via wrapper helpers and regular sync with toolchain updates noted in the macro specialist guidelines.【F:AGENTS_DOCS/markdown/3.0.0/tasks/02_macro_specialist_tasks.md†L100-L197】
- **Diagnostic Noise** — Additional compiler diagnostics could obscure macro errors; enforce exact-match assertions and bail-out behavior to maintain clarity.【F:AGENTS_DOCS/markdown/3.0.0/tasks/02_macro_specialist_tasks.md†L140-L186】
- **Coordination Gaps** — Missing communication with testing/documentation specialists could duplicate effort; follow the coordination points listed in the macro specialist tasks document.【F:AGENTS_DOCS/markdown/3.0.0/tasks/02_macro_specialist_tasks.md†L175-L186】

## 11. Acceptance Criteria
1. The roadmap checkbox for negative tests is marked complete with tests merged and documented.【F:AGENTS_DOCS/markdown/3.0.0/00_3.0.0_TODO_SpecificationKit.md†L9-L18】
2. The v3.0.0 PRD table's acceptance condition (tests emit expected diagnostics on mismatches) is demonstrably satisfied via the new suite.【F:AGENTS_DOCS/markdown/3.0.0/01_3.0.0_TODO_GPT5.md†L333-L340】
3. Macro diagnostics adhere to the message structure, severity, and quality bar set out in the macro specialist guidelines, with centralized constants and helper APIs in place.【F:AGENTS_DOCS/markdown/3.0.0/tasks/02_macro_specialist_tasks.md†L140-L186】
4. Test coverage for macro error paths remains above the >95% goal after integrating the suite.【F:AGENTS_DOCS/markdown/3.0.0/tasks/02_macro_specialist_tasks.md†L140-L168】

## 12. Open Questions
- Should the diagnostics expose structured payloads (e.g., `DiagnosticMessage` with associated fix-its) so developer tooling can offer quick fixes? Coordinate with the macro specialist before implementation.【F:AGENTS_DOCS/markdown/3.0.0/tasks/02_macro_specialist_tasks.md†L146-L168】
- When the validation toolchain lands, can we provide compile-time fix-its suggesting a conforming provider, or is documentation the preferred channel?【F:AGENTS_DOCS/markdown/3.0.0/tasks/02_macro_specialist_tasks.md†L146-L168】
