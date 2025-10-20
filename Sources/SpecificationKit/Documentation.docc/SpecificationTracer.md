# SpecificationTracer

Comprehensive execution tracing and debugging utilities for complex specification evaluations.

## Overview

`SpecificationTracer` provides detailed debugging and analysis capabilities for specification executions, allowing developers to understand complex specification behavior, identify bottlenecks, and debug logical issues in composite specifications.

The tracer captures detailed information about each specification evaluation, including execution hierarchy and nesting relationships, timing information for performance analysis, input contexts and output results, and metadata for custom analysis.

## Key Features

- **Hierarchical Tracing**: Captures nested specification evaluations with parent-child relationships
- **Performance Monitoring**: Precise timing measurements for each evaluation
- **Visual Representation**: Tree-based visualization and DOT graph generation
- **Thread-Safe Operation**: Concurrent tracing across multiple threads
- **Zero-Overhead When Disabled**: Minimal performance impact when not actively tracing

## Basic Usage

### Simple Tracing Session

Start a tracing session to capture specification evaluations:

```swift
import SpecificationKit

let tracer = SpecificationTracer.shared
let sessionId = tracer.startTracing()

let spec = CooldownIntervalSpec(eventKey: "user_action", cooldownInterval: 300)
let context = EvaluationContext(events: ["user_action": Date()])

// Traced evaluation
let result = tracer.trace(specification: spec, context: context)

if let session = tracer.stopTracing() {
    print("Traced \(session.entries.count) evaluations")
    print("Total time: \(session.totalExecutionTime * 1000)ms")

    // Print execution tree
    for tree in session.traceTree {
        tree.printTree()
    }
}
```

### Composite Specification Debugging

Debug complex composite specifications to understand execution flow:

```swift
let tracer = SpecificationTracer.shared
tracer.startTracing()

let complexSpec = spec1.and(spec2).or(spec3.not())
let result = tracer.trace(specification: complexSpec, context: context)

if let session = tracer.stopTracing() {
    // Analyze which branch was taken
    session.traceTree.forEach { $0.printTree() }

    // Generate visual graph
    let dotGraph = session.traceTree.first?.generateDotGraph()
    print(dotGraph ?? "No trace data")
}
```

### Performance Analysis

Identify performance bottlenecks in specification evaluations:

```swift
let tracer = SpecificationTracer.shared
tracer.startTracing()

// Run specifications
for i in 1...1000 {
    let result = tracer.trace(specification: mySpec, context: contexts[i])
}

if let session = tracer.stopTracing() {
    let slowExecutions = session.entries.filter { $0.executionTime > 0.001 }
    print("Found \(slowExecutions.count) slow executions")

    // Identify performance bottlenecks
    let groupedBySpec = Dictionary(grouping: session.entries) { $0.specification }
    for (spec, entries) in groupedBySpec {
        let avgTime = entries.map(\.executionTime).reduce(0, +) / Double(entries.count)
        print("\(spec): \(avgTime * 1000)ms average")
    }
}
```

## Trace Data Structure

### TraceEntry

Each specification evaluation is captured in a `TraceEntry`:

```swift
public struct TraceEntry {
    public let id: UUID
    public let specification: String
    public let context: String
    public let result: String
    public let executionTime: TimeInterval
    public let depth: Int
    public let parentId: UUID?
    public let timestamp: Date
    public let metadata: [String: Any]
}
```

### TraceSession

A complete tracing session contains all recorded evaluations:

```swift
public struct TraceSession {
    public let id: UUID
    public let startTime: Date
    public var entries: [TraceEntry]
    public var isActive: Bool
    
    public var totalExecutionTime: TimeInterval
    public var traceTree: [TraceNode]
}
```

### TraceNode

Hierarchical tree representation of trace entries:

```swift
public struct TraceNode {
    public let entry: TraceEntry
    public let children: [TraceNode]
    
    public func printTree(indent: String = "")
    public func generateDotGraph() -> String
}
```

## Visualization

### Tree Output

The tracer provides ASCII tree visualization:

```
├─ AndSpecification → true (1.234ms)
│  ├─ PredicateSpec<Int> → true (0.567ms)
│  └─ CooldownIntervalSpec → true (0.667ms)
```

### DOT Graph Generation

Generate Graphviz-compatible DOT graphs for visual analysis:

```swift
let tracer = SpecificationTracer.shared
tracer.startTracing()

let result = tracer.trace(specification: complexSpec, context: context)

if let session = tracer.stopTracing() {
    if let tree = session.traceTree.first {
        let dotGraph = tree.generateDotGraph()
        try dotGraph.write(to: URL(fileURLWithPath: "trace.dot"))
        // Render with: dot -Tpng trace.dot -o trace.png
    }
}
```

## Advanced Features

### Custom Metadata

Add custom metadata to trace entries for specialized analysis:

```swift
let result = tracer.traceWithMetadata(
    specification: spec,
    context: context,
    metadata: ["input_range": "0-100", "test_scenario": "edge_case"]
)
```

### Composite Specification Tracing

Specialized tracing for logical operations with short-circuit detection:

```swift
let result = tracer.traceComposite(
    "AND",
    left: spec1,
    right: spec2,
    context: context
)

// Will show short-circuit behavior if spec1 returns false
```

### Type-Erased Specification Support

Trace any specification including type-erased ones:

```swift
let anySpec = AnySpecification(someSpec)
let result = tracer.traceAny(specification: anySpec, context: context)
```

