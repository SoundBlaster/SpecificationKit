import Foundation
import SpecificationKit

struct MetricSnapshot {
    let metricName: String
    let currentValue: Double
    let baselineValue: Double
    let targetRange: ClosedRange<Double>
    let units: String
}

struct RangeValidationRules {
    private let belowTarget: ComparativeSpec<MetricSnapshot, Double>
    private let aboveTarget: ComparativeSpec<MetricSnapshot, Double>

    init() {
        self.belowTarget = ComparativeSpec(
            extracting: { snapshot in snapshot.currentValue - snapshot.targetRange.lowerBound },
            comparison: .lessThan(0)
        )

        self.aboveTarget = ComparativeSpec(
            extracting: { snapshot in snapshot.currentValue - snapshot.targetRange.upperBound },
            comparison: .greaterThan(0)
        )
    }

    func status(for snapshot: MetricSnapshot) -> String {
        let withinRange = ComparativeSpec(
            extracting: { $0.currentValue },
            comparison: .between(snapshot.targetRange.lowerBound, snapshot.targetRange.upperBound)
        )

        if withinRange.isSatisfiedBy(snapshot) {
            return "On target"
        }

        if belowTarget.isSatisfiedBy(snapshot) {
            return "Below target"
        }

        if aboveTarget.isSatisfiedBy(snapshot) {
            return "Above target"
        }

        return "Unknown"
    }
}

let snapshot = MetricSnapshot(
    metricName: "Checkout conversion",
    currentValue: 0.046,
    baselineValue: 0.043,
    targetRange: 0.045...0.055,
    units: "%"
)

let rules = RangeValidationRules()
let status = rules.status(for: snapshot)
