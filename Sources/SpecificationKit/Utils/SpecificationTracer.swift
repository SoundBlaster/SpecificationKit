//
//  SpecificationTracer.swift
//  SpecificationKit
//
//  Specification execution tracing and debugging utilities for SpecificationKit v3.0.0
//

import Darwin
import Foundation

/// A comprehensive execution trace for specification evaluations.
///
/// `SpecificationTracer` provides detailed debugging and analysis capabilities for specification
/// executions, allowing developers to understand complex specification behavior, identify
/// bottlenecks, and debug logical issues in composite specifications.
///
/// ## Overview
///
/// The tracer captures detailed information about each specification evaluation, including:
/// - Execution hierarchy and nesting relationships
/// - Timing information for performance analysis
/// - Input contexts and output results
/// - Metadata for custom analysis
///
/// ### Key Features
///
/// - **Hierarchical Tracing**: Captures nested specification evaluations with parent-child relationships
/// - **Performance Monitoring**: Precise timing measurements for each evaluation
/// - **Visual Representation**: Tree-based visualization and DOT graph generation
/// - **Thread-Safe Operation**: Concurrent tracing across multiple threads
/// - **Zero-Overhead When Disabled**: Minimal performance impact when not actively tracing
///
/// ## Usage Patterns
///
/// ### Basic Tracing
///
/// ```swift
/// let tracer = SpecificationTracer.shared
/// let sessionId = tracer.startTracing()
///
/// let spec = CooldownIntervalSpec(eventKey: "user_action", cooldownInterval: 300)
/// let context = EvaluationContext(events: ["user_action": Date()])
///
/// // Traced evaluation
/// let result = tracer.trace(specification: spec, context: context)
///
/// if let session = tracer.stopTracing() {
///     print("Traced \(session.entries.count) evaluations")
///     print("Total time: \(session.totalExecutionTime * 1000)ms")
///
///     // Print execution tree
///     for tree in session.traceTree {
///         tree.printTree()
///     }
/// }
/// ```
///
/// ### Composite Specification Debugging
///
/// ```swift
/// let tracer = SpecificationTracer.shared
/// tracer.startTracing()
///
/// let complexSpec = spec1.and(spec2).or(spec3.not())
/// let result = tracer.trace(specification: complexSpec, context: context)
///
/// if let session = tracer.stopTracing() {
///     // Analyze which branch was taken
///     session.traceTree.forEach { $0.printTree() }
///
///     // Generate visual graph
///     let dotGraph = session.traceTree.first?.generateDotGraph()
///     print(dotGraph ?? "No trace data")
/// }
/// ```
///
/// ### Performance Analysis Integration
///
/// ```swift
/// let tracer = SpecificationTracer.shared
/// tracer.startTracing()
///
/// // Run specifications
/// for i in 1...1000 {
///     let result = tracer.trace(specification: mySpec, context: contexts[i])
/// }
///
/// if let session = tracer.stopTracing() {
///     let slowExecutions = session.entries.filter { $0.executionTime > 0.001 }
///     print("Found \(slowExecutions.count) slow executions")
///
///     // Identify performance bottlenecks
///     let groupedBySpec = Dictionary(grouping: session.entries) { $0.specification }
///     for (spec, entries) in groupedBySpec {
///         let avgTime = entries.map(\.executionTime).reduce(0, +) / Double(entries.count)
///         print("\(spec): \(avgTime * 1000)ms average")
///     }
/// }
/// ```
///
/// ## Topics
///
/// ### Core Data Types
/// - ``TraceEntry``
/// - ``TraceSession``
/// - ``TraceNode``
///
/// ### Singleton Access
/// - ``shared``
///
/// ### Session Management
/// - ``startTracing()``
/// - ``stopTracing()``
/// - ``isTracing``
///
/// ### Tracing Operations
/// - ``trace(specification:context:parentId:depth:)``
/// - ``traceComposite(_:left:right:context:parentId:depth:)``
/// - ``traceWithMetadata(specification:context:metadata:parentId:depth:)``
///
/// ### Tree Visualization
/// - ``buildTraceTree(from:)``
///
/// - Important: Tracing adds significant overhead to specification evaluation. Use only during development and debugging.
/// - Note: Trace data is stored in memory and will be lost when the app terminates.
/// - Warning: Large trace sessions can consume significant memory. Monitor session size in long-running traces.
public final class SpecificationTracer {

