# ⚙️ AUTOCONTEXT.md – AutoContext Macro in SpecificationKit

This document outlines the purpose, design, and behavior of the proposed `@AutoContext` macro in the SpecificationKit library. It allows developers to create specification types that automatically include a context provider.

---

## 🎯 Purpose

`@AutoContext` eliminates the need to manually declare and wire a `contextProvider` in every specification.

Instead of writing:

```swift
struct MySpec: AutoContextSpecification {
    static let contextProvider = DefaultContextProvider()
    init() { ... }
    func isSatisfiedBy(_ ctx: EvaluationContext) -> Bool { ... }
}
```

You can simply write:

```swift
@AutoContext
struct MySpec: Specification {
    func isSatisfiedBy(_ ctx: EvaluationContext) -> Bool { ... }
}
```

---

## 🧩 What `@AutoContext` Does

| Feature                          | Description                                      |
|----------------------------------|--------------------------------------------------|
| Adds `static var contextProvider`| Default provider is auto-injected               |
| Synthesizes `init()`             | If not explicitly defined                       |
| Enables use in `@Satisfies`      | Without needing a manual context                |
| Future extensibility             | Could support DI, `@Environment`, etc.          |

---

## ✅ Usage

```swift
@AutoContext
struct IsNightTimeSpec: Specification {
    func isSatisfiedBy(_ ctx: EvaluationContext) -> Bool {
        ctx.localTime.hour >= 22 || ctx.localTime.hour < 6
    }
}

@Satisfies(using: IsNightTimeSpec.self)
var isNightMode: Bool
```

---

## 🔐 Type Safety

- Ensures `Context` matches provider’s context
- Fails at compile-time if applied incorrectly
- Can restrict to `Specification<Context == EvaluationContext>`

---

## 💡 Future Extensions

**Implementation Status:** ✅ **Infrastructure Complete** (as of 2025-11-16)

The macro now includes parsing infrastructure for future enhancement flags. These flags are recognized and parsed but emit informative diagnostics indicating they are not yet fully implemented:

| Syntax                            | Status | Behavior                                         |
|----------------------------------|--------|--------------------------------------------------|
| `@AutoContext(DefaultContextProvider.self)` | 🔄 Planned | Override provider inline (emits warning)                  |
| `@AutoContext(environment)`       | 🔄 Planned | Use SwiftUI Environment (emits warning)                         |
| `@AutoContext(infer)`             | 🔄 Planned | Infer provider from generic context (emits warning)             |

### Current Behavior

When using future extension flags, the macro will:
1. **Parse** the argument successfully
2. **Emit** an informative warning diagnostic explaining the feature is planned but not yet implemented
3. **Generate** the default implementation using `DefaultContextProvider.shared`
4. **Compile** successfully with the warning

This allows code to be written using the future syntax and provides a smooth migration path when these features are fully implemented in future Swift toolchain versions.

---

## 🧪 With Macros and `@specs(...)`

Combining `@AutoContext` with `@specs(...)`:

```swift
@AutoContext
@specs(MaxCountSpec(limit: 3), CooldownIntervalSpec(interval: .days(7)))
struct RetrySpec: Specification { }
```

No need to manually implement anything — macro generates it all.

---

## 🧭 Implementation Notes

- This is an attached macro on `struct`, `class`, or `enum`
- Validates conformance to `Specification`
- Injects a provider and optional `init()`
- **Argument Parsing:** The macro parses optional arguments and provides appropriate diagnostics
- **Future-Ready:** Infrastructure exists for `environment`, `infer`, and custom provider types
- **Backward Compatible:** Plain `@AutoContext` continues to work as before

### Technical Implementation Details

**File:** `Sources/SpecificationKitMacros/AutoContextMacro.swift`

The macro implementation includes:
- **Argument Parser:** Recognizes identifier-based flags (`environment`, `infer`) and type expressions (`CustomProvider.self`)
- **Diagnostic System:** Emits warnings for planned features and errors for invalid syntax
- **Extensible Architecture:** Enum-based argument classification ready for future implementation

**Test Coverage:** `Tests/SpecificationKitTests/AutoContextMacroComprehensiveTests.swift`
- Basic expansion tests for struct, class, and enum
- Integration tests with real specifications
- Future flag parsing tests with diagnostic validation
- Edge cases and error scenarios

---

## ✅ Summary

`@AutoContext` transforms a plain spec into a **self-sufficient, auto-configured unit** that integrates seamlessly with the `@Satisfies` property wrapper. It minimizes boilerplate, improves readability, and supports future extension toward a fully declarative DSL for specification-based rule logic.

**Latest Update (2025-11-16):** Added infrastructure for parsing future enhancement flags (`environment`, `infer`, custom provider types). These flags are recognized and provide informative diagnostics, creating a smooth evolution path as Swift's macro capabilities expand.
