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

struct DecisionStageResult<Result> {
    let name: String
    let output: Result
}

struct MultiStageDecisionPipeline {
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

    func evaluate(
        evaluation: EvaluationContext,
        metrics: MetricsEvaluationContext,
        service: ServiceContext
    ) -> [DecisionStageResult<String>] {
        var stages: [DecisionStageResult<String>] = []

        let variant = variantSpec.decide(evaluation)
        stages.append(DecisionStageResult(name: "Variant selection", output: variant?.rawValue ?? "none"))

        if let p90Latency = latencySpec.decide(metrics) {
            stages.append(DecisionStageResult(name: "Latency forecast", output: String(format: "%.0f ms", p90Latency)))
        } else {
            stages.append(DecisionStageResult(name: "Latency forecast", output: "Insufficient data"))
        }

        let errorBreached = errorThreshold.isSatisfiedBy(service)
        stages.append(DecisionStageResult(name: "Error budget", output: errorBreached ? "breached" : "healthy"))

        let incidentBreached = incidentThreshold.isSatisfiedBy(service)
        stages.append(DecisionStageResult(name: "Incident fatigue", output: incidentBreached ? "too many" : "acceptable"))

        let finalDecision: String
        if errorBreached || incidentBreached {
            finalDecision = "Hold rollout"
        } else if let variant {
            finalDecision = "Activate \(variant.rawValue)"
        } else {
            finalDecision = "No qualifying variant"
        }

        stages.append(DecisionStageResult(name: "Final decision", output: finalDecision))
        return stages
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

let provider = RollingMetricsProvider()
provider.record(410, for: "latency")
provider.record(450, for: "latency")
provider.record(520, for: "latency")

let pipeline = try MultiStageDecisionPipeline(metricsProvider: provider)
let stages = pipeline.evaluate(
    evaluation: EvaluationContext(
        flags: [
            "experiment_onboarding_revamp": true,
            "experiment_loyalty_upsell": true,
            "experiment_control": true
        ]
    ),
    metrics: MetricsEvaluationContext(metricKey: "latency", now: Date()),
    service: ServiceContext(
        activeUsers: 1490,
        errorRate: 0.035,
        responseTime: 545,
        baselineResponseTime: 430,
        recentIncidents: 4
    )
)
