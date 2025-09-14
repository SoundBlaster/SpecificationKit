# WeightedSpec

A decision specification that performs weighted random selection among multiple specifications.

## Overview

`WeightedSpec` implements probability-based decision making where each specification has an associated weight that determines its selection probability. This is essential for A/B testing, feature rollouts, load balancing, and any scenario requiring probabilistic outcomes.

The specification uses weighted random sampling where each candidate has a probability proportional to its weight:
- Total weight: W = Σ(w_i) for all weights w_i
- Probability of selection: P(i) = w_i / W

## Basic Usage

### A/B Test Distribution

Create a weighted specification for distributing users across different test variants:

```swift
import SpecificationKit

let abTestSpec = WeightedSpec([
    (FeatureFlagSpec(flag: "variant_a"), 0.5, "variant_a"),
    (FeatureFlagSpec(flag: "variant_b"), 0.3, "variant_b"), 
    (FeatureFlagSpec(flag: "control"), 0.2, "control")
])

@Maybe(using: abTestSpec)
var experimentVariant: String?

// Use the result
switch experimentVariant {
case "variant_a":
    showVariantA()
case "variant_b": 
    showVariantB()
case "control":
    showControl()
default:
    showDefault()
}
```

### Load Balancing

Distribute traffic across servers based on their capacity:

```swift
let loadBalancerSpec = WeightedSpec([
    (ServerHealthSpec(server: "server1"), 10.0, "server1"),
    (ServerHealthSpec(server: "server2"), 8.0, "server2"),
    (ServerHealthSpec(server: "server3"), 5.0, "server3")
])

@Maybe(using: loadBalancerSpec)
var selectedServer: String?
```

### With Fallback

Ensure a result is always returned by providing a fallback:

```swift
let discountSpec = WeightedSpec.withFallback([
    (PremiumMemberSpec(), 0.8, 0.25),
    (LoyalCustomerSpec(), 0.6, 0.15),
    (FirstTimeUserSpec(), 0.4, 0.10)
], fallback: 0.05)

@Decides(using: discountSpec, or: 0.0)
var discountRate: Double
```

## Statistical Analysis

### Probability Distribution

Access the normalized probability distribution for all candidates:

```swift
let spec = WeightedSpec([
    (AlwaysTrueSpec<Context>(), 0.7, "A"),
    (AlwaysTrueSpec<Context>(), 0.3, "B")
])

let distribution = spec.probabilityDistribution
// [0.7, 0.3]
```

### Expected Value and Variance

For numeric results, calculate statistical measures:

```swift
let numericSpec = WeightedSpec([
    (AlwaysTrueSpec<Context>(), 0.6, 10.0),
    (AlwaysTrueSpec<Context>(), 0.4, 20.0)
])

let expectedValue = numericSpec.expectedValue() // 14.0
let variance = numericSpec.variance() // 24.0
let standardDeviation = numericSpec.standardDeviation() // ~4.9
```

## Advanced Features

### Typed Specifications

Create weighted specs with strongly-typed specifications:

```swift
let typedSpec = WeightedSpec([
    (PremiumUserSpec(), 0.8, "premium_feature"),
    (BetaUserSpec(), 0.2, "beta_feature")
])
```

### Mathematical Validation

WeightedSpec validates inputs and provides detailed error information:

```swift
// This will trigger a precondition failure
let invalidSpec = WeightedSpec([
    (AlwaysTrueSpec<Context>(), 0.0, "invalid"), // Zero weight not allowed
    (AlwaysTrueSpec<Context>(), -0.5, "negative") // Negative weight not allowed
])
```

## Best Practices

### 1. Weight Selection

Choose weights that reflect the desired probability distribution:

```swift
// 50% A, 30% B, 20% C
let balanced = WeightedSpec([
    (specA, 0.5, "A"),
    (specB, 0.3, "B"),
    (specC, 0.2, "C")
])

// Equivalent using different weight values
let equivalent = WeightedSpec([
    (specA, 50, "A"),
    (specB, 30, "B"), 
    (specC, 20, "C")
])
```

### 2. Testing Statistical Distribution

Validate that your weighted distribution behaves as expected:

```swift
func testDistribution() {
    let spec = WeightedSpec([
        (AlwaysTrueSpec<TestContext>(), 0.7, "A"),
        (AlwaysTrueSpec<TestContext>(), 0.3, "B")
    ])
    
    let iterations = 10000
    let results = (1...iterations).compactMap { _ in 
        spec.decide(TestContext())
    }
    
    let aCount = results.filter { $0 == "A" }.count
    let ratio = Double(aCount) / Double(results.count)
    
    // Should be approximately 0.7 ± statistical margin
    XCTAssertEqual(ratio, 0.7, accuracy: 0.05)
}
```

### 3. Graceful Fallbacks

Always provide meaningful fallbacks for production use:

```swift
let productionSpec = WeightedSpec.withFallback([
    (NewFeatureSpec(), 0.1, "new_feature"),
    (BetaFeatureSpec(), 0.05, "beta_feature")
], fallback: "stable_feature")
```

## Implementation Details

### Performance Characteristics

- **Selection Time**: O(n) where n is the number of candidates
- **Memory Usage**: O(n) for storing candidates
- **Thread Safety**: Each instance is thread-safe for concurrent evaluation

### Randomization

WeightedSpec uses Swift's `Double.random(in:)` for selection, which provides cryptographically secure randomization suitable for production use.

### Edge Case Handling

- **Empty Candidates**: Triggers precondition failure
- **Zero/Negative Weights**: Triggers precondition failure  
- **All Specifications Unsatisfied**: Returns `nil`
- **Floating Point Precision**: Handles edge cases in cumulative weight calculation

## See Also

- ``DecisionSpec`` - The protocol that WeightedSpec implements
- ``FirstMatchSpec`` - For priority-based (non-probabilistic) selection
- ``ComparativeSpec`` - For threshold-based decisions
- ``ThresholdSpec`` - For adaptive threshold evaluation