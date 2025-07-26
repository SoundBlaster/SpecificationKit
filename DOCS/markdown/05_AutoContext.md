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

| Syntax                            | Behavior                                         |
|----------------------------------|--------------------------------------------------|
| `@AutoContext(DefaultContextProvider.self)` | Override provider inline                  |
| `@AutoContext(environment)`       | Use SwiftUI Environment                         |
| `@AutoContext(infer)`             | Infer provider from generic context             |

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

- This is an attached macro on `struct`
- Validates conformance to `Specification`
- Injects a provider and optional `init()`

---

## ✅ Summary

`@AutoContext` transforms a plain spec into a **self-sufficient, auto-configured unit** that integrates seamlessly with the `@Satisfies` property wrapper. It minimizes boilerplate, improves readability, and supports future extension toward a fully declarative DSL for specification-based rule logic.
