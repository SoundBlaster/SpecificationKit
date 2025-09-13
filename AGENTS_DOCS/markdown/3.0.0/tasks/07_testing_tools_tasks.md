# Test Infrastructure Specialist Tasks

## Agent Profile
- **Primary Skills**: Test frameworks, debugging tools, developer experience, profiling
- **Secondary Skills**: Reflection, logging systems, visualization, performance measurement
- **Complexity Level**: Medium-High (3-4/5)

## Task Overview

### Testing & Debugging Infrastructure
**Objective**: Implement SpecificationTracer, MockSpecificationBuilder, and profiling tools
**Priority**: Medium (depends on core features)
**Dependencies**: Core specifications and context providers
**Timeline**: 10 days total

---

## 4.1: SpecificationTracer Implementation

### Timeline: 4 days

#### API Design Target
```swift
public final class SpecificationTracer {
    public struct TraceEntry {
        let id: UUID
        let specification: String
        let context: String
        let result: String
        let executionTime: TimeInterval
        let depth: Int
        let parentId: UUID?
        let timestamp: Date
        let metadata: [String: Any]
        
        public init(
            specification: String,
            context: String,
            result: String,
            executionTime: TimeInterval,
            depth: Int,
            parentId: UUID? = nil,
            metadata: [String: Any] = [:]
        ) {
            self.id = UUID()
            self.specification = specification
            self.context = context
            self.result = result
            self.executionTime = executionTime
            self.depth = depth
            self.parentId = parentId
            self.timestamp = Date()
            self.metadata = metadata
        }
    }
    
    public struct TraceSession {
        let id: UUID
        let startTime: Date
        var entries: [TraceEntry]
        var isActive: Bool
        
        public var totalExecutionTime: TimeInterval {
            entries.map(\.executionTime).reduce(0, +)
        }
        
        public var traceTree: [TraceNode] {
            buildTraceTree(from: entries)
        }
    }
    
    private var currentSession: TraceSession?
    private var isEnabled: Bool = false
    private let queue = DispatchQueue(label: "specification-tracer", qos: .utility)
    
    public static let shared = SpecificationTracer()
    
    private init() {}
}
```

#### Core Tracing Functionality
```swift
extension SpecificationTracer {
    public func startTracing() -> UUID {
        return queue.sync {
            let sessionId = UUID()
            currentSession = TraceSession(
                id: sessionId,
                startTime: Date(),
                entries: [],
                isActive: true
            )
            isEnabled = true
            return sessionId
        }
    }
    
    public func stopTracing() -> TraceSession? {
        return queue.sync {
            defer {
                currentSession = nil
                isEnabled = false
            }
            
            var session = currentSession
            session?.isActive = false
            return session
        }
    }
    
    public func trace<T, Context>(
        specification: any Specification<Context>,
        context: Context,
        parentId: UUID? = nil,
        depth: Int = 0
    ) -> T where T == Bool {
        guard isEnabled, currentSession != nil else {
            return specification.isSatisfiedBy(context)
        }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = specification.isSatisfiedBy(context)
        let executionTime = CFAbsoluteTimeGetCurrent() - startTime
        
        let entry = TraceEntry(
            specification: String(describing: type(of: specification)),
            context: String(describing: context),
            result: String(describing: result),
            executionTime: executionTime,
            depth: depth,
            parentId: parentId
        )
        
        queue.async {
            self.currentSession?.entries.append(entry)
        }
        
        return result
    }
}
```

