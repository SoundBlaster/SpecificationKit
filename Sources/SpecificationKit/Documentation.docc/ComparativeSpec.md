# ComparativeSpec

A specification that performs comparisons against baseline values or other specifications.

## Overview

`ComparativeSpec` enables decision making based on relative comparisons rather than absolute values. This is essential for adaptive systems, performance monitoring, competitive analysis, and any scenario where decisions depend on relative positioning or comparison outcomes.

The specification supports various comparison types including fixed values, ranges, and custom comparison logic, making it versatile for different evaluation scenarios.

## Basic Usage

### Performance Comparison

Compare current performance against a baseline:

```swift
import SpecificationKit

let performanceSpec = ComparativeSpec(
    keyPath: \.currentResponseTime,
    comparison: .greaterThan(100.0) // Milliseconds
)

@Satisfies(using: performanceSpec)
var isPerformingPoorly: Bool

if isPerformingPoorly {
    triggerPerformanceAlert()
}
```

### Value Extraction with Closures

Use custom logic to extract values for comparison:

```swift
let loadSpec = ComparativeSpec(
    extracting: { context in 
        context.cpuUsage * 0.6 + context.memoryUsage * 0.4 // Weighted load
    },
    comparison: .lessThan(80.0)
)

@Satisfies(using: loadSpec)
var isLoadAcceptable: Bool
```

### Range Validation

Check if values fall within acceptable ranges:

```swift
let temperatureSpec = ComparativeSpec(
    keyPath: \.currentTemperature,
    comparison: .between(18.0, 24.0) // Celsius
)

@Satisfies(using: temperatureSpec)
var isTemperatureOptimal: Bool
```

## Comparison Types

### Fixed Value Comparisons

Compare against static thresholds:

```swift
// Greater than comparison
let highPerformanceSpec = ComparativeSpec(
    keyPath: \.throughput,
    comparison: .greaterThan(1000.0)
)

// Less than comparison
let lowLatencySpec = ComparativeSpec(
    keyPath: \.latency,
    comparison: .lessThan(50.0)
)

// Equality with tolerance
let preciseSpec = ComparativeSpec(
    keyPath: \.measurement,
    comparison: .equalTo(42.0),
    tolerance: 0.1
)
```

### Range Comparisons

Validate values within specific bounds:

```swift
let validRangeSpec = ComparativeSpec(
    keyPath: \.score,
    comparison: .between(0.0, 100.0)
)

// Equivalent to checking score >= 0.0 && score <= 100.0
@Satisfies(using: validRangeSpec)
var isScoreValid: Bool
```

### Custom Comparison Logic

Implement complex comparison scenarios:

```swift
let advancedSpec = ComparativeSpec(
    keyPath: \.metrics,
    comparison: .custom { value, context in
        // Complex business logic
        let baseline = context.calculateDynamicBaseline()
        let tolerance = context.getToleranceLevel()
        
        return abs(value - baseline) <= tolerance &&
               value > context.minimumAcceptableValue
    }
)
```

## Advanced Features

### Tolerance-Based Comparisons

Handle floating-point precision issues with tolerance:

```swift
let tolerantSpec = ComparativeSpec(
    keyPath: \.calculatedValue,
    comparison: .equalTo(expectedValue),
    tolerance: 0.001 // Allow small variations
)

// For example: 42.0001 will be considered equal to 42.0 with tolerance 0.001
```

### Convenience Extensions for Arithmetic Types

For types that support arithmetic operations:

```swift
// Within tolerance range
let toleranceSpec = ComparativeSpec.withinTolerance(
    of: targetValue,
    tolerance: 5.0,
    keyPath: \.measurement
)
```

### Floating-Point Approximate Equality

Handle relative errors in floating-point comparisons:

```swift
let approximateSpec = ComparativeSpec.approximatelyEqual(
    to: 100.0,
    relativeError: 0.05, // 5% tolerance
    keyPath: \.percentage
)

// 95.0 to 105.0 would be considered approximately equal to 100.0
```

## Integration Examples

### With SwiftUI

Create reactive UI that responds to comparative evaluations:

```swift
import SwiftUI

struct SystemMonitor: View {
    @State private var systemMetrics = SystemMetrics()
    
    var cpuStatus: String {
        let spec = ComparativeSpec(
            keyPath: \.cpuUsage,
            comparison: .between(0.0, 70.0)
        )
        return spec.isSatisfiedBy(systemMetrics) ? "Normal" : "High"
    }
    
    var body: some View {
        VStack {
            Text("CPU Usage: \(cpuStatus)")
                .foregroundColor(cpuStatus == "Normal" ? .green : .red)
            
            ProgressView(value: systemMetrics.cpuUsage, in: 0...100)
        }
    }
}
```

### With Combine

Monitor comparative conditions over time:

