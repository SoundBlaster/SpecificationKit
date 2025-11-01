# Summary of Work — Baseline Capture Reset (2025-11-19)

## Current Focus
- Schedule macOS executions of `SpecificationKitBenchmarks` to record v2.0.0 release baselines.
- Draft the P2.2 AnySpecification optimization plan informed by the forthcoming metrics.
- Explore Linux-safe alternatives for CoreData-dependent benchmarks so automated environments can validate performance.

## Recent Changes
- Archived prior working notes under `AGENTS_DOCS/TASK_ARCHIVE/5_Capture_Benchmark_Baselines/`, including the dated task log and blocker history.
- Refreshed `next_tasks.md` and `blocked.md` to reflect actionable follow-ups after the archive.
- Updated roadmap trackers (`AGENTS_DOCS/markdown/00_SpecificationKit_TODO.md`, `AGENTS_DOCS/markdown/3.0.0/tasks/SpecificationKit_v3.0.0_Progress.md`) to reference the new archive folder.

## 2025-11-19 Updates (Commit TBD)
- Implemented a reusable `BenchmarkTimer` to measure average execution time without including XCTest harness overhead and refactored the key performance tests to adopt it.
- Added conditional `IOKit` imports to the benchmark validation utilities so macOS builds resolve device APIs, while CoreData-backed providers are now guarded behind `canImport(CoreData)` to keep Linux builds compiling.
- Simplified `BenchmarkStorage`'s fallback path to rely on `FileManager.temporaryDirectory`, matching modern deployment targets and enabling deterministic tests.

## Coordination Notes
- Use the macOS GitHub Actions workflow (`.github/workflows/ci.yml`) for release builds/tests and benchmark runs until direct macOS access is available.
- Capture benchmark outputs in the benchmarking archive (`AGENTS_DOCS/TASK_ARCHIVE/4_Benchmarking_Infrastructure/`) and surface highlights in project roadmaps once collected.
- Record new blockers immediately so long-term issues can migrate into `AGENTS_DOCS/TASK_ARCHIVE/BLOCKED/` if necessary.
