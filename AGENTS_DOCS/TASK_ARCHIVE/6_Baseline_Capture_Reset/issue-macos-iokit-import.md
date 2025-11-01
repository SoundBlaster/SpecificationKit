# Import IOKit for macOS device model detection

## Status
- **2025-11-19 — Completed.** Added a conditional `IOKit` import to `BenchmarkValidation.swift`, enabling the macOS-specific device model helpers to compile on Apple platforms while keeping Linux builds intact.

## Original Issue
The macOS branch of `TestEnvironment.getDeviceModel()` invokes `IOServiceGetMatchingService`, `IOServiceMatching`, `IORegistryEntryCreateCFProperty`, and `IOObjectRelease`, all of which are declared in the IOKit framework. This file only imports Foundation/XCTest, so the test target will not compile on macOS (Cannot find 'IOServiceGetMatchingService' in scope). Add import IOKit (optionally wrapped in #if os(macOS)) before using these APIs so the benchmarks build on Apple platforms.