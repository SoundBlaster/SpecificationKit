# SpecificationKit Project Architecture v0.1.0

This document outlines a recommended architectural breakdown for a Swift project implementing the Specification Pattern using macros, property wrappers, and context providers.

---

## 🧱 Hierarchical Architecture Overview

### 1. **Core Layer** – Foundational abstractions

| Subsystem               | Purpose                                             |
|------------------------|-----------------------------------------------------|
| `Specification`        | Protocol with `isSatisfiedBy` for T                 |
| `AnySpecification<T>`  | Type-erased wrapper for any specification           |
| `SpecificationOperators` | `.and()`, `.or()`, `.not()` and `&&` overloads    |
| `ContextProviding`     | Generic protocol for context suppliers              |

---

### 2. **Composables Layer** – Concrete reusable specifications

| File / Module            | Purpose                                            |
|--------------------------|----------------------------------------------------|
| `DelaySinceLaunchSpec`   | Checks if X seconds passed since launch           |
| `MaxDisplayCountSpec`    | Checks if show count < N                          |
| `CooldownSpec`           | Checks if enough time passed since last show     |
| `CustomPredicateSpec<T>` | Allows arbitrary closures as specifications       |

---

### 3. **Macro Layer** *(if used)*

| Component       | Purpose                                                  |
|-----------------|-----------------------------------------------------------|
| `@specs(...)`   | Generates composite specs from multiple inner specs       |
| `@AutoContext`  | (future) derives context from environment automatically   |

---

### 4. **Property Wrapper Layer**

| Wrapper                | Purpose                                                   |
|------------------------|------------------------------------------------------------|
| `@Satisfies`           | Applies spec with auto context provider (via protocol)     |
| `@Satisfies(context:)` | Alternative manual context override API                    |

---

### 5. **Specification Definitions Layer**

| Structure                  | Purpose                                               |
|---------------------------|--------------------------------------------------------|
| `PromoBannerSpec`         | Composite spec describing banner display rules         |
| `AutoContextSpecification`| Protocol for specs that include a context provider     |

---

### 6. **Context Layer** – Context generation and configuration

| Component                     | Purpose                                              |
|------------------------------|------------------------------------------------------|
| `PromoContext`               | Contains the data needed to evaluate display rules   |
| `DefaultPromoContextProvider` | Supplies context from runtime state                 |
| `MockPromoContextProvider`     | Used in unit tests                                  |

---

### 7. **Application Integration Layer**

Integration in app code (SwiftUI / UIKit):

```swift
@Satisfies(using: PromoBannerSpec.self)
var shouldShowPromo: Bool
```

---

### 8. **Tests Layer**

| Tests                       | What they cover                                      |
|-----------------------------|------------------------------------------------------|
| `*SpecTests`               | Unit tests for individual specs                      |
| `CompositeSpecTests`       | Logical operator correctness                         |
| `PromoBannerSpecTests`     | Composite rule tests                                 |
| `SatisfiesWrapperTests`    | Wrapper behavior under real conditions               |
| `MockProviderTests`        | Context replacement for test isolation               |

---

## 📦 Suggested SwiftPM Folder Structure

```
Sources/
├── SpecificationKit/
│   ├── Core/
│   │   ├── Specification.swift
│   │   ├── AnySpecification.swift
│   │   ├── SpecificationOperators.swift
│   │   ├── ContextProviding.swift
│   ├── Specs/
│   │   ├── DelaySinceLaunchSpec.swift
│   │   ├── MaxDisplayCountSpec.swift
│   │   ├── CooldownSpec.swift
│   ├── Providers/
│   │   ├── PromoContext.swift
│   │   ├── DefaultPromoContextProvider.swift
│   ├── Wrappers/
│   │   ├── Satisfies.swift
│   ├── Definitions/
│   │   ├── PromoBannerSpec.swift
│   └── Macros/ (optional)
│       ├── SpecsMacro.swift
│       ├── MacroPlugin.swift

Tests/
├── SpecificationKitTests/
│   ├── DelaySinceLaunchSpecTests.swift
│   ├── PromoBannerSpecTests.swift
│   ├── SatisfiesWrapperTests.swift
│   ├── ...
```

---

## ✅ Summary

- **Core** — foundation: protocols and combinators
- **Specs** — reusable individual business rules
- **Definitions** — composite logic (e.g. `PromoBannerSpec`)
- **Wrappers** — `@Satisfies` logic
- **Providers** — context construction and injection
- **Macros** — declarative sugar (optional)
- **Tests** — isolation and integration guarantees

