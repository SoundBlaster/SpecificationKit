import Foundation
import SpecificationKit
import SwiftUI

#if canImport(CoreLocation) && (os(iOS) || os(watchOS))
    import CoreLocation
#endif

#if canImport(UIKit) && (os(iOS) || os(tvOS))
    import UIKit
#endif

@available(iOS 14.0, macOS 11.0, watchOS 7.0, tvOS 14.0, *)
struct PlatformContextDemoView: View {
    var body: some View {
        List {
            Section(
                header: Text("Platform Features"),
                footer: Text("iOS-specific context providers for device state and location")
            ) {
                #if os(iOS)
                    NavigationLink(destination: DeviceInfoDemoView()) {
                        Label("Device State", systemImage: "iphone")
                            .badge("iOS")
                    }

                    NavigationLink(destination: LocationDemoView()) {
                        Label("Location Context", systemImage: "location")
                            .badge("iOS")
                    }
                #else
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Platform-specific features are available on iOS")
                            .foregroundStyle(.secondary)

                        Text("• Device State Monitoring")
                        Text("• Location-Based Specifications")
                        Text("• Battery and Thermal Management")
                        Text("• Accessibility State Detection")
                    }
                    .font(.caption)
                    .padding(.vertical, 4)
                #endif
            }

            Section(header: Text("Cross-Platform Factory")) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("PlatformContextProviders provides unified factory methods:")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("createDeviceCapabilitySpec(.darkMode)")
                        }

                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("createLocationBasedSpec(.atLocation)")
                        }

                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("createBatterySpec(.lowPowerMode)")
                        }

                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Graceful degradation on unsupported platforms")
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
            }

            Section(header: Text("Platform Support Matrix")) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Feature")
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("iOS")
                            .fontWeight(.medium)
                            .frame(width: 50)
                        Text("macOS")
                            .fontWeight(.medium)
                            .frame(width: 50)
                        Text("watchOS")
                            .fontWeight(.medium)
                            .frame(width: 50)
                        Text("tvOS")
                            .fontWeight(.medium)
                            .frame(width: 50)
                    }
                    .font(.caption)

                    Divider()

                    HStack {
                        Text("Device State")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        PlatformSupportBadge(supported: true)
                            .frame(width: 50)
                        PlatformSupportBadge(supported: false)
                            .frame(width: 50)
                        PlatformSupportBadge(supported: false)
                            .frame(width: 50)
                        PlatformSupportBadge(supported: true)
                            .frame(width: 50)
                    }

                    HStack {
                        Text("Location")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        PlatformSupportBadge(supported: true)
                            .frame(width: 50)
                        PlatformSupportBadge(supported: false)
                            .frame(width: 50)
                        PlatformSupportBadge(supported: true)
                            .frame(width: 50)
                        PlatformSupportBadge(supported: false)
                            .frame(width: 50)
                    }

                    HStack {
                        Text("Battery")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        PlatformSupportBadge(supported: true)
                            .frame(width: 50)
                        PlatformSupportBadge(supported: false)
                            .frame(width: 50)
                        PlatformSupportBadge(supported: true)
                            .frame(width: 50)
                        PlatformSupportBadge(supported: false)
                            .frame(width: 50)
                    }

                    HStack {
                        Text("Thermal")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        PlatformSupportBadge(supported: true)
                            .frame(width: 50)
                        PlatformSupportBadge(supported: false)
                            .frame(width: 50)
                        PlatformSupportBadge(supported: false)
                            .frame(width: 50)
                        PlatformSupportBadge(supported: false)
                            .frame(width: 50)
                    }
                }
                .font(.caption2)
            }
        }
        .navigationTitle("Platform Context")
    }
}

struct PlatformSupportBadge: View {
    let supported: Bool

    var body: some View {
        Image(systemName: supported ? "checkmark.circle.fill" : "xmark.circle.fill")
            .foregroundColor(supported ? .green : .red)
    }
}