    /// Individual trace entry capturing a single specification evaluation.
    ///
    /// Each `TraceEntry` represents one evaluation of a specification, containing
    /// comprehensive information about the execution context, results, and timing.
    /// Entries are linked together through parent-child relationships to form
    /// execution trees that represent complex specification evaluations.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let entry = TraceEntry(
    ///     specification: "PredicateSpec<Int>",
    ///     context: "42",
    ///     result: "true",
    ///     executionTime: 0.001,
    ///     depth: 0,
    ///     parentId: nil,
    ///     metadata: ["input_range": "0-100"]
    /// )
    /// ```
    public struct TraceEntry {
        /// Unique identifier for this trace entry.
        public let id: UUID

        /// String representation of the specification type being traced.
        public let specification: String

        /// String representation of the evaluation context.
        public let context: String

        /// String representation of the evaluation result.
        public let result: String

        /// Execution time in seconds for this evaluation.
        public let executionTime: TimeInterval

        /// Nesting depth in the evaluation hierarchy (0 = root level).
        public let depth: Int

        /// ID of the parent trace entry, if this is a nested evaluation.
        public let parentId: UUID?

        /// Timestamp when this evaluation was performed.
        public let timestamp: Date

        /// Additional metadata for custom analysis.
        public let metadata: [String: Any]

        /// Create a new trace entry with the specified parameters.
        ///
        /// - Parameters:
        ///   - specification: String representation of the specification type
        ///   - context: String representation of the evaluation context
        ///   - result: String representation of the evaluation result
        ///   - executionTime: Execution time in seconds
        ///   - depth: Nesting depth (0 = root level)
        ///   - parentId: Optional parent trace entry ID
        ///   - metadata: Additional metadata for analysis
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

