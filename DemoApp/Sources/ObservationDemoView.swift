import SwiftUI
import SpecificationKit

struct ObservationDemoView: View {
    private let provider = DefaultContextProvider.shared

    // Observed specs that auto-refresh when provider changes
    @ObservedSatisfies(provider: DefaultContextProvider.shared,
                       predicate: { $0.flag(for: "obs_flag") })
    private var flagOn: Bool

    @ObservedSatisfies(provider: DefaultContextProvider.shared,
                       using: MaxCountSpec(counterKey: "obs_count", limit: 3))
    private var underLimit: Bool

    @ObservedSatisfies(provider: DefaultContextProvider.shared,
                       using: CooldownIntervalSpec(eventKey: "obs_event", seconds: 3))
    private var cooldownOK: Bool

    @ObservedSatisfies(provider: DefaultContextProvider.shared,
                       using: CompositeSpec(minimumLaunchDelay: 0,
                                            maxShowCount: 3,
                                            cooldownDays: 3.0/86400.0,
                                            counterKey: "obs_count",
                                            eventKey: "obs_event"))
    private var shouldShow: Bool

    // ObservedMaybe demos (optional reactive results)
    @ObservedMaybe(provider: DefaultContextProvider.shared,
                   firstMatch: [
                       (FeatureFlagSpec(flagKey: "obs_flag"), "Flag is ON")
                   ])
    private var maybeFlagMessage: String?

    @ObservedMaybe(provider: DefaultContextProvider.shared,
                   decide: { ctx in
                       ctx.counter(for: "obs_count") > 0 ? "Count > 0" : nil
                   })
    private var maybeCountMessage: String?

    @State private var flagState: Bool = false
    @State private var countState: Int = 0
    @State private var lastEvent: String = "Never"

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Observation Demo")
                .font(.title)

            Group {
                LabelRow(ok: flagOn, text: "Flag obs_flag = true")
                LabelRow(ok: underLimit, text: "Counter obs_count < 3")
                LabelRow(ok: cooldownOK, text: "Cooldown obs_event ≥ 3s")
                Divider()
                LabelRow(ok: shouldShow, text: "Composite: show when all true")
                Divider()
                OptionalRow(value: maybeFlagMessage, label: "@ObservedMaybe flag message")
                OptionalRow(value: maybeCountMessage, label: "@ObservedMaybe count message")
            }

            Divider()

            Group {
                Toggle("obs_flag", isOn: .init(
                    get: { flagState },
                    set: { newValue in
                        flagState = newValue
                        provider.setFlag("obs_flag", to: newValue)
                    }
                ))

                HStack(spacing: 12) {
                    Text("obs_count: \(countState)")
                    Button("+1") { incrementCount() }
                    Button("Reset") { resetCount() }
                }

                HStack(spacing: 12) {
                    Text("obs_event: \(lastEvent)")
                    Button("Record now") { recordEvent() }
                    Button("Clear") { clearEvent() }
                }
            }

            Spacer()
        }
        .padding()
        .onAppear(perform: syncFromProvider)
        .navigationTitle("Observation")
    }

    private func syncFromProvider() {
        flagState = provider.getFlag("obs_flag")
        countState = provider.getCounter("obs_count")
        if let d = provider.getEvent("obs_event") {
            let f = DateFormatter(); f.timeStyle = .medium
            lastEvent = f.string(from: d)
        } else { lastEvent = "Never" }
    }

    private func incrementCount() {
        _ = provider.incrementCounter("obs_count")
        countState = provider.getCounter("obs_count")
    }

    private func resetCount() {
        provider.setCounter("obs_count", to: 0)
        countState = 0
    }

    private func recordEvent() {
        provider.recordEvent("obs_event")
        syncFromProvider()
    }

    private func clearEvent() {
        provider.removeEvent("obs_event")
        syncFromProvider()
    }
}

private struct LabelRow: View {
    let ok: Bool
    let text: String
    var body: some View {
        HStack {
            Circle()
                .fill(ok ? Color.green : Color.red)
                .frame(width: 12, height: 12)
            Text(text)
        }
    }
}

private struct OptionalRow: View {
    let value: String?
    let label: String
    var body: some View {
        HStack {
            Circle()
                .fill((value != nil) ? Color.green : Color.gray)
                .frame(width: 12, height: 12)
            Text("\(label): \(value ?? "nil")")
        }
    }
}

#Preview { ObservationDemoView() }
