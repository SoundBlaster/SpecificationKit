# ThresholdSpec

A specification that evaluates values against dynamic or static thresholds.

## Overview

`ThresholdSpec` provides flexible threshold-based decision making with support for static values, adaptive thresholds, contextual thresholds, and custom threshold logic. This is essential for monitoring systems, alerts, adaptive controls, and any scenario requiring threshold-based decisions.

The specification supports multiple threshold types and comparison operators, making it highly versatile for different monitoring and evaluation scenarios.

## Basic Usage

### Fixed Threshold

Evaluate against a static threshold value:

```swift
import SpecificationKit

let responseTimeSpec = ThresholdSpec(
    keyPath: \.responseTime,
    threshold: .fixed(200.0), // 200ms threshold
    operator: .lessThan
)

@Satisfies(using: responseTimeSpec)
var isResponseTimeAcceptable: Bool

if !isResponseTimeAcceptable {
    triggerPerformanceAlert()
}
```

### Adaptive Threshold

Use dynamically calculated thresholds:

```swift
let adaptiveSpec = ThresholdSpec(
    keyPath: \.currentLoad,
    threshold: .adaptive { 
        getCurrentCapacity() * 0.8 // 80% of current capacity
    },
    operator: .lessThan
)

@Satisfies(using: adaptiveSpec)
var isLoadWithinLimits: Bool
```

### Contextual Threshold

Extract threshold values from the evaluation context:

```swift
let contextualSpec = ThresholdSpec(
    keyPath: \.currentUsage,
    threshold: .contextual(\.maxAllowedUsage),
    operator: .lessThanOrEqual
)

@Satisfies(using: contextualSpec)
var isWithinAllowedLimits: Bool
```

## Threshold Types

### Fixed Thresholds

Static values that never change:

```swift
let staticSpec = ThresholdSpec(
    keyPath: \.temperature,
    threshold: .fixed(75.0), // Fixed temperature limit
    operator: .lessThan
)
```

### Adaptive Thresholds

Calculated at evaluation time:

```swift
let adaptiveSpec = ThresholdSpec(
    keyPath: \.memoryUsage,
    threshold: .adaptive {
        // Calculate based on current system state
        let totalMemory = SystemInfo.totalMemory
        let reservedMemory = SystemInfo.reservedMemory
        return (totalMemory - reservedMemory) * 0.9 // 90% of available
    },
    operator: .lessThan
)
```

### Contextual Thresholds

Extracted from the evaluation context:

```swift
struct UserContext {
    let currentScore: Int
    let personalBest: Int
    let levelRequirement: Int
}

let contextualSpec = ThresholdSpec(
    keyPath: \.currentScore,
    threshold: .contextual(\.levelRequirement),
    operator: .greaterThanOrEqual
)
```

### Custom Threshold Logic

Implement complex threshold calculations:

```swift
let customSpec = ThresholdSpec(
    keyPath: \.complexMetric,
    threshold: .custom { context in
        // Complex calculation based on multiple factors
        let baseThreshold = context.baseValue
        let adjustment = context.environmentalFactor * 0.1
        let seasonality = context.getSeasonalAdjustment()
        
        return baseThreshold + adjustment + seasonality
    },
    operator: .greaterThan
)
```

## Comparison Operators

### Basic Comparisons

```swift
// Greater than
let gtSpec = ThresholdSpec(
    keyPath: \.value,
    threshold: .fixed(100.0),
    operator: .greaterThan
)

// Greater than or equal
let gteSpec = ThresholdSpec(
    keyPath: \.value,
    threshold: .fixed(100.0),
    operator: .greaterThanOrEqual
)

// Less than
let ltSpec = ThresholdSpec(
    keyPath: \.value,
    threshold: .fixed(100.0),
    operator: .lessThan
)

// Less than or equal
let lteSpec = ThresholdSpec(
    keyPath: \.value,
    threshold: .fixed(100.0),
    operator: .lessThanOrEqual
)
```

### Equality with Tolerance

Handle floating-point comparisons with tolerance:

