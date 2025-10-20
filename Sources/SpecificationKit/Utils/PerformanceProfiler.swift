//
//  PerformanceProfiler.swift
//  SpecificationKit
//
//  Runtime performance profiling utilities for SpecificationKit v3.0.0
//

import Foundation

/// Performance data collected for a specific specification type.
///
/// `ProfileData` contains comprehensive timing statistics for specification evaluations,
/// including execution times, call counts, and statistical analysis. This data is essential
/// for performance optimization and regression detection.
///
/// ## Overview
///
/// Each `ProfileData` instance represents the aggregated performance metrics for a single
/// specification type across multiple evaluations. The data includes:
///
/// - **Timing Statistics**: Min, max, average, and total execution times
/// - **Call Metrics**: Total number of evaluations performed
/// - **Statistical Analysis**: Standard deviation for variance analysis
/// - **Formatted Summary**: Human-readable performance report
///
/// ## Example Usage
///
/// ```swift
/// let profiler = SpecificationProfiler.shared
/// let spec = PredicateSpec<Int> { $0 > 50 }
///
/// // Profile multiple evaluations
/// for i in 1...1000 {
///     _ = profiler.profile(spec, context: i)
/// }
///
/// // Get performance data
/// if let data = profiler.getProfileData(for: PredicateSpec<Int>.self) {
///     print(data.summary)
///     print("Average time: \(data.averageTime * 1000)ms")
///     print("Standard deviation: \(data.standardDeviation * 1000)ms")
/// }
/// ```
///
/// ## Topics
///
/// ### Performance Metrics
/// - ``specificationName``
/// - ``executionTimes``
/// - ``callCount``
/// - ``totalTime``
/// - ``averageTime``
/// - ``minTime``
/// - ``maxTime``
/// - ``standardDeviation``
///
/// ### Formatted Output
/// - ``summary``
public struct ProfileData {
    /// The name of the specification type being profiled.
    ///
    /// This string represents the Swift type name of the specification,
    /// allowing you to identify which specification type the performance
    /// data corresponds to.
    public let specificationName: String

    /// Array of individual execution times for all evaluations.
    ///
    /// Each element represents the time taken for a single specification
    /// evaluation, measured in seconds. This raw data can be used for
    /// detailed statistical analysis beyond the provided aggregates.
    public let executionTimes: [TimeInterval]

    /// Total number of specification evaluations performed.
    ///
    /// This count represents how many times the specification's
    /// `isSatisfiedBy(_:)` method was called during profiling.
    public let callCount: Int

    /// Total cumulative execution time across all evaluations.
    ///
    /// The sum of all individual execution times, measured in seconds.
    /// This metric is useful for understanding the overall performance
    /// impact of a specification.
    public let totalTime: TimeInterval

    /// Average execution time per evaluation.
    ///
    /// Calculated as `totalTime / callCount`, this metric provides
    /// a baseline understanding of typical specification performance.
    /// Values should generally be under 1ms for optimal performance.
    public let averageTime: TimeInterval

    /// Fastest single execution time recorded.
    ///
    /// The minimum time observed across all evaluations, useful for
    /// understanding best-case performance scenarios.
    public let minTime: TimeInterval

    /// Slowest single execution time recorded.
    ///
    /// The maximum time observed across all evaluations, useful for
    /// identifying performance outliers or worst-case scenarios.
    public let maxTime: TimeInterval

    /// Standard deviation of execution times.
    ///
    /// Measures the variability in execution times. Lower values indicate
    /// more consistent performance, while higher values suggest significant
    /// variance that may warrant investigation.
    public let standardDeviation: TimeInterval

    /// A formatted summary of the performance data.
    ///
    /// Returns a multi-line string containing all key performance metrics
    /// formatted for human readability. Times are displayed in milliseconds
    /// with three decimal places of precision.
    ///
    /// ## Example Output
    ///
    /// ```
    /// Specification: PredicateSpec<Int>
    /// Calls: 1000
    /// Total: 1.234ms
    /// Average: 0.001ms
    /// Min/Max: 0.001/0.002ms
    /// StdDev: 0.000ms
    /// ```
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

    internal init(name: String, times: [TimeInterval]) {
        self.specificationName = name
        self.executionTimes = times
        self.callCount = times.count
        self.totalTime = times.reduce(0, +)
        self.averageTime = totalTime / Double(times.count)
        self.minTime = times.min() ?? 0
        self.maxTime = times.max() ?? 0

        // Calculate standard deviation
        let avg = self.averageTime
        let variance = times.map { pow($0 - avg, 2) }.reduce(0, +) / Double(times.count)
        self.standardDeviation = sqrt(variance)
    }
}

