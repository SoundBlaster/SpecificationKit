import Combine
import Foundation
import SpecificationKit

struct ServiceContext {
    let activeUsers: Int
    let errorRate: Double
    let responseTime: Double
    let baselineResponseTime: Double
    let timeOfDay: Int
    let recentIncidents: Int
}

struct ThresholdRule {
    let name: String
    let specification: AnySpecification<ServiceContext>

    func evaluate(_ context: ServiceContext) -> Bool {
        specification.isSatisfiedBy(context)
    }
}

final class MonitoringSystem: ObservableObject {
    private let rules: [ThresholdRule]

    @Published private(set) var triggeredRules: [String] = []

    init() {
        let loadRule = ThresholdRule(
            name: "Load surge",
            specification: AnySpecification(
                ThresholdSpec(
                    keyPath: \.activeUsers,
                    threshold: .custom { context in
                        context.timeOfDay >= 18 || context.timeOfDay < 6 ? 1200 : 800
                    },
                    operator: .greaterThan
                )
            )
        )

        let errorRule = ThresholdRule(
            name: "Error budget",
            specification: AnySpecification(
                ThresholdSpec(
                    extracting: { $0.errorRate },
                    threshold: .custom { context in context.activeUsers > 1000 ? 0.03 : 0.05 },
                    operator: .greaterThan
                )
            )
        )

        let responseRule = ThresholdRule(
            name: "Latency regression",
            specification: AnySpecification(
                ThresholdSpec(
                    extracting: { $0.responseTime },
                    threshold: .contextual(\.baselineResponseTime),
                    operator: .greaterThan,
                    tolerance: 40
                )
            )
        )

        let incidentRule = ThresholdRule(
            name: "Incident fatigue",
            specification: AnySpecification(
                ThresholdSpec(
                    keyPath: \.recentIncidents,
                    threshold: .fixed(3),
                    operator: .greaterThanOrEqual
                )
            )
        )

        self.rules = [loadRule, errorRule, responseRule, incidentRule]
    }

    func evaluate(context: ServiceContext) {
        triggeredRules = rules
            .filter { $0.evaluate(context) }
            .map(\.name)
    }
}

let monitoring = MonitoringSystem()
let context = ServiceContext(
    activeUsers: 1480,
    errorRate: 0.034,
    responseTime: 540,
    baselineResponseTime: 420,
    timeOfDay: 21,
    recentIncidents: 4
)

monitoring.evaluate(context: context)
let triggered = monitoring.triggeredRules
