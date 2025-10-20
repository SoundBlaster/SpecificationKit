# ``SpecificationKit``

A powerful Swift framework implementing the Specification Pattern for clean, composable, and testable business logic.

## Overview

SpecificationKit empowers you to build maintainable applications by encapsulating business rules in small, focused, and composable specifications. With first-class SwiftUI integration, reactive property wrappers, and advanced specification types, it's the definitive solution for implementing the Specification Pattern in Swift.

### Key Features

- **🧩 Composable Logic**: Build complex rules from simple specifications using `.and()`, `.or()`, and `.not()`
- **⚡ Reactive UI**: Declarative property wrappers with SwiftUI integration: ``@Satisfies``, ``@Decides``, ``@Maybe``, ``@ObservedSatisfies``
- **🎯 Advanced Patterns**: Sophisticated specifications for real-world scenarios: ``WeightedSpec``, ``HistoricalSpec``, ``ComparativeSpec``, ``ThresholdSpec``
- **🚀 Developer Experience**: Swift macros (`@specs`, `@AutoContext`) for code generation and reduced boilerplate
- **🔧 Flexible Context**: Powerful context providers for dependency injection and testing
- **⚙️ Production Ready**: Thread-safe, performant, with comprehensive testing utilities

## Quick Start

### Basic Specification
```swift
import SpecificationKit

// Define a simple specification
struct PremiumUserSpec: Specification {
    func isSatisfiedBy(_ user: User) -> Bool {
        user.subscriptionTier == .premium && user.isActive
    }
}

// Use with property wrapper for clean, declarative code
@Satisfies(using: PremiumUserSpec())
var isPremiumUser: Bool

if isPremiumUser {
    showPremiumFeatures()
}
```

### Composable Business Logic
```swift
// Combine specifications with logical operators
let eligibilitySpec = PremiumUserSpec()
    .and(MaxCountSpec(counterKey: "feature_used", maximumCount: 10))
    .and(TimeSinceEventSpec(eventKey: "last_usage", minimumInterval: 3600))

@Satisfies(using: eligibilitySpec)
var canUseFeature: Bool
```

### SwiftUI Integration
```swift
struct FeatureView: View {
    @ObservedSatisfies(using: PremiumUserSpec())
    var isPremiumUser: Bool

    var body: some View {
        VStack {
            if isPremiumUser {
                PremiumContent()
            } else {
                UpgradePrompt()
            }
        }
        .onChange(of: isPremiumUser) { enabled in
            analyticsTracker.track("premium_status_changed", enabled: enabled)
        }
    }
}
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

## Tutorials

Start your journey with SpecificationKit through our comprehensive tutorials:

- <doc:GettingStarted> - Learn the fundamentals of the Specification Pattern and create your first specifications
- <doc:AdvancedPatterns> - Master sophisticated patterns for real-world applications

## Getting Started

Whether you're new to the Specification Pattern or upgrading from a previous version, SpecificationKit makes it easy to implement clean, maintainable business logic.

### Installation

Add SpecificationKit to your project using Swift Package Manager:

```swift
dependencies: [
    .package(url: "https://github.com/SoundBlaster/SpecificationKit.git", from: "3.0.0")
]
```

### Your First Specification

1. **Define the rule**: Create a struct conforming to ``Specification``
2. **Implement logic**: Add your business logic in `isSatisfiedBy(_:)`
3. **Use declaratively**: Apply with property wrappers for clean code

```swift
// 1. Define the specification
struct ActiveSubscriptionSpec: Specification {
    func isSatisfiedBy(_ user: User) -> Bool {
        return user.subscription?.isActive == true
    }
}

// 2. Use in your app
@Satisfies(using: ActiveSubscriptionSpec())
var hasActiveSubscription: Bool

// 3. Build conditional logic
if hasActiveSubscription {
    showPremiumContent()
} else {
    showSubscriptionOffer()
}
```

### Composition and Reusability

Combine simple specifications to create complex business rules:

```swift
let premiumAccess = ActiveSubscriptionSpec()
    .and(UserVerificationSpec())
    .and(RegionAvailabilitySpec(region: .northAmerica))