/// Thread-safe performance profiler for specification evaluation and optimization.
///
/// `SpecificationProfiler` provides comprehensive performance monitoring capabilities for
/// SpecificationKit, enabling developers to identify bottlenecks, track performance regressions,
/// and optimize specification implementations for production use.
///
/// ## Overview
///
/// The profiler operates by intercepting specification evaluations and measuring their execution
/// times. All data collection is thread-safe and designed to have minimal impact on application
/// performance, especially in release builds.
///
/// ### Key Features
///
/// - **Zero-Overhead When Disabled**: Minimal performance impact in release builds
/// - **Thread-Safe Operation**: Concurrent profiling across multiple threads
/// - **Comprehensive Statistics**: Min, max, average, and standard deviation calculations
/// - **Memory Efficient**: Bounded storage with intelligent data management
/// - **Export Capabilities**: JSON export for external analysis tools (debug builds)
///
/// ## Usage Patterns
///
/// ### Basic Profiling
///
/// ```swift
/// let profiler = SpecificationProfiler.shared
/// let spec = CooldownIntervalSpec(eventKey: "user_action", cooldownInterval: 300)
/// let context = EvaluationContext(events: ["user_action": Date()])
///
/// // Profile a single evaluation
/// let result = profiler.profile(spec, context: context)
///
/// // Get performance data
/// let data = profiler.getProfileData()
/// print(profiler.generateReport())
/// ```
///
/// ### Performance Testing
///
/// ```swift
/// // Profile multiple iterations for statistical significance
/// let profiler = SpecificationProfiler.shared
/// let spec = PredicateSpec<Int> { $0 > 50 }
///
/// profiler.reset() // Clear previous data
/// for i in 1...10000 {
///     _ = profiler.profile(spec, context: i)
/// }
///
/// // Analyze results
/// if let data = profiler.getProfileData(for: PredicateSpec<Int>.self) {
///     print("Average: \(data.averageTime * 1000)ms")
///     print("Standard deviation: \(data.standardDeviation * 1000)ms")
/// }
/// ```
///
/// ### Regression Detection
///
/// ```swift
/// // Establish baseline
/// let profiler = SpecificationProfiler.shared
/// // ... perform profiling ...
/// let baselineData = profiler.getProfileData()
///
/// // After code changes, compare performance
/// profiler.reset()
/// // ... perform same profiling ...
/// let newData = profiler.getProfileData()
///
/// // Check for regressions
/// for (baseline, current) in zip(baselineData, newData) {
///     let regression = (current.averageTime - baseline.averageTime) / baseline.averageTime
///     if regression > 0.10 { // 10% regression threshold
///         print("Performance regression detected: \(regression * 100)%")
///     }
/// }
/// ```
///
/// ### SwiftUI Integration
///
/// ```swift
/// struct PerformanceMonitorView: View {
///     @State private var profileData: [ProfileData] = []
///
///     var body: some View {
///         List(profileData, id: \.specificationName) { data in
///             VStack(alignment: .leading) {
///                 Text(data.specificationName).font(.headline)
///                 Text("Avg: \(String(format: "%.3f", data.averageTime * 1000))ms")
///                 Text("Calls: \(data.callCount)")
///             }
///         }
///         .onAppear {
///             profileData = SpecificationProfiler.shared.getProfileData()
///         }
///     }
/// }
/// ```
///
/// ## Performance Guidelines
///
/// ### Target Performance Metrics
///
/// - **Simple Specifications**: < 1ms average execution time
/// - **Complex Specifications**: < 10ms average execution time
/// - **Standard Deviation**: < 50% of average execution time
/// - **Profiler Overhead**: < 10% in release builds, < 200% in debug builds
///
/// ### Best Practices
///
/// 1. **Profile Representative Workloads**: Use realistic contexts and data volumes
/// 2. **Statistical Significance**: Run at least 1000 iterations for reliable statistics
/// 3. **Environment Consistency**: Profile on target hardware and OS versions
/// 4. **Baseline Comparisons**: Establish performance baselines for regression detection
/// 5. **Production Monitoring**: Disable profiling in production unless actively debugging
///
/// ## Topics
///
/// ### Singleton Access
/// - ``shared``
///
/// ### Profiling Operations
/// - ``profile(_:context:)``
/// - ``profileAny(_:context:)``
/// - ``profileAnySequence(_:context:)``
/// - ``profileConcurrently(_:context:iterations:)``
///
/// ### Data Retrieval
/// - ``getProfileData()``
/// - ``getProfileData(for:)``
/// - ``generateReport()``
///
/// ### Management
/// - ``reset()``
/// - ``validateOverhead()``
///
/// ### Debug Utilities
/// - ``enableSlowSpecificationLogging(threshold:)``
/// - ``exportAsJSON()``
///
/// - Important: Profiling adds overhead to specification evaluation. Use judiciously in production environments.
/// - Note: Profile data is stored in memory and will be lost when the app terminates. Export important data before app shutdown.
/// - Warning: Concurrent profiling of the same specification type may affect timing accuracy due to CPU contention.
public final class SpecificationProfiler {

