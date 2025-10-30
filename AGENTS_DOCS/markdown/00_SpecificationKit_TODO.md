# 📋 SpecificationKit – Development Plan (TODO)

This file provides a step-by-step plan for implementing the SpecificationKit library using SwiftPM, including core logic, wrappers, context injection, and (optionally) macro support.

---

## ✅ 1. Repository Initialization

- [x] Create a new SwiftPM project:
  ```bash
  swift package init --type library
  ```
- [x] Update `Package.swift`:
  - Name: `SpecificationKit`
  - Set minimum Swift version: 5.9+
- [x] Create folders:
  ```
  Sources/SpecificationKit/Core/
  Sources/SpecificationKit/Specs/
  Sources/SpecificationKit/Providers/
  Sources/SpecificationKit/Wrappers/
  Sources/SpecificationKit/Definitions/
  Sources/SpecificationKit/Macros/       # optional
  Tests/SpecificationKitTests/
  ```

---

## ⚙️ 2. Core Layer

- [x] `Specification.swift` – Base protocol
- [x] `AnySpecification.swift` – Type-erased wrapper
- [x] `SpecificationOperators.swift` – `.and`, `.or`, `.not`, operators
- [x] `ContextProviding.swift` – Protocol for providing `Context`

---

## 🧩 3. Composables Layer – General-purpose specifications

- [x] `TimeSinceEventSpec.swift`
- [x] `MaxCountSpec.swift`
- [x] `CooldownIntervalSpec.swift`
- [x] `PredicateSpec.swift`

---

## 🧵 4. Property Wrapper Layer

- [x] `Satisfies.swift`
  - Support:
    - [x] `@Satisfies(using: Spec.self)` (auto context)
    - [x] `@Satisfies(context: ..., using: Spec.self)` (manual context)

---

## 🧠 5. Definitions Layer

- [x] `CompositeSpec.swift` – Example combining multiple specs
- [x] `AutoContextSpecification.swift` – Protocol with `static var contextProvider` + `init()`

---

## 🔌 6. Context Layer

- [x] `EvaluationContext.swift` – Holds evaluation state
- [x] `DefaultContextProvider.swift` – Runtime context provider
- [x] `MockContextProvider.swift` – For unit testing

---

## 🪄 7. Macro Layer (Optional)

- [x] `@specs(...)` – Macro to generate composite spec
- [x] `MacroPlugin.swift` – Plugin registration
- [x] Update `DemoApp/`: Modify an example in the demo application to use the new macro, showcasing its simplicity.

---

## 🧪 8. Tests

- [x] Core specification tests (`TimeSinceEventSpec`, `MaxCountSpec`, `CooldownIntervalSpec`, `CompositeSpec`) are covered within `SpecificationKitTests.swift`.
- [x] Mock context provider tests are included in `SpecificationKitTests.swift`.
- [x] Macro expansion tests are implemented in `SpecsMacroTests.swift`.
- [x] `SatisfiesWrapperTests.swift` now covers the `@Satisfies` property wrapper, including manual context usage (see `AGENTS_DOCS/TASK_ARCHIVE/2_SatisfiesManualContext_and_P21_Benchmarks/Summary_of_Work.md`).
- [x] Expand edge-case and stress coverage for property wrappers as new scenarios emerge (async cache projections, failure paths) — archived in `AGENTS_DOCS/TASK_ARCHIVE/3_PropertyWrapperEdgeCases/`.

---

## 📄 9. Documentation

- [x] `README.md` – Overview, motivation, usage
- [x] `CONTRIBUTING.md`
- [x] `LICENSE`
- [x] `CHANGELOG.md`
- [x] Example: `DemoApp/` folder

---

## 🚀 10. CI & Packaging

- [ ] Add GitHub Actions workflow `.github/workflows/test.yml`
- [ ] Optional: Set up DocC documentation target
- [x] Tag `v0.1.0` after initial implementation

---

## 📈 11. Performance Benchmarking

- [ ] P2.1 Benchmarking infrastructure — establish dedicated benchmark target, capture v2.0.0 baselines, and integrate XCTest `measure` suites (see `AGENTS_DOCS/INPROGRESS/next_tasks.md`).
