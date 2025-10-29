//
//  BenchmarkValidation.swift
//  SpecificationKitTests
//
//  Benchmark result validation and regression detection for SpecificationKit v3.0.0
//

import Foundation
import XCTest

@testable import SpecificationKit

/// Benchmark result with environment metadata
struct BenchmarkResult: Codable {
    let testName: String
    let executionTime: TimeInterval
    let memoryUsage: Int64
    let timestamp: Date
    let environment: TestEnvironment
    let iterations: Int
    let standardDeviation: TimeInterval?

    init(
        testName: String, executionTime: TimeInterval, memoryUsage: Int64 = 0, iterations: Int = 1,
        standardDeviation: TimeInterval? = nil
    ) {
        self.testName = testName
        self.executionTime = executionTime
        self.memoryUsage = memoryUsage
        self.timestamp = Date()
        self.environment = TestEnvironment.current
        self.iterations = iterations
        self.standardDeviation = standardDeviation
    }
}

/// Test environment metadata for benchmark comparison
struct TestEnvironment: Codable {
    let platform: String
    let osVersion: String
    let deviceModel: String
    let swiftVersion: String
    let buildConfiguration: String

    static var current: TestEnvironment {
        return TestEnvironment(
            platform: getCurrentPlatform(),
            osVersion: ProcessInfo.processInfo.operatingSystemVersionString,
            deviceModel: getDeviceModel(),
            swiftVersion: getSwiftVersion(),
            buildConfiguration: getBuildConfiguration()
        )
    }

    private static func getCurrentPlatform() -> String {
        #if os(iOS)
            return "iOS"
        #elseif os(macOS)
            return "macOS"
        #elseif os(watchOS)
            return "watchOS"
        #elseif os(tvOS)
            return "tvOS"
        #else
            return "Unknown"
        #endif
    }

    private static func getDeviceModel() -> String {
        #if os(iOS) || os(tvOS)
            var systemInfo = utsname()
            uname(&systemInfo)
            return withUnsafePointer(to: &systemInfo.machine) {
                $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                    String(validatingUTF8: $0) ?? "Unknown"
                }
            }
        #elseif os(macOS)
            let service = IOServiceGetMatchingService(
                kIOMainPortDefault, IOServiceMatching("IOPlatformExpertDevice"))
            var modelIdentifier: String? = nil
            if let modelData = IORegistryEntryCreateCFProperty(
                service, "model" as CFString, kCFAllocatorDefault, 0
            ).takeRetainedValue() as? Data {
                modelIdentifier = String(data: modelData, encoding: .utf8)?.trimmingCharacters(
                    in: .controlCharacters)
            }
            IOObjectRelease(service)
            return modelIdentifier ?? "Unknown Mac"
        #else
            return "Unknown"
        #endif
    }

    private static func getSwiftVersion() -> String {
        #if swift(>=6.0)
            return "6.0+"
        #elseif swift(>=5.10)
            return "5.10"
        #elseif swift(>=5.9)
            return "5.9"
        #else
            return "5.x"
        #endif
    }

    private static func getBuildConfiguration() -> String {
        #if DEBUG
            return "Debug"
        #else
            return "Release"
        #endif
    }
}

/// Benchmark storage and regression detection system
class BenchmarkStorage {
    private let fileManager = FileManager.default
    private let storageDirectory: URL

    init() {
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.storageDirectory = documentsPath.appendingPathComponent("SpecificationKitBenchmarks")

        try? fileManager.createDirectory(at: storageDirectory, withIntermediateDirectories: true)
    }

    /// Initialize with custom directory (for testing)
    init(storageDirectory: URL) {
        self.storageDirectory = storageDirectory
        try? fileManager.createDirectory(at: storageDirectory, withIntermediateDirectories: true)
    }

    /// Store a benchmark result
    func storeBenchmark(_ result: BenchmarkResult) {
        let filename = "\(result.testName)_\(result.timestamp.timeIntervalSince1970).json"
        let url = storageDirectory.appendingPathComponent(filename)

        do {
            let data = try JSONEncoder().encode(result)
            try data.write(to: url)
        } catch {
            print("Failed to store benchmark result: \(error)")
            // Re-throw in test environments to make failures visible
            #if DEBUG
                if ProcessInfo.processInfo.environment["XCTestSessionIdentifier"] != nil {
                    fatalError("Benchmark storage failed in test environment: \(error)")
                }
            #endif
        }
    }

    /// Load historical benchmark results for a specific test
    func loadBenchmarks(for testName: String) -> [BenchmarkResult] {
        do {
            let files = try fileManager.contentsOfDirectory(
                at: storageDirectory, includingPropertiesForKeys: nil)
            let matchingFiles = files.filter { $0.lastPathComponent.hasPrefix(testName) }

            return matchingFiles.compactMap { url in
                guard let data = try? Data(contentsOf: url),
                    let result = try? JSONDecoder().decode(BenchmarkResult.self, from: data)
                else {
                    return nil
                }
                return result
            }.sorted { $0.timestamp > $1.timestamp }
        } catch {
            print("Failed to load benchmark results: \(error)")
            return []
        }
    }

