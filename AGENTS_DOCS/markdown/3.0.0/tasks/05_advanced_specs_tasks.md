# Algorithm/Logic Specialist Tasks

## Agent Profile
- **Primary Skills**: Probability algorithms, statistical analysis, generics, mathematical correctness
- **Secondary Skills**: Performance optimization, data structures, edge case handling
- **Complexity Level**: High (4-5/5)

## Task Overview

### Advanced Specification Types Implementation
**Objective**: Implement WeightedSpec, HistoricalSpec, ComparativeSpec, and ThresholdSpec
**Priority**: High
**Dependencies**: Context providers (for HistoricalSpec)
**Timeline**: 14 days total

---

## 3.2.1: WeightedSpec Implementation

### Timeline: 4 days
### Mathematical Foundation

#### API Design Target
```swift
public struct WeightedSpec<Context, Result>: DecisionSpec {
    public typealias Candidate = (specification: any Specification<Context>, weight: Double, result: Result)
    
    public let candidates: [Candidate]
    private let randomGenerator: RandomNumberGenerator
    
    public init(candidates: [Candidate], using generator: RandomNumberGenerator = SystemRandomNumberGenerator()) {
        precondition(!candidates.isEmpty, "WeightedSpec requires at least one candidate")
        precondition(candidates.allSatisfy { $0.weight > 0 }, "All weights must be positive")
        
        self.candidates = candidates
        self.randomGenerator = generator
    }
    
    public func isSatisfiedBy(_ context: Context) -> Result {
        // Weighted random selection based on probability distribution
        let totalWeight = candidates.map(\.weight).reduce(0, +)
        let randomValue = Double.random(in: 0..<totalWeight, using: &randomGenerator)
        
        var cumulativeWeight: Double = 0
        for candidate in candidates {
            cumulativeWeight += candidate.weight
            if randomValue < cumulativeWeight {
                if candidate.specification.isSatisfiedBy(context) {
                    return candidate.result
                }
                break // Specification not satisfied, continue with probabilistic selection
            }
        }
        
        // Fallback: select first satisfied specification
        return candidates.first { $0.specification.isSatisfiedBy(context) }?.result 
            ?? candidates.first!.result
    }
}
```

#### Advanced Probability Distribution
```swift
extension WeightedSpec {
    /// Normalized probability distribution
    public var probabilityDistribution: [Double] {
        let total = candidates.map(\.weight).reduce(0, +)
        return candidates.map { $0.weight / total }
    }
    
    /// Expected value calculation (for numeric results)
    public func expectedValue() -> Double where Result == Double {
        zip(candidates.map(\.result), probabilityDistribution)
            .map(*)
            .reduce(0, +)
    }
    
    /// Variance calculation (for numeric results)
    public func variance() -> Double where Result == Double {
        let expected = expectedValue()
        return zip(candidates.map(\.result), probabilityDistribution)
            .map { pow($0 - expected, 2) * $1 }
            .reduce(0, +)
    }
}
```

#### Edge Case Handling
```swift
extension WeightedSpec {
    /// Handle zero weights gracefully
    private func normalizeWeights() -> [Candidate] {
        let nonZeroWeights = candidates.filter { $0.weight > 0 }
        guard !nonZeroWeights.isEmpty else {
            // If all weights are zero, assign equal weight
            return candidates.map { (specification: $0.specification, weight: 1.0, result: $0.result) }
        }
        return nonZeroWeights
    }
    
    /// Validate mathematical constraints
    private func validateConstraints() throws {
        guard !candidates.isEmpty else {
            throw SpecificationError.invalidConfiguration("WeightedSpec requires at least one candidate")
        }
        
        guard candidates.allSatisfy({ $0.weight.isFinite && $0.weight >= 0 }) else {
            throw SpecificationError.invalidConfiguration("All weights must be non-negative finite numbers")
        }
    }
}
```

#### Statistical Testing Framework
```swift
class WeightedSpecStatisticalTests: XCTestCase {
    func testProbabilityDistribution() {
        let spec = WeightedSpec(candidates: [
            (AlwaysTrueSpec(), weight: 0.7, result: "A"),
            (AlwaysTrueSpec(), weight: 0.3, result: "B")
        ])
        
        let iterations = 100_000
        let results = (1...iterations).map { _ in spec.isSatisfiedBy(EmptyContext()) }
        
        let aCount = results.filter { $0 == "A" }.count
        let ratio = Double(aCount) / Double(iterations)
        
        // Statistical significance test (within 3 standard deviations)
        let expectedRatio = 0.7
        let standardError = sqrt(expectedRatio * (1 - expectedRatio) / Double(iterations))
        let margin = 3 * standardError
        
        XCTAssertEqual(ratio, expectedRatio, accuracy: margin)
    }
    
    func testChiSquareGoodnessOfFit() {
        // Implement chi-square test for distribution correctness
        let spec = WeightedSpec(candidates: [
            (AlwaysTrueSpec(), weight: 0.4, result: "A"),
            (AlwaysTrueSpec(), weight: 0.35, result: "B"),
            (AlwaysTrueSpec(), weight: 0.25, result: "C")
        ])
        
        let results = performTrials(spec: spec, iterations: 10_000)
        let chiSquare = calculateChiSquare(observed: results, expected: spec.probabilityDistribution)
        
        // Chi-square critical value for 2 degrees of freedom at 0.05 significance level
        XCTAssertLessThan(chiSquare, 5.991, "Distribution does not match expected weights")
    }
}
```

