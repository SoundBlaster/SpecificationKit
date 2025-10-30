# Next Tasks

## ✅ Stand up P2.1 Benchmarking Infrastructure — completed
- **Outcome:** Dedicated benchmark target in place with baseline validation utilities and XCTest performance coverage.
- **Artifacts:**
  - `Package.swift` registers the `SpecificationKitBenchmarks` test target.
  - Benchmarks migrated to `Tests/SpecificationKitBenchmarks/` with baseline validator coverage.
  - Baseline thresholds documented via `BenchmarkBaseline` and `BaselineValidator` helpers.
- **Notes:** Linux toolchains lack `CoreData`; maintainers should execute the suite on Apple platforms for full coverage until a cross-platform stub lands.

_No additional active workstreams are tracked at this time._
