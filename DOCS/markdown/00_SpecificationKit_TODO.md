# 📋 SpecificationKit – Development Plan (TODO)

This file provides a step-by-step plan for implementing the SpecificationKit library using SwiftPM, including core logic, wrappers, context injection, and (optionally) macro support.

---

## ✅ 1. Repository Initialization

- [ ] Create a new SwiftPM project:
  ```bash
  swift package init --type library
  ```
- [ ] Update `Package.swift`:
  - Name: `SpecificationKit`
  - Set minimum Swift version: 5.9+
- [ ] Create folders:
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

- [ ] `Specification.swift` – Base protocol
- [ ] `AnySpecification.swift` – Type-erased wrapper
- [ ] `SpecificationOperators.swift` – `.and`, `.or`, `.not`, operators
- [ ] `ContextProviding.swift` – Protocol for providing `Context`

---

## 🧩 3. Composables Layer – General-purpose specifications

- [ ] `TimeSinceEventSpec.swift`
- [ ] `MaxCountSpec.swift`
- [ ] `CooldownIntervalSpec.swift`
- [ ] `PredicateSpec.swift`

---

## 🧵 4. Property Wrapper Layer

- [ ] `Satisfies.swift`
  - Support:
    - `@Satisfies(using: Spec.self)` (auto context)
    - `@Satisfies(context: ..., using: Spec.self)` (manual context)

---

## 🧠 5. Definitions Layer

- [ ] `CompositeSpec.swift` – Example combining multiple specs
- [ ] `AutoContextSpecification.swift` – Protocol with `static var contextProvider` + `init()`

---

## 🔌 6. Context Layer

- [ ] `EvaluationContext.swift` – Holds evaluation state
- [ ] `DefaultContextProvider.swift` – Runtime context provider
- [ ] `MockContextProvider.swift` – For unit testing

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

- [ ] `README.md` – Overview, motivation, usage
- [ ] `CONTRIBUTING.md`, `LICENSE`, `CHANGELOG.md` (if public)
- [ ] Optional: `Examples/` folder

---

## 🚀 10. CI & Packaging

- [ ] Add GitHub Actions workflow `.github/workflows/test.yml`
- [ ] Optional: Set up DocC documentation target
- [ ] Tag `v0.1.0` after initial implementation