---

## 3.2.2: HistoricalSpec Implementation

### Timeline: 5 days
### Time-Series Analysis Integration

#### API Design
```swift
public struct HistoricalSpec<Context, Result>: DecisionSpec {
    public enum AnalysisWindow {
        case lastN(Int)
        case timeRange(TimeInterval)
        case sliding(window: TimeInterval, step: TimeInterval)
    }
    
    public enum AggregationMethod {
        case average
        case median
        case trend(regression: RegressionType)
        case seasonality(period: TimeInterval)
        case custom(([(Date, Result)] -> Result))
    }
    
    private let dataProvider: HistoricalDataProvider
    private let window: AnalysisWindow
    private let aggregation: AggregationMethod
    
    public init(
        provider: HistoricalDataProvider,
        window: AnalysisWindow,
        aggregation: AggregationMethod
    ) {
        self.dataProvider = provider
        self.window = window
        self.aggregation = aggregation
    }
    
    public func isSatisfiedBy(_ context: Context) -> Result {
        let historicalData = dataProvider.getData(for: window, context: context)
        return aggregateData(historicalData, using: aggregation)
    }
}
```

#### Time-Series Data Management
```swift
protocol HistoricalDataProvider {
    func getData<Context, Result>(
        for window: HistoricalSpec<Context, Result>.AnalysisWindow,
        context: Context
    ) -> [(Date, Result)]
}

public final class DefaultHistoricalDataProvider: HistoricalDataProvider {
    private let storage: TimeSeriesStorage
    private let interpolator: DataInterpolator
    
    public init(storage: TimeSeriesStorage, interpolator: DataInterpolator = LinearInterpolator()) {
        self.storage = storage
        self.interpolator = interpolator
    }
    
    public func getData<Context, Result>(
        for window: HistoricalSpec<Context, Result>.AnalysisWindow,
        context: Context
    ) -> [(Date, Result)] {
        let rawData = storage.fetchData(for: window, context: context)
        return interpolator.interpolateMissingValues(rawData)
    }
}
```

#### Advanced Statistical Analysis
```swift
extension HistoricalSpec {
    /// Linear regression trend analysis
    private func calculateTrend(_ data: [(Date, Double)]) -> Double {
        guard data.count > 1 else { return data.first?.1 ?? 0 }
        
        let n = Double(data.count)
        let sumX = data.enumerated().map { Double($0.offset) }.reduce(0, +)
        let sumY = data.map(\.1).reduce(0, +)
        let sumXY = data.enumerated().map { Double($0.offset) * $0.element.1 }.reduce(0, +)
        let sumXX = data.enumerated().map { pow(Double($0.offset), 2) }.reduce(0, +)
        
        let slope = (n * sumXY - sumX * sumY) / (n * sumXX - pow(sumX, 2))
        return slope
    }
    
    /// Seasonal decomposition
    private func detectSeasonality(_ data: [(Date, Double)], period: TimeInterval) -> Double {
        // Implement seasonal decomposition algorithm
        // Return seasonal component strength
    }
    
    /// Moving average with configurable window
    private func movingAverage(_ data: [(Date, Double)], windowSize: Int) -> [(Date, Double)] {
        guard data.count >= windowSize else { return data }
        
        return data.enumerated().compactMap { index, element in
            guard index >= windowSize - 1 else { return nil }
            
            let window = data[(index - windowSize + 1)...index]
            let average = window.map(\.1).reduce(0, +) / Double(windowSize)
            return (element.0, average)
        }
    }
}
```

#### Missing Data Interpolation
```swift
protocol DataInterpolator {
    func interpolateMissingValues<Result>(_ data: [(Date, Result?)]) -> [(Date, Result)]
}

struct LinearInterpolator: DataInterpolator {
    func interpolateMissingValues<Result>(_ data: [(Date, Result?)]) -> [(Date, Result)] {
        // Implement linear interpolation for missing data points
        var interpolated: [(Date, Result)] = []
        
        for (index, (date, value)) in data.enumerated() {
            if let value = value {
                interpolated.append((date, value))
            } else {
                // Find nearest non-nil values for interpolation
                let interpolatedValue = interpolate(at: index, in: data)
                interpolated.append((date, interpolatedValue))
            }
        }
        
        return interpolated
    }
    
    private func interpolate<Result>(at index: Int, in data: [(Date, Result?)]) -> Result {
        // Implementation depends on Result type constraints
        fatalError("Interpolation requires Result to be numeric")
    }
}

// Specialized implementation for numeric types
extension LinearInterpolator {
    func interpolateMissingValues(_ data: [(Date, Double?)]) -> [(Date, Double)] {
        // Specific implementation for Double values
    }
}
```

