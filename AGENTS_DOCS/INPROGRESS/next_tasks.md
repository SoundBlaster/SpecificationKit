# Next Tasks

## 🔬 Capture Benchmark Baselines
- **Goal:** Run the `SpecificationKitBenchmarks` target on macOS hardware and record v2.0.0 baseline metrics for spec evaluation, macro compilation, and wrapper overhead scenarios.
- **Artifacts to Update:** Append results to the benchmarking log under `AGENTS_DOCS/TASK_ARCHIVE/4_Benchmarking_Infrastructure/` and surface key numbers in `AGENTS_DOCS/markdown/00_SpecificationKit_TODO.md` performance section.
- **References:** `AGENTS_DOCS/markdown/00_SpecificationKit_TODO.md` (§11 Performance Benchmarking), `AGENTS_DOCS/markdown/3.0.0/tasks/03_performance_tasks.md` (P2.1 expectations).

## 🚀 Prepare P2.2 AnySpecification Optimization
- **Goal:** Review `AGENTS_DOCS/markdown/3.0.0/tasks/03_performance_tasks.md` (§P2.2) and outline targeted optimization experiments leveraging the new benchmark harness.
- **Artifacts to Produce:** Draft a research plan in `AGENTS_DOCS/INPROGRESS/` (create new dated log) that prioritizes high-impact scenarios and identifies required data from recent baselines.
- **Dependencies:** Completion of the benchmark baseline capture above to inform optimization targets.

## ⚙️ Platform Compatibility Follow-up
- **Goal:** Investigate Linux-friendly substitutes or conditional compilation paths for CoreData-dependent benchmarks so the suite can run headless in CI.
- **Next Step:** File design notes under a new `AGENTS_DOCS/INPROGRESS/` log once feasible approaches are identified; track blockers in `blocked.md` if tooling gaps persist.
- **References:** `AGENTS_DOCS/TASK_ARCHIVE/4_Benchmarking_Infrastructure/Summary_of_Work.md` Linux limitation note, SwiftPM benchmarking discussion threads (see roadmap citations).