```swift
let equalSpec = ThresholdSpec(
    keyPath: \.measurement,
    threshold: .fixed(42.0),
    operator: .equal,
    tolerance: 0.1 // Within ±0.1
)

let notEqualSpec = ThresholdSpec(
    keyPath: \.measurement,
    threshold: .fixed(42.0),
    operator: .notEqual,
    tolerance: 0.1
)
```

## Convenience Methods

### Exceeds

Check if a value exceeds a threshold:

```swift
let exceedsSpec = ThresholdSpec.exceeds(
    keyPath: \.cpuUsage,
    value: 80.0
)

// Equivalent to:
// ThresholdSpec(keyPath: \.cpuUsage, threshold: .fixed(80.0), operator: .greaterThan)
```

### Below

Check if a value is below a threshold:

```swift
let belowSpec = ThresholdSpec.below(
    keyPath: \.latency,
    value: 100.0
)

// Equivalent to:
// ThresholdSpec(keyPath: \.latency, threshold: .fixed(100.0), operator: .lessThan)
```

### Adaptive

Create adaptive threshold specifications:

```swift
let adaptiveSpec = ThresholdSpec.adaptive(
    keyPath: \.load,
    threshold: { calculateDynamicThreshold() }
)
```

## Integration Examples

### System Monitoring

Create a comprehensive monitoring system:

```swift
import SwiftUI

struct SystemMonitorView: View {
    @State private var systemMetrics = SystemMetrics()
    
    private let cpuThresholdSpec = ThresholdSpec(
        keyPath: \.cpuUsage,
        threshold: .fixed(80.0),
        operator: .lessThan
    )
    
    private let memoryThresholdSpec = ThresholdSpec(
        keyPath: \.memoryUsage,
        threshold: .contextual(\.memoryLimit),
        operator: .lessThan
    )
    
    var systemStatus: String {
        let cpuOK = cpuThresholdSpec.isSatisfiedBy(systemMetrics)
        let memoryOK = memoryThresholdSpec.isSatisfiedBy(systemMetrics)
        
        return cpuOK && memoryOK ? "Healthy" : "Warning"
    }
    
    var body: some View {
        VStack {
            Text("System Status: \(systemStatus)")
                .foregroundColor(systemStatus == "Healthy" ? .green : .orange)
            
            Text("CPU: \(systemMetrics.cpuUsage, specifier: "%.1f")%")
            Text("Memory: \(systemMetrics.memoryUsage, specifier: "%.1f")MB")
        }
    }
}
```

### Alert System

Implement threshold-based alerting:

```swift
import Combine

class AlertSystem: ObservableObject {
    @Published var activeAlerts: [String] = []
    
    private let thresholds: [String: ThresholdSpec<MetricsContext, Double>] = [
        "cpu_high": ThresholdSpec(
            keyPath: \.cpuUsage,
            threshold: .adaptive { Self.getCPUThreshold() },
            operator: .greaterThan
        ),
        "memory_low": ThresholdSpec(
            keyPath: \.availableMemory,
            threshold: .fixed(1024.0), // 1GB
            operator: .lessThan
        ),
        "disk_full": ThresholdSpec(
            keyPath: \.diskUsage,
            threshold: .contextual(\.diskCapacity),
            operator: .custom { usage, context in
                usage / context.diskCapacity > 0.9 // 90% full
            }
        )
    ]
    
    func checkAlerts(with metrics: MetricsContext) {
        activeAlerts = thresholds.compactMap { name, spec in
            spec.isSatisfiedBy(metrics) ? nil : name
        }
    }
    
    private static func getCPUThreshold() -> Double {
        // Dynamic threshold based on system load
        return SystemInfo.isHighLoadPeriod ? 90.0 : 75.0
    }
}
```

### Feature Gating

Use thresholds to control feature availability:

```swift
class FeatureController {
    private let userLevelSpec = ThresholdSpec(
        keyPath: \.userLevel,
        threshold: .fixed(5),
        operator: .greaterThanOrEqual
    )
    
    private let subscriptionSpec = ThresholdSpec(
        keyPath: \.subscriptionTier,
        threshold: .contextual(\.requiredTier),
        operator: .greaterThanOrEqual
    )
    
    @Satisfies(using: userLevelSpec.and(subscriptionSpec))
    var canAccessPremiumFeature: Bool
    
    func evaluateAccess(for user: User, feature: Feature) -> Bool {
        let context = FeatureContext(
            userLevel: user.level,
            subscriptionTier: user.subscriptionTier,
            requiredTier: feature.requiredTier
        )
        
        return canAccessPremiumFeature.evaluate(context)
    }
}
```

