import SpecificationKit
import SwiftUI

@available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
struct PersistentContextDemoView: View {
    // Provider instance using in-memory store for demo
    @State private var persistentProvider: PersistentContextProvider?

    // UI State
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var lastUpdateTime: Date?
    @State private var contextData: String = "No data loaded"

    // Configuration options
    @State private var storeType: PersistentContextProvider.StoreType = .inMemoryStoreType
    @State private var encryptionEnabled = true
    @State private var migrationPolicy: PersistentContextProvider.MigrationPolicy = .automatic

    // Demo data inputs
    @State private var counterKey = "demo_counter"
    @State private var counterValue = 0
    @State private var flagKey = "demo_flag"
    @State private var flagValue = false
    @State private var userDataKey = "demo_data"
    @State private var userDataValue = "Hello World"
    @State private var eventKey = "demo_event"
    @State private var segmentValue = "premium"
    @State private var expirationMinutes: Double = 60
    @State private var useExpiration = false

    // Specification results
    @State private var counterSpecResult: String = "—"
    @State private var flagSpecResult: String = "—"
    @State private var eventSpecResult: String = "—"
    @State private var compositeSpecResult: String = "—"

    var body: some View {
        List {
            Section(
                header: Text("Provider Configuration"),
                footer: Text(
                    "Configure the PersistentContextProvider settings. In-memory store is recommended for demo."
                )
            ) {
                VStack(alignment: .leading, spacing: 12) {
                    Picker("Store Type", selection: $storeType) {
                        Text("In-Memory").tag(PersistentContextProvider.StoreType.inMemoryStoreType)
                        Text("SQLite").tag(PersistentContextProvider.StoreType.sqliteStoreType)
                        Text("Binary").tag(PersistentContextProvider.StoreType.binaryStoreType)
                    }
                    .pickerStyle(.segmented)

                    Toggle("Encryption Enabled", isOn: $encryptionEnabled)

                    HStack {
                        Text("Migration Policy: Automatic")
                            .foregroundStyle(.secondary)
                        Spacer()
                    }

                    Button("Create Provider") {
                        createProvider()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(persistentProvider != nil)

                    if persistentProvider != nil {
                        Text("✅ Provider created successfully")
                            .foregroundStyle(.green)
                            .font(.caption)
                    }
                }
            }

            if persistentProvider != nil {
                Section(header: Text("Data Operations")) {
                    Group {
                        // Counter operations
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Counter Operations")
                                .font(.subheadline)
                                .fontWeight(.medium)

                            HStack {
                                TextField("Key", text: $counterKey)
                                    .textFieldStyle(.roundedBorder)
                                Stepper("Value: \(counterValue)", value: $counterValue, in: 0...100)
                            }

                            HStack {
                                Button("Set Counter") {
                                    Task { await setCounter() }
                                }
                                Button("Increment") {
                                    Task { await incrementCounter() }
                                }
                                Button("Load Context") {
                                    Task { await loadContext() }
                                }
                            }
                            .disabled(isLoading)
                        }

                        // Flag operations
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Flag Operations")
                                .font(.subheadline)
                                .fontWeight(.medium)

                            HStack {
                                TextField("Key", text: $flagKey)
                                    .textFieldStyle(.roundedBorder)
                                Toggle("Value", isOn: $flagValue)
                            }

                            Button("Set Flag") {
                                Task { await setFlag() }
                            }
                            .disabled(isLoading)
                        }

                        // UserData operations
                        VStack(alignment: .leading, spacing: 8) {
                            Text("UserData Operations")
                                .font(.subheadline)
                                .fontWeight(.medium)

                            HStack {
                                TextField("Key", text: $userDataKey)
                                    .textFieldStyle(.roundedBorder)
                                TextField("Value", text: $userDataValue)
                                    .textFieldStyle(.roundedBorder)
                            }

                            Button("Set UserData") {
                                Task { await setUserData() }
                            }
                            .disabled(isLoading)
                        }

                        // Event operations
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Event Operations")
                                .font(.subheadline)
                                .fontWeight(.medium)

                            HStack {
                                TextField("Key", text: $eventKey)
                                    .textFieldStyle(.roundedBorder)
                                Button("Record Event") {
                                    Task { await recordEvent() }
                                }
                                .disabled(isLoading)
                            }
                        }

                        // Segment operations
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Segment Operations")
                                .font(.subheadline)
                                .fontWeight(.medium)

                            HStack {
                                TextField("Segment", text: $segmentValue)
                                    .textFieldStyle(.roundedBorder)
                                Button("Add Segment") {
                                    Task { await addSegment() }
                                }
                                Button("Remove") {
                                    Task { await removeSegment() }
                                }
                            }
                            .disabled(isLoading)
                        }
                    }
                }

