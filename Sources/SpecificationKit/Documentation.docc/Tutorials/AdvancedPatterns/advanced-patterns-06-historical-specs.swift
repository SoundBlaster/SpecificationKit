import Dispatch
import Foundation
import SpecificationKit

struct MetricsEvaluationContext {
    let metricKey: String
    let now: Date
}

extension MetricsEvaluationContext {
    static func latency(now: Date = Date()) -> MetricsEvaluationContext {
        MetricsEvaluationContext(metricKey: "request_latency", now: now)
    }

    static func errorRate(now: Date = Date()) -> MetricsEvaluationContext {
        MetricsEvaluationContext(metricKey: "error_rate", now: now)
    }
}

final class RollingMetricsProvider: HistoricalDataProvider {
    private var storage: [String: [(Date, Any)]] = [:]
    private let queue = DispatchQueue(label: "com.specificationkit.metrics", qos: .utility)

    func record<Value>(
        _ value: Value,
        for key: String,
        at date: Date = Date()
    ) {
        queue.sync {
            var samples = storage[key, default: []]
            samples.append((date, value))
            samples.sort { $0.0 < $1.0 }
            storage[key] = samples
        }
    }

    func getData<Context, Value>(
        for window: HistoricalSpec<Context, Value>.AnalysisWindow,
        context: Context
    ) -> [(Date, Value)] {
        queue.sync {
            guard let metricsContext = context as? MetricsEvaluationContext else { return [] }
            guard let samples = storage[metricsContext.metricKey] else { return [] }

            let typedSamples: [(Date, Value)] = samples.compactMap { entry in
                guard let value = entry.1 as? Value else { return nil }
                return (entry.0, value)
            }

            return filter(
                samples: typedSamples,
                window: window,
                now: metricsContext.now
            )
        }
    }

    private func filter<Context, Value>(
        samples: [(Date, Value)],
        window: HistoricalSpec<Context, Value>.AnalysisWindow,
        now: Date
    ) -> [(Date, Value)] {
        switch window {
        case .lastN(let count):
            return Array(samples.suffix(count))
        case .timeRange(let interval):
            let lowerBound = now.addingTimeInterval(-interval)
            return samples.filter { sample in sample.0 >= lowerBound }
        case .all:
            return samples
        }
    }
}

struct MetricsAnalyzer {
    private let provider: RollingMetricsProvider
    let medianLatencySpec: HistoricalSpec<MetricsEvaluationContext, Double>
    let percentileLatencySpec: HistoricalSpec<MetricsEvaluationContext, Double>
    let errorRateSpec: HistoricalSpec<MetricsEvaluationContext, Double>

    init(provider: RollingMetricsProvider) {
        self.provider = provider
        self.medianLatencySpec = HistoricalSpec(
            provider: provider,
            window: .lastN(30),
            aggregation: .median,
            minimumDataPoints: 5
        )
        self.percentileLatencySpec = HistoricalSpec(
            provider: provider,
            window: .timeRange(TimeInterval.minutes(15)),
            aggregation: .percentile(95)
        )
        self.errorRateSpec = HistoricalSpec(
            provider: provider,
            window: .timeRange(TimeInterval.hours(1)),
            aggregation: .percentile(90)
        )
    }

    func recordLatency(_ value: Double, at date: Date = Date()) {
        provider.record(value, for: "request_latency", at: date)
    }

    func recordErrorRate(_ value: Double, at date: Date = Date()) {
        provider.record(value, for: "error_rate", at: date)
    }

    func medianLatency(now: Date = Date()) -> Double? {
        medianLatencySpec.decide(.latency(now: now))
    }

    func percentileLatency(now: Date = Date()) -> Double? {
        percentileLatencySpec.decide(.latency(now: now))
    }

    func recentErrorRate(now: Date = Date()) -> Double? {
        errorRateSpec.decide(.errorRate(now: now))
    }
}

let provider = RollingMetricsProvider()
let analyzer = MetricsAnalyzer(provider: provider)
analyzer.recordLatency(420)
analyzer.recordLatency(380)
analyzer.recordErrorRate(0.012)
let median = analyzer.medianLatency()
let p95 = analyzer.percentileLatency()
let errorRate = analyzer.recentErrorRate()