## Advanced Features

### Custom Value Extraction

Use closures for complex value extraction:

```swift
let complexSpec = ThresholdSpec(
    extracting: { context in
        // Complex calculation
        let baseValue = context.primaryMetric
        let adjustment = context.adjustmentFactor
        return baseValue * adjustment + context.offset
    },
    threshold: .adaptive {
        calculateComplexThreshold()
    },
    operator: .greaterThan
)
```

### Multiple Threshold Evaluation

Combine multiple thresholds for sophisticated logic:

```swift
let multiThresholdSpec = ThresholdSpec.exceeds(
    keyPath: \.temperature,
    value: warningThreshold
).and(
    ThresholdSpec.exceeds(
        keyPath: \.humidity,
        value: humidityThreshold
    )
).or(
    ThresholdSpec.below(
        keyPath: \.airQuality,
        value: qualityThreshold
    )
)
```

## Best Practices

### 1. Choose Appropriate Threshold Types

Select the right threshold type for your use case:

```swift
// Use fixed thresholds for well-defined limits
let fixedSpec = ThresholdSpec(
    keyPath: \.maxConnections,
    threshold: .fixed(1000),
    operator: .lessThan
)

// Use adaptive thresholds for dynamic systems
let adaptiveSpec = ThresholdSpec(
    keyPath: \.loadAverage,
    threshold: .adaptive { getCurrentCapacity() * 0.8 },
    operator: .lessThan
)

// Use contextual thresholds for user-specific limits
let contextualSpec = ThresholdSpec(
    keyPath: \.dailyUsage,
    threshold: .contextual(\.dailyLimit),
    operator: .lessThan
)
```

### 2. Handle Edge Cases

Account for potential edge cases:

```swift
let robustSpec = ThresholdSpec(
    extracting: { context in
        // Ensure valid data before comparison
        guard context.isValid else { return nil }
        return context.normalizedValue
    },
    threshold: .custom { context in
        // Handle special conditions
        guard context.hasValidConfiguration else { return Double.infinity }
        return context.calculateThreshold()
    },
    operator: .lessThan
)
```

### 3. Use Tolerance for Floating-Point Comparisons

Always use appropriate tolerance for equality comparisons:

```swift
let tolerantSpec = ThresholdSpec(
    keyPath: \.measuredValue,
    threshold: .fixed(targetValue),
    operator: .equal,
    tolerance: 0.001 // Appropriate precision
)
```

### 4. Document Threshold Logic

Make threshold calculations clear and maintainable:

```swift
struct PerformanceThresholds {
    /// CPU usage threshold based on system configuration
    static func cpuThreshold() -> Double {
        let coreCount = ProcessInfo.processInfo.processorCount
        return min(80.0, 60.0 + Double(coreCount) * 5.0) // Scale with core count
    }
    
    /// Memory threshold as percentage of total memory
    static func memoryThreshold(totalMemory: Double) -> Double {
        return totalMemory * 0.85 // Allow 85% usage
    }
}

let cpuSpec = ThresholdSpec(
    keyPath: \.cpuUsage,
    threshold: .adaptive(PerformanceThresholds.cpuThreshold),
    operator: .lessThan
)
```

## Performance Characteristics

- **Evaluation Time**: O(1) for fixed/contextual thresholds, O(f) where f is the complexity of adaptive/custom threshold functions
- **Memory Usage**: O(1) for the specification itself
- **Thread Safety**: Specifications are thread-safe for concurrent evaluation

## See Also

- ``Specification`` - The base protocol for all specifications
- ``ComparativeSpec`` - For more complex comparative operations
- ``HistoricalSpec`` - For historical trend-based thresholds
- ``WeightedSpec`` - For probabilistic threshold-based selection
- ``DecisionSpec`` - For decision-oriented specifications