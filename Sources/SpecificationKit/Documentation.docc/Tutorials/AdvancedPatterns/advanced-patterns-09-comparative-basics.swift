import Foundation
import SpecificationKit

struct MetricSnapshot {
    let metricName: String
    let currentValue: Double
    let baselineValue: Double
    let units: String
}

struct BaselineComparisonRules {
    let aboveBaseline: ComparativeSpec<MetricSnapshot, Double>
    let meetsBaseline: ComparativeSpec<MetricSnapshot, Double>

    init() {
        self.aboveBaseline = ComparativeSpec(
            extracting: { snapshot in snapshot.currentValue - snapshot.baselineValue },
            comparison: .greaterThan(0)
        )

        self.meetsBaseline = ComparativeSpec(
            extracting: { snapshot in snapshot.currentValue - snapshot.baselineValue },
            comparison: .greaterThan(-0.01)
        )
    }

    func status(for snapshot: MetricSnapshot) -> String {
        if aboveBaseline.isSatisfiedBy(snapshot) {
            return "Improving"
        } else if meetsBaseline.isSatisfiedBy(snapshot) {
            return "Holding"
        } else {
            return "Underperforming"
        }
    }
}

let snapshot = MetricSnapshot(
    metricName: "Activation",
    currentValue: 0.42,
    baselineValue: 0.37,
    units: "%"
)

let rules = BaselineComparisonRules()
let status = rules.status(for: snapshot)
