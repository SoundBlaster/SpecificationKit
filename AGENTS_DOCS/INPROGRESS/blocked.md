# Blocked Work — Recoverable Items

## 🚧 Active Blockers

### Capture Benchmark Baselines (macOS Hardware Required)
**Date Blocked**: 2025-11-18

**Issue**: Benchmark suite requires macOS hardware to execute CoreData-dependent test cases. The primary CI container is Linux-only, yielding `no such module 'CoreData'` during `swift build` and `swift test`.

**Mitigation**:
- Trigger the macOS GitHub Actions workflow (`.github/workflows/ci.yml`) for release benchmark runs
- Schedule interactive macOS access capable of running:
  ```bash
  swift test --configuration release --filter Benchmark
  ```
  targeting the `SpecificationKitBenchmarks` product

**Status**: Recoverable once macOS execution time is scheduled

**References**:
- Archived context: `AGENTS_DOCS/TASK_ARCHIVE/5_Capture_Benchmark_Baselines/Capture_Benchmark_Baselines_Summary.md`
- Related archive: `AGENTS_DOCS/TASK_ARCHIVE/6_Baseline_Capture_Reset/`
- Progress tracker: `AGENTS_DOCS/markdown/3.0.0/tasks/SpecificationKit_v3.0.0_Progress.md`

**Next Steps**:
1. Schedule macOS CI workflow run for release benchmarks
2. Capture baseline metrics to `Benchmarks/baselines/`
3. Update progress tracker and move item to completed
4. Remove from this blocker log

---

## 📝 Notes
- Only **recoverable** blockers should appear in this file
- Permanently blocked work belongs in `AGENTS_DOCS/TASK_ARCHIVE/BLOCKED/`
- Update this file after each blocker resolution attempt