#### Composite Specification Tracing
```swift
// Extension for tracing composite specifications
extension SpecificationTracer {
    public func traceComposite<Context>(
        _ operation: String,
        left: any Specification<Context>,
        right: any Specification<Context>,
        context: Context,
        parentId: UUID? = nil,
        depth: Int = 0
    ) -> Bool {
        let compositeId = UUID()
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Trace left specification
        let leftResult = trace(
            specification: left,
            context: context,
            parentId: compositeId,
            depth: depth + 1
        )
        
        // For AND operations, short-circuit if left is false
        if operation == "AND" && !leftResult {
            let executionTime = CFAbsoluteTimeGetCurrent() - startTime
            recordCompositeEntry(
                operation: operation,
                result: false,
                executionTime: executionTime,
                parentId: parentId,
                depth: depth,
                shortCircuited: true
            )
            return false
        }
        
        // For OR operations, short-circuit if left is true
        if operation == "OR" && leftResult {
            let executionTime = CFAbsoluteTimeGetCurrent() - startTime
            recordCompositeEntry(
                operation: operation,
                result: true,
                executionTime: executionTime,
                parentId: parentId,
                depth: depth,
                shortCircuited: true
            )
            return true
        }
        
        // Trace right specification
        let rightResult = trace(
            specification: right,
            context: context,
            parentId: compositeId,
            depth: depth + 1
        )
        
        let finalResult = operation == "AND" ? (leftResult && rightResult) : (leftResult || rightResult)
        let executionTime = CFAbsoluteTimeGetCurrent() - startTime
        
        recordCompositeEntry(
            operation: operation,
            result: finalResult,
            executionTime: executionTime,
            parentId: parentId,
            depth: depth,
            shortCircuited: false
        )
        
        return finalResult
    }
}
```

#### Visual Representation
```swift
public struct TraceNode {
    let entry: TraceEntry
    let children: [TraceNode]
    
    public func printTree(indent: String = "") {
        let duration = String(format: "%.3fms", entry.executionTime * 1000)
        print("\(indent)├─ \(entry.specification) → \(entry.result) (\(duration))")
        
        for (index, child) in children.enumerated() {
            let isLast = index == children.count - 1
            let childIndent = indent + (isLast ? "   " : "│  ")
            child.printTree(indent: childIndent)
        }
    }
    
    public func generateDotGraph() -> String {
        var dot = "digraph SpecificationTrace {\n"
        dot += "  rankdir=TB;\n"
        dot += "  node [shape=box, style=rounded];\n"
        
        func addNode(_ node: TraceNode, parentId: String? = nil) {
            let nodeId = "node_\(node.entry.id.uuidString.prefix(8))"
            let duration = String(format: "%.3f", node.entry.executionTime * 1000)
            let label = "\(node.entry.specification)\\n\(node.entry.result)\\n\(duration)ms"
            
            dot += "  \(nodeId) [label=\"\(label)\"];\n"
            
            if let parent = parentId {
                dot += "  \(parent) -> \(nodeId);\n"
            }
            
            for child in node.children {
                addNode(child, parentId: nodeId)
            }
        }
        
        addNode(self)
        dot += "}\n"
        return dot
    }
}

extension SpecificationTracer {
    private func buildTraceTree(from entries: [TraceEntry]) -> [TraceNode] {
        let entryMap = Dictionary(uniqueKeysWithValues: entries.map { ($0.id, $0) })
        let rootEntries = entries.filter { $0.parentId == nil }
        
        func buildNode(for entry: TraceEntry) -> TraceNode {
            let children = entries
                .filter { $0.parentId == entry.id }
                .sorted { $0.timestamp < $1.timestamp }
                .map(buildNode)
            
            return TraceNode(entry: entry, children: children)
        }
        
        return rootEntries
            .sorted { $0.timestamp < $1.timestamp }
            .map(buildNode)
    }
}
```

---

## 4.2: MockSpecificationBuilder Implementation

### Timeline: 3 days

