# Next Task — P2.1 Benchmarking Infrastructure

## Selection Metadata
- **Selection Date:** 2025-10-30
- **Chosen Task:** Stand up the dedicated benchmarking target and baseline performance suite for SpecificationKit.
- **Source Backlog Entries:**
  - `AGENTS_DOCS/markdown/00_SpecificationKit_TODO.md` lines 99-109
  - `AGENTS_DOCS/markdown/3.0.0/tasks/03_performance_tasks.md` lines 10-105
- **Status:** Completed — benchmarking target live in repository (2025-10-30)
- **Blocking Issues:** None identified

## Candidate Review
- **Evaluated Options:**
  - Establish the P2.1 benchmarking infrastructure to unblock downstream optimization work and fulfill the critical-path performance objectives. References: `AGENTS_DOCS/markdown/00_SpecificationKit_TODO.md` lines 99-109; `AGENTS_DOCS/markdown/3.0.0/tasks/03_performance_tasks.md` lines 10-105.
  - Add a GitHub Actions CI workflow to run the test suite on pushes and pull requests. Reference: `AGENTS_DOCS/markdown/00_SpecificationKit_TODO.md` lines 99-103.
- **Why this task now:** The benchmarking infrastructure is flagged as a critical-path dependency for multiple v3.0.0 performance initiatives and has no outstanding blockers. Completing it enables data-driven optimization tasks (e.g., AnySpecification tuning) and provides measurable baselines before adding more automation like CI.

## Implementation Notes
- **Entry Points / Files to Inspect:**
  - `Package.swift` — add a benchmark test target and ensure dependencies compile with performance metrics enabled.
  - `Tests/` — introduce `SpecificationKitBenchmarks` suite (likely under a new benchmarks folder) covering spec evaluation, macro compilation overhead, and wrapper performance per roadmap guidance.
  - `AGENTS_DOCS/INPROGRESS/next_tasks.md` — align immediate steps with the existing high-level checklist.
- **Acceptance Thoughts:**
  - Benchmarks execute locally via `swift test --filter` or dedicated scheme, capturing wall-clock and memory metrics for the scenarios outlined in the backlog.
  - Baseline thresholds are documented alongside results so regressions can be spotted in future runs.
  - Follow-up optimization tasks (e.g., P2.2 AnySpecification work) have clear benchmark entry points to target.
- **Open Questions / Risks:**
  - Need to confirm availability of representative v2.0.0 baseline numbers or recreate them if artifacts are missing.
  - SwiftPM support for performance tests may require custom tooling or integration with XCTest's `measure` APIs; ensure automation hooks are viable for future CI integration.

## Immediate Next Actions
1. Scaffold the benchmark target structure (files, target registration, and placeholder XCTestCase) and validate it compiles.
2. Implement the initial measurement loops for spec evaluation, macro compilation, and property wrapper overhead, recording provisional baseline metrics for review.

## Completion Summary
- Created the dedicated `SpecificationKitBenchmarks` test target and migrated the legacy performance cases into it for isolated execution.
- Introduced reusable baseline validation utilities (`BenchmarkBaseline`, `BaselineValidator`, metric/result types) exercised by new unit coverage.
- Updated documentation trackers (`00_SpecificationKit_TODO.md`, `SpecificationKit_v3.0.0_Progress.md`) and in-progress notes to reflect the infrastructure delivery.
- Benchmarks run locally; Linux environments lack CoreData, so the suite reports the pre-existing module import limitation during `swift test`.