@Satisfies(using: premiumAccess)
var canAccessPremiumFeatures: Bool
```

## Advanced Specifications (v3.0.0)

SpecificationKit v3.0.0 introduces sophisticated specification types for complex real-world scenarios:

### Probabilistic Decisions
Perfect for A/B testing, feature rollouts, and load balancing.

<doc:WeightedSpec>

```swift
let abTest = WeightedSpec([
    (VariantASpec(), 0.5, "variant_a"),
    (VariantBSpec(), 0.3, "variant_b"),
    (ControlSpec(), 0.2, "control")
])

@Maybe(using: abTest)
var experimentVariant: String?
```

### Time-Series Analysis
Analyze trends and patterns from historical data.

<doc:HistoricalSpec>

```swift
let performanceSpec = HistoricalSpec(
    provider: MetricsProvider(),
    window: .lastN(30),
    aggregation: .percentile(0.95)
)

@Maybe(using: performanceSpec)
var p95ResponseTime: Double?
```

### Relative Validation
Compare values against baselines and ranges.

<doc:ComparativeSpec>

```swift
let temperatureSpec = ComparativeSpec(
    keyPath: \.temperature,
    comparison: .between(18.0, 24.0),
    tolerance: 0.5
)

@Satisfies(using: temperatureSpec)
var isComfortableTemperature: Bool
```

### Adaptive Thresholds
Dynamic thresholds that adapt to changing conditions.

<doc:ThresholdSpec>

```swift
let alertSpec = ThresholdSpec(
    keyPath: \.cpuUsage,
    threshold: .adaptive { context in
        context.systemLoad > 0.8 ? 0.7 : 0.9
    },
    operator: .greaterThan
)

@Satisfies(using: alertSpec)
var shouldTriggerAlert: Bool
```

## Topics

### Learning SpecificationKit

- <doc:GettingStarted>
- <doc:AdvancedPatterns>

### Core Architecture

- ``Specification``
- ``AnySpecification``
- ``DecisionSpec``
- ``AsyncSpecification``

### Property Wrappers

#### Basic Wrappers
- ``Satisfies``
- ``Decides``
- ``Maybe``
- ``AsyncSatisfies``

#### Reactive Wrappers
- ``ObservedSatisfies``
- ``ObservedDecides``
- ``ObservedMaybe``

#### Performance Wrappers
- ``CachedSatisfies``
- ``ConditionalSatisfies``

#### Reactive Integration
- <doc:ReactiveWrappers>

### Built-in Specifications

#### Core Specifications
- ``MaxCountSpec``
- ``TimeSinceEventSpec``
- ``CooldownIntervalSpec``
- ``PredicateSpec``
- ``FirstMatchSpec``

#### Date and Time
- ``DateRangeSpec``
- ``DateComparisonSpec``

#### Context-Based
- ``FeatureFlagSpec``
- ``UserSegmentSpec``
- ``SubscriptionStatusSpec``

### Advanced Specifications (v3.0.0)

#### Probabilistic & Analytics
- <doc:WeightedSpec>
- <doc:HistoricalSpec>

#### Validation & Monitoring
- <doc:ComparativeSpec>
- <doc:ThresholdSpec>

### Context System

#### Core Providers
- ``ContextProviding``
- ``DefaultContextProvider``
- ``EnvironmentContextProvider``
- ``MockContextProvider``

#### Advanced Providers
- ``NetworkContextProvider``
- ``PersistentContextProvider``
- ``CompositeContextProvider``
- ``AnyContextProvider``

#### Platform Integration
- <doc:PlatformContextProviders>
- <doc:MacOSSystemContextProvider>
- <doc:AppleTVContextProvider>

### Code Generation

- ``specs(_:)``
- ``AutoContext()``

### Testing & Development

#### Testing Utilities
- <doc:MockSpecificationBuilder>
- ``MockContextProvider``

#### Debugging Tools
- <doc:SpecificationTracer>

#### Performance Analysis
- Performance profiling tools
