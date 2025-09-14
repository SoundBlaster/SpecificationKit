//
//  HistoricalSpecTests.swift
//  SpecificationKitTests
//
//  Created by SpecificationKit on 2024.
//

import XCTest

@testable import SpecificationKit

final class HistoricalSpecTests: XCTestCase {

    // Test context
    struct MetricsContext {
        var metricKey: String
        var currentTime: Date
    }

    // MARK: - Initialization Tests

    func testHistoricalSpec_init_succeeds() {
        // Arrange
        let provider = MockHistoricalDataProvider()

        // Act & Assert
        XCTAssertNoThrow {
            let _ = HistoricalSpec<MetricsContext, Double>(
                provider: provider,
                window: .lastN(10),
                aggregation: .median
            )
        }
    }

    // MARK: - Analysis Window Tests

    func testHistoricalSpec_lastNWindow_returnsCorrectData() {
        // Arrange
        let testData = generateTestData(count: 20)
        let provider = MockHistoricalDataProvider(data: ["test": testData])

        let spec = HistoricalSpec<MetricsContext, Double>(
            provider: provider,
            window: .lastN(5),
            aggregation: .custom { data in
                let values = data.map(\.1)
                return values.reduce(0, +) / Double(values.count)
            }
        )

        let context = MetricsContext(metricKey: "test", currentTime: Date())

        // Act
        let result = spec.decide(context)

        // Assert
        XCTAssertNotNil(result)
        // The mock provider should return the last 5 values
        let expectedAverage = testData.suffix(5).map(\.1).reduce(0, +) / 5.0
        XCTAssertEqual(result!, expectedAverage, accuracy: 0.001)
    }

    func testHistoricalSpec_timeRangeWindow_filtersCorrectly() {
        // Arrange
        let now = Date()
        let testData = [
            (now.addingTimeInterval(-3600), 10.0),  // 1 hour ago
            (now.addingTimeInterval(-1800), 20.0),  // 30 minutes ago
            (now.addingTimeInterval(-900), 30.0),  // 15 minutes ago
            (now.addingTimeInterval(-300), 40.0),  // 5 minutes ago
        ]

        let provider = MockHistoricalDataProvider(data: ["test": testData])

        let spec = HistoricalSpec<MetricsContext, Double>(
            provider: provider,
            window: .timeRange(2700),  // 45 minutes
            aggregation: .custom { data in
                let values = data.map(\.1)
                return values.reduce(0, +) / Double(values.count)
            }
        )

        let context = MetricsContext(metricKey: "test", currentTime: now)

        // Act
        let result = spec.decide(context)

        // Assert
        XCTAssertNotNil(result)
        // Should include last 3 values (within 45 minutes)
        let expectedAverage = (20.0 + 30.0 + 40.0) / 3.0
        XCTAssertEqual(result!, expectedAverage, accuracy: 0.001)
    }

    // MARK: - Aggregation Method Tests

    func testHistoricalSpec_averageAggregation_calculatesCorrectly() {
        // Arrange
        let testData = [(Date(), 10.0), (Date(), 20.0), (Date(), 30.0)]
        let provider = MockHistoricalDataProvider(data: ["test": testData])

        let spec = HistoricalSpec<MetricsContext, Double>(
            provider: provider,
            window: .all,
            aggregation: .custom { data in
                let values = data.map(\.1)
                return values.reduce(0, +) / Double(values.count)
            }
        )

        let context = MetricsContext(metricKey: "test", currentTime: Date())

        // Act
        let result = spec.decide(context)

        // Assert
        XCTAssertNotNil(result)
        XCTAssertEqual(result!, 20.0, accuracy: 0.001)
    }

    func testHistoricalSpec_medianAggregation_calculatesCorrectly() {
        // Arrange
        let testData = [(Date(), 10.0), (Date(), 30.0), (Date(), 20.0)]
        let provider = MockHistoricalDataProvider(data: ["test": testData])

        let spec = HistoricalSpec<MetricsContext, Double>(
            provider: provider,
            window: .all,
            aggregation: .median
        )

        let context = MetricsContext(metricKey: "test", currentTime: Date())

        // Act
        let result = spec.decide(context)

        // Assert
        XCTAssertNotNil(result)
        XCTAssertEqual(result!, 20.0, accuracy: 0.001)
    }

    func testHistoricalSpec_percentileAggregation_calculatesCorrectly() {
        // Arrange
        let testData = (1...100).map { (Date(), Double($0)) }
        let provider = MockHistoricalDataProvider(data: ["test": testData])

        let spec = HistoricalSpec<MetricsContext, Double>(
            provider: provider,
            window: .all,
            aggregation: .percentile(90)
        )

        let context = MetricsContext(metricKey: "test", currentTime: Date())

        // Act
        let result = spec.decide(context)

        // Assert
        XCTAssertNotNil(result)
        XCTAssertEqual(result!, 90.0, accuracy: 1.0)  // Should be around 90th percentile
    }

    func testHistoricalSpec_customAggregation_calculatesCorrectly() {
        // Arrange
        let testData = [(Date(), 10.0), (Date(), 20.0), (Date(), 30.0)]
        let provider = MockHistoricalDataProvider(data: ["test": testData])

        let spec = HistoricalSpec<MetricsContext, Double>(
            provider: provider,
            window: .all,
            aggregation: .custom { data in
                data.map(\.1).max() ?? 0.0  // Return maximum value
            }
        )

        let context = MetricsContext(metricKey: "test", currentTime: Date())

        // Act
        let result = spec.decide(context)

        // Assert
        XCTAssertNotNil(result)
        XCTAssertEqual(result!, 30.0, accuracy: 0.001)
    }

