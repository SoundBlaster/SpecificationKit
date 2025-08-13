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
    - [ ] `@Satisfies(context: ..., using: Spec.self)` (manual context)

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

- [ ] `@specs(...)` – Macro to generate composite spec
- [ ] `MacroPlugin.swift` – Plugin registration

---

## 🧪 8. Tests

- [ ] `TimeSinceEventSpecTests.swift`
- [ ] `MaxCountSpecTests.swift`
- [ ] `CooldownIntervalSpecTests.swift`
- [ ] `CompositeSpecTests.swift`
- [ ] `SatisfiesWrapperTests.swift`
- [ ] `MockProviderTests.swift`

---

## 📄 9. Documentation

- [x] `README.md` – Overview, motivation, usage
- [ ] `CONTRIBUTING.md`, `LICENSE`, `CHANGELOG.md` (if public)
- [x] Example: `DemoApp/` folder

---

## 🚀 10. CI & Packaging

- [ ] Add GitHub Actions workflow `.github/workflows/test.yml`
- [ ] Optional: Set up DocC documentation target
- [x] Tag `v0.1.0` after initial implementation