## Integration Examples

### SwiftUI Debug View

Create a debug view showing live tracing information:

```swift
import SwiftUI

struct SpecificationDebugView: View {
    @State private var traceResults: [TraceEntry] = []
    @State private var isTracing = false
    
    private let tracer = SpecificationTracer.shared
    
    var body: some View {
        VStack {
            Button(isTracing ? "Stop Tracing" : "Start Tracing") {
                if isTracing {
                    if let session = tracer.stopTracing() {
                        traceResults = session.entries
                    }
                } else {
                    tracer.startTracing()
                    traceResults = []
                }
                isTracing.toggle()
            }
            
            List(traceResults, id: \.id) { entry in
                VStack(alignment: .leading) {
                    Text(entry.specification)
                        .font(.headline)
                    Text("Result: \(entry.result)")
                    Text("Time: \(entry.executionTime * 1000, specifier: "%.3f")ms")
                        .font(.caption)
                }
            }
        }
        .navigationTitle("Specification Tracer")
    }
}
```

### Testing Integration

Use tracing in unit tests to verify specification behavior:

```swift
class SpecificationTracingTests: XCTestCase {
    func testCompositeSpecificationExecution() {
        // Given
        let tracer = SpecificationTracer.shared
        let spec = spec1.and(spec2).or(spec3)
        let context = TestContext()
        
        // When
        tracer.startTracing()
        let result = tracer.trace(specification: spec, context: context)
        let session = tracer.stopTracing()
        
        // Then
        XCTAssertTrue(result)
        XCTAssertEqual(session?.entries.count, 4) // 3 leaf specs + 1 composite
        
        // Verify execution order
        let entries = session?.entries ?? []
        XCTAssertEqual(entries[0].specification, "spec1")
        XCTAssertEqual(entries[1].specification, "spec2")
        XCTAssertEqual(entries[2].specification, "ANDSpecification")
        XCTAssertEqual(entries[3].specification, "ORSpecification")
    }
    
    func testPerformanceAnalysis() {
        let tracer = SpecificationTracer.shared
        let spec = ExpensiveSpec()
        
        tracer.startTracing()
        _ = tracer.trace(specification: spec, context: TestContext())
        let session = tracer.stopTracing()
        
        let totalTime = session?.totalExecutionTime ?? 0
        XCTAssertLessThan(totalTime, 0.1) // Should complete in under 100ms
    }
}
```

## Debug Mode Features

### Export and Analysis

Export trace data for external analysis:

```swift
#if DEBUG
let tracer = SpecificationTracer.shared
tracer.startTracing()

// ... perform evaluations ...

if let session = tracer.stopTracing() {
    // Export as JSON
    let jsonData = try tracer.exportSession(session)
    try jsonData.write(to: URL(fileURLWithPath: "trace_export.json"))
    
    // Generate analysis report
    let report = tracer.generateAnalysisReport(session)
    print(report)
}
#endif
```

### Statistical Analysis

Analyze specification performance patterns:

```swift
#if DEBUG
let session = tracer.stopTracing()

// Find slow specifications
let slowThreshold: TimeInterval = 0.010 // 10ms
let slowEntries = session.entries.filter { $0.executionTime > slowThreshold }

// Group by specification type
let grouped = Dictionary(grouping: session.entries) { $0.specification }
for (spec, entries) in grouped {
    let avgTime = entries.map(\.executionTime).reduce(0, +) / Double(entries.count)
    print("\(spec): avg \(avgTime * 1000)ms")
}
#endif
```

## Best Practices

### 1. Use for Development Only

Keep tracing disabled in production builds:

```swift
#if DEBUG
let tracer = SpecificationTracer.shared
tracer.startTracing()
// ... trace evaluations ...
let session = tracer.stopTracing()
#endif
```

### 2. Manage Session Lifecycle

Always stop tracing sessions to prevent memory leaks:

```swift
let tracer = SpecificationTracer.shared
tracer.startTracing()

defer {
    _ = tracer.stopTracing()
}

// ... perform traced evaluations ...
```

### 3. Focus on Complex Specifications

Use tracing primarily for debugging complex composite specifications:

```swift
// Good candidate for tracing
let complexRule = userEngaged
    .and(firstWeek.not())
    .and(notCompletedYet)
    .or(forceShowOnboarding)

// Simple specifications may not need tracing
let simpleCheck = MaxCountSpec(counterKey: "attempts", limit: 3)
```

### 4. Monitor Memory Usage

Be mindful of memory usage in long-running trace sessions:

```swift
let tracer = SpecificationTracer.shared
tracer.startTracing()

// Periodically check and clear if needed
if let session = tracer.currentSession, session.entries.count > 10000 {
    _ = tracer.stopTracing()
    tracer.startTracing() // Start fresh session
}
```

## Performance Characteristics

- **Tracing Overhead**: ~10-20% performance impact when active
- **Memory Usage**: O(n) where n is the number of traced evaluations
- **Thread Safety**: Full thread safety for concurrent evaluation
- **Zero Overhead**: No performance impact when disabled

## Important Notes

- Tracing adds significant overhead to specification evaluation
- Use only during development and debugging
- Trace data is stored in memory and lost when the app terminates
- Large trace sessions can consume significant memory

## See Also

- ``Specification`` - The base protocol for all specifications
- ``AnySpecification`` - Type-erased specifications
- ``DefaultContextProvider`` - Context provider for testing
- Performance benchmarking tools and utilities