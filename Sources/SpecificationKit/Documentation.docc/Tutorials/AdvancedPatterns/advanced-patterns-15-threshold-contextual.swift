import Foundation
import SpecificationKit

struct ServiceContext {
    let activeUsers: Int
    let errorRate: Double
    let responseTime: Double
    let baselineResponseTime: Double
    let timeOfDay: Int
}

struct ContextualThresholds {
    let loadThreshold: ThresholdSpec<ServiceContext, Int>
    let errorBudgetThreshold: ThresholdSpec<ServiceContext, Double>
    let responseTimeThreshold: ThresholdSpec<ServiceContext, Double>

    init() {
        self.loadThreshold = ThresholdSpec(
            keyPath: \.activeUsers,
            threshold: .custom { context in
                context.timeOfDay >= 18 || context.timeOfDay < 6 ? 1200 : 800
            },
            operator: .greaterThan
        )

        self.errorBudgetThreshold = ThresholdSpec(
            extracting: { $0.errorRate },
            threshold: .custom { context in context.activeUsers > 1000 ? 0.03 : 0.05 },
            operator: .greaterThan
        )

        self.responseTimeThreshold = ThresholdSpec(
            extracting: { $0.responseTime },
            threshold: .contextual(\.baselineResponseTime),
            operator: .greaterThan,
            tolerance: 50
        )
    }

    func alerts(for context: ServiceContext) -> [String] {
        var alerts: [String] = []

        if loadThreshold.isSatisfiedBy(context) {
            alerts.append("Active users above contextual limit")
        }

        if errorBudgetThreshold.isSatisfiedBy(context) {
            alerts.append("Error rate beyond acceptable budget")
        }

        if responseTimeThreshold.isSatisfiedBy(context) {
            alerts.append("Response time exceeds contextual baseline")
        }

        return alerts
    }
}

let context = ServiceContext(
    activeUsers: 1340,
    errorRate: 0.042,
    responseTime: 520,
    baselineResponseTime: 420,
    timeOfDay: 20
)

let thresholds = ContextualThresholds()
let alerts = thresholds.alerts(for: context)
