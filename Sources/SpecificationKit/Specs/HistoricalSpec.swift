//
//  HistoricalSpec.swift
//  SpecificationKit
//
//  Created by SpecificationKit on 2024.
//

import Foundation

/// A decision specification that analyzes historical data over time to make decisions.
///
/// `HistoricalSpec` provides time-series analysis capabilities for specifications that need
/// to evaluate trends, patterns, or statistical measures from historical data. This is useful
/// for adaptive systems, trend analysis, seasonal adjustments, and predictive decision making.
///
/// ## Usage Examples
///
/// ### Performance Analysis
/// ```swift
/// let performanceSpec = HistoricalSpec(
///     provider: MetricsHistoryProvider(),
///     window: .lastN(30),
///     aggregation: .median
/// )
/// ```
public struct HistoricalSpec<Context, Value>: DecisionSpec where Value: Comparable {
    public typealias Result = Value

    /// Defines the time window for historical data analysis
    public enum AnalysisWindow {
        /// Analyze the last N data points
        case lastN(Int)
        /// Analyze data within a specific time range
        case timeRange(TimeInterval)
        /// Analyze all available data
        case all
    }

    /// Statistical aggregation methods for historical data
    public enum AggregationMethod {
        /// Find median value
        case median
        /// Calculate specific percentile
        case percentile(Double)
        /// Custom aggregation function
        case custom(([(Date, Value)]) -> Value)
    }

    private let dataProvider: any HistoricalDataProvider
    private let window: AnalysisWindow
    private let aggregation: AggregationMethod
    private let minimumDataPoints: Int

    /// Creates a new HistoricalSpec with the specified parameters
    public init(
        provider: any HistoricalDataProvider,
        window: AnalysisWindow,
        aggregation: AggregationMethod,
        minimumDataPoints: Int = 1
    ) {
        self.dataProvider = provider
        self.window = window
        self.aggregation = aggregation
        self.minimumDataPoints = minimumDataPoints
    }

    /// Analyzes historical data and returns the aggregated result
    public func decide(_ context: Context) -> Value? {
        let historicalData = dataProvider.getData(for: window, context: context)

        guard historicalData.count >= minimumDataPoints else {
            return nil
        }

        return aggregateData(historicalData, using: aggregation)
    }

    /// Performs the specified aggregation on historical data
    private func aggregateData(
        _ data: [(Date, Value)],
        using method: AggregationMethod
    ) -> Value? {
        guard !data.isEmpty else { return nil }

        switch method {
        case .median:
            return calculateMedian(data)
        case .percentile(let p):
            return calculatePercentile(data, percentile: p)
        case .custom(let aggregator):
            return aggregator(data)
        }
    }

    /// Calculates the median value
    private func calculateMedian(_ data: [(Date, Value)]) -> Value? {
        let sortedValues = data.map(\.1).sorted()
        let count = sortedValues.count

        if count % 2 == 0 {
            // For even count, return the lower middle value for non-numeric types
            return sortedValues[count / 2 - 1]
        } else {
            return sortedValues[count / 2]
        }
    }

    /// Calculates the specified percentile
    private func calculatePercentile(
        _ data: [(Date, Value)],
        percentile: Double
    ) -> Value? {
        guard !data.isEmpty, (0...100).contains(percentile) else { return nil }

        let sortedValues = data.map(\.1).sorted()
        let index = (percentile / 100.0) * Double(sortedValues.count - 1)
        let nearestIndex = Int(index.rounded())
        return sortedValues[min(nearestIndex, sortedValues.count - 1)]
    }
}

// MARK: - Historical Data Provider Protocol

/// Protocol for providing historical data to HistoricalSpec
public protocol HistoricalDataProvider {
    /// Retrieves historical data for the specified window and context
    func getData<Context, Value>(
        for window: HistoricalSpec<Context, Value>.AnalysisWindow,
        context: Context
    ) -> [(Date, Value)]
}

// MARK: - Default Implementation

/// Default implementation of HistoricalDataProvider using in-memory storage
public final class DefaultHistoricalDataProvider: HistoricalDataProvider {
    private let storage: [String: [(Date, Any)]]
    private let lock = NSLock()

    /// Creates a new provider with the specified storage
    public init(storage: [String: [(Date, Any)]] = [:]) {
        self.storage = storage
    }

    public func getData<Context, Value>(
        for window: HistoricalSpec<Context, Value>.AnalysisWindow,
        context: Context
    ) -> [(Date, Value)] {
        lock.lock()
        defer { lock.unlock() }

        // Extract storage key from context (implementation-specific)
        let key = String(describing: Context.self)
        let rawData = storage[key] ?? []

        // Filter data based on window
        let filteredData = filterData(rawData, using: window)

        // Type cast and filter
        return filteredData.compactMap { (date, value) -> (Date, Value)? in
            guard let typedValue = value as? Value else { return nil }
            return (date, typedValue)
        }
    }

    /// Filters data based on the analysis window
    private func filterData<C, V>(
        _ data: [(Date, Any)],
        using window: HistoricalSpec<C, V>.AnalysisWindow
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

// MARK: - Time Interval Extensions

extension TimeInterval {
    /// One day in seconds
    public static let days: (Int) -> TimeInterval = { Double($0) * 24 * 60 * 60 }

    /// One hour in seconds
    public static let hours: (Int) -> TimeInterval = { Double($0) * 60 * 60 }

    /// One minute in seconds
    public static let minutes: (Int) -> TimeInterval = { Double($0) * 60 }
}
