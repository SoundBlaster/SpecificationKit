import SwiftUI
import SpecificationKit

struct AdvancedSpecsDemoView: View {
    private let provider = DefaultContextProvider.shared

    // MARK: - Shared demo state
    @State private var metricValue: Double = 50
    @State private var thresholdValue: Double = 60
    @State private var ctxThresholdValue: Double = 55
    @State private var approxTarget: Double = 42
    @State private var approxRelError: Double = 0.05

    // WeightedSpec state
    @State private var weightA: Double = 0.5
    @State private var weightB: Double = 0.3
    @State private var weightC: Double = 0.2
    @State private var flagA: Bool = true
    @State private var flagB: Bool = false
    @State private var lastWeightedPick: String = "—"
    @State private var sampleRuns: Int = 100
    @State private var sampleA: Int = 0
    @State private var sampleB: Int = 0
    @State private var sampleC: Int = 0

    // HistoricalSpec state
    @StateObject private var history = DemoHistoryProvider()
    @State private var newDataPoint: Double = 50
    @State private var windowMode: HistoryWindow = .lastN
    @State private var aggregation: HistoryAggregation = .median
    @State private var minPoints: Int = 1
    @State private var historicalResult: Double? = nil

    enum HistoryWindow: String, CaseIterable, Identifiable {
        case last10 = "Last 10"
        case last50 = "Last 50"
        case last100 = "Last 100"
        case lastN = "Custom N"
        case lastMinute = "Last 60s"
        case all = "All"
        var id: String { rawValue }

        static func toSpecWindow(_ w: HistoryWindow, n: Int) -> HistoricalSpec<EvaluationContext, Double>.AnalysisWindow {
            switch w {
            case .last10: return .lastN(10)
            case .last50: return .lastN(50)
            case .last100: return .lastN(100)
            case .lastN: return .lastN(max(1, n))
            case .lastMinute: return .timeRange(.minutes(1))
            case .all: return .all
            }
        }
    }

    enum HistoryAggregation: String, CaseIterable, Identifiable {
        case median = "Median"
        case p90 = "P90"
        case p99 = "P99"
        var id: String { rawValue }

        static func toSpecAggregation(_ a: HistoryAggregation) -> HistoricalSpec<EvaluationContext, Double>.AggregationMethod {
            switch a {
            case .median: return .median
            case .p90: return .percentile(90)
            case .p99: return .percentile(99)
            }
        }
    }

    var body: some View {
        List {
            Section(header: Text("Setup")) {
                Slider(value: $metricValue, in: 0...100, step: 1) {
                    Text("metric (userData.metric)")
                } minimumValueLabel: { Text("0") } maximumValueLabel: { Text("100") }
                Text("metric: \(Int(metricValue))")

                HStack {
                    Stepper("Context threshold: \(Int(ctxThresholdValue))", value: $ctxThresholdValue, in: 0...100)
                    Spacer()
                    Button("Apply to context") {
                        provider.setUserData("ctx_threshold", to: ctxThresholdValue)
                    }
                }
            }

            // MARK: - ComparativeSpec
            Section(header: Text("1) ComparativeSpec"), footer: Text("Uses extracting: and helpers like withinTolerance and approximatelyEqual")) {
                let greater = ComparativeSpec<EvaluationContext, Double>(
                    extracting: { $0.userData(for: "metric", as: Double.self) },
                    comparison: .greaterThan(thresholdValue)
                )
                let between = ComparativeSpec<EvaluationContext, Double>(
                    extracting: { $0.userData(for: "metric", as: Double.self) },
                    comparison: .between(40, 60)
                )
                // Approximately equal using a custom comparison range
                let approxCustom = ComparativeSpec<EvaluationContext, Double>(
                    extracting: { $0.userData(for: "metric", as: Double.self) },
                    comparison: .between(approxTarget * (1 - approxRelError), approxTarget * (1 + approxRelError))
                )

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Stepper("threshold: \(Int(thresholdValue))", value: $thresholdValue, in: 0...100)
                        Spacer()
                    }
                    HStack {
                        Stepper("approx target: \(Int(approxTarget))", value: $approxTarget, in: 0...100)
                        Spacer()
                        Stepper("rel error: \(Int(approxRelError * 100))%", value: $approxRelError, in: 0.01...0.25, step: 0.01)
                    }

                    let ctx = updatedContext()
                    statusRow("metric > threshold", ok: greater.isSatisfiedBy(ctx))
                    statusRow("metric between 40…60", ok: between.isSatisfiedBy(ctx))
                    statusRow("metric ≈ target (custom)", ok: approxCustom.isSatisfiedBy(ctx))
                }
            }

