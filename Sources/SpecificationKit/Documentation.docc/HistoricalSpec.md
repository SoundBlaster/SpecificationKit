# HistoricalSpec

A decision specification that analyzes historical data over time to make decisions.

## Overview

`HistoricalSpec` provides time-series analysis capabilities for specifications that need to evaluate trends, patterns, or statistical measures from historical data. This is essential for adaptive systems, trend analysis, seasonal adjustments, and predictive decision making.

The specification supports various analysis windows (time ranges, last N points) and aggregation methods (median, percentiles, custom functions) to transform historical data into actionable decisions.

## Basic Usage

### Performance Analysis

Analyze historical performance data to make adaptive decisions:

```swift
import SpecificationKit

let performanceSpec = HistoricalSpec(
    provider: MetricsHistoryProvider(),
    window: .lastN(30),
    aggregation: .median
)

@Maybe(using: performanceSpec)
var medianPerformance: Double?

// Use the historical analysis
if let median = medianPerformance, median > acceptableThreshold {
    enableOptimizations()
}
```

### Capacity Planning

Use historical data to predict resource needs:

```swift
let capacitySpec = HistoricalSpec(
    provider: ResourceHistoryProvider(),
    window: .timeRange(TimeInterval.days(7)),
    aggregation: .percentile(90)
)

@Decides(using: capacitySpec, or: defaultCapacity)
var recommendedCapacity: Double
```

### Custom Aggregation

Define custom analysis logic for specific business needs:

```swift
let trendSpec = HistoricalSpec(
    provider: SalesHistoryProvider(),
    window: .lastN(12), // Last 12 months
    aggregation: .custom { data in
        // Calculate growth rate from first to last data point
        guard let first = data.first?.1, let last = data.last?.1, first > 0 else { return 0 }
        return (last - first) / first * 100 // Percentage growth
    }
)
```

## Analysis Windows

### Last N Data Points

Analyze the most recent N data points regardless of time:

```swift
let recentDataSpec = HistoricalSpec(
    provider: dataProvider,
    window: .lastN(100), // Last 100 data points
    aggregation: .median
)
```

### Time Range

Analyze data within a specific time period:

```swift
let weeklySpec = HistoricalSpec(
    provider: dataProvider,
    window: .timeRange(TimeInterval.days(7)), // Last 7 days
    aggregation: .percentile(75)
)

let hourlySpec = HistoricalSpec(
    provider: dataProvider,
    window: .timeRange(TimeInterval.hours(1)), // Last hour
    aggregation: .median
)
```

### All Available Data

Use the entire historical dataset:

```swift
let comprehensiveSpec = HistoricalSpec(
    provider: dataProvider,
    window: .all,
    aggregation: .percentile(95)
)
```

## Aggregation Methods

### Median

Find the middle value of the dataset:

```swift
let medianSpec = HistoricalSpec(
    provider: dataProvider,
    window: .lastN(50),
    aggregation: .median
)
```

### Percentiles

Calculate specific percentiles for threshold analysis:

```swift
// 90th percentile for outlier detection
let outlierSpec = HistoricalSpec(
    provider: dataProvider,
    window: .timeRange(TimeInterval.days(30)),
    aggregation: .percentile(90)
)

// 25th percentile for low-end analysis
let lowEndSpec = HistoricalSpec(
    provider: dataProvider,
    window: .lastN(200),
    aggregation: .percentile(25)
)
```

### Custom Analysis

Implement domain-specific calculations:

```swift
let volatilitySpec = HistoricalSpec(
    provider: priceProvider,
    window: .lastN(20),
    aggregation: .custom { data in
        // Calculate price volatility (standard deviation)
        let prices = data.map(\.1)
        let mean = prices.reduce(0, +) / Double(prices.count)
        let variance = prices.map { pow($0 - mean, 2) }.reduce(0, +) / Double(prices.count)
        return sqrt(variance)
    }
)
```

## Specialized Extensions for Double Values

For `Double` values, additional aggregation methods are available:

```swift
let doubleSpec = HistoricalSpec(
    provider: numericProvider,
    window: .lastN(50),
    doubleAggregation: .average // Additional option for Double types
)

let trendSpec = HistoricalSpec(
    provider: numericProvider,
    window: .timeRange(TimeInterval.days(30)),
    doubleAggregation: .linearTrend // Returns slope of linear regression
)
```

## Data Providers

### Default Implementation

Use the built-in in-memory provider:

