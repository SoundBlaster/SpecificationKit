import SwiftUI
import SpecificationKit

struct CompositeDemoView: View {
    private let defaults = DefaultContextProvider.shared
    @StateObject private var env = EnvironmentContextProvider()

    enum Strategy: String, CaseIterable, Identifiable { case preferLast, preferFirst
        var id: String { rawValue }
        var title: String { self == .preferLast ? "Prefer Last (override)" : "Prefer First (preserve)" }
        var merge: CompositeContextProvider.MergeStrategy { self == .preferLast ? .preferLast : .preferFirst }
    }
    @State private var strategy: Strategy = .preferLast

    // Demo state mirrors
    @State private var defFlag: Bool = false
    @State private var defCount: Int = 0
    @State private var defUserK: String = "v1"

    @State private var envFlag: Bool = true
    @State private var envCount: Int = 2
    @State private var envUserK: String = "v2"

    var body: some View {
        let composite = CompositeContextProvider(
            providers: [AnyContextProvider(defaults), AnyContextProvider(env)],
            strategy: strategy.merge
        )
        let ctx = composite.currentContext()

        return List {
            Section(header: Text("What This Shows")) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("This screen composes two providers — Default (shared) and Environment (local) — into a single EvaluationContext using CompositeContextProvider.")
                    Text("Order matters: with Prefer Last, later providers override conflicting keys; with Prefer First, earlier values are preserved.")
                    Text("Segments are unioned across providers. Launch date follows the chosen strategy's precedence.")
                    Text("Edit values below in each provider to see how the merged context resolves conflicts in real time.")
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
            Section(header: Text("Merge Strategy")) {
                Picker("Strategy", selection: $strategy) {
                    ForEach(Strategy.allCases) { s in Text(s.title).tag(s) }
                }
                .pickerStyle(.segmented)
            }

            Section(header: Text("DefaultContextProvider (shared)"), footer: Text("Keys used: flag/promo, counter/launch_count, userData/k.")) {
                Toggle("flag/promo", isOn: .init(
                    get: { defFlag },
                    set: { v in defFlag = v; defaults.setFlag("promo", to: v) }
                ))
                Stepper("counter/launch_count: \(defCount)", value: .init(
                    get: { defCount },
                    set: { v in defCount = v; defaults.setCounter("launch_count", to: v) }
                ), in: 0...20)
                HStack {
                    Text("userData/k (string)")
                    Spacer()
                    TextField("v1", text: .init(
                        get: { defUserK },
                        set: { v in defUserK = v; defaults.setUserData("k", to: v) }
                    ))
                    .multilineTextAlignment(.trailing)
                    .textFieldStyle(.roundedBorder)
                }
                Button("Reset Default Provider") {
                    defaults.clearAll()
                    syncFromDefaults()
                }
                .buttonStyle(.bordered)
            }

            Section(header: Text("EnvironmentContextProvider (local)"), footer: Text("Keys used: flag/promo, counter/launch_count, userData/k.")) {
                Toggle("flag/promo", isOn: $envFlag)
                    .onChange(of: envFlag) { v in env.flags["promo"] = v }
                Stepper("counter/launch_count: \(envCount)", value: $envCount, in: 0...20)
                    .onChange(of: envCount) { v in env.counters["launch_count"] = v }
                HStack {
                    Text("userData/k (string)")
                    Spacer()
                    TextField("v2", text: $envUserK)
                        .multilineTextAlignment(.trailing)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: envUserK) { v in env.userData["k"] = v }
                }
                Button("Reset Environment Provider") {
                    env.flags.removeAll(); env.counters.removeAll(); env.userData.removeAll();
                    envFlag = false; envCount = 0; envUserK = ""
                }
                .buttonStyle(.bordered)
            }

            Section(header: Text("Merged Context (\(strategy.title))")) {
                keyValue("flag/promo", value: String(ctx.flag(for: "promo")))
                keyValue("counter/launch_count", value: String(ctx.counter(for: "launch_count")))
                keyValue("userData/k", value: (ctx.userData["k"] as? String) ?? "—")
                keyValue("segments (count)", value: String(ctx.segments.count))
                keyValue("launchDate source", value: strategy == .preferLast ? "Environment (if later in order)" : "Default (first)")
            }
        }
        .navigationTitle("Context Composition")
        .onAppear {
            syncFromDefaults()
            syncEnvInitial()
        }
    }

    private func keyValue(_ k: String, value: String) -> some View {
        HStack {
            Text(k)
            Spacer()
            Text(value).foregroundStyle(.secondary)
        }
    }

    private func syncFromDefaults() {
        defFlag = defaults.getFlag("promo")
        defCount = defaults.getCounter("launch_count")
        defUserK = (defaults.getUserData("k", as: String.self) ?? defUserK)
    }

    private func syncEnvInitial() {
        env.flags["promo"] = envFlag
        env.counters["launch_count"] = envCount
        env.userData["k"] = envUserK
    }
}

#Preview {
    NavigationView { CompositeDemoView() }
}
