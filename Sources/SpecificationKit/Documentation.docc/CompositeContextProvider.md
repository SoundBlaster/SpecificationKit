# ``SpecificationKit/CompositeContextProvider``

Compose multiple context providers and merge their values into a single ``EvaluationContext``.

## Overview

``CompositeContextProvider`` lets you unify several context sources into one snapshot. This is useful when your application state comes from different subsystems (e.g., defaults, environment, feature flags) and you want a single provider for specification evaluation.

- Deterministic merge strategies
- Order-sensitive composition
- UI-agnostic and platform-neutral

### Merge Strategies

- ``CompositeContextProvider/MergeStrategy-swift.enum/preferFirst``: Earlier providers win on conflicts; later providers only fill missing keys.
- ``CompositeContextProvider/MergeStrategy-swift.enum/preferLast``: Later providers override earlier providers on conflicts.
- ``CompositeContextProvider/MergeStrategy-swift.enum/custom(_:)``: Supply a closure to merge an ordered array of contexts.

Segments are unioned across providers in built-in strategies. The `launchDate` follows the precedence of the chosen strategy.

## Topics

### Creating a Composite Provider

- ``CompositeContextProvider/init(providers:strategy:)``

### Merge Strategy

- ``CompositeContextProvider/MergeStrategy``

## Examples

### Prefer Last (override) Example

```swift
let base = GenericContextProvider {
    EvaluationContext(
        flags: ["promo": false],
        counters: ["launch": 1],
        userData: ["k": "v1"],
        segments: ["beta"]
    )
}

let overrides = GenericContextProvider {
    EvaluationContext(
        flags: ["promo": true],
        counters: ["launch": 2],
        userData: ["k": "v2", "only": 2],
        segments: ["vip"]
    )
}

let provider = CompositeContextProvider(
    providers: [base, overrides],
    strategy: .preferLast
)

let ctx = provider.currentContext()
// ctx.flag("promo") == true, counter("launch") == 2, userData["k"] == "v2"
// userData["only"] == 2, segments == ["beta", "vip"]
```

### Prefer First (preserve) Example

```swift
let p1 = GenericContextProvider { EvaluationContext(flags: ["f": false]) }
let p2 = GenericContextProvider { EvaluationContext(flags: ["f": true]) }

let provider = CompositeContextProvider(providers: [p1, p2], strategy: .preferFirst)
let ctx = provider.currentContext()
// ctx.flag("f") == false
```

### Custom Merge Example

```swift
let providers: [AnyContextProvider<EvaluationContext>] = [
    AnyContextProvider { EvaluationContext(counters: ["a": 1]) },
    AnyContextProvider { EvaluationContext(counters: ["a": 10, "b": 2]) }
]

let provider = CompositeContextProvider(
    providers: providers,
    strategy: .custom { contexts in
        // Example: sum counters across providers
        var counters: [String: Int] = [:]
        for ctx in contexts {
            counters.merge(ctx.counters, uniquingKeysWith: +)
        }
        return EvaluationContext(counters: counters)
    }
)

let ctx = provider.currentContext()
// ctx.counter("a") == 11, ctx.counter("b") == 2
```

## See Also

- ``AnyContextProvider`` – type erasure for `ContextProviding`
- ``DefaultContextProvider`` – app-wide mutable store with Combine updates
- ``EnvironmentContextProvider`` – bridges environment/state into `EvaluationContext`