```swift
import Combine

class PerformanceMonitor: ObservableObject {
    @Published var alertStatus: String = "OK"
    
    private let metricsSpec = ComparativeSpec(
        keyPath: \.performanceScore,
        comparison: .lessThan(threshold)
    )
    
    private var cancellables = Set<AnyCancellable>()
    
    func startMonitoring() {
        metricsPublisher
            .map { [weak self] metrics in
                self?.metricsSpec.isSatisfiedBy(metrics) == false ? "ALERT" : "OK"
            }
            .assign(to: \.alertStatus, on: self)
            .store(in: &cancellables)
    }
}
```

### Complex Multi-Criteria Scenarios

Combine multiple comparative specifications for sophisticated logic:

```swift
let systemHealthSpec = ComparativeSpec(
    keyPath: \.cpuUsage,
    comparison: .lessThan(80.0)
).and(
    ComparativeSpec(
        keyPath: \.memoryUsage,
        comparison: .lessThan(90.0)
    )
).and(
    ComparativeSpec(
        keyPath: \.diskUsage,
        comparison: .lessThan(85.0)
    )
)

@Satisfies(using: systemHealthSpec)
var isSystemHealthy: Bool
```

## Best Practices

### 1. Choose Appropriate Comparison Types

Select the most suitable comparison for your use case:

```swift
// For exact matches (be careful with floating-point)
let exactSpec = ComparativeSpec(
    keyPath: \.id,
    comparison: .equalTo(expectedId)
)

// For ranges with clear bounds
let boundsSpec = ComparativeSpec(
    keyPath: \.value,
    comparison: .between(minValue, maxValue)
)

// For threshold-based decisions
let thresholdSpec = ComparativeSpec(
    keyPath: \.metric,
    comparison: .greaterThan(threshold)
)
```

### 2. Handle Edge Cases

Account for potential edge cases in your comparisons:

```swift
let robustSpec = ComparativeSpec(
    extracting: { context in
        // Ensure valid range before comparison
        guard context.isValid else { return nil }
        return context.normalizedValue
    },
    comparison: .custom { value, context in
        // Handle special cases
        guard let value = value else { return false }
        
        // Check for special conditions
        if context.isSpecialMode {
            return value > context.specialThreshold
        }
        
        return value > context.normalThreshold
    }
)
```

### 3. Use Tolerance for Floating-Point Comparisons

Always use appropriate tolerance for floating-point equality:

```swift
// BAD: Direct equality comparison
let badSpec = ComparativeSpec(
    keyPath: \.calculatedValue,
    comparison: .equalTo(42.0)
)

// GOOD: Equality with tolerance
let goodSpec = ComparativeSpec(
    keyPath: \.calculatedValue,
    comparison: .equalTo(42.0),
    tolerance: 0.001
)
```

### 4. Combine with Other Specifications

Use comparative specs as building blocks for complex logic:

```swift
let eligibilitySpec = ComparativeSpec(
    keyPath: \.age,
    comparison: .greaterThan(18)
).and(
    ComparativeSpec(
        keyPath: \.creditScore,
        comparison: .between(600, 850)
    )
).and(
    ComparativeSpec(
        keyPath: \.income,
        comparison: .greaterThan(minimumIncome)
    )
)
```

## Performance Characteristics

- **Evaluation Time**: O(1) for basic comparisons, O(f) where f is the complexity of custom comparison functions
- **Memory Usage**: O(1) for the specification itself
- **Thread Safety**: Specifications are thread-safe for concurrent evaluation

## Common Patterns

### Validation Specifications

```swift
struct ValidationSpecs {
    static let emailLength = ComparativeSpec(
        extracting: \.email.count,
        comparison: .between(5, 100)
    )
    
    static let passwordStrength = ComparativeSpec(
        extracting: calculatePasswordStrength,
        comparison: .greaterThan(3)
    )
    
    static let ageRequirement = ComparativeSpec(
        keyPath: \.age,
        comparison: .greaterThan(13)
    )
}
```

### Performance Monitoring

```swift
struct PerformanceSpecs {
    static let responseTime = ComparativeSpec(
        keyPath: \.responseTime,
        comparison: .lessThan(200.0) // milliseconds
    )
    
    static let throughput = ComparativeSpec(
        keyPath: \.requestsPerSecond,
        comparison: .greaterThan(100.0)
    )
    
    static let errorRate = ComparativeSpec(
        extracting: { $0.errors / max($0.totalRequests, 1) },
        comparison: .lessThan(0.01) // Less than 1% error rate
    )
}
```

## See Also

- ``Specification`` - The base protocol for all specifications
- ``ThresholdSpec`` - For dynamic threshold-based comparisons
- ``HistoricalSpec`` - For historical baseline comparisons  
- ``WeightedSpec`` - For probabilistic selection
- ``DecisionSpec`` - For decision-oriented specifications