    // MARK: - Trend Analysis Tests (removed - not supported by current API)

    // MARK: - Minimum Data Points Tests

    func testHistoricalSpec_insufficientData_returnsNil() {
        // Arrange
        let testData: [(Date, Double)] = []
        let provider = MockHistoricalDataProvider(data: ["test": testData])

        let spec = HistoricalSpec<MetricsContext, Double>(
            provider: provider,
            window: .all,
            aggregation: .median,
            minimumDataPoints: 3
        )

        let context = MetricsContext(metricKey: "test", currentTime: Date())

        // Act
        let result = spec.decide(context)

        // Assert
        XCTAssertNil(result)
    }

    func testHistoricalSpec_sufficientData_returnsResult() {
        // Arrange
        let testData = [(Date(), 10.0), (Date(), 20.0), (Date(), 30.0)]
        let provider = MockHistoricalDataProvider(data: ["test": testData])

        let spec = HistoricalSpec<MetricsContext, Double>(
            provider: provider,
            window: .all,
            aggregation: .custom { data in
                let values = data.map(\.1)
                return values.reduce(0, +) / Double(values.count)
            },
            minimumDataPoints: 3
        )

        let context = MetricsContext(metricKey: "test", currentTime: Date())

        // Act
        let result = spec.decide(context)

        // Assert
        XCTAssertNotNil(result)
    }

    // MARK: - Data Interpolation Tests

    // Data Interpolation test removed (no interpolator in current API)

    // MARK: - Performance Tests

    func testHistoricalSpec_performance_largeDataset() {
        // Arrange
        let largeTestData = generateTestData(count: 10000)
        let provider = MockHistoricalDataProvider(data: ["test": largeTestData])

        let spec = HistoricalSpec<MetricsContext, Double>(
            provider: provider,
            window: .lastN(1000),
            aggregation: .custom { data in
                let values = data.map(\.1)
                return values.reduce(0, +) / Double(values.count)
            }
        )

        let context = MetricsContext(metricKey: "test", currentTime: Date())

        // Act & Assert
        measure {
            let _ = spec.decide(context)
        }
    }

    // MARK: - Edge Cases

    func testHistoricalSpec_emptyDataset_returnsNil() {
        // Arrange
        let provider = MockHistoricalDataProvider(data: [:])

        let spec = HistoricalSpec<MetricsContext, Double>(
            provider: provider,
            window: .all,
            aggregation: .median
        )

        let context = MetricsContext(metricKey: "nonexistent", currentTime: Date())

        // Act
        let result = spec.decide(context)

        // Assert
        XCTAssertNil(result)
    }

    func testHistoricalSpec_singleDataPoint_returnsValue() {
        // Arrange
        let testData = [(Date(), 42.0)]
        let provider = MockHistoricalDataProvider(data: ["test": testData])

        let spec = HistoricalSpec<MetricsContext, Double>(
            provider: provider,
            window: .all,
            aggregation: .median
        )

        let context = MetricsContext(metricKey: "test", currentTime: Date())

        // Act
        let result = spec.decide(context)

        // Assert
        XCTAssertNotNil(result)
        XCTAssertEqual(result!, 42.0)
    }

    // MARK: - Helper Methods

    private func generateTestData(count: Int) -> [(Date, Double)] {
        let baseTime = Date().timeIntervalSinceReferenceDate
        return (0..<count).map { index in
            (Date(timeIntervalSinceReferenceDate: baseTime + Double(index * 60)), Double(index))
        }
    }
}

// MARK: - Mock Historical Data Provider

class MockHistoricalDataProvider: HistoricalDataProvider {
    private let mockData: [String: [(Date, Any)]]

    init(data: [String: [(Date, Any)]] = [:]) {
        self.mockData = data
    }

    func getData<Context, Value>(
        for window: HistoricalSpec<Context, Value>.AnalysisWindow,
        context: Context
    ) -> [(Date, Value)] {
        // Extract key from context (simplified for testing)
        let key = extractKey(from: context)
        let rawData = mockData[key] ?? []

        // Apply window filtering
        let windowedData = applyWindow(window, to: rawData)

        // Type cast and return
        return windowedData.compactMap { (date, value) in
            guard let typedValue = value as? Value else { return nil }
            return (date, typedValue)
        }
    }

    private func extractKey<Context>(from context: Context) -> String {
        // Simplified key extraction for testing
        if let metricsContext = context as? HistoricalSpecTests.MetricsContext {
            return metricsContext.metricKey
        }
        return "default"
    }

    private func applyWindow<C, V>(
        _ window: HistoricalSpec<C, V>.AnalysisWindow,
        to data: [(Date, Any)]
    ) -> [(Date, Any)] {
        let sortedData = data.sorted { $0.0 < $1.0 }
        let now = Date()

        switch window {
        case .lastN(let n):
            return Array(sortedData.suffix(n))
        case .timeRange(let interval):
            let cutoffDate = now.addingTimeInterval(-interval)
            return sortedData.filter { $0.0 >= cutoffDate }
        case .all:
            return sortedData
        }
    }
}
