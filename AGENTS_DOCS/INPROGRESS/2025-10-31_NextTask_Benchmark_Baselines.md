# Next Task — Capture Benchmark Baselines

## Selection Metadata
- **Selection Date:** 2025-10-31
- **Chosen Task:** Run the SpecificationKit benchmark target on macOS hardware and record reproducible v2.0.0 baseline metrics for spec evaluation, macro compilation, and wrapper overhead scenarios.
- **Source Backlog Entries:**
  - `AGENTS_DOCS/markdown/00_SpecificationKit_TODO.md` §10–11 (CI & performance priorities)
  - `AGENTS_DOCS/markdown/3.0.0/tasks/03_performance_tasks.md` §P2.1 baseline checklist
  - `AGENTS_DOCS/INPROGRESS/next_tasks.md` “Capture Benchmark Baselines” queue item
- **Status:** Selected / Ready to plan implementation
- **Blocking Issues:** None — must execute on macOS to avoid the known Linux CoreData limitation noted in benchmarking summary.

## Candidate Review
- **Evaluated Options:**
  - Capture benchmark baselines to unlock downstream optimization work and populate the performance backlog with real metrics. References: `AGENTS_DOCS/markdown/00_SpecificationKit_TODO.md` §11; `AGENTS_DOCS/markdown/3.0.0/tasks/03_performance_tasks.md` (baseline + documentation steps); `AGENTS_DOCS/INPROGRESS/next_tasks.md` (top entry).
  - Draft the P2.2 AnySpecification optimization plan. References: `AGENTS_DOCS/markdown/3.0.0/tasks/03_performance_tasks.md` §P2.2; `AGENTS_DOCS/INPROGRESS/next_tasks.md` (depends on fresh baselines). Deferred until the new measurements exist.
  - Investigate Linux-friendly benchmark substitutes. References: `AGENTS_DOCS/INPROGRESS/next_tasks.md` (platform compatibility follow-up); `AGENTS_DOCS/TASK_ARCHIVE/4_Benchmarking_Infrastructure/Summary_of_Work.md` (documented CoreData limitation). Scoped as a follow-on once macOS baselines confirm current performance.
- **Why this task now:** Benchmarks landed yesterday but remain data-free. Capturing baselines is the highest-priority unblocker for optimization work, roadmap progress tracking, and future CI regression detection, and it has no external dependencies beyond running the new suite on supported hardware.

## Implementation Notes
- **Entry Points / Files to Inspect:**
  - `Tests/SpecificationKitBenchmarks/PerformanceBenchmarks.swift` — houses the evaluation, macro, and wrapper performance cases that need to run with release builds.
  - `Tests/SpecificationKitBenchmarks/BenchmarkBaselineTests.swift` & `BenchmarkValidation.swift` — utilities for recording and validating baseline metrics to update with fresh data.
  - `AGENTS_DOCS/TASK_ARCHIVE/4_Benchmarking_Infrastructure/Summary_of_Work.md` — prior notes detailing macOS requirement and expected artifacts.
  - `AGENTS_DOCS/markdown/00_SpecificationKit_TODO.md` & `AGENTS_DOCS/markdown/3.0.0/tasks/03_performance_tasks.md` — update performance sections with captured numbers and any follow-up recommendations.
- **Acceptance Thoughts:**
  - Benchmarks execute successfully on macOS hardware with release configuration and produce timing/memory metrics for each scenario.
  - Results are logged in `AGENTS_DOCS/TASK_ARCHIVE/4_Benchmarking_Infrastructure/` and summarized in the main TODO / roadmap documents.
  - Document any deviations from target thresholds and flag follow-up tasks (e.g., optimization candidates or infrastructure tweaks).
- **Open Questions / Risks:**
  - Availability of macOS hardware in the current environment; if unavailable, document blocker details and required access.
  - Ensuring benchmark runs are deterministic enough for regression tracking; may need repeated runs or averaging guidance.
  - Potential adjustments to accommodate CoreData dependencies or to stub them when capturing baselines.

## Immediate Next Actions
1. Run the `SpecificationKitBenchmarks` suite on macOS (release configuration) and capture raw timing/memory outputs.
2. Summarize the metrics in `AGENTS_DOCS/TASK_ARCHIVE/4_Benchmarking_Infrastructure/` and update roadmap trackers with baseline values and follow-up recommendations.