---

## 3.2.3: ComparativeSpec Implementation

### Timeline: 3 days

#### API Design
```swift
public struct ComparativeSpec<Context, Result: Comparable>: DecisionSpec {
    public enum ComparisonType {
        case greaterThan(Result)
        case lessThan(Result)
        case equalTo(Result)
        case between(Result, Result)
        case ranking(percentile: Double) // Compare against historical percentiles
    }
    
    private let baselineSpec: any DecisionSpec<Context, Result>
    private let comparison: ComparisonType
    
    public init(
        comparing baselineSpec: any DecisionSpec<Context, Result>,
        to comparison: ComparisonType
    ) {
        self.baselineSpec = baselineSpec
        self.comparison = comparison
    }
    
    public func isSatisfiedBy(_ context: Context) -> Bool {
        let baselineValue = baselineSpec.isSatisfiedBy(context)
        return evaluate(baselineValue, against: comparison)
    }
}
```

#### Advanced Comparison Logic
```swift
extension ComparativeSpec {
    private func evaluate(_ value: Result, against comparison: ComparisonType) -> Bool {
        switch comparison {
        case .greaterThan(let threshold):
            return value > threshold
        case .lessThan(let threshold):
            return value < threshold
        case .equalTo(let expected):
            return value == expected
        case .between(let lower, let upper):
            return lower <= value && value <= upper
        case .ranking(let percentile):
            return evaluatePercentileRanking(value, percentile: percentile)
        }
    }
    
    private func evaluatePercentileRanking(_ value: Result, percentile: Double) -> Bool {
        // Requires integration with HistoricalSpec for percentile calculation
        fatalError("Percentile ranking requires historical data integration")
    }
}
```

---

## 3.2.4: ThresholdSpec Implementation

### Timeline: 2 days

#### API Design
```swift
public struct ThresholdSpec<Context, Value: Comparable>: Specification {
    public enum ThresholdType {
        case fixed(Value)
        case adaptive(provider: () -> Value)
        case contextual(keyPath: KeyPath<Context, Value>)
        case percentile(Double, from: [Value])
    }
    
    private let valueExtractor: (Context) -> Value
    private let threshold: ThresholdType
    
    public init(
        extracting valueExtractor: @escaping (Context) -> Value,
        threshold: ThresholdType
    ) {
        self.valueExtractor = valueExtractor
        self.threshold = threshold
    }
    
    public func isSatisfiedBy(_ context: Context) -> Bool {
        let currentValue = valueExtractor(context)
        let thresholdValue = resolveThreshold(threshold, context: context)
        return currentValue >= thresholdValue
    }
}
```

#### Dynamic Threshold Resolution
```swift
extension ThresholdSpec {
    private func resolveThreshold(_ type: ThresholdType, context: Context) -> Value {
        switch type {
        case .fixed(let value):
            return value
        case .adaptive(let provider):
            return provider()
        case .contextual(let keyPath):
            return context[keyPath: keyPath]
        case .percentile(let percentile, let distribution):
            return calculatePercentile(percentile, from: distribution)
        }
    }
    
    private func calculatePercentile(_ percentile: Double, from values: [Value]) -> Value {
        let sortedValues = values.sorted()
        let index = Int((percentile / 100.0) * Double(sortedValues.count - 1))
        return sortedValues[min(index, sortedValues.count - 1)]
    }
}
```

---

## Implementation Guidelines

### Mathematical Correctness Standards
- **Statistical Validation**: All probability distributions must pass statistical tests
- **Numerical Stability**: Handle edge cases like zero weights, empty data sets
- **Performance**: Optimize for large data sets and frequent evaluations
- **Thread Safety**: All calculations must be thread-safe

### Testing Strategy
```swift
class AdvancedSpecsTests: XCTestCase {
    func testWeightedSpecDistribution() {
        // Statistical significance tests
    }
    
    func testHistoricalDataInterpolation() {
        // Test missing data handling
    }
    
    func testComparativeSpecEdgeCases() {
        // Test boundary conditions
    }
    
    func testThresholdSpecAdaptability() {
        // Test dynamic threshold updates
    }
}
```

### Performance Requirements
- **WeightedSpec**: <1ms for selection from 100 candidates
- **HistoricalSpec**: <10ms for 1000 data points analysis
- **ComparativeSpec**: <0.5ms for basic comparisons
- **ThresholdSpec**: <0.1ms for threshold resolution

## Dependencies & Coordination

### External Dependencies
- Foundation for statistical calculations
- Integration with context providers for historical data
- Thread-safe data structures for concurrent access

### Coordination Points
- **Context Providers Team**: Historical data storage and retrieval
- **Performance Team**: Optimization of mathematical algorithms
- **Testing Team**: Statistical test validation frameworks

## Success Metrics
- **Mathematical Correctness**: Pass all statistical validation tests
- **Performance**: Meet all latency requirements
- **Edge Case Handling**: Handle all identified edge cases gracefully
- **Documentation**: Comprehensive mathematical documentation and examples