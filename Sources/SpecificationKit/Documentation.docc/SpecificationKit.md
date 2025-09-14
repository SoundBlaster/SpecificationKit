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

## Advanced Specs Overview (v3.0.0)

The v3.0.0 release adds four advanced, production-ready specification types designed for probabilistic selection, time-series analysis, relative comparisons, and dynamic thresholds. See their dedicated pages for full guides and APIs.

- <doc:WeightedSpec>: probability-based selection among candidates; ideal for A/B testing, rollouts, and load balancing.
- <doc:HistoricalSpec>: time-series aggregation over windows; ideal for trends, percentiles, and adaptive decisions.
- <doc:ComparativeSpec>: relative comparisons vs. baselines/ranges; ideal for validation and monitoring.
- <doc:ThresholdSpec>: static/adaptive/contextual thresholds; ideal for alerts and feature gating.

### When To Use Which

- Weighted: choose 1 of N outcomes by probability; compute expected value/variance for numeric results.
- Historical: summarize past values over a window (median, percentile, trend) to guide current decisions.
- Comparative: check current value against a fixed/range/custom rule with optional tolerance.
- Threshold: evaluate against dynamic thresholds derived from context or functions.

### Quick Examples

Weighted (A/B/C split):
```swift
let abTest = WeightedSpec([
    (FeatureFlagSpec(flag: "variant_a"), 0.5, "A"),
    (FeatureFlagSpec(flag: "variant_b"), 0.3, "B"),
    (FeatureFlagSpec(flag: "control"), 0.2, "C")
])
@Maybe(using: abTest) var variant: String?
```

Historical (median of last 30):
```swift
let perf = HistoricalSpec(
    provider: MetricsHistoryProvider(),
    window: .lastN(30),
    aggregation: .median
)
@Maybe(using: perf) var medianPerf: Double?
```

Comparative (range check):
```swift
let tempOK = ComparativeSpec(
    keyPath: \.currentTemperature,
    comparison: .between(18.0, 24.0)
)
@Satisfies(using: tempOK) var isComfortable: Bool
```

Threshold (adaptive baseline):
```swift
let alert = ThresholdSpec(
    keyPath: \.responseTime,
    threshold: .adaptive { getCurrentBaseline() },
    operator: .greaterThan
)
@Satisfies(using: alert) var shouldAlert: Bool
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
