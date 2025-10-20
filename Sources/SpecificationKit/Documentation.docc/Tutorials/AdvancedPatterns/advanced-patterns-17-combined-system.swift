import Foundation
import SpecificationKit

enum ExperimentVariant: String {
    case control
    case onboardingRevamp
    case loyaltyUpsell
}

struct ExperimentConfiguration {
    let candidates: [(FeatureFlagSpec, Double, ExperimentVariant)]

    init() {
        candidates = [
            (FeatureFlagSpec.enabled("experiment_onboarding_revamp"), 0.45, .onboardingRevamp),
            (FeatureFlagSpec.enabled("experiment_loyalty_upsell"), 0.35, .loyaltyUpsell),
            (FeatureFlagSpec.enabled("experiment_control"), 0.20, .control)
        ]
    }
}

struct MetricsEvaluationContext {
    let metricKey: String
    let now: Date
}

struct ServiceContext {
    let activeUsers: Int
    let errorRate: Double
    let responseTime: Double
    let baselineResponseTime: Double
    let recentIncidents: Int
}

struct RecommendationContext {
    let evaluation: EvaluationContext
    let metrics: MetricsEvaluationContext
    let service: ServiceContext
}

struct RecommendationDecision {
    let variant: ExperimentVariant?
    let predictedLatency: Double?
    let healthAlerts: [String]
}

final class RecommendationEngine {
    private let variantSpec: WeightedSpec<EvaluationContext, ExperimentVariant>
    private let latencySpec: HistoricalSpec<MetricsEvaluationContext, Double>
    private let errorThreshold: ThresholdSpec<ServiceContext, Double>
    private let incidentThreshold: ThresholdSpec<ServiceContext, Int>

    init(
        configuration: ExperimentConfiguration = ExperimentConfiguration(),
        metricsProvider: any HistoricalDataProvider
    ) throws {
        self.variantSpec = try WeightedSpec(configuration.candidates)
        self.latencySpec = HistoricalSpec(
            provider: metricsProvider,
            window: .lastN(20),
            aggregation: .percentile(90),
            minimumDataPoints: 3
        )
        self.errorThreshold = ThresholdSpec(
            extracting: { $0.errorRate },
            threshold: .custom { $0.activeUsers > 1000 ? 0.03 : 0.05 },
            operator: .greaterThan
        )
        self.incidentThreshold = ThresholdSpec(
            keyPath: \.recentIncidents,
            threshold: .fixed(3),
            operator: .greaterThanOrEqual
        )
    }

    func evaluate(_ context: RecommendationContext) -> RecommendationDecision {
        let variant = variantSpec.decide(context.evaluation)
        let predictedLatency = latencySpec.decide(context.metrics)

        var alerts: [String] = []
        if errorThreshold.isSatisfiedBy(context.service) {
            alerts.append("Error rate beyond dynamic budget")
        }
        if incidentThreshold.isSatisfiedBy(context.service) {
            alerts.append("Recent incidents exceed acceptable count")
        }

        return RecommendationDecision(
            variant: variant,
            predictedLatency: predictedLatency,
            healthAlerts: alerts
        )
    }
}

final class RollingMetricsProvider: HistoricalDataProvider {
    private var storage: [String: [(Date, Any)]] = [:]
    private let lock = NSLock()

    func record(_ value: Double, for key: String, at date: Date = Date()) {
        lock.lock()
        defer { lock.unlock() }
        var samples = storage[key, default: []]
        samples.append((date, value))
        samples.sort { $0.0 < $1.0 }
        storage[key] = samples
    }

    func getData<Context, Value>(
        for window: HistoricalSpec<Context, Value>.AnalysisWindow,
        context: Context
    ) -> [(Date, Value)] {
        lock.lock()
        defer { lock.unlock() }

        guard let metrics = context as? MetricsEvaluationContext else { return [] }
        guard let samples = storage[metrics.metricKey] else { return [] }

        let typed: [(Date, Value)] = samples.compactMap { entry in
            guard let value = entry.1 as? Value else { return nil }
            return (entry.0, value)
        }

        switch window {
        case .lastN(let n):
            return Array(typed.suffix(n))
        case .timeRange(let interval):
            let lower = metrics.now.addingTimeInterval(-interval)
            return typed.filter { $0.0 >= lower }
        case .all:
            return typed
        }
    }
}

let metricsProvider = RollingMetricsProvider()
metricsProvider.record(420, for: "latency")
metricsProvider.record(380, for: "latency")
metricsProvider.record(512, for: "latency")

let evaluationContext = EvaluationContext(
    flags: [
        "experiment_onboarding_revamp": true,
        "experiment_loyalty_upsell": false,
        "experiment_control": true
    ]
)

let recommendationContext = RecommendationContext(
    evaluation: evaluationContext,
    metrics: MetricsEvaluationContext(metricKey: "latency", now: Date()),
    service: ServiceContext(
        activeUsers: 1350,
        errorRate: 0.028,
        responseTime: 510,
        baselineResponseTime: 430,
        recentIncidents: 2
    )
)

let engine = try RecommendationEngine(metricsProvider: metricsProvider)
let decision = engine.evaluate(recommendationContext)