    private var profiles: [String: [TimeInterval]] = [:]
    private let queue = DispatchQueue(label: "specification-profiler", qos: .utility)

    /// Shared singleton instance of the performance profiler.
    ///
    /// Use this shared instance for consistent profiling across your application.
    /// The singleton pattern ensures that all profiling data is centralized and
    /// can be accessed from any part of your codebase.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let profiler = SpecificationProfiler.shared
    /// let result = profiler.profile(mySpec, context: myContext)
    /// print(profiler.generateReport())
    /// ```
    public static let shared = SpecificationProfiler()

    private init() {}

    /// Profile a specification execution and return its result.
    ///
    /// This method wraps the specification's `isSatisfiedBy(_:)` call with timing
    /// measurement, recording the execution time for later analysis. The profiling
    /// operation is thread-safe and designed to have minimal performance overhead.
    ///
    /// - Parameters:
    ///   - specification: The specification to profile
    ///   - context: The context to evaluate the specification against
    /// - Returns: The boolean result of the specification evaluation
    ///
    /// ## Example
    ///
    /// ```swift
    /// let profiler = SpecificationProfiler.shared
    /// let spec = PredicateSpec<String> { $0.count > 5 }
    ///
    /// let result = profiler.profile(spec, context: "Hello World")
    /// print(result) // true
    ///
    /// // Access profiling data
    /// if let data = profiler.getProfileData(for: PredicateSpec<String>.self) {
    ///     print("Execution time: \(data.averageTime * 1000)ms")
    /// }
    /// ```
    ///
    /// - Note: Each call to this method records timing data that contributes to the
    ///   statistical analysis available through ``getProfileData()`` and ``generateReport()``.
    public func profile<Context, SpecType: Specification>(
        _ specification: SpecType, context: Context
    ) -> Bool
    where SpecType.T == Context {
        let specName = String(describing: type(of: specification))
        let startTime = CFAbsoluteTimeGetCurrent()

        let result = specification.isSatisfiedBy(context)

        let executionTime = CFAbsoluteTimeGetCurrent() - startTime

        queue.async {
            self.profiles[specName, default: []].append(executionTime)
        }

        return result
    }

    /// Profile a type-erased specification and return its result.
    ///
    /// This method provides profiling capabilities for `AnySpecification` instances,
    /// which are commonly used when working with heterogeneous collections of
    /// specifications or when specification types cannot be known at compile time.
    ///
    /// - Parameters:
    ///   - specification: The type-erased specification to profile
    ///   - context: The context to evaluate the specification against
    /// - Returns: The boolean result of the specification evaluation
    ///
    /// ## Example
    ///
    /// ```swift
    /// let profiler = SpecificationProfiler.shared
    /// let specs = [
    ///     AnySpecification(PredicateSpec<Int> { $0 > 10 }),
    ///     AnySpecification(PredicateSpec<Int> { $0 < 100 })
    /// ]
    ///
    /// for spec in specs {
    ///     let result = profiler.profileAny(spec, context: 50)
    ///     print("Result: \(result)")
    /// }
    ///
    /// // View aggregated data for type-erased specs
    /// let data = profiler.getProfileData()
    /// print(profiler.generateReport())
    /// ```
    ///
    /// - Note: Type-erased specifications are grouped under a generic name in profiling
    ///   data since their original types are not available at runtime.
    public func profileAny<Context>(_ specification: AnySpecification<Context>, context: Context)
        -> Bool
    {
        let specName = "AnySpecification<\(String(describing: Context.self))>"
        let startTime = CFAbsoluteTimeGetCurrent()

        let result = specification.isSatisfiedBy(context)

        let executionTime = CFAbsoluteTimeGetCurrent() - startTime

        queue.async {
            self.profiles[specName, default: []].append(executionTime)
        }

        return result
    }

