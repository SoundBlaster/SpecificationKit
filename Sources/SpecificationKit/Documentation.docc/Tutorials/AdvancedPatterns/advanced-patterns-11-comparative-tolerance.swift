import Foundation
import SpecificationKit

struct MetricSnapshot {
    let metricName: String
    let currentValue: Double
    let targetValue: Double
    let allowableDrift: Double
}

struct ToleranceComparisons {
    func isWithinTolerance(_ snapshot: MetricSnapshot) -> Bool {
        let toleranceSpec = ComparativeSpec.withinTolerance(
            of: snapshot.targetValue,
            tolerance: snapshot.allowableDrift,
            keyPath: \.currentValue
        )
        return toleranceSpec.isSatisfiedBy(snapshot)
    }

    func isApproximatelyEqual(
        _ snapshot: MetricSnapshot,
        relativeError: Double = 0.05
    ) -> Bool {
        let approxSpec = ComparativeSpec.approximatelyEqual(
            to: snapshot.targetValue,
            relativeError: relativeError,
            keyPath: \.currentValue
        )
        return approxSpec.isSatisfiedBy(snapshot)
    }
}

let snapshot = MetricSnapshot(
    metricName: "API latency",
    currentValue: 402,
    targetValue: 400,
    allowableDrift: 25
)

let comparisons = ToleranceComparisons()
let withinTolerance = comparisons.isWithinTolerance(snapshot)
let approximatelyEqual = comparisons.isApproximatelyEqual(snapshot, relativeError: 0.1)
