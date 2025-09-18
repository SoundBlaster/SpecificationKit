import Combine
import Foundation
import SpecificationKit
import SwiftUI

struct MetricSnapshot {
    let metricName: String
    var currentValue: Double
    let targetValue: Double
    let allowableDrift: Double
    let units: String
}

final class MetricComparisonViewModel: ObservableObject {
    @Published var snapshot: MetricSnapshot {
        didSet { refreshBindings() }
    }

    private let toleranceSpec: ComparativeSpec<MetricSnapshot, Double>
    private let improvementSpec: ComparativeSpec<MetricSnapshot, Double>

    @Satisfies(provider: staticContext(MetricSnapshot(metricName: "", currentValue: 0, targetValue: 0, allowableDrift: 0, units: "")), using: ComparativeSpec.withinTolerance(of: 0, tolerance: 0, keyPath: \.currentValue))
    private var meetsTolerance: Bool

    @Satisfies(provider: staticContext(MetricSnapshot(metricName: "", currentValue: 0, targetValue: 0, allowableDrift: 0, units: "")), using: ComparativeSpec(extracting: { _ in 0.0 }, comparison: .greaterThan(0)))
    private var isImproving: Bool

    init(snapshot: MetricSnapshot) {
        self.snapshot = snapshot
        self.toleranceSpec = ComparativeSpec.withinTolerance(
            of: snapshot.targetValue,
            tolerance: snapshot.allowableDrift,
            keyPath: \.currentValue
        )
        self.improvementSpec = ComparativeSpec(
            extracting: { $0.currentValue - $0.targetValue },
            comparison: .greaterThan(0)
        )

        let provider = staticContext(snapshot)
        self._meetsTolerance = Satisfies(provider: provider, using: toleranceSpec)
        self._isImproving = Satisfies(provider: provider, using: improvementSpec)
    }

    func updateCurrentValue(_ newValue: Double) {
        snapshot = MetricSnapshot(
            metricName: snapshot.metricName,
            currentValue: newValue,
            targetValue: snapshot.targetValue,
            allowableDrift: snapshot.allowableDrift,
            units: snapshot.units
        )
    }

    func toleranceStatus() -> Bool {
        meetsTolerance
    }

    func improvementStatus() -> Bool {
        isImproving
    }

    private func refreshBindings() {
        let provider = staticContext(snapshot)
        _meetsTolerance = Satisfies(provider: provider, using: toleranceSpec)
        _isImproving = Satisfies(provider: provider, using: improvementSpec)
        objectWillChange.send()
    }
}

struct MetricComparisonView: View {
    @StateObject private var viewModel: MetricComparisonViewModel

    init(snapshot: MetricSnapshot) {
        _viewModel = StateObject(wrappedValue: MetricComparisonViewModel(snapshot: snapshot))
    }

    var body: some View {
        VStack(spacing: 12) {
            Text(viewModel.snapshot.metricName)
                .font(.title3)

            HStack {
                Text("Current: \(viewModel.snapshot.currentValue, specifier: "%.3f")")
                Text("Target: \(viewModel.snapshot.targetValue, specifier: "%.3f")")
                Text("± \(viewModel.snapshot.allowableDrift, specifier: "%.3f")")
            }
            .font(.footnote)

            if viewModel.toleranceStatus() {
                Label("Within tolerance", systemImage: "checkmark.seal.fill")
                    .foregroundStyle(.green)
            } else {
                Label("Outside tolerance", systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
            }

            if viewModel.improvementStatus() {
                Label("Improving", systemImage: "arrow.up.forward.circle.fill")
                    .foregroundStyle(.blue)
            } else {
                Label("Needs improvement", systemImage: "arrow.down.circle.fill")
                    .foregroundStyle(.secondary)
            }

            HStack {
                Button("-0.002") {
                    viewModel.updateCurrentValue(viewModel.snapshot.currentValue - 0.002)
                }
                Button("Reset") {
                    viewModel.updateCurrentValue(viewModel.snapshot.targetValue)
                }
                Button("+0.002") {
                    viewModel.updateCurrentValue(viewModel.snapshot.currentValue + 0.002)
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(Color.purple.opacity(0.08))
        .cornerRadius(16)
    }
}

let snapshot = MetricSnapshot(
    metricName: "Checkout conversion",
    currentValue: 0.048,
    targetValue: 0.050,
    allowableDrift: 0.004,
    units: "%"
)

let view = MetricComparisonView(snapshot: snapshot)
