import XCTest
import SpecificationKit

enum ExperimentVariant: String {
    case control
    case onboardingRevamp
    case loyaltyUpsell
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

final class InMemoryHistoricalProvider: HistoricalDataProvider {
    private var samples: [String: [(Date, Any)]] = [:]

    func record(_ value: Double, for key: String, at date: Date = Date()) {
        var entries = samples[key, default: []]
        entries.append((date, value))
        entries.sort { $0.0 < $1.0 }
        samples[key] = entries
    }

    func getData<Context, Value>(
        for window: HistoricalSpec<Context, Value>.AnalysisWindow,
        context: Context
    ) -> [(Date, Value)] {
        guard let metrics = context as? MetricsEvaluationContext else { return [] }
        guard let entries = samples[metrics.metricKey] else { return [] }

        let typed = entries.compactMap { entry -> (Date, Value)? in
            guard let value = entry.1 as? Value else { return nil }
            return (entry.0, value)
        }

        switch window {
        case .lastN(let count):
            return Array(typed.suffix(count))
        case .timeRange(let interval):
            let lower = metrics.now.addingTimeInterval(-interval)
            return typed.filter { $0.0 >= lower }
        case .all:
            return typed
        }
    }
}

final class RecommendationEngine {
    private let variantSpec: WeightedSpec<EvaluationContext, ExperimentVariant>
    private let latencySpec: HistoricalSpec<MetricsEvaluationContext, Double>
    private let errorThreshold: ThresholdSpec<ServiceContext, Double>

    init(
        configuration: [(FeatureFlagSpec, Double, ExperimentVariant)],
        metricsProvider: any HistoricalDataProvider
    ) throws {
        self.variantSpec = try WeightedSpec(configuration)
        self.latencySpec = HistoricalSpec(
            provider: metricsProvider,
            window: .lastN(10),
            aggregation: .median,
            minimumDataPoints: 2
        )
        self.errorThreshold = ThresholdSpec(
            extracting: { $0.errorRate },
            threshold: .fixed(0.05),
            operator: .greaterThan
        )
    }

    func variant(for context: EvaluationContext) -> ExperimentVariant? {
        variantSpec.decide(context)
    }

    func predictedLatency(for context: MetricsEvaluationContext) -> Double? {
        latencySpec.decide(context)
    }

    func isHealthy(_ service: ServiceContext) -> Bool {
        !errorThreshold.isSatisfiedBy(service)
    }
}

final class RecommendationEngineTests: XCTestCase {
    func testSelectsVariantWhenFlagsEnabled() throws {
        let provider = InMemoryHistoricalProvider()
        provider.record(410, for: "latency")
        provider.record(430, for: "latency")

        let engine = try RecommendationEngine(
            configuration: [
                (FeatureFlagSpec.enabled("experiment_onboarding_revamp"), 0.7, .onboardingRevamp),
                (FeatureFlagSpec.enabled("experiment_control"), 0.3, .control)
            ],
            metricsProvider: provider
        )

        let context = EvaluationContext(flags: [
            "experiment_onboarding_revamp": true,
            "experiment_control": true
        ])

        let variant = engine.variant(for: context)
        XCTAssertNotNil(variant)
    }

    func testLatencyPredictionUsesHistoricalSamples() throws {
        let provider = InMemoryHistoricalProvider()
        provider.record(380, for: "latency")
        provider.record(400, for: "latency")
        provider.record(420, for: "latency")

        let engine = try RecommendationEngine(
            configuration: [
                (FeatureFlagSpec.enabled("experiment_control"), 1.0, .control)
            ],
            metricsProvider: provider
        )

        let prediction = engine.predictedLatency(for: MetricsEvaluationContext(metricKey: "latency", now: Date()))
        XCTAssertEqual(prediction, 400, accuracy: 0.001)
    }

    func testDetectsUnhealthyServiceWhenErrorsSpike() throws {
        let provider = InMemoryHistoricalProvider()
        provider.record(380, for: "latency")
        provider.record(400, for: "latency")

        let engine = try RecommendationEngine(
            configuration: [
                (FeatureFlagSpec.enabled("experiment_control"), 1.0, .control)
            ],
            metricsProvider: provider
        )

        let healthyService = ServiceContext(
            activeUsers: 800,
            errorRate: 0.02,
            responseTime: 420,
            baselineResponseTime: 380,
            recentIncidents: 1
        )

        XCTAssertTrue(engine.isHealthy(healthyService))

        let unhealthyService = ServiceContext(
            activeUsers: 1200,
            errorRate: 0.07,
            responseTime: 520,
            baselineResponseTime: 420,
            recentIncidents: 3
        )

        XCTAssertFalse(engine.isHealthy(unhealthyService))
    }
}