        /// Create a new trace entry with a specific ID.
        ///
        /// This initializer is used internally for composite specifications
        /// that need to maintain consistent parent-child relationships.
        internal init(
            id: UUID,
            specification: String,
            context: String,
            result: String,
            executionTime: TimeInterval,
            depth: Int,
            parentId: UUID? = nil,
            metadata: [String: Any] = [:]
        ) {
            self.id = id
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

    /// Complete trace session containing all recorded evaluations.
    ///
    /// A `TraceSession` represents a bounded period of specification tracing,
    /// capturing all evaluations that occurred between `startTracing()` and
    /// `stopTracing()` calls. The session provides both raw entry data and
    /// processed tree structures for analysis.
    public struct TraceSession {
        /// Unique identifier for this trace session.
        public let id: UUID

        /// Timestamp when tracing was started.
        public let startTime: Date

        /// All trace entries recorded during this session.
        public var entries: [TraceEntry]

        /// Whether this session is currently active.
        public var isActive: Bool

        /// Total execution time across all traced evaluations.
        public var totalExecutionTime: TimeInterval {
            entries.map(\.executionTime).reduce(0, +)
        }

        /// Hierarchical tree representation of all trace entries.
        ///
        /// The trace tree organizes entries into a hierarchical structure based
        /// on parent-child relationships, making it easy to understand the
        /// evaluation flow of complex composite specifications.
        ///
        /// Root-level nodes represent top-level specification evaluations,
        /// while child nodes represent nested evaluations within composite
        /// specifications.
        public var traceTree: [TraceNode] {
            SpecificationTracer.buildTraceTree(from: entries)
        }

        internal init(id: UUID, startTime: Date, entries: [TraceEntry] = [], isActive: Bool = true)
        {
            self.id = id
            self.startTime = startTime
            self.entries = entries
            self.isActive = isActive
        }
    }

    /// Tree node representing a specification evaluation with its nested children.
    ///
    /// `TraceNode` provides hierarchical organization of trace entries, enabling
    /// tree-based visualization and analysis of complex specification evaluations.
    /// Each node contains a trace entry and references to any child evaluations
    /// that occurred within its scope.
    public struct TraceNode {
        /// The trace entry data for this node.
        public let entry: TraceEntry

        /// Child nodes representing nested evaluations.
        public let children: [TraceNode]

        /// Print a textual tree representation to the console.
        ///
        /// Outputs a hierarchical ASCII tree showing the evaluation structure,
        /// timing information, and results. This is useful for quick debugging
        /// and understanding specification execution flow.
        ///
        /// - Parameter indent: Base indentation string (used internally for recursion)
        ///
        /// ## Example Output
        ///
        /// ```
        /// ├─ AndSpecification → true (1.234ms)
        /// │  ├─ PredicateSpec<Int> → true (0.567ms)
        /// │  └─ CooldownIntervalSpec → true (0.667ms)
        /// ```
        public func printTree(indent: String = "") {
            let duration = String(format: "%.3fms", entry.executionTime * 1000)
            print("\(indent)├─ \(entry.specification) → \(entry.result) (\(duration))")

            for (index, child) in children.enumerated() {
                let isLast = index == children.count - 1
                let childIndent = indent + (isLast ? "   " : "│  ")
                child.printTree(indent: childIndent)
            }
        }

        /// Generate a DOT graph representation for visualization.
        ///
        /// Creates a DOT language graph definition that can be rendered using
        /// Graphviz or other DOT-compatible visualization tools. This provides
        /// a visual representation of the specification evaluation tree.
        ///
        /// - Returns: DOT graph definition as a string
        ///
        /// ## Example
        ///
        /// ```swift
        /// let dotGraph = traceNode.generateDotGraph()
        /// try dotGraph.write(to: URL(fileURLWithPath: "trace.dot"))
        /// // Render with: dot -Tpng trace.dot -o trace.png
        /// ```
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

    // MARK: - Private Properties

    private var currentSession: TraceSession?
    private var isEnabled: Bool = false
    private let queue = DispatchQueue(label: "specification-tracer", qos: .utility)

    // Static timing properties for high-precision measurement
    private static var timebaseInfo = mach_timebase_info_data_t()
    private static let initializeTimebase: () = {
        mach_timebase_info(&timebaseInfo)
    }()

    /// Shared singleton instance of the specification tracer.
    ///
    /// Use this shared instance for consistent tracing across your application.
    /// The singleton pattern ensures that trace sessions are centralized and
    /// can be managed from any part of your codebase.
    public static let shared = SpecificationTracer()

    private init() {}

    // MARK: - Private Helpers

    /// Convert mach time to seconds for high-precision timing
    private static func machTimeToSeconds(_ machTime: UInt64) -> TimeInterval {
        _ = initializeTimebase  // Ensure timebase is initialized

        let nanoseconds = machTime * UInt64(timebaseInfo.numer) / UInt64(timebaseInfo.denom)
        return TimeInterval(nanoseconds) / 1_000_000_000.0
    }

    // MARK: - Public API

    /// Whether tracing is currently active.
    ///
    /// Returns `true` if a trace session is currently running and collecting
    /// evaluation data, `false` otherwise.
    public var isTracing: Bool {
        queue.sync { isEnabled && currentSession?.isActive == true }
    }

    /// Start a new trace session.
    ///
    /// Begins collecting trace data for specification evaluations. Only one
    /// session can be active at a time; calling this method while a session
    /// is already active will terminate the existing session and start a new one.
    ///
    /// - Returns: Unique identifier for the new trace session
    ///
    /// ## Example
    ///
    /// ```swift
    /// let tracer = SpecificationTracer.shared
    /// let sessionId = tracer.startTracing()
    ///
    /// // Perform traced evaluations...
    ///
    /// if let session = tracer.stopTracing() {
    ///     print("Session \(sessionId) captured \(session.entries.count) evaluations")
    /// }
    /// ```
    @discardableResult
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

    /// Stop the current trace session and return collected data.
    ///
    /// Ends the active trace session and returns all collected trace data.
    /// If no session is currently active, returns `nil`.
    ///
    /// - Returns: The completed trace session, or `nil` if no session was active
    ///
    /// ## Example
    ///
    /// ```swift
    /// let tracer = SpecificationTracer.shared
    /// tracer.startTracing()
    ///
    /// // Perform evaluations...
    ///
    /// if let session = tracer.stopTracing() {
    ///     print("Captured \(session.entries.count) evaluations")
    ///     print("Total time: \(session.totalExecutionTime * 1000)ms")
    ///
    ///     // Analyze trace tree
    ///     for tree in session.traceTree {
    ///         tree.printTree()
    ///     }
    /// }
    /// ```
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

    /// Trace a specification evaluation with detailed timing and context capture.
    ///
    /// This method wraps a specification evaluation with comprehensive tracing,
    /// recording execution time, context information, results, and hierarchical
    /// relationships. If no trace session is active, the evaluation proceeds
    /// normally without tracing overhead.
    ///
    /// - Parameters:
    ///   - specification: The specification to evaluate and trace
    ///   - context: The context to evaluate against
    ///   - parentId: Optional parent trace entry ID for nested evaluations
    ///   - depth: Nesting depth in the evaluation hierarchy
    /// - Returns: The boolean result of the specification evaluation
    ///
    /// ## Example
    ///
    /// ```swift
    /// let tracer = SpecificationTracer.shared
    /// tracer.startTracing()
    ///
    /// let spec = PredicateSpec<Int> { $0 > 50 }
    /// let result = tracer.trace(specification: spec, context: 75)
    ///
    /// print(result) // true
    ///
    /// // Trace data is automatically captured
    /// if let session = tracer.stopTracing() {
    ///     print("Execution time: \(session.entries.first?.executionTime ?? 0)ms")
    /// }
    /// ```
    public func trace<Context, SpecType: Specification>(
        specification: SpecType,
        context: Context,
        parentId: UUID? = nil,
        depth: Int = 0
    ) -> Bool where SpecType.T == Context {
        guard isEnabled, currentSession != nil else {
            return specification.isSatisfiedBy(context)
        }

        let startTime = mach_absolute_time()
        let result = specification.isSatisfiedBy(context)
        let endTime = mach_absolute_time()

        let executionTime = Self.machTimeToSeconds(endTime - startTime)

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

    /// Trace a specification evaluation with custom metadata.
    ///
    /// Similar to the standard trace method, but allows adding custom metadata
    /// for specialized analysis and debugging scenarios.
    ///
    /// - Parameters:
    ///   - specification: The specification to evaluate and trace
    ///   - context: The context to evaluate against
    ///   - metadata: Additional metadata to include in the trace entry
    ///   - parentId: Optional parent trace entry ID for nested evaluations
    ///   - depth: Nesting depth in the evaluation hierarchy
    /// - Returns: The boolean result of the specification evaluation
    public func traceWithMetadata<Context, SpecType: Specification>(
        specification: SpecType,
        context: Context,
        metadata: [String: Any],
        parentId: UUID? = nil,
        depth: Int = 0
    ) -> Bool where SpecType.T == Context {
        guard isEnabled, currentSession != nil else {
            return specification.isSatisfiedBy(context)
        }

        let startTime = mach_absolute_time()
        let result = specification.isSatisfiedBy(context)
        let endTime = mach_absolute_time()

        let executionTime = Self.machTimeToSeconds(endTime - startTime)

        let entry = TraceEntry(
            specification: String(describing: type(of: specification)),
            context: String(describing: context),
            result: String(describing: result),
            executionTime: executionTime,
            depth: depth,
            parentId: parentId,
            metadata: metadata
        )

        queue.async {
            self.currentSession?.entries.append(entry)
        }

        return result
    }

    // MARK: - Composite Specification Support

    /// Trace composite specification evaluations with short-circuit detection.
    ///
    /// This specialized method traces logical operations (AND, OR) between
    /// specifications, including detection of short-circuit evaluation where
    /// the second operand is not evaluated due to the first operand's result.
    ///
    /// - Parameters:
    ///   - operation: The logical operation being performed ("AND" or "OR")
    ///   - left: The left operand specification
    ///   - right: The right operand specification
    ///   - context: The evaluation context
    ///   - parentId: Optional parent trace entry ID
    ///   - depth: Nesting depth in the evaluation hierarchy
    /// - Returns: The boolean result of the composite evaluation
    ///
    /// ## Example
    ///
    /// ```swift
    /// let tracer = SpecificationTracer.shared
    /// tracer.startTracing()
    ///
    /// let spec1 = PredicateSpec<Int> { $0 > 50 }
    /// let spec2 = PredicateSpec<Int> { $0 < 100 }
    ///
    /// let result = tracer.traceComposite(
    ///     "AND",
    ///     left: spec1,
    ///     right: spec2,
    ///     context: 25
    /// )
    ///
    /// // Will show short-circuit behavior since spec1 returns false
    /// if let session = tracer.stopTracing() {
    ///     session.traceTree.forEach { $0.printTree() }
    /// }
    /// ```
    public func traceComposite<Context, LeftSpec: Specification, RightSpec: Specification>(
        _ operation: String,
        left: LeftSpec,
        right: RightSpec,
        context: Context,
        parentId: UUID? = nil,
        depth: Int = 0
    ) -> Bool where LeftSpec.T == Context, RightSpec.T == Context {
        let compositeId = UUID()
        let startTime = mach_absolute_time()

        // Trace left specification
        let leftResult = trace(
            specification: left,
            context: context,
            parentId: compositeId,
            depth: depth + 1
        )

        // For AND operations, short-circuit if left is false
        if operation == "AND" && !leftResult {
            let endTime = mach_absolute_time()
            let executionTime = Self.machTimeToSeconds(endTime - startTime)
            recordCompositeEntry(
                compositeId: compositeId,
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
            let endTime = mach_absolute_time()
            let executionTime = Self.machTimeToSeconds(endTime - startTime)
            recordCompositeEntry(
                compositeId: compositeId,
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

        let finalResult =
            operation == "AND" ? (leftResult && rightResult) : (leftResult || rightResult)
        let endTime = mach_absolute_time()
        let executionTime = Self.machTimeToSeconds(endTime - startTime)

        recordCompositeEntry(
            compositeId: compositeId,
            operation: operation,
            result: finalResult,
            executionTime: executionTime,
            parentId: parentId,
            depth: depth,
            shortCircuited: false
        )

        return finalResult
    }

    // MARK: - Private Methods

    private func recordCompositeEntry(
        compositeId: UUID,
        operation: String,
        result: Bool,
        executionTime: TimeInterval,
        parentId: UUID?,
        depth: Int,
        shortCircuited: Bool
    ) {
        guard isEnabled else { return }

        let metadata: [String: Any] = [
            "operation": operation,
            "short_circuited": shortCircuited,
        ]

        let entry = TraceEntry(
            id: compositeId,
            specification: "\(operation)Specification",
            context: "composite",
            result: String(describing: result),
            executionTime: executionTime,
            depth: depth,
            parentId: parentId,
            metadata: metadata
        )

        queue.async {
            self.currentSession?.entries.append(entry)
        }
    }

    /// Build hierarchical trace tree from flat entry list.
    ///
    /// Converts the flat list of trace entries into a hierarchical tree structure
    /// based on parent-child relationships. Root nodes represent top-level
    /// evaluations, while child nodes represent nested evaluations.
    ///
    /// - Parameter entries: Flat list of trace entries
    /// - Returns: Array of root-level trace nodes
    public static func buildTraceTree(from entries: [TraceEntry]) -> [TraceNode] {
        let rootEntries = entries.filter { $0.parentId == nil }

        func buildNode(for entry: TraceEntry) -> TraceNode {
            let children =
                entries
                .filter { $0.parentId == entry.id }
                .sorted { $0.timestamp < $1.timestamp }
                .map(buildNode)

            return TraceNode(entry: entry, children: children)
        }

        return
            rootEntries
            .sorted { $0.timestamp < $1.timestamp }
            .map(buildNode)
    }
}

// MARK: - Integration Extensions

extension SpecificationTracer {
    /// Trace any specification (type-erased)
    public func traceAny<Context>(
        specification: AnySpecification<Context>,
        context: Context,
        parentId: UUID? = nil,
        depth: Int = 0
    ) -> Bool {
        guard isEnabled, currentSession != nil else {
            return specification.isSatisfiedBy(context)
        }

        let startTime = mach_absolute_time()
        let result = specification.isSatisfiedBy(context)
        let endTime = mach_absolute_time()

        let executionTime = Self.machTimeToSeconds(endTime - startTime)

        let entry = TraceEntry(
            specification: "AnySpecification<\(String(describing: Context.self))>",
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

#if DEBUG
    // MARK: - Debug Extensions

    extension SpecificationTracer {
        /// Export trace session as JSON for external analysis
        public func exportSession(_ session: TraceSession) throws -> Data {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            encoder.dateEncodingStrategy = .iso8601

            struct ExportEntry: Codable {
                let id: String
                let specification: String
                let context: String
                let result: String
                let executionTime: TimeInterval
                let depth: Int
                let parentId: String?
                let timestamp: Date
            }

            let exportEntries = session.entries.map { entry in
                ExportEntry(
                    id: entry.id.uuidString,
                    specification: entry.specification,
                    context: entry.context,
                    result: entry.result,
                    executionTime: entry.executionTime,
                    depth: entry.depth,
                    parentId: entry.parentId?.uuidString,
                    timestamp: entry.timestamp
                )
            }

            return try encoder.encode(exportEntries)
        }

        /// Generate comprehensive analysis report
        public func generateAnalysisReport(_ session: TraceSession) -> String {
            var report = "Specification Trace Analysis\n"
            report += "============================\n\n"

            report += "Session Information:\n"
            report += "  ID: \(session.id)\n"
            report += "  Start Time: \(session.startTime)\n"
            report += "  Total Entries: \(session.entries.count)\n"
            report +=
                "  Total Time: \(String(format: "%.3fms", session.totalExecutionTime * 1000))\n\n"

            // Group by specification type
            let grouped = Dictionary(grouping: session.entries) { $0.specification }

            report += "Specification Breakdown:\n"
            for (spec, entries) in grouped.sorted(by: { $0.key < $1.key }) {
                let totalTime = entries.map(\.executionTime).reduce(0, +)
                let avgTime = totalTime / Double(entries.count)
                let maxTime = entries.map(\.executionTime).max() ?? 0

                report += "  \(spec):\n"
                report += "    Calls: \(entries.count)\n"
                report += "    Total: \(String(format: "%.3fms", totalTime * 1000))\n"
                report += "    Average: \(String(format: "%.3fms", avgTime * 1000))\n"
                report += "    Max: \(String(format: "%.3fms", maxTime * 1000))\n\n"
            }

            // Identify slow evaluations
            let slowThreshold: TimeInterval = 0.010  // 10ms
            let slowEntries = session.entries.filter { $0.executionTime > slowThreshold }

            if !slowEntries.isEmpty {
                report += "Slow Evaluations (>\(slowThreshold * 1000)ms):\n"
                for entry in slowEntries.sorted(by: { $0.executionTime > $1.executionTime }) {
                    report +=
                        "  \(entry.specification): \(String(format: "%.3fms", entry.executionTime * 1000))\n"
                }
                report += "\n"
            }

            return report
        }
    }
#endif
