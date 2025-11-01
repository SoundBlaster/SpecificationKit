# Blocked Work — Recoverable Items

- **2025-11-18 – Capture Benchmark Baselines:** Benchmark suite requires macOS hardware to execute CoreData-dependent cases. The primary CI container remains Linux-only, yielding `no such module 'CoreData'` during `swift build` and `swift test`.
  - **Mitigation:** Trigger the macOS GitHub Actions workflow (`.github/workflows/ci.yml`) for release benchmark runs or secure interactive macOS access capable of running `swift test --configuration release --filter Benchmark` for `SpecificationKitBenchmarks`.
  - **Status:** Recoverable once macOS execution time is scheduled; track progress in `AGENTS_DOCS/TASK_ARCHIVE/5_Capture_Benchmark_Baselines/Capture_Benchmark_Baselines_Summary.md` and update this log after each attempt.