            // MARK: - ThresholdSpec
            Section(header: Text("2) ThresholdSpec"), footer: Text("Fixed, adaptive, contextual thresholds")) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Stepper("fixed threshold: \(Int(thresholdValue))", value: $thresholdValue, in: 0...100)
                        Spacer()
                    }
                    let ctx = updatedContext()
                    // Value via extracting from userData
                    let fixed = ThresholdSpec<EvaluationContext, Double>(
                        extracting: { $0.userData(for: "metric", as: Double.self) },
                        threshold: .fixed(thresholdValue),
                        operator: .greaterThanOrEqual
                    )
                    statusRow("metric ≥ fixed", ok: fixed.isSatisfiedBy(ctx))

                    let adaptive = ThresholdSpec<EvaluationContext, Double>(
                        extracting: { $0.userData(for: "metric", as: Double.self) },
                        threshold: .adaptive { Double.random(in: 30...70) },
                        operator: .greaterThan
                    )
                    statusRow("metric > adaptive(random)", ok: adaptive.isSatisfiedBy(ctx))

                    // Contextual threshold read from context userData
                    let contextual = ThresholdSpec<EvaluationContext, Double>(
                        extracting: { $0.userData(for: "metric", as: Double.self) },
                        threshold: .custom { ctx in ctx.userData(for: "ctx_threshold", as: Double.self) ?? 0 },
                        operator: .greaterThanOrEqual
                    )
                    statusRow("metric ≥ ctx_threshold", ok: contextual.isSatisfiedBy(ctx))
                }
            }

            // MARK: - WeightedSpec
            Section(header: Text("3) WeightedSpec"), footer: Text("Probabilistic selection among satisfied candidates")) {
                VStack(alignment: .leading, spacing: 8) {
                    Toggle("Flag A", isOn: .init(
                        get: { flagA },
                        set: { v in flagA = v; provider.setFlag("weighted_a", to: v) }
                    ))
                    Toggle("Flag B", isOn: .init(
                        get: { flagB },
                        set: { v in flagB = v; provider.setFlag("weighted_b", to: v) }
                    ))

                    HStack {
                        Stepper("wA: \(String(format: "%.2f", weightA))", value: $weightA, in: 0.1...5, step: 0.1)
                        Stepper("wB: \(String(format: "%.2f", weightB))", value: $weightB, in: 0.1...5, step: 0.1)
                        Stepper("wC: \(String(format: "%.2f", weightC))", value: $weightC, in: 0.1...5, step: 0.1)
                    }

                    HStack {
                        Button("Pick once") { pickWeightedOnce() }
                        Text("Result: \(lastWeightedPick)")
                    }

                    HStack {
                        Stepper("Samples: \(sampleRuns)", value: $sampleRuns, in: 50...2000, step: 50)
                        Button("Run samples") { runSamples() }
                    }
                    Text("A: \(sampleA)  B: \(sampleB)  C: \(sampleC)")
                        .foregroundStyle(.secondary)
                }
            }

            // MARK: - HistoricalSpec
            Section(header: Text("4) HistoricalSpec"), footer: Text("Aggregate time-series data with median/percentile")) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Slider(value: $newDataPoint, in: 0...100, step: 1) {
                            Text("Add data point")
                        }
                        Text("\(Int(newDataPoint))")
                        Button("Record") { history.record(value: newDataPoint) }
                        Button("Clear") { history.clear() }
                    }

                    Picker("Window", selection: $windowMode) {
                        Text("Last 10").tag(HistoryWindow.last10)
                        Text("Last 50").tag(HistoryWindow.last50)
                        Text("Last 100").tag(HistoryWindow.last100)
                        Text("Custom N").tag(HistoryWindow.lastN)
                        Text("Last 60s").tag(HistoryWindow.lastMinute)
                        Text("All").tag(HistoryWindow.all)
                    }
                    .pickerStyle(.segmented)

                    if case .lastN = windowMode {
                        Stepper("N (minPoints): \(minPoints)", value: $minPoints, in: 1...500)
                    }

                    Picker("Aggregation", selection: $aggregation) {
                        Text("Median").tag(HistoryAggregation.median)
                        Text("P90").tag(HistoryAggregation.p90)
                        Text("P99").tag(HistoryAggregation.p99)
                    }
                    .pickerStyle(.segmented)

                    HStack {
                        Button("Compute") { computeHistorical() }
                        Text("Result: \(historicalResult.map { String(Int($0)) } ?? "—")")
                    }
                }
            }
        }
        .navigationTitle("Advanced Specs")
        .onAppear {
            // Initialize provider with current UI state
            provider.setUserData("metric", to: metricValue)
            provider.setUserData("ctx_threshold", to: ctxThresholdValue)
            provider.setFlag("weighted_a", to: flagA)
            provider.setFlag("weighted_b", to: flagB)
        }
        .onChange(of: metricValue) { v in provider.setUserData("metric", to: v) }
        .onChange(of: ctxThresholdValue) { v in provider.setUserData("ctx_threshold", to: v) }
    }

    // MARK: - Helpers
    private func updatedContext() -> EvaluationContext {
        provider.currentContext()
    }

    @ViewBuilder
    private func statusRow(_ title: String, ok: Bool) -> some View {
        HStack {
            Image(systemName: ok ? "checkmark.circle.fill" : "xmark.octagon.fill")
                .foregroundColor(ok ? .green : .red)
            Text(title)
            Spacer()
            Text(ok ? "Pass" : "Fail").foregroundStyle(.secondary)
        }
    }

    private func pickWeightedOnce() {
        let a = PredicateSpec<EvaluationContext> { $0.flag(for: "weighted_a") }
        let b = PredicateSpec<EvaluationContext> { $0.flag(for: "weighted_b") }
        let always = AlwaysTrueSpec<EvaluationContext>()

        let spec = WeightedSpec<EvaluationContext, String>(
            candidates: [
                (AnySpecification(a), weightA, "A"),
                (AnySpecification(b), weightB, "B"),
                (AnySpecification(always), weightC, "C")
            ]
        )

        let ctx = updatedContext()
        lastWeightedPick = spec.decide(ctx) ?? "—"
    }

    private func runSamples() {
        sampleA = 0; sampleB = 0; sampleC = 0
        let a = PredicateSpec<EvaluationContext> { $0.flag(for: "weighted_a") }
        let b = PredicateSpec<EvaluationContext> { $0.flag(for: "weighted_b") }
        let always = AlwaysTrueSpec<EvaluationContext>()
        let spec = WeightedSpec<EvaluationContext, String>(
            candidates: [
                (AnySpecification(a), weightA, "A"),
                (AnySpecification(b), weightB, "B"),
                (AnySpecification(always), weightC, "C")
            ]
        )

        let ctx = updatedContext()
        for _ in 0..<sampleRuns {
            switch spec.decide(ctx) {
            case "A": sampleA += 1
            case "B": sampleB += 1
            case "C": sampleC += 1
            default: break
            }
        }
    }

    private func computeHistorical() {
        let spec = HistoricalSpec<EvaluationContext, Double>(
            provider: history,
            window: HistoryWindow.toSpecWindow(windowMode, n: minPoints),
            aggregation: HistoryAggregation.toSpecAggregation(aggregation),
            minimumDataPoints: minPoints
        )
        historicalResult = spec.decide(updatedContext())
    }
}

// MARK: - Demo History Provider

final class DemoHistoryProvider: ObservableObject, HistoricalDataProvider {
    @Published private(set) var data: [(Date, Double)] = []
    private let lock = NSLock()

    func record(value: Double) {
        lock.lock(); defer { lock.unlock() }
        data.append((Date(), value))
    }

    func clear() {
        lock.lock(); defer { lock.unlock() }
        data.removeAll()
    }

    func getData<Context, Value>(
        for window: HistoricalSpec<Context, Value>.AnalysisWindow,
        context: Context
    ) -> [(Date, Value)] {
        lock.lock(); defer { lock.unlock() }
        let casted: [(Date, Any)] = data.map { ($0.0, $0.1 as Any) }
        let now = Date()
        let filtered: [(Date, Any)]
        switch window {
        case .lastN(let n):
            filtered = Array(casted.suffix(n))
        case .timeRange(let interval):
            let cutoff = now.addingTimeInterval(-interval)
            filtered = casted.filter { $0.0 >= cutoff }
        case .all:
            filtered = casted
        }
        return filtered.compactMap { (d, v) -> (Date, Value)? in
            (v as? Value).map { (d, $0) }
        }
    }
}

#Preview {
    NavigationView { AdvancedSpecsDemoView() }
}
