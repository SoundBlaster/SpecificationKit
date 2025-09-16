import SpecificationKit
import SwiftUI

#if canImport(Charts)
    import Charts
#endif

struct SpecificationTracerDemoView: View {
    @StateObject private var demoManager = TracerDemoManager()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("SpecificationTracer Demo")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text(
                        "Visualize specification execution with detailed tracing and performance analysis."
                    )
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                .padding()

                // Controls Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Controls")
                        .font(.headline)

                    HStack(spacing: 12) {
                        Button(demoManager.isTracing ? "Stop Tracing" : "Start Tracing") {
                            demoManager.toggleTracing()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(demoManager.isTracing ? .red : .green)

                        Button("Run Test Spec") {
                            demoManager.runTestSpecification()
                        }
                        .disabled(!demoManager.isTracing)

                        Button("Run Complex Spec") {
                            demoManager.runComplexSpecification()
                        }
                        .disabled(!demoManager.isTracing)

                        Button("Clear Results") {
                            demoManager.clearResults()
                        }
                    }

                    // Spec Configuration
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Test Configuration")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        HStack {
                            Text("Counter Value:")
                            TextField("Value", value: $demoManager.counterValue, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 60)

                            Toggle("Feature Flag", isOn: $demoManager.featureFlag)
                        }
                    }
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)

                // Status Section
                if demoManager.isTracing {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tracing Status")
                            .font(.headline)

                        HStack {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 12, height: 12)
                            Text("Recording...")
                                .foregroundColor(.green)
                                .fontWeight(.medium)
                        }

                        Text("Session ID: \(demoManager.sessionId?.uuidString ?? "N/A")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)
                }

                // Results Section
                if !demoManager.traceEntries.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Trace Results")
                            .font(.headline)

                        Text("Total Evaluations: \(demoManager.traceEntries.count)")
                        Text(
                            "Total Time: \(String(format: "%.3f", demoManager.totalExecutionTime * 1000))ms"
                        )

                        if let slowestEntry = demoManager.slowestEntry {
                            Text(
                                "Slowest: \(slowestEntry.specification) (\(String(format: "%.3f", slowestEntry.executionTime * 1000))ms)"
                            )
                            .foregroundColor(.orange)
                        }
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
                }

                // Performance Chart Section
                if #available(iOS 16.0, macOS 13.0, *), !demoManager.traceEntries.isEmpty {
                    PerformanceChartView(entries: demoManager.traceEntries)
                        .frame(height: 200)
                        .padding()
                        .background(Color.purple.opacity(0.1))
                        .cornerRadius(12)
                }

                // Execution Tree Section
                if !demoManager.treeOutput.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Execution Tree")
                            .font(.headline)

                        ScrollView(.horizontal, showsIndicators: true) {
                            Text(demoManager.treeOutput)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.primary)
                                .padding()
                        }
                        .frame(maxHeight: 200)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(12)
                }

                // Detailed Entries Section
                if !demoManager.traceEntries.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Detailed Trace Entries")
                            .font(.headline)

                        LazyVStack(spacing: 6) {
                            ForEach(Array(demoManager.traceEntries.enumerated()), id: \.offset) {
                                index, entry in
                                TraceEntryRow(entry: entry, index: index)
                            }
                        }
                    }
                    .padding()
                    .background(Color.indigo.opacity(0.1))
                    .cornerRadius(12)
                }

                Spacer(minLength: 20)
            }
            .padding()
        }
        .navigationTitle("Specification Tracer")
        .onAppear {
            demoManager.setup()
        }
    }
}

@available(iOS 16.0, macOS 13.0, *)
struct PerformanceChartView: View {
    let entries: [SpecificationTracer.TraceEntry]

    var chartData: [ChartDataPoint] {
        entries.enumerated().map { index, entry in
            ChartDataPoint(
                index: index,
                executionTime: entry.executionTime * 1000,  // Convert to ms
                specification: entry.specification
            )
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Performance Timeline")
                .font(.headline)

            Chart(chartData, id: \.index) { dataPoint in
                BarMark(
                    x: .value("Index", dataPoint.index),
                    y: .value("Time (ms)", dataPoint.executionTime)
                )
                .foregroundStyle(colorForTime(dataPoint.executionTime))
                .opacity(0.8)
            }
            .chartYAxisLabel("Execution Time (ms)")
            .chartXAxisLabel("Evaluation Order")
        }
    }

