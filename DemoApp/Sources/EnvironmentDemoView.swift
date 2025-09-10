import SwiftUI
import SpecificationKit

struct EnvironmentDemoView: View {
    // Persisted toggles via AppStorage
    @AppStorage("promo_enabled") private var promoEnabled: Bool = false
    @AppStorage("launch_count") private var launchCount: Int = 0

    // SwiftUI environment
    @Environment(\.locale) private var locale
    @Environment(\.colorScheme) private var colorScheme

    // Provider bridging environment/app storage -> EvaluationContext
    @StateObject private var envProvider = EnvironmentContextProvider()

    // Sample specs evaluated against provider context
    private var promoFlagSpec: FeatureFlagSpec { FeatureFlagSpec(flagKey: "promo_enabled", expected: true) }
    private var launchCountSpec: AnySpecification<EvaluationContext> {
        AnySpecification(
            PredicateSpec<EvaluationContext>.counter("launch_count", .greaterThanOrEqual, 3)
        )
    }

    var body: some View {
        List {
            Section(header: Text("Environment")) {
                keyValueRow(title: "Locale", value: locale.identifier, systemImage: "globe")
                keyValueRow(
                    title: "Color Scheme",
                    value: colorScheme == .dark ? "dark" : "light",
                    systemImage: "moonphase"
                )
            }

            Section(header: Text("App Settings")) {
                Toggle(isOn: $promoEnabled) {
                    Label("Promo Enabled", systemImage: "flag")
                }
                Stepper(value: $launchCount, in: 0...20) {
                    Label("Launch Count: \(launchCount)", systemImage: "number.circle")
                }
                Button(role: .destructive) {
                    promoEnabled = false
                    launchCount = 0
                } label: {
                    Label("Reset", systemImage: "arrow.uturn.backward")
                }
            }

            Section(header: Text("Evaluation")) {
                let ctx = envProvider.currentContext()
                statusRow(
                    title: "FeatureFlag(promo_enabled) == true",
                    ok: promoFlagSpec.isSatisfiedBy(ctx)
                )
                statusRow(
                    title: "launch_count >= 3",
                    ok: launchCountSpec.isSatisfiedBy(ctx)
                )
            }
        }
        .listStyle(SidebarListStyle())
        .navigationTitle("Environment Context")
        .onAppear(perform: syncProvider)
        .onChange(of: locale) { _ in syncProvider() }
        .onChange(of: colorScheme) { _ in syncProvider() }
        .onChange(of: promoEnabled) { newValue in
            envProvider.flags["promo_enabled"] = newValue
        }
        .onChange(of: launchCount) { newValue in
            envProvider.counters["launch_count"] = newValue
        }
    }

    private func keyValueRow(title: String, value: String, systemImage: String) -> some View {
        HStack {
            Label(title, systemImage: systemImage)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
        }
    }

    private func statusRow(title: String, ok: Bool) -> some View {
        HStack {
            Image(systemName: ok ? "checkmark.circle.fill" : "xmark.octagon.fill")
                .foregroundColor(ok ? .green : .red)
            Text(title)
            Spacer()
            Text(ok ? "Pass" : "Fail")
                .foregroundColor(.secondary)
        }
    }

    private func syncProvider() {
        // Environment snapshot
        envProvider.locale = locale
        envProvider.interfaceStyle = (colorScheme == .dark ? "dark" : "light")

        // AppStorage bridge
        envProvider.flags["promo_enabled"] = promoEnabled
        envProvider.counters["launch_count"] = launchCount
    }
}

#Preview {
    NavigationView {
        EnvironmentDemoView()
    }
}
