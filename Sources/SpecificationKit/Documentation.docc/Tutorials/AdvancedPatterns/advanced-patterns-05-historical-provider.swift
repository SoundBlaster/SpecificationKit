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

let provider = RollingMetricsProvider()
provider.record(420.0, for: "request_latency")
provider.record(380.0, for: "request_latency")
let latencySamples = provider.getData(
    for: .lastN(2),
    context: MetricsEvaluationContext.latency()
)
