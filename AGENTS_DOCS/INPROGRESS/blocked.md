# Blocked Work

- **2025-11-18 – Capture Benchmark Baselines:** Benchmark suite requires macOS hardware to execute CoreData-dependent cases. Current automation container is Linux-only, so runs fail before producing metrics, and both `swift build` and `swift test` terminate with `no such module 'CoreData'`. Resolution: schedule execution on a macOS runner or provision remote access that can run `swift test --configuration release --filter Benchmark` against `SpecificationKitBenchmarks`.
  - 2025-11-19: Added `.github/workflows/ci.yml` macOS CI job so future agents can trigger `swift build`, `swift test`, and the `SpecificationKitBenchmarks` product on hosted macOS hardware while local access is arranged for baseline capture.