#### Builder Pattern for Test Specifications
```swift
public final class MockSpecificationBuilder<Context> {
    public enum BehaviorType {
        case alwaysTrue
        case alwaysFalse
        case conditional((Context) -> Bool)
        case delayed(TimeInterval, result: Bool)
        case random(probability: Double)
        case sequence([Bool]) // Return results in sequence
        case contextDependent(keyPath: KeyPath<Context, Bool>)
    }
    
    private var behavior: BehaviorType = .alwaysTrue
    private var callCount: Int = 0
    private var callHistory: [(Context, Date)] = []
    private var shouldThrow: Error?
    private var executionTime: TimeInterval = 0
    
    public init() {}
    
    public func alwaysReturns(_ result: Bool) -> Self {
        behavior = result ? .alwaysTrue : .alwaysFalse
        return self
    }
    
    public func returns(_ predicate: @escaping (Context) -> Bool) -> Self {
        behavior = .conditional(predicate)
        return self
    }
    
    public func withDelay(_ delay: TimeInterval, returning result: Bool) -> Self {
        behavior = .delayed(delay, result: result)
        return self
    }
    
    public func withRandomResult(probability: Double) -> Self {
        behavior = .random(probability: probability)
        return self
    }
    
    public func withSequence(_ results: [Bool]) -> Self {
        behavior = .sequence(results)
        return self
    }
    
    public func throws(_ error: Error) -> Self {
        shouldThrow = error
        return self
    }
    
    public func withExecutionTime(_ time: TimeInterval) -> Self {
        executionTime = time
        return self
    }
    
    public func build() -> MockSpecification<Context> {
        return MockSpecification(
            behavior: behavior,
            shouldThrow: shouldThrow,
            executionTime: executionTime
        )
    }
}
```

#### Mock Specification Implementation
```swift
public final class MockSpecification<Context>: Specification {
    private let behavior: MockSpecificationBuilder<Context>.BehaviorType
    private let shouldThrow: Error?
    private let executionTime: TimeInterval
    private var sequenceIndex = 0
    private var callHistory: [(Context, Date, Bool)] = []
    
    internal init(
        behavior: MockSpecificationBuilder<Context>.BehaviorType,
        shouldThrow: Error?,
        executionTime: TimeInterval
    ) {
        self.behavior = behavior
        self.shouldThrow = shouldThrow
        self.executionTime = executionTime
    }
    
    public func isSatisfiedBy(_ context: Context) -> Bool {
        // Simulate execution time
        if executionTime > 0 {
            Thread.sleep(forTimeInterval: executionTime)
        }
        
        // Check if should throw error
        if let error = shouldThrow {
            fatalError("Mock specification error: \(error)")
        }
        
        let result: Bool
        
        switch behavior {
        case .alwaysTrue:
            result = true
        case .alwaysFalse:
            result = false
        case .conditional(let predicate):
            result = predicate(context)
        case .delayed(_, let delayedResult):
            result = delayedResult
        case .random(let probability):
            result = Double.random(in: 0...1) < probability
        case .sequence(let results):
            result = results[sequenceIndex % results.count]
            sequenceIndex += 1
        case .contextDependent(let keyPath):
            result = context[keyPath: keyPath] as? Bool ?? false
        }
        
        // Record call history
        callHistory.append((context, Date(), result))
        
        return result
    }
    
    // Testing utilities
    public var callCount: Int { callHistory.count }
    public var lastContext: Context? { callHistory.last?.0 }
    public var allResults: [Bool] { callHistory.map(\.2) }
    
    public func reset() {
        callHistory.removeAll()
        sequenceIndex = 0
    }
}
```

#### Test Helper Extensions
```swift
extension MockSpecificationBuilder {
    // Convenience methods for common test scenarios
    public static func alwaysTrue() -> MockSpecification<Context> {
        return MockSpecificationBuilder<Context>()
            .alwaysReturns(true)
            .build()
    }
    
    public static func alwaysFalse() -> MockSpecification<Context> {
        return MockSpecificationBuilder<Context>()
            .alwaysReturns(false)
            .build()
    }
    
    public static func flaky(successRate: Double = 0.8) -> MockSpecification<Context> {
        return MockSpecificationBuilder<Context>()
            .withRandomResult(probability: successRate)
            .build()
    }
    
    public static func slow(delay: TimeInterval) -> MockSpecification<Context> {
        return MockSpecificationBuilder<Context>()
            .withDelay(delay, returning: true)
            .build()
    }
}
```

---

## 4.3: Profiling Tools Implementation

### Timeline: 3 days