    /// Detect performance regressions based on historical data
    func detectRegressions(
        for testName: String, currentResult: BenchmarkResult, threshold: Double = 0.15
    ) -> [RegressionAlert] {
        let historicalResults = loadBenchmarks(for: testName)
        guard historicalResults.count >= 3 else { return [] }

        // Use the last 5 results for baseline calculation
        let recentResults = Array(historicalResults.prefix(5))
        let baselineTime =
            recentResults.map(\.executionTime).reduce(0, +) / Double(recentResults.count)
        let baselineMemory =
            recentResults.map(\.memoryUsage).reduce(0, +) / Int64(recentResults.count)

        var alerts: [RegressionAlert] = []

        // Check execution time regression
        let timeIncrease = (currentResult.executionTime - baselineTime) / baselineTime
        if timeIncrease > threshold {
            alerts.append(
                RegressionAlert(
                    type: .executionTime,
                    testName: testName,
                    baselineValue: baselineTime,
                    currentValue: currentResult.executionTime,
                    regressionPercent: timeIncrease * 100
                ))
        }

        // Check memory usage regression
        if currentResult.memoryUsage > 0 && baselineMemory > 0 {
            let memoryIncrease =
                Double(currentResult.memoryUsage - baselineMemory) / Double(baselineMemory)
            if memoryIncrease > threshold {
                alerts.append(
                    RegressionAlert(
                        type: .memoryUsage,
                        testName: testName,
                        baselineValue: Double(baselineMemory),
                        currentValue: Double(currentResult.memoryUsage),
                        regressionPercent: memoryIncrease * 100
                    ))
            }
        }

        return alerts
    }

    /// Generate a performance trend report
    func generateTrendReport(for testName: String) -> String {
        let results = loadBenchmarks(for: testName)
        guard results.count > 1 else {
            return "Insufficient data for trend analysis"
        }

        let sortedResults = results.sorted { $0.timestamp < $1.timestamp }

        var report = "Performance Trend Report for \(testName)\n"
        report += "==========================================\n\n"

        // Calculate trend
        let firstResult = sortedResults.first!
        let lastResult = sortedResults.last!
        let timespan = lastResult.timestamp.timeIntervalSince(firstResult.timestamp)
        let timeChange = lastResult.executionTime - firstResult.executionTime
        let timeChangePercent = (timeChange / firstResult.executionTime) * 100

        report += "Time Range: \(firstResult.timestamp) to \(lastResult.timestamp)\n"
        report += "Duration: \(String(format: "%.1f", timespan / 86400)) days\n"
        report += "Samples: \(results.count)\n\n"

        report += "Execution Time Trend:\n"
        report += "Initial: \(String(format: "%.3fms", firstResult.executionTime * 1000))\n"
        report += "Latest: \(String(format: "%.3fms", lastResult.executionTime * 1000))\n"
        report += "Change: \(String(format: "%.2f%%", timeChangePercent))\n\n"

        // Recent performance stats
        let recentResults = Array(sortedResults.suffix(10))
        let avgRecent =
            recentResults.map(\.executionTime).reduce(0, +) / Double(recentResults.count)
        let minRecent = recentResults.map(\.executionTime).min() ?? 0
        let maxRecent = recentResults.map(\.executionTime).max() ?? 0

        report += "Recent Performance (last 10 runs):\n"
        report += "Average: \(String(format: "%.3fms", avgRecent * 1000))\n"
        report += "Min: \(String(format: "%.3fms", minRecent * 1000))\n"
        report += "Max: \(String(format: "%.3fms", maxRecent * 1000))\n"

        return report
    }
}

/// Performance regression alert
struct RegressionAlert {
    enum RegressionType {
        case executionTime
        case memoryUsage
    }

    let type: RegressionType
    let testName: String
    let baselineValue: Double
    let currentValue: Double
    let regressionPercent: Double

    var description: String {
        let metric = type == .executionTime ? "execution time" : "memory usage"
        let unit = type == .executionTime ? "ms" : "bytes"
        let baselineFormatted =
            type == .executionTime
            ? String(format: "%.3f%@", baselineValue * 1000, unit)
            : String(format: "%.0f %@", baselineValue, unit)
        let currentFormatted =
            type == .executionTime
            ? String(format: "%.3f%@", currentValue * 1000, unit)
            : String(format: "%.0f %@", currentValue, unit)

        return
            "⚠️  REGRESSION DETECTED in \(testName): \(metric) increased by \(String(format: "%.1f%%", regressionPercent)) (from \(baselineFormatted) to \(currentFormatted))"
    }
}