                Section(header: Text("Expiration Settings")) {
                    Toggle("Use Expiration", isOn: $useExpiration)
                    if useExpiration {
                        Stepper(
                            "Expires in: \(Int(expirationMinutes)) minutes",
                            value: $expirationMinutes,
                            in: 1...1440
                        )
                    }
                }

                Section(header: Text("Context Data")) {
                    VStack(alignment: .leading, spacing: 8) {
                        if isLoading {
                            HStack {
                                ProgressView()
                                    .controlSize(.small)
                                Text("Loading...")
                            }
                        }

                        if let lastUpdate = lastUpdateTime {
                            Text("Last Update: \(lastUpdate, formatter: timeFormatter)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        if let error = errorMessage {
                            Text("Error: \(error)")
                                .foregroundStyle(.red)
                                .font(.caption)
                        }

                        Text(contextData)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(8)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)

                        Button("Refresh Context") {
                            Task { await loadContext() }
                        }
                        .disabled(isLoading)
                    }
                }

                Section(header: Text("Specification Examples")) {
                    VStack(alignment: .leading, spacing: 12) {
                        Button("Test Counter Spec (limit 5)") {
                            Task { await testCounterSpec() }
                        }
                        Text("Result: \(counterSpecResult)")
                            .font(.caption)

                        Button("Test Flag Spec") {
                            Task { await testFlagSpec() }
                        }
                        Text("Result: \(flagSpecResult)")
                            .font(.caption)

                        Button("Test Event Cooldown (30s)") {
                            Task { await testEventSpec() }
                        }
                        Text("Result: \(eventSpecResult)")
                            .font(.caption)

                        Button("Test Composite Spec") {
                            Task { await testCompositeSpec() }
                        }
                        Text("Result: \(compositeSpecResult)")
                            .font(.caption)
                    }
                    .disabled(isLoading)
                }

