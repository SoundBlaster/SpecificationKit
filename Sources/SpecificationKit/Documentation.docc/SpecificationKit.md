# ``SpecificationKit``

SpecificationKit is a Swift-first implementation of the Specification pattern.
It helps you encode business rules as composable, reusable, and testable specifications,
with first-class support for SwiftUI, property wrappers, macros, and async/await.

## Overview

- Composable specifications using `.and()`, `.or()`, and `.not()`
- Declarative property wrappers: `@Satisfies`, `@Decides`, `@Maybe`, `@ObservedSatisfies`, `@ObservedMaybe`
- Advanced specifications: `WeightedSpec` (probability-based), `HistoricalSpec` (time-series), `ComparativeSpec` (relative comparisons), `ThresholdSpec` (dynamic thresholds)
- Macros: `@specs` for composite specs and `@AutoContext` for automatic provider injection
- Context providers for dependency injection and testing (Default/Environment/Mock)
- Async support and type-safe generics throughout

## Quick Start

### Basic Specification
```swift
import SpecificationKit

let isEligible = MaxCountSpec(counterKey: "promoShown", maximumCount: 3)

@Satisfies(using: isEligible)
var shouldShowPromo: Bool

if shouldShowPromo {
    showPromoBanner()
}
```

### Macro-Generated Composite Specification
```swift
@specs(
    MaxCountSpec(counterKey: "promoShown", maximumCount: 3),
    TimeSinceEventSpec(eventKey: "lastShown", minimumInterval: 24 * 3600)
)
@AutoContext
struct PromoEligibilitySpec: Specification {
    typealias T = EvaluationContext
}

@Satisfies(using: PromoEligibilitySpec.self)
var isEligibleForPromo: Bool
```

### Decision Making
```swift
@Decides([
    (PremiumUserSpec(), "premium_discount"),
    (FirstTimeUserSpec(), "welcome_discount"),
    (RegularUserSpec(), "standard_discount")
], or: "no_discount")
var discountType: String
```

## Topics

### Reactive Wrappers

- <doc:ReactiveWrappers>

### Core Concepts

- ``Specification``
- ``AnySpecification``
- ``DecisionSpec``
- ``FirstMatchSpec``
- ``ContextProviding``
- ``DefaultContextProvider``

### Built-in Specs

- ``MaxCountSpec``
- ``TimeSinceEventSpec``
- ``CooldownIntervalSpec``
- ``DateRangeSpec``
- ``DateComparisonSpec``
- ``FeatureFlagSpec``
- ``UserSegmentSpec``
- ``SubscriptionStatusSpec``

### Advanced Specs

- <doc:WeightedSpec>
- <doc:HistoricalSpec>
- <doc:ComparativeSpec>
- <doc:ThresholdSpec>

### Macros

- ``specs(_:)``
- ``AutoContext()``