/// Enhanced benchmark validation test case
class BenchmarkValidation: XCTestCase {
    private let storage = BenchmarkStorage()

    override func setUp() {
        super.setUp()
        // Clear any existing profiling data
        SpecificationProfiler.shared.reset()
    }

    /// Validate specification evaluation meets performance baseline
    func testSpecificationPerformanceBaseline() {
        let spec = CooldownIntervalSpec(eventKey: "test", cooldownInterval: 10.0)
        let context = EvaluationContext(
            currentDate: Date(),
            events: ["test": Date().addingTimeInterval(-15)]
        )

        let startTime = CFAbsoluteTimeGetCurrent()
        var results: [Bool] = []

        // Run multiple iterations for statistical significance
        for _ in 1...1000 {
            results.append(spec.isSatisfiedBy(context))
        }

        let endTime = CFAbsoluteTimeGetCurrent()
        let averageTime = (endTime - startTime) / 1000.0

        let result = BenchmarkResult(
            testName: "CooldownIntervalSpec_Performance",
            executionTime: averageTime,
            iterations: 1000
        )

        storage.storeBenchmark(result)

        // Check for regressions
        let alerts = storage.detectRegressions(for: result.testName, currentResult: result)
        for alert in alerts {
            print(alert.description)
        }

        // Validate against baseline
        XCTAssertLessThan(
            averageTime, PerformanceBaseline.specificationEvaluation,
            "Specification evaluation exceeds 1ms baseline")
        XCTAssertEqual(results.filter { $0 }.count, 1000, "All evaluations should return true")
    }

    /// Test that profiler overhead is within acceptable limits
    func testProfilerOverhead() {
        let workload = Array(0..<512)
        let spec = PredicateSpec<[Int]> { values in
            var total: Int = 0
            for value in values {
                total &+= (value &* 3)
                total &-= (value >> 1)
            }
            return total > 0
        }
        let iterations = 2000

        let profiler = SpecificationProfiler.shared
        profiler.reset()

        // Measure without profiling using the same workload to establish a baseline.
        let startDirect = CFAbsoluteTimeGetCurrent()
        for _ in 0..<iterations {
            _ = spec.isSatisfiedBy(workload)
        }
        let directTime = CFAbsoluteTimeGetCurrent() - startDirect

        // Measure with profiling enabled.
        let startProfiled = CFAbsoluteTimeGetCurrent()
        for _ in 0..<iterations {
            _ = profiler.profile(spec, context: workload)
        }
        let profiledTime = CFAbsoluteTimeGetCurrent() - startProfiled

        let baseline = max(directTime, .leastNonzeroMagnitude)
        let overhead = (profiledTime - directTime) / baseline

        let result = BenchmarkResult(
            testName: "Profiler_Overhead",
            executionTime: overhead,
            iterations: iterations
        )

        storage.storeBenchmark(result)

        // In debug builds, profiler overhead can be higher, so use a more lenient threshold
        #if DEBUG
            XCTAssertLessThan(
                overhead, 10.0, "Profiler overhead should be less than 1000% in debug builds")
        #else
            XCTAssertLessThan(
                overhead, 0.10, "Profiler overhead should be less than 10% in release builds")
        #endif
        XCTAssertTrue(profiler.validateOverhead(), "Profiler overhead validation failed")
    }

    /// Test benchmark storage and retrieval
    func testBenchmarkStorage() {
        // Create a temporary directory for this test to avoid conflicts
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("SpecificationKitBenchmarksTest_\(UUID().uuidString)")

        // Use temporary storage instance
        let testStorage = BenchmarkStorage(storageDirectory: tempDir)

        // Ensure directory was created successfully
        XCTAssertTrue(
            FileManager.default.fileExists(atPath: tempDir.path),
            "Temporary directory should be created")

        let testResult = BenchmarkResult(
            testName: "TestStorage",
            executionTime: 0.005,
            memoryUsage: 1024,
            iterations: 100
        )

        testStorage.storeBenchmark(testResult)

        let retrievedResults = testStorage.loadBenchmarks(for: "TestStorage")
        XCTAssertGreaterThan(retrievedResults.count, 0, "Should retrieve stored benchmark")

        let retrieved = retrievedResults.first!
        XCTAssertEqual(retrieved.testName, testResult.testName)
        XCTAssertEqual(retrieved.executionTime, testResult.executionTime, accuracy: 0.001)
        XCTAssertEqual(retrieved.memoryUsage, testResult.memoryUsage)
        XCTAssertEqual(retrieved.iterations, testResult.iterations)

        // Cleanup: Remove temporary directory
        try? FileManager.default.removeItem(at: tempDir)
    }
}
