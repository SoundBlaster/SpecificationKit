import Foundation
import SpecificationKit

struct AlertContext {
    let cpuUsage: Double
    let memoryUsage: Double
    let queueDepth: Int
    let rollingAverageCpu: Double
    let rollingAverageMemory: Double
}

struct AdaptiveThresholds {
    let adaptiveCpu: ThresholdSpec<AlertContext, Double>
    let adaptiveMemory: ThresholdSpec<AlertContext, Double>
    let backlogRecovery: ThresholdSpec<AlertContext, Int>

    init(cpuMultiplier: Double = 1.15, memoryMultiplier: Double = 1.20) {
        self.adaptiveCpu = ThresholdSpec(
            keyPath: \.cpuUsage,
            threshold: .custom { context in context.rollingAverageCpu * cpuMultiplier },
            operator: .greaterThan
        )

        self.adaptiveMemory = ThresholdSpec(
            keyPath: \.memoryUsage,
            threshold: .custom { context in context.rollingAverageMemory * memoryMultiplier },
            operator: .greaterThan
        )

        self.backlogRecovery = ThresholdSpec(
            keyPath: \.queueDepth,
            threshold: .adaptive { 25 },
            operator: .lessThan
        )
    }

    func alerts(for context: AlertContext) -> [String] {
        var alerts: [String] = []

        if adaptiveCpu.isSatisfiedBy(context) {
            alerts.append("CPU usage spiked above rolling average")
        }

        if adaptiveMemory.isSatisfiedBy(context) {
            alerts.append("Memory usage spiked above rolling average")
        }

        if !backlogRecovery.isSatisfiedBy(context) {
            alerts.append("Backlog has not recovered yet")
        }

        return alerts
    }
}

let context = AlertContext(
    cpuUsage: 0.82,
    memoryUsage: 0.78,
    queueDepth: 18,
    rollingAverageCpu: 0.65,
    rollingAverageMemory: 0.60
)

let thresholds = AdaptiveThresholds()
let alerts = thresholds.alerts(for: context)
