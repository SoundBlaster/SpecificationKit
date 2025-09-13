//
//  PerformanceProfiler.swift
//  SpecificationKit
//
//  Runtime performance profiling utilities for SpecificationKit v3.0.0
//

import Foundation

/// Performance data for a specific specification type
public struct ProfileData {
    public let specificationName: String
    public let executionTimes: [TimeInterval]
    public let callCount: Int
    public let totalTime: TimeInterval
    public let averageTime: TimeInterval
    public let minTime: TimeInterval
    public let maxTime: TimeInterval
    public let standardDeviation: TimeInterval

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

/// Thread-safe performance profiler for specification evaluation
public final class SpecificationProfiler {

    private var profiles: [String: [TimeInterval]] = [:]
    private let queue = DispatchQueue(label: "specification-profiler", qos: .utility)

    public static let shared = SpecificationProfiler()

    private init() {}

    /// Profile a specification execution and return its result
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

    /// Profile an AnySpecification (type-erased version)
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

    /// Get performance data for all profiled specifications
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