                Section(header: Text("Data Management")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Button("Clear All Data") {
                            Task { await clearAllData() }
                        }
                        .foregroundStyle(.red)

                        Button("Remove Expired Data") {
                            Task { await removeExpiredData() }
                        }
                        .foregroundStyle(.orange)
                    }
                    .disabled(isLoading)
                }
            }
        }
        .navigationTitle("Persistent Context")
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            if let error = errorMessage {
                Text(error)
            }
        }
    }

    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        return formatter
    }

    private func createProvider() {
        let config = PersistentContextProvider.Configuration(
            modelName: "SpecificationContext",
            storeType: storeType,
            migrationPolicy: migrationPolicy,
            encryptionEnabled: encryptionEnabled
        )

        persistentProvider = PersistentContextProvider(configuration: config)
        errorMessage = nil

        // Load initial context
        Task { await loadContext() }
    }

    @MainActor
    private func setCounter() async {
        guard let provider = persistentProvider else { return }

        isLoading = true
        defer { isLoading = false }

        let expiration = useExpiration ? Date().addingTimeInterval(expirationMinutes * 60) : nil
        await provider.setCounter(counterValue, for: counterKey, expirationDate: expiration)
        await loadContext()
    }

    @MainActor
    private func incrementCounter() async {
        guard let provider = persistentProvider else { return }

        isLoading = true
        defer { isLoading = false }

        await provider.incrementCounter(for: counterKey, by: 1)
        await loadContext()
    }

    @MainActor
    private func setFlag() async {
        guard let provider = persistentProvider else { return }

        isLoading = true
        defer { isLoading = false }

        let expiration = useExpiration ? Date().addingTimeInterval(expirationMinutes * 60) : nil
        await provider.setFlag(flagValue, for: flagKey, expirationDate: expiration)
        await loadContext()
    }

    @MainActor
    private func setUserData() async {
        guard let provider = persistentProvider else { return }

        isLoading = true
        defer { isLoading = false }

        let expiration = useExpiration ? Date().addingTimeInterval(expirationMinutes * 60) : nil
        await provider.setValue(userDataValue, for: userDataKey, expirationDate: expiration)
        await loadContext()
    }

    @MainActor
    private func recordEvent() async {
        guard let provider = persistentProvider else { return }

        isLoading = true
        defer { isLoading = false }

        let expiration = useExpiration ? Date().addingTimeInterval(expirationMinutes * 60) : nil
        await provider.setEvent(Date(), for: eventKey, expirationDate: expiration)
        await loadContext()
    }

    @MainActor
    private func addSegment() async {
        guard let provider = persistentProvider else { return }

        isLoading = true
        defer { isLoading = false }

        await provider.addSegment(segmentValue)
        await loadContext()
    }

    @MainActor
    private func removeSegment() async {
        guard let provider = persistentProvider else { return }

        isLoading = true
        defer { isLoading = false }

        await provider.removeSegment(segmentValue)
        await loadContext()
    }

    @MainActor
    private func loadContext() async {
        guard let provider = persistentProvider else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            let context = try await provider.currentContextAsync()
            lastUpdateTime = Date()

            // Format context data for display
            let userData =
                context.userData.isEmpty
                ? "None" : context.userData.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
            let flags =
                context.flags.isEmpty
                ? "None" : context.flags.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
            let counters =
                context.counters.isEmpty
                ? "None" : context.counters.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
            let events =
                context.events.isEmpty
                ? "None"
                : context.events.map { "\($0.key): \(timeFormatter.string(from: $0.value))" }
                    .joined(separator: ", ")
            let segments =
                context.segments.isEmpty ? "None" : Array(context.segments).joined(separator: ", ")

            contextData = """
                UserData: \(userData)
                Flags: \(flags)
                Counters: \(counters)
                Events: \(events)
                Segments: \(segments)
                """

            errorMessage = nil

        } catch {
            errorMessage = error.localizedDescription
            contextData = "Failed to load context"
        }
    }

    @MainActor
    private func testCounterSpec() async {
        guard let provider = persistentProvider else {
            counterSpecResult = "No provider"
            return
        }

        do {
            let context = try await provider.currentContextAsync()
            let spec = MaxCountSpec(counterKey: counterKey, limit: 5)
            let result = spec.isSatisfiedBy(context)
            counterSpecResult = result ? "PASS (count ≤ 5)" : "FAIL (count > 5)"
        } catch {
            counterSpecResult = "Error: \(error.localizedDescription)"
        }
    }

    @MainActor
    private func testFlagSpec() async {
        guard let provider = persistentProvider else {
            flagSpecResult = "No provider"
            return
        }

        do {
            let context = try await provider.currentContextAsync()
            let spec = FeatureFlagSpec(flagKey: flagKey, expected: true)
            let result = spec.isSatisfiedBy(context)
            flagSpecResult = result ? "PASS (flag = true)" : "FAIL (flag ≠ true)"
        } catch {
            flagSpecResult = "Error: \(error.localizedDescription)"
        }
    }

    @MainActor
    private func testEventSpec() async {
        guard let provider = persistentProvider else {
            eventSpecResult = "No provider"
            return
        }

        do {
            let context = try await provider.currentContextAsync()
            let spec = CooldownIntervalSpec(eventKey: eventKey, seconds: 30)
            let result = spec.isSatisfiedBy(context)
            eventSpecResult = result ? "PASS (cooldown OK)" : "FAIL (still in cooldown)"
        } catch {
            eventSpecResult = "Error: \(error.localizedDescription)"
        }
    }

    @MainActor
    private func testCompositeSpec() async {
        guard let provider = persistentProvider else {
            compositeSpecResult = "No provider"
            return
        }

        do {
            let context = try await provider.currentContextAsync()

            // Create a composite spec combining multiple conditions
            let counterSpec = MaxCountSpec(counterKey: counterKey, limit: 5)
            let flagSpec = FeatureFlagSpec(flagKey: flagKey, expected: true)
            let segmentSpec = UserSegmentSpec(.vip)

            let compositeSpec = counterSpec.and(flagSpec).and(segmentSpec)
            let result = compositeSpec.isSatisfiedBy(context)

            compositeSpecResult =
                result ? "PASS (all conditions met)" : "FAIL (some conditions not met)"
        } catch {
            compositeSpecResult = "Error: \(error.localizedDescription)"
        }
    }

    @MainActor
    private func clearAllData() async {
        guard let provider = persistentProvider else { return }

        isLoading = true
        defer { isLoading = false }

        await provider.clearAllData()
        await loadContext()
    }

    @MainActor
    private func removeExpiredData() async {
        guard let provider = persistentProvider else { return }

        isLoading = true
        defer { isLoading = false }

        await provider.removeExpiredData()
        await loadContext()
    }
}

#Preview {
    if #available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *) {
        NavigationView {
            PersistentContextDemoView()
        }
    } else {
        Text("PersistentContextProvider requires macOS 13.0+/iOS 16.0+")
    }
}