#if os(iOS)
    @available(iOS 14.0, *)
    struct DeviceInfoDemoView: View {
        @StateObject private var deviceProvider = DeviceContextProvider()
        @StateObject private var refreshTimer = RefreshTimer()

        // Specifications for different device states
        @State private var batteryLowResult: String = "—"
        @State private var thermalStateResult: String = "—"
        @State private var darkModeResult: String = "—"
        @State private var accessibilityResult: String = "—"

        var body: some View {
            List {
                Section(
                    header: Text("Device State Monitoring"),
                    footer: Text("Real-time monitoring of iOS device capabilities and state")
                ) {
                    DeviceStateRow(
                        title: "Battery Level",
                        value: "\(Int(deviceProvider.deviceContext.batteryLevel * 100))%",
                        systemImage: batterySystemImage
                    )

                    DeviceStateRow(
                        title: "Battery State",
                        value: batteryStateText,
                        systemImage: "battery.100"
                    )

                    DeviceStateRow(
                        title: "Low Power Mode",
                        value: deviceProvider.deviceContext.isLowPowerModeEnabled
                            ? "Enabled" : "Disabled",
                        systemImage: "battery.0"
                    )

                    DeviceStateRow(
                        title: "Thermal State",
                        value: thermalStateText,
                        systemImage: thermalSystemImage
                    )

                    DeviceStateRow(
                        title: "Dark Mode",
                        value: deviceProvider.deviceContext.isDarkModeEnabled
                            ? "Enabled" : "Disabled",
                        systemImage: "moon.fill"
                    )

                    DeviceStateRow(
                        title: "Reduced Motion",
                        value: deviceProvider.deviceContext.isReducedMotionEnabled
                            ? "Enabled" : "Disabled",
                        systemImage: "figure.walk"
                    )

                    DeviceStateRow(
                        title: "Voice Over",
                        value: deviceProvider.deviceContext.isVoiceOverRunning
                            ? "Running" : "Not Running",
                        systemImage: "speaker.wave.3"
                    )
                }

                Section(header: Text("Specification Examples")) {
                    VStack(alignment: .leading, spacing: 12) {
                        Button("Test Battery Low Spec") {
                            testBatteryLowSpec()
                        }
                        Text("Result: \(batteryLowResult)")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Button("Test Thermal State Spec") {
                            testThermalStateSpec()
                        }
                        Text("Result: \(thermalStateResult)")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Button("Test Dark Mode Spec") {
                            testDarkModeSpec()
                        }
                        Text("Result: \(darkModeResult)")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Button("Test Accessibility Spec") {
                            testAccessibilitySpec()
                        }
                        Text("Result: \(accessibilityResult)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section(
                    header: Text("Cross-Platform Factory"),
                    footer: Text(
                        "These specifications work across platforms with graceful degradation")
                ) {
                    VStack(alignment: .leading, spacing: 8) {
                        CodeExample(
                            title: "Battery Specification",
                            code: "PlatformContextProviders.createBatterySpec(.lowPowerMode)"
                        )

                        CodeExample(
                            title: "Device Capability",
                            code: "PlatformContextProviders.createDeviceCapabilitySpec(.darkMode)"
                        )

                        CodeExample(
                            title: "Accessibility",
                            code: "PlatformContextProviders.createDeviceCapabilitySpec(.voiceOver)"
                        )
                    }
                }
            }
            .navigationTitle("Device State")
            .onReceive(refreshTimer.timer) { _ in
                // Timer triggers UI refresh
            }
        }

        private var batterySystemImage: String {
            let level = deviceProvider.deviceContext.batteryLevel
            switch level {
            case 0.0..<0.25: return "battery.25"
            case 0.25..<0.5: return "battery.50"
            case 0.5..<0.75: return "battery.75"
            default: return "battery.100"
            }
        }

        private var batteryStateText: String {
            switch deviceProvider.deviceContext.batteryState {
            case .unknown: return "Unknown"
            case .unplugged: return "Unplugged"
            case .charging: return "Charging"
            case .full: return "Full"
            @unknown default: return "Unknown"
            }
        }

        private var thermalStateText: String {
            switch deviceProvider.deviceContext.thermalState {
            case .nominal: return "Nominal"
            case .fair: return "Fair"
            case .serious: return "Serious"
            case .critical: return "Critical"
            @unknown default: return "Unknown"
            }
        }

        private var thermalSystemImage: String {
            switch deviceProvider.deviceContext.thermalState {
            case .nominal: return "thermometer.medium"
            case .fair: return "thermometer.medium"
            case .serious: return "thermometer.high"
            case .critical: return "thermometer.high"
            @unknown default: return "thermometer"
            }
        }

        private func testBatteryLowSpec() {
            if let spec = PlatformContextProviders.createBatterySpec(.lowPowerMode) {
                let context = deviceProvider.currentContext()
                let result = spec.isSatisfiedBy(context)
                batteryLowResult = result ? "Low Power Mode ACTIVE" : "Low Power Mode INACTIVE"
            } else {
                batteryLowResult = "Not supported on this platform"
            }
        }

        private func testThermalStateSpec() {
            if let spec = PlatformContextProviders.createBatterySpec(.thermalStateNormal) {
                let context = deviceProvider.currentContext()
                let result = spec.isSatisfiedBy(context)
                thermalStateResult = result ? "Thermal state NORMAL" : "Thermal state ELEVATED"
            } else {
                thermalStateResult = "Not supported on this platform"
            }
        }

        private func testDarkModeSpec() {
            if let spec = PlatformContextProviders.createDeviceCapabilitySpec(.darkMode) {
                let context = deviceProvider.currentContext()
                let result = spec.isSatisfiedBy(context)
                darkModeResult = result ? "Dark Mode ENABLED" : "Dark Mode DISABLED"
            } else {
                darkModeResult = "Not supported on this platform"
            }
        }

        private func testAccessibilitySpec() {
            if let spec = PlatformContextProviders.createDeviceCapabilitySpec(.voiceOver) {
                let context = deviceProvider.currentContext()
                let result = spec.isSatisfiedBy(context)
                accessibilityResult = result ? "VoiceOver RUNNING" : "VoiceOver NOT RUNNING"
            } else {
                accessibilityResult = "Not supported on this platform"
            }
        }
    }

    @available(iOS 14.0, *)
    struct LocationDemoView: View {
        @StateObject private var locationProvider = LocationContextProvider()
        @StateObject private var refreshTimer = RefreshTimer()

        @State private var targetLatitude: String = "37.7749"
        @State private var targetLongitude: String = "-122.4194"
        @State private var radiusMeters: String = "1000"
        @State private var minAccuracy: String = "100"

        @State private var locationResult: String = "—"
        @State private var proximityResult: String = "—"
        @State private var accuracyResult: String = "—"

        var body: some View {
            List {
                Section(
                    header: Text("Location Status"),
                    footer: Text("Current device location and authorization status")
                ) {
                    LocationStatusRow(
                        title: "Authorization",
                        value: authorizationStatusText,
                        systemImage: "location"
                    )

                    if locationProvider.locationContext.authorizationStatus == .authorizedWhenInUse
                        || locationProvider.locationContext.authorizationStatus == .authorizedAlways
                    {

                        if let location = locationProvider.locationContext.currentLocation {
                            LocationStatusRow(
                                title: "Latitude",
                                value: String(format: "%.6f", location.coordinate.latitude),
                                systemImage: "location.north"
                            )

                            LocationStatusRow(
                                title: "Longitude",
                                value: String(format: "%.6f", location.coordinate.longitude),
                                systemImage: "location"
                            )

                            LocationStatusRow(
                                title: "Accuracy",
                                value: "\(Int(location.horizontalAccuracy))m",
                                systemImage: "target"
                            )

                            LocationStatusRow(
                                title: "Last Update",
                                value: timeFormatter.string(from: location.timestamp),
                                systemImage: "clock"
                            )
                        } else {
                            Text("Location not available")
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Location access required")
                                .foregroundStyle(.secondary)

                            Button("Request Location Permission") {
                                locationProvider.requestLocationPermission()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section(header: Text("Location Configuration")) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Target Latitude:")
                            TextField("37.7749", text: $targetLatitude)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.decimalPad)
                        }

                        HStack {
                            Text("Target Longitude:")
                            TextField("-122.4194", text: $targetLongitude)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.decimalPad)
                        }

                        HStack {
                            Text("Radius (meters):")
                            TextField("1000", text: $radiusMeters)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.numberPad)
                        }

                        HStack {
                            Text("Min Accuracy (m):")
                            TextField("100", text: $minAccuracy)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.numberPad)
                        }
                    }
                }

                Section(header: Text("Specification Examples")) {
                    VStack(alignment: .leading, spacing: 12) {
                        Button("Test Location Available") {
                            testLocationAvailableSpec()
                        }
                        Text("Result: \(locationResult)")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Button("Test Proximity Spec") {
                            testProximitySpec()
                        }
                        Text("Result: \(proximityResult)")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Button("Test Accuracy Spec") {
                            testAccuracySpec()
                        }
                        Text("Result: \(accuracyResult)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section(
                    header: Text("Cross-Platform Factory"),
                    footer: Text("Location specifications with automatic permission handling")
                ) {
                    VStack(alignment: .leading, spacing: 8) {
                        CodeExample(
                            title: "Location Available",
                            code:
                                "PlatformContextProviders.createLocationBasedSpec(.locationAvailable)"
                        )

                        CodeExample(
                            title: "At Location",
                            code:
                                "PlatformContextProviders.createLocationBasedSpec(.atLocation(lat: 37.7749, lon: -122.4194, radius: 1000))"
                        )

                        CodeExample(
                            title: "Accurate Location",
                            code:
                                "PlatformContextProviders.createLocationBasedSpec(.accurateLocation(within: 100))"
                        )
                    }
                }
            }
            .navigationTitle("Location Context")
            .onReceive(refreshTimer.timer) { _ in
                // Timer triggers UI refresh
            }
        }

        private var timeFormatter: DateFormatter {
            let formatter = DateFormatter()
            formatter.timeStyle = .medium
            return formatter
        }

        private var authorizationStatusText: String {
            switch locationProvider.locationContext.authorizationStatus {
            case .notDetermined: return "Not Determined"
            case .restricted: return "Restricted"
            case .denied: return "Denied"
            case .authorizedAlways: return "Always Authorized"
            case .authorizedWhenInUse: return "When In Use"
            @unknown default: return "Unknown"
            }
        }

        private func testLocationAvailableSpec() {
            if let spec = PlatformContextProviders.createLocationBasedSpec(.locationAvailable) {
                let context = locationProvider.currentContext()
                let result = spec.isSatisfiedBy(context)
                locationResult = result ? "Location AVAILABLE" : "Location NOT AVAILABLE"
            } else {
                locationResult = "Not supported on this platform"
            }
        }

        private func testProximitySpec() {
            guard let lat = Double(targetLatitude),
                let lon = Double(targetLongitude),
                let radius = Double(radiusMeters)
            else {
                proximityResult = "Invalid coordinates"
                return
            }

            if let spec = PlatformContextProviders.createLocationBasedSpec(
                .atLocation(lat: lat, lon: lon, radius: radius))
            {
                let context = locationProvider.currentContext()
                let result = spec.isSatisfiedBy(context)
                proximityResult = result ? "WITHIN radius" : "OUTSIDE radius"
            } else {
                proximityResult = "Not supported on this platform"
            }
        }

        private func testAccuracySpec() {
            guard let accuracy = Double(minAccuracy) else {
                accuracyResult = "Invalid accuracy value"
                return
            }

            if let spec = PlatformContextProviders.createLocationBasedSpec(
                .accurateLocation(within: accuracy))
            {
                let context = locationProvider.currentContext()
                let result = spec.isSatisfiedBy(context)
                accuracyResult = result ? "ACCURATE location" : "INACCURATE location"
            } else {
                accuracyResult = "Not supported on this platform"
            }
        }
    }
#endif

// MARK: - Helper Views

struct DeviceStateRow: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        HStack {
            Image(systemName: systemImage)
                .foregroundColor(.blue)
                .frame(width: 20)

            Text(title)

            Spacer()

            Text(value)
                .foregroundStyle(.secondary)
        }
    }
}

struct LocationStatusRow: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        HStack {
            Image(systemName: systemImage)
                .foregroundColor(.green)
                .frame(width: 20)

            Text(title)

            Spacer()

            Text(value)
                .foregroundStyle(.secondary)
        }
    }
}

struct CodeExample: View {
    let title: String
    let code: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)

            Text(code)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.secondary)
                .padding(8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(6)
        }
    }
}

class RefreshTimer: ObservableObject {
    let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
}

#Preview {
    if #available(iOS 14.0, macOS 11.0, watchOS 7.0, tvOS 14.0, *) {
        NavigationView {
            PlatformContextDemoView()
        }
    } else {
        Text("PlatformContextDemoView requires iOS 14.0+")
    }
}