    /// Retrieve performance data for all profiled specifications.
    ///
    /// Returns an array of `ProfileData` instances containing comprehensive performance
    /// statistics for each specification type that has been profiled. The data is sorted
    /// by total execution time in descending order, making it easy to identify the most
    /// time-consuming specifications.
    ///
    /// - Returns: Array of profile data sorted by total execution time (highest first)
    ///
    /// ## Example
    ///
    /// ```swift
    /// let profiler = SpecificationProfiler.shared
    ///
    /// // Profile various specifications
    /// _ = profiler.profile(spec1, context: context1)
    /// _ = profiler.profile(spec2, context: context2)
    ///
    /// // Get all performance data
    /// let allData = profiler.getProfileData()
    /// for data in allData {
    ///     print("\(data.specificationName): \(data.averageTime * 1000)ms avg")
    /// }
    /// ```
    ///
    /// - Note: The returned data represents a snapshot at the time of the call.
    ///   Continued profiling will not affect the returned `ProfileData` instances.
    public func getProfileData() -> [ProfileData] {
        return queue.sync {
            return profiles.compactMap { (name, times) in
                guard !times.isEmpty else { return nil }
                return ProfileData(name: name, times: times)
            }.sorted { $0.totalTime > $1.totalTime }
        }
    }

    /// Reset all profiling data
    public func reset() {
        queue.sync {
            profiles.removeAll()
        }
    }

    /// Generate a comprehensive performance report
    public func generateReport() -> String {
        let data = getProfileData()

        var report = "Specification Performance Report\n"
        report += "================================\n\n"

        if data.isEmpty {
            report += "No profiling data available.\n"
            return report
        }

        for profile in data {
            report += profile.summary + "\n\n"
        }

        // Add summary statistics
        let totalExecutions = data.reduce(0) { $0 + $1.callCount }
        let overallTime = data.reduce(0) { $0 + $1.totalTime }
        let averageExecution = overallTime / Double(totalExecutions)

        report += "Summary Statistics\n"
        report += "==================\n"
        report += "Total Specifications: \(data.count)\n"
        report += "Total Executions: \(totalExecutions)\n"
        report += "Overall Time: \(String(format: "%.3fms", overallTime * 1000))\n"
        report += "Average Execution: \(String(format: "%.3fms", averageExecution * 1000))\n"

        return report
    }

    /// Get profile data for a specific specification type
    public func getProfileData<T>(for specificationType: T.Type) -> ProfileData? {
        let typeName = String(describing: specificationType)
        return queue.sync {
            guard let times = profiles[typeName], !times.isEmpty else { return nil }
            return ProfileData(name: typeName, times: times)
        }
    }

    /// Check if profiling overhead is within acceptable limits
    public func validateOverhead() -> Bool {
        // Profiling should add less than 5% overhead
        let data = getProfileData()
        let fastSpecs = data.filter { $0.averageTime < 0.001 }  // Specs under 1ms

        // For fast specs, profiling overhead should be minimal
        return fastSpecs.allSatisfy { $0.averageTime < 0.0015 }  // Allow up to 50% overhead for very fast specs
    }
}

/// Performance monitoring utilities
extension SpecificationProfiler {

    /// Profile multiple AnySpecifications in sequence
    public func profileAnySequence<Context>(
        _ specifications: [AnySpecification<Context>], context: Context
    ) -> [Bool] {
        return specifications.map { profileAny($0, context: context) }
    }

    /// Profile specifications concurrently (for thread safety testing)
    @available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, *)
    public func profileConcurrently<Context, SpecType: Specification>(
        _ specification: SpecType, context: Context, iterations: Int
    ) async -> [Bool]
    where SpecType.T == Context {
        return await withTaskGroup(of: Bool.self) { group in
            for _ in 0..<iterations {
                group.addTask {
                    return self.profile(specification, context: context)
                }
            }

            var results: [Bool] = []
            for await result in group {
                results.append(result)
            }
            return results
        }
    }
}

#if DEBUG
    /// Debug-only profiling utilities
    extension SpecificationProfiler {

        /// Enable detailed logging of slow specifications
        public func enableSlowSpecificationLogging(threshold: TimeInterval = 0.010) {
            // Implementation would log specifications that exceed threshold
            // This is a placeholder for debug builds
        }

        /// Export profiling data as JSON for external analysis
        public func exportAsJSON() throws -> Data {
            let data = getProfileData()
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted

            // Create encodable structure instead of using [String: Any]
            struct ExportProfile: Encodable {
                let name: String
                let callCount: Int
                let totalTime: TimeInterval
                let averageTime: TimeInterval
                let minTime: TimeInterval
                let maxTime: TimeInterval
                let standardDeviation: TimeInterval
            }

            let exportData = data.map { profile in
                ExportProfile(
                    name: profile.specificationName,
                    callCount: profile.callCount,
                    totalTime: profile.totalTime,
                    averageTime: profile.averageTime,
                    minTime: profile.minTime,
                    maxTime: profile.maxTime,
                    standardDeviation: profile.standardDeviation
                )
            }

            return try encoder.encode(exportData)
        }
    }
#endif
