import Combine
import Dispatch
import Foundation
import SpecificationKit
import SwiftUI

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

    func latestValue<Value>(for key: String) -> (Date, Value)? {
        queue.sync {
            guard let last = storage[key]?.last, let value = last.1 as? Value else { return nil }
            return (last.0, value)
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

    func latestLatency() -> (Date, Double)? {
        provider.latestValue(for: "request_latency")
    }
}

struct LatencyTrend {
    let sampledAt: Date
    let latestLatency: Double
    let rollingMedian: Double
    let percentileLatency: Double
    let deviationRatio: Double
}

struct LatencyTrendDetector: Specification {
    typealias T = MetricsEvaluationContext

    private let analyzer: MetricsAnalyzer
    private let spikeRatio: Double

    init(analyzer: MetricsAnalyzer, spikeRatio: Double = 1.3) {
        self.analyzer = analyzer
        self.spikeRatio = spikeRatio
    }

    func isSatisfiedBy(_ candidate: MetricsEvaluationContext) -> Bool {
        guard
            let median = analyzer.medianLatency(now: candidate.now),
            let p95 = analyzer.percentileLatency(now: candidate.now),
            median > 0
        else { return false }

        let ratio = p95 / median
        return ratio >= spikeRatio
    }

    func trend(at now: Date = Date()) -> LatencyTrend? {
        let context = MetricsEvaluationContext.latency(now: now)
        guard
            let median = analyzer.medianLatency(now: now),
            let percentile = analyzer.percentileLatency(now: now),
            let latest = analyzer.latestLatency()
        else { return nil }

        let ratio = percentile / max(median, 1)
        return LatencyTrend(
            sampledAt: latest.0,
            latestLatency: latest.1,
            rollingMedian: median,
            percentileLatency: percentile,
            deviationRatio: ratio
        )
    }
}

final class ObservableMetricsProvider: ObservableObject, ContextProviding {
    typealias Context = MetricsEvaluationContext

    private var current: MetricsEvaluationContext
    private let updatesSubject = PassthroughSubject<Void, Never>()

    init(metricKey: String = "request_latency", now: Date = Date()) {
        self.current = MetricsEvaluationContext(metricKey: metricKey, now: now)
    }

    func currentContext() -> MetricsEvaluationContext {
        current
    }

    func advance(to date: Date) {
        current = MetricsEvaluationContext(metricKey: current.metricKey, now: date)
        updatesSubject.send()
        objectWillChange.send()
    }
}

extension ObservableMetricsProvider: ContextUpdatesProviding {
    var contextUpdates: AnyPublisher<Void, Never> {
        updatesSubject.eraseToAnyPublisher()
    }

    var contextStream: AsyncStream<Void> {
        AsyncStream { continuation in
            let cancellable = updatesSubject.sink { _ in continuation.yield(()) }
            continuation.onTermination = { _ in cancellable.cancel() }
        }
    }
}

final class MetricsDashboardViewModel: ObservableObject {
    private let analyzer: MetricsAnalyzer
    private let detector: LatencyTrendDetector
    private let provider: ObservableMetricsProvider

    @ObservedSatisfies(provider: ObservableMetricsProvider(), using: LatencyTrendDetector(analyzer: MetricsAnalyzer(provider: RollingMetricsProvider())))
    private var hasLatencySpike: Bool

    @Published private(set) var trend: LatencyTrend?

    init(analyzer: MetricsAnalyzer, provider: ObservableMetricsProvider) {
        self.analyzer = analyzer
        self.detector = LatencyTrendDetector(analyzer: analyzer)
        self.provider = provider
        self._hasLatencySpike = ObservedSatisfies(provider: provider, using: detector)
        self.trend = detector.trend(at: provider.currentContext().now)
    }

    func refresh(now: Date = Date()) {
        provider.advance(to: now)
        trend = detector.trend(at: now)
    }

    func isSpikeActive() -> Bool {
        hasLatencySpike
    }
}

struct MetricsDashboardView: View {
    @StateObject private var provider = ObservableMetricsProvider(now: Date())
    @StateObject private var viewModel: MetricsDashboardViewModel
    private let analyzer: MetricsAnalyzer

    init(analyzer: MetricsAnalyzer) {
        let provider = ObservableMetricsProvider(now: Date())
        _provider = StateObject(wrappedValue: provider)
        _viewModel = StateObject(wrappedValue: MetricsDashboardViewModel(analyzer: analyzer, provider: provider))
        self.analyzer = analyzer
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Latency Dashboard")
                .font(.title2)

            if let trend = viewModel.trend {
                VStack(spacing: 8) {
                    Text("Median: \(trend.rollingMedian, specifier: "%.0f") ms")
                    Text("P95: \(trend.percentileLatency, specifier: "%.0f") ms")
                    Text("Latest: \(trend.latestLatency, specifier: "%.0f") ms")
                }
            } else {
                Text("Insufficient data")
                    .foregroundColor(.secondary)
            }

            if viewModel.isSpikeActive() {
                Text("Latency spike detected")
                    .font(.headline)
                    .foregroundColor(.red)
            } else {
                Text("Latency within limits")
                    .font(.headline)
                    .foregroundColor(.green)
            }

            Button("Simulate new sample") {
                let sample = Double.random(in: 300...700)
                analyzer.recordLatency(sample)
                viewModel.refresh(now: Date())
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(Color.orange.opacity(0.08))
        .cornerRadius(16)
    }
}

let provider = RollingMetricsProvider()
let analyzer = MetricsAnalyzer(provider: provider)
let dashboard = MetricsDashboardView(analyzer: analyzer)
