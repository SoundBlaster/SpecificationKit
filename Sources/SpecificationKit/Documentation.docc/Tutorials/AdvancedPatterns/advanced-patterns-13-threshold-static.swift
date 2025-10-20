import Foundation
import SpecificationKit

struct AlertContext {
    let cpuUsage: Double
    let memoryUsage: Double
    let queueDepth: Int
}

struct StaticThresholds {
    let highCpu: ThresholdSpec<AlertContext, Double>
    let highMemory: ThresholdSpec<AlertContext, Double>
    let deepQueue: ThresholdSpec<AlertContext, Int>

    init() {
        self.highCpu = ThresholdSpec.exceeds(keyPath: \.cpuUsage, value: 0.85)
        self.highMemory = ThresholdSpec.exceeds(keyPath: \.memoryUsage, value: 0.90)
        self.deepQueue = ThresholdSpec(
            keyPath: \.queueDepth,
            threshold: .fixed(50),
            operator: .greaterThanOrEqual
        )
    }

    func alerts(for context: AlertContext) -> [String] {
        var alerts: [String] = []

        if highCpu.isSatisfiedBy(context) {
            alerts.append("CPU usage above 85%")
        }

        if highMemory.isSatisfiedBy(context) {
            alerts.append("Memory usage above 90%")
        }

        if deepQueue.isSatisfiedBy(context) {
            alerts.append("Queue depth over 50")
        }

        return alerts
    }
}

let thresholds = StaticThresholds()
let context = AlertContext(cpuUsage: 0.92, memoryUsage: 0.88, queueDepth: 72)
let alerts = thresholds.alerts(for: context)