    private func colorForTime(_ time: Double) -> Color {
        if time > 10.0 { return .red }
        if time > 5.0 { return .orange }
        if time > 1.0 { return .yellow }
        return .green
    }
}

struct ChartDataPoint {
    let index: Int
    let executionTime: Double
    let specification: String
}

struct TraceEntryRow: View {
    let entry: SpecificationTracer.TraceEntry
    let index: Int

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(index + 1). \(entry.specification)")
                    .font(.caption)
                    .fontWeight(.medium)

                HStack {
                    Text("Result: \(entry.result)")
                        .font(.caption2)
                        .foregroundColor(entry.result == "true" ? .green : .red)

                    Spacer()

                    Text("\(String(format: "%.3f", entry.executionTime * 1000))ms")
                        .font(.caption2)
                        .foregroundColor(executionTimeColor(entry.executionTime * 1000))
                        .fontWeight(.medium)
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(Color.white.opacity(0.6))
        .cornerRadius(6)
    }

    private func executionTimeColor(_ timeMs: Double) -> Color {
        if timeMs > 10.0 { return .red }
        if timeMs > 5.0 { return .orange }
        if timeMs > 1.0 { return .yellow }
        return .green
    }
}

class TracerDemoManager: ObservableObject {
    @Published var isTracing = false
    @Published var traceEntries: [SpecificationTracer.TraceEntry] = []
    @Published var treeOutput: String = ""
    @Published var sessionId: UUID?
    @Published var counterValue: Int = 2
    @Published var featureFlag: Bool = true

    private let tracer = SpecificationTracer.shared
    private let contextProvider = DefaultContextProvider.shared

    var totalExecutionTime: TimeInterval {
        traceEntries.map(\.executionTime).reduce(0, +)
    }

    var slowestEntry: SpecificationTracer.TraceEntry? {
        traceEntries.max(by: { $0.executionTime < $1.executionTime })
    }

    func setup() {
        updateContext()
    }

    func toggleTracing() {
        if isTracing {
            stopTracing()
        } else {
            startTracing()
        }
    }

    func startTracing() {
        sessionId = tracer.startTracing()
        isTracing = true
        clearResults()
    }

    func stopTracing() {
        if let session = tracer.stopTracing() {
            traceEntries = session.entries
            generateTreeOutput(from: session.traceTree)
        }
        isTracing = false
        sessionId = nil
    }

    func runTestSpecification() {
        guard isTracing else { return }

        updateContext()

        let spec = MaxCountSpec(counterKey: "demo_counter", limit: 5)
        let context = contextProvider.currentContext()

        _ = tracer.trace(specification: spec, context: context)
    }

    func runComplexSpecification() {
        guard isTracing else { return }

        updateContext()

        // Create a complex composite specification
        let maxCountSpec = MaxCountSpec(counterKey: "demo_counter", limit: 5)
        let featureFlagSpec = FeatureFlagSpec(flagKey: "demo_feature")
        let cooldownSpec = CooldownIntervalSpec(eventKey: "demo_event", seconds: 3)

        let compositeSpec = maxCountSpec.and(featureFlagSpec).and(cooldownSpec)
        let context = contextProvider.currentContext()

        _ = tracer.trace(specification: compositeSpec, context: context)
    }

    func clearResults() {
        traceEntries = []
        treeOutput = ""
    }

    private func updateContext() {
        contextProvider.setCounter("demo_counter", to: counterValue)
        contextProvider.setFlag("demo_feature", to: featureFlag)
        contextProvider.recordEvent("demo_event")
    }

    private func generateTreeOutput(from trees: [SpecificationTracer.TraceNode]) {
        var output = ""
        for tree in trees {
            output += generateTreeString(from: tree, indent: "")
        }
        treeOutput = output
    }

    private func generateTreeString(from node: SpecificationTracer.TraceNode, indent: String)
        -> String
    {
        let duration = String(format: "%.3f", node.entry.executionTime * 1000)
        var result =
            "\(indent)├─ \(node.entry.specification) → \(node.entry.result) (\(duration)ms)\n"

        for (index, child) in node.children.enumerated() {
            let isLast = index == node.children.count - 1
            let childIndent = indent + (isLast ? "   " : "│  ")
            result += generateTreeString(from: child, indent: childIndent)
        }

        return result
    }
}

#Preview {
    NavigationView {
        SpecificationTracerDemoView()
    }
}