```swift
let historyProvider = DefaultHistoricalDataProvider(storage: [
    "cpu_usage": [
        (Date().addingTimeInterval(-3600), 45.0), // 1 hour ago
        (Date().addingTimeInterval(-1800), 52.0), // 30 minutes ago
        (Date().addingTimeInterval(-900), 48.0),  // 15 minutes ago
        (Date(), 50.0)                            // Now
    ]
])

let spec = HistoricalSpec(
    provider: historyProvider,
    window: .all,
    aggregation: .median
)
```

### Custom Provider

Implement your own data provider for database integration:

```swift
class DatabaseHistoryProvider: HistoricalDataProvider {
    private let database: Database
    
    init(database: Database) {
        self.database = database
    }
    
    func getData<Context, Value>(
        for window: HistoricalSpec<Context, Value>.AnalysisWindow,
        context: Context
    ) -> [(Date, Value)] {
        // Query database based on window and context
        // Return time-series data
        return fetchFromDatabase(window: window, context: context)
    }
}
```

## Integration Examples

### With SwiftUI

Create reactive views that update based on historical analysis:

```swift
import SwiftUI

struct PerformanceDashboard: View {
    @State private var historyProvider = createHistoryProvider()
    @State private var currentMetric: Double?
    
    var body: some View {
        VStack {
            Text("Performance Trend")
            
            if let metric = currentMetric {
                Text("Current: \(metric, specifier: "%.2f")")
                    .foregroundColor(metric > historicalMedian ? .green : .red)
            }
        }
        .onAppear {
            updateMetrics()
        }
    }
    
    private var historicalMedian: Double {
        let spec = HistoricalSpec(
            provider: historyProvider,
            window: .lastN(30),
            aggregation: .median
        )
        return spec.decide(MetricsContext()) ?? 0.0
    }
}
```

### With Combine

Stream historical analysis updates:

```swift
import Combine

class MetricsAnalyzer: ObservableObject {
    @Published var trendDirection: String = "stable"
    
    private let historyProvider: HistoricalDataProvider
    private var cancellables = Set<AnyCancellable>()
    
    init(provider: HistoricalDataProvider) {
        self.historyProvider = provider
        startAnalysis()
    }
    
    private func startAnalysis() {
        Timer.publish(every: 60, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.analyzeTrend()
            }
            .store(in: &cancellables)
    }
    
    private func analyzeTrend() {
        let trendSpec = HistoricalSpec(
            provider: historyProvider,
            window: .lastN(10),
            doubleAggregation: .linearTrend
        )
        
        if let slope = trendSpec.decide(MetricsContext()) {
            trendDirection = slope > 0.1 ? "increasing" : 
                            slope < -0.1 ? "decreasing" : "stable"
        }
    }
}
```

## Best Practices

### 1. Data Quality

Ensure historical data is clean and consistent:

```swift
let robustSpec = HistoricalSpec(
    provider: dataProvider,
    window: .lastN(50),
    aggregation: .custom { data in
        // Filter outliers before analysis
        let values = data.map(\.1)
        let sorted = values.sorted()
        let q1 = sorted[sorted.count / 4]
        let q3 = sorted[3 * sorted.count / 4]
        let iqr = q3 - q1
        let filtered = values.filter { value in
            value >= q1 - 1.5 * iqr && value <= q3 + 1.5 * iqr
        }
        return filtered.reduce(0, +) / Double(filtered.count)
    }
)
```

### 2. Appropriate Window Sizes

Choose window sizes that balance responsiveness with stability:

```swift
// For real-time systems: smaller windows
let realtimeSpec = HistoricalSpec(
    provider: dataProvider,
    window: .timeRange(TimeInterval.minutes(5)),
    aggregation: .median
)

// For trend analysis: larger windows  
let trendSpec = HistoricalSpec(
    provider: dataProvider,
    window: .timeRange(TimeInterval.days(30)),
    aggregation: .percentile(75)
)
```

### 3. Minimum Data Requirements

Set appropriate minimum data point requirements:

```swift
let reliableSpec = HistoricalSpec(
    provider: dataProvider,
    window: .lastN(100),
    aggregation: .percentile(90),
    minimumDataPoints: 20 // Require at least 20 data points
)
```

## Performance Characteristics

- **Memory Usage**: O(n) where n is the number of historical data points in the window
- **Computation Time**: O(n log n) for percentile calculations, O(n) for median and custom aggregations
- **Thread Safety**: Each provider instance should implement its own thread safety

## See Also

- ``HistoricalDataProvider`` - Protocol for providing historical data
- ``DefaultHistoricalDataProvider`` - Built-in in-memory provider
- ``ComparativeSpec`` - For comparing against historical baselines
- ``ThresholdSpec`` - For adaptive threshold evaluation
- ``DecisionSpec`` - The protocol that HistoricalSpec implements