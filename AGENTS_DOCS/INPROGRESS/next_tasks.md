# Next Tasks

## 1. Stand up P2.1 Benchmarking Infrastructure
- **Why:** Still required per `AGENTS_DOCS/markdown/3.0.0/tasks/03_performance_tasks.md` and the project TODO rollup.
- **Immediate steps:**
  - Scaffold a `Tests/SpecificationKitBenchmarks` target and register it in `Package.swift`.
  - Capture baseline numbers from the v2.0.0 artifacts noted in the performance backlog.
  - Implement initial XCTest `measure` suites for specification evaluation and property wrapper overhead.
- **Success signal:** Benchmarks execute locally with documented baselines, enabling downstream P2.2 optimization tasks.

_No additional active workstreams are tracked at this time._