#### Performance Profiler
```swift
public final class SpecificationProfiler {
    public struct ProfileData {
        let specificationName: String
        let executionTimes: [TimeInterval]
        let callCount: Int
        let totalTime: TimeInterval
        let averageTime: TimeInterval
        let minTime: TimeInterval
        let maxTime: TimeInterval
        let standardDeviation: TimeInterval
        
        public var summary: String {
            """
            Specification: \(specificationName)
            Calls: \(callCount)
            Total: \(String(format: "%.3fms", totalTime * 1000))
            Average: \(String(format: "%.3fms", averageTime * 1000))
            Min/Max: \(String(format: "%.3f/%.3fms", minTime * 1000, maxTime * 1000))
            StdDev: \(String(format: "%.3fms", standardDeviation * 1000))
            """
        }
    }
    
    private var profiles: [String: [TimeInterval]] = [:]
    private let queue = DispatchQueue(label: "specification-profiler", qos: .utility)
    
    public static let shared = SpecificationProfiler()
    
    private init() {}
    
    public func profile<Context>(
        _ specification: any Specification<Context>,
        context: Context
    ) -> Bool {
        let specName = String(describing: type(of: specification))
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let result = specification.isSatisfiedBy(context)
        
        let executionTime = CFAbsoluteTimeGetCurrent() - startTime
        
        queue.async {
            self.profiles[specName, default: []].append(executionTime)
        }
        
        return result
    }
    
    public func getProfileData() -> [ProfileData] {
        return queue.sync {
            return profiles.compactMap { (name, times) in
                guard !times.isEmpty else { return nil }
                
                let total = times.reduce(0, +)
                let average = total / Double(times.count)
                let min = times.min() ?? 0
                let max = times.max() ?? 0
                
                let variance = times.map { pow($0 - average, 2) }.reduce(0, +) / Double(times.count)
                let stdDev = sqrt(variance)
                
                return ProfileData(
                    specificationName: name,
                    executionTimes: times,
                    callCount: times.count,
                    totalTime: total,
                    averageTime: average,
                    minTime: min,
                    maxTime: max,
                    standardDeviation: stdDev
                )
            }.sorted { $0.totalTime > $1.totalTime }
        }
    }
    
    public func reset() {
        queue.sync {
            profiles.removeAll()
        }
    }
    
    public func generateReport() -> String {
        let data = getProfileData()
        
        var report = "Specification Performance Report\n"
        report += "================================\n\n"
        
        for profile in data {
            report += profile.summary + "\n\n"
        }
        
        return report
    }
}
```

---

## Implementation Guidelines

### Zero-Overhead When Disabled
```swift
// Compile-time flag to disable tracing in production
#if DEBUG
public func trace<T>(_ operation: () -> T) -> T {
    return SpecificationTracer.shared.isEnabled ? 
        SpecificationTracer.shared.trace(operation) : operation()
}
#else
@inlinable
public func trace<T>(_ operation: () -> T) -> T {
    return operation()
}
#endif
```

### Integration with System Logging
```swift
extension SpecificationTracer {
    public func enableSystemLogging() {
        // Integration with os_log for production debugging
    }
    
    public func exportToOSLog(_ session: TraceSession) {
        for entry in session.entries {
            os_log(.debug, log: .specification, 
                   "Spec: %@ Result: %@ Time: %.3fms",
                   entry.specification, entry.result, entry.executionTime * 1000)
        }
    }
}
```

### Testing Strategy
```swift
class TestingToolsTests: XCTestCase {
    func testTracingAccuracy() {
        // Test tracing overhead and accuracy
    }
    
    func testMockSpecificationBehavior() {
        // Test various mock behaviors
    }
    
    func testProfilingStatistics() {
        // Test statistical calculations
    }
    
    func testZeroOverheadWhenDisabled() {
        // Benchmark overhead when tracing disabled
    }
}
```

## Dependencies & Coordination

### External Dependencies
- Foundation for timing and data structures
- os.log for system logging integration
- Swift reflection for specification introspection

### Coordination Points
- **All Feature Teams**: Integration of tracing calls in specifications
- **Performance Team**: Validation that tools have minimal overhead
- **Documentation Team**: Usage guides for debugging tools

## Success Metrics
- **Zero Overhead**: <1% performance impact when disabled
- **Accuracy**: Tracing captures 100% of specification evaluations
- **Usability**: Intuitive APIs that encourage adoption
- **Visualization**: Clear and actionable debugging output