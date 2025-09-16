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
                #elseif os(macOS)
                    NavigationLink(destination: MacOSSystemDemoView()) {
                        Label("System State", systemImage: "desktopcomputer")
                            .badge("macOS")
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

            Section(header: Text("Live Platform Context Demo")) {
                VStack(alignment: .leading, spacing: 12) {
                    #if os(macOS)
                        Text("macOS System Context Provider")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        LiveMacOSContextDemo()
                    #elseif os(iOS)
                        Text("iOS Device Context Provider")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        LiveIOSContextDemo()
                    #else
                        Text("Platform context providers are available on macOS and iOS")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    #endif
                }
                .padding(.vertical, 8)
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
                        Text("System State")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        PlatformSupportBadge(supported: false)
                            .frame(width: 50)
                        PlatformSupportBadge(supported: true)
                            .frame(width: 50)
                        PlatformSupportBadge(supported: false)
                            .frame(width: 50)
                        PlatformSupportBadge(supported: false)
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

#if os(macOS)
    @available(macOS 10.15, *)
    struct MacOSSystemDemoView: View {
        @StateObject private var systemProvider = MacOSSystemContextProvider()
        @StateObject private var refreshTimer = RefreshTimer()

        // Specification test results
        @State private var darkModeResult: String = "—"
        @State private var batteryResult: String = "—"
        @State private var dockResult: String = "—"
        @State private var performanceResult: String = "—"
        @State private var memoryResult: String = "—"

        var body: some View {
            List {
                Section(
                    header: Text("macOS System State"),
                    footer: Text("Real-time monitoring of macOS system preferences and state")
                ) {
                    SystemStateRow(
                        title: "Dark Mode",
                        value: systemProvider.currentContext().isDarkModeEnabled == true
                            ? "Enabled" : "Disabled",
                        systemImage: "moon.fill"
                    )

                    SystemStateRow(
                        title: "Reduce Motion",
                        value: systemProvider.currentContext().isReduceMotionEnabled == true
                            ? "Enabled" : "Disabled",
                        systemImage: "figure.walk"
                    )

                    if let uptime = systemProvider.currentContext().systemUptime {
                        SystemStateRow(
                            title: "System Uptime",
                            value: formatUptime(uptime),
                            systemImage: "clock"
                        )
                    }

                    if let version = systemProvider.currentContext().operatingSystemVersion {
                        SystemStateRow(
                            title: "macOS Version",
                            value: version,
                            systemImage: "info.circle"
                        )
                    }

                    if let cores = systemProvider.currentContext().processorCount {
                        SystemStateRow(
                            title: "CPU Cores",
                            value: "\(cores)",
                            systemImage: "cpu"
                        )
                    }

                    if let memory = systemProvider.currentContext().physicalMemory {
                        SystemStateRow(
                            title: "Physical Memory",
                            value: formatMemory(memory),
                            systemImage: "memorychip"
                        )
                    }

                    SystemStateRow(
                        title: "On Battery",
                        value: systemProvider.currentContext().isOnBattery == true ? "Yes" : "No",
                        systemImage: "battery.100"
                    )

                    if let dockPosition = systemProvider.currentContext().dockPosition {
                        SystemStateRow(
                            title: "Dock Position",
                            value: dockPosition.capitalized,
                            systemImage: "dock.rectangle"
                        )
                    }

                    if let menuBarHeight = systemProvider.currentContext().menuBarHeight {
                        SystemStateRow(
                            title: "Menu Bar Height",
                            value: "\(Int(menuBarHeight))pt",
                            systemImage: "menubar.rectangle"
                        )
                    }

                    SystemStateRow(
                        title: "Performance Tier",
                        value: systemProvider.currentContext().performanceTier.rawValue.capitalized,
                        systemImage: "speedometer"
                    )
                }

                Section(header: Text("Specification Examples")) {
                    VStack(alignment: .leading, spacing: 12) {
                        Button("Test Dark Mode Spec") {
                            testDarkModeSpec()
                        }
                        Text("Result: \(darkModeResult)")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Button("Test Battery Spec") {
                            testBatterySpec()
                        }
                        Text("Result: \(batteryResult)")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Button("Test Dock Position Spec") {
                            testDockSpec()
                        }
                        Text("Result: \(dockResult)")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Button("Test Performance Spec") {
                            testPerformanceSpec()
                        }
                        Text("Result: \(performanceResult)")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Button("Test Memory Spec (8GB+)") {
                            testMemorySpec()
                        }
                        Text("Result: \(memoryResult)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section(
                    header: Text("Cross-Platform Factory"),
                    footer: Text("macOS specifications with automatic platform detection")
                ) {
                    VStack(alignment: .leading, spacing: 8) {
                        CodeExample(
                            title: "Dark Mode Detection",
                            code: "PlatformContextProviders.createMacOSSystemSpec(.darkMode)"
                        )

                        CodeExample(
                            title: "Battery State",
                            code: "PlatformContextProviders.createMacOSSystemSpec(.onBattery)"
                        )

                        CodeExample(
                            title: "Dock Position",
                            code: "PlatformContextProviders.createMacOSDockSpec(.bottom)"
                        )

                        CodeExample(
                            title: "Performance Tier",
                            code: "PlatformContextProviders.createMacOSPerformanceSpec(.medium)"
                        )

                        CodeExample(
                            title: "Memory Requirement",
                            code:
                                "PlatformContextProviders.createMacOSSystemSpec(.highMemory(minimumGB: 8))"
                        )
                    }
                }

                Section(header: Text("System Health")) {
                    VStack(alignment: .leading, spacing: 8) {
                        let context = systemProvider.currentContext()

                        HStack {
                            Image(
                                systemName: context.isHighPerformanceAvailable
                                    ? "checkmark.circle.fill" : "xmark.circle.fill"
                            )
                            .foregroundColor(context.isHighPerformanceAvailable ? .green : .red)
                            Text("High Performance Available")
                        }

                        HStack {
                            Image(
                                systemName: context.shouldReduceFeatures
                                    ? "exclamationmark.triangle.fill" : "checkmark.circle.fill"
                            )
                            .foregroundColor(context.shouldReduceFeatures ? .orange : .green)
                            Text("Should Reduce Features")
                        }

                        HStack {
                            Image(
                                systemName: context.hasAccessibilityFeaturesEnabled
                                    ? "accessibility" : "checkmark.circle.fill"
                            )
                            .foregroundColor(
                                context.hasAccessibilityFeaturesEnabled ? .blue : .green)
                            Text("Accessibility Features")
                        }
                    }
                }
            }
            .navigationTitle("macOS System")
            .onReceive(refreshTimer.timer) { _ in
                // Timer triggers UI refresh
            }
        }

        private func formatUptime(_ seconds: TimeInterval) -> String {
            let days = Int(seconds) / 86400
            let hours = Int(seconds) % 86400 / 3600
            let minutes = Int(seconds) % 3600 / 60

            if days > 0 {
                return "\(days)d \(hours)h \(minutes)m"
            } else if hours > 0 {
                return "\(hours)h \(minutes)m"
            } else {
                return "\(minutes)m"
            }
        }

        private func formatMemory(_ bytes: UInt64) -> String {
            let gb = Double(bytes) / (1024 * 1024 * 1024)
            return String(format: "%.1f GB", gb)
        }

        private func testDarkModeSpec() {
            let spec = PlatformContextProviders.createMacOSSystemSpec(.darkMode)
            let result = spec.isSatisfiedBy("test")
            darkModeResult = result ? "Dark Mode ENABLED" : "Dark Mode DISABLED"
        }

        private func testBatterySpec() {
            let spec = PlatformContextProviders.createMacOSSystemSpec(.onBattery)
            let result = spec.isSatisfiedBy("test")
            batteryResult = result ? "RUNNING on battery" : "PLUGGED IN"
        }

        private func testDockSpec() {
            let spec = PlatformContextProviders.createMacOSDockSpec(.bottom)
            let result = spec.isSatisfiedBy("test")
            dockResult = result ? "Dock at BOTTOM" : "Dock NOT at bottom"
        }

        private func testPerformanceSpec() {
            let spec = PlatformContextProviders.createMacOSPerformanceSpec(.medium)
            let result = spec.isSatisfiedBy("test")
            performanceResult = result ? "Performance tier SUFFICIENT" : "Performance tier LOW"
        }

        private func testMemorySpec() {
            let spec = PlatformContextProviders.createMacOSSystemSpec(.highMemory(minimumGB: 8))
            let result = spec.isSatisfiedBy("test")
            memoryResult = result ? "Memory SUFFICIENT (8GB+)" : "Memory INSUFFICIENT (<8GB)"
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

struct SystemStateRow: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        HStack {
            Image(systemName: systemImage)
                .foregroundColor(.orange)
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

// MARK: - Live Platform Context Demos

#if os(macOS)
    @available(macOS 10.15, *)
    struct LiveMacOSContextDemo: View {
        @StateObject private var provider = MacOSSystemContextProvider()
        @StateObject private var refreshTimer = RefreshTimer()
        @State private var specResults: [String: String] = [:]

        var body: some View {
            let context = provider.currentContext()

            VStack(alignment: .leading, spacing: 8) {
                // Current system state
                Group {
                    statusRow(
                        "Dark Mode", value: context.isDarkModeEnabled == true ? "ON" : "OFF",
                        color: context.isDarkModeEnabled == true ? .blue : .gray)

                    if let uptime = context.systemUptime {
                        statusRow("System Uptime", value: formatUptime(uptime), color: .green)
                    }

                    statusRow(
                        "On Battery", value: context.isOnBattery == true ? "YES" : "NO",
                        color: context.isOnBattery == true ? .orange : .green)

                    if let dock = context.dockPosition {
                        statusRow("Dock Position", value: dock.capitalized, color: .purple)
                    }

                    if let memory = context.physicalMemory {
                        statusRow("Memory", value: formatMemory(memory), color: .cyan)
                    }
                }

                Divider()

                // Specification tests
                Text("Live Specification Tests")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)

                Group {
                    Button("Dark Mode") {
                        testDarkModeSpec()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.mini)

                    if let result = specResults["darkMode"] {
                        Text("Result: \(result)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    Button("Memory (8GB+)") {
                        testMemorySpec()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.mini)

                    if let result = specResults["memory"] {
                        Text("Result: \(result)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .onReceive(refreshTimer.timer) { _ in
                // Auto-refresh context data
            }
        }

        private func statusRow(_ title: String, value: String, color: Color) -> some View {
            HStack {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                Text(title)
                    .font(.caption)
                Spacer()
                Text(value)
                    .font(.caption)
                    .fontWeight(.medium)
            }
        }

        private func formatUptime(_ seconds: TimeInterval) -> String {
            let hours = Int(seconds) / 3600
            let minutes = Int(seconds) % 3600 / 60
            return "\(hours)h \(minutes)m"
        }

        private func formatMemory(_ bytes: UInt64) -> String {
            let gb = Double(bytes) / (1024 * 1024 * 1024)
            return String(format: "%.1f GB", gb)
        }

        private func testDarkModeSpec() {
            let spec = PlatformContextProviders.createMacOSSystemSpec(.darkMode)
            let result = spec.isSatisfiedBy("test")
            specResults["darkMode"] = result ? "✅ Dark Mode" : "❌ Light Mode"
        }

        private func testMemorySpec() {
            let spec = PlatformContextProviders.createMacOSSystemSpec(.highMemory(minimumGB: 8))
            let result = spec.isSatisfiedBy("test")
            specResults["memory"] = result ? "✅ 8GB+" : "❌ < 8GB"
        }
    }
#endif

#if os(iOS)
    @available(iOS 14.0, *)
    struct LiveIOSContextDemo: View {
        @StateObject private var provider = DeviceContextProvider()
        @StateObject private var refreshTimer = RefreshTimer()
        @State private var specResults: [String: String] = [:]

        var body: some View {
            let context = provider.deviceContext

            VStack(alignment: .leading, spacing: 8) {
                // Current device state
                Group {
                    statusRow(
                        "Battery Level", value: "\(Int(context.batteryLevel * 100))%",
                        color: batteryColor(context.batteryLevel))

                    statusRow(
                        "Low Power Mode", value: context.isLowPowerModeEnabled ? "ON" : "OFF",
                        color: context.isLowPowerModeEnabled ? .orange : .green)

                    statusRow(
                        "Dark Mode", value: context.isDarkModeEnabled ? "ON" : "OFF",
                        color: context.isDarkModeEnabled ? .blue : .gray)

                    statusRow(
                        "Thermal State", value: thermalStateText(context.thermalState),
                        color: thermalColor(context.thermalState))

                    statusRow(
                        "Voice Over", value: context.isVoiceOverRunning ? "RUNNING" : "OFF",
                        color: context.isVoiceOverRunning ? .blue : .gray)
                }

                Divider()

                // Specification tests
                Text("Live Specification Tests")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)

                Group {
                    Button("Low Power") {
                        testLowPowerSpec()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.mini)

                    if let result = specResults["lowPower"] {
                        Text("Result: \(result)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    Button("Dark Mode") {
                        testDarkModeSpec()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.mini)

                    if let result = specResults["darkMode"] {
                        Text("Result: \(result)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .onReceive(refreshTimer.timer) { _ in
                // Auto-refresh device data
            }
        }

        private func statusRow(_ title: String, value: String, color: Color) -> some View {
            HStack {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                Text(title)
                    .font(.caption)
                Spacer()
                Text(value)
                    .font(.caption)
                    .fontWeight(.medium)
            }
        }

        private func batteryColor(_ level: Float) -> Color {
            switch level {
            case 0.0..<0.2: return .red
            case 0.2..<0.5: return .orange
            default: return .green
            }
        }

        private func thermalColor(_ state: ProcessInfo.ThermalState) -> Color {
            switch state {
            case .nominal: return .green
            case .fair: return .yellow
            case .serious: return .orange
            case .critical: return .red
            @unknown default: return .gray
            }
        }

        private func thermalStateText(_ state: ProcessInfo.ThermalState) -> String {
            switch state {
            case .nominal: return "Normal"
            case .fair: return "Fair"
            case .serious: return "Serious"
            case .critical: return "Critical"
            @unknown default: return "Unknown"
            }
        }

        private func testLowPowerSpec() {
            if let spec = PlatformContextProviders.createBatterySpec(.lowPowerMode) {
                let context = provider.currentContext()
                let result = spec.isSatisfiedBy(context)
                specResults["lowPower"] = result ? "✅ Low Power ON" : "❌ Low Power OFF"
            } else {
                specResults["lowPower"] = "❓ Not supported"
            }
        }

        private func testDarkModeSpec() {
            if let spec = PlatformContextProviders.createDeviceCapabilitySpec(.darkMode) {
                let context = provider.currentContext()
                let result = spec.isSatisfiedBy(context)
                specResults["darkMode"] = result ? "✅ Dark Mode ON" : "❌ Light Mode"
            } else {
                specResults["darkMode"] = "❓ Not supported"
            }
        }
    }
#endif

#Preview {
    if #available(iOS 14.0, macOS 11.0, watchOS 7.0, tvOS 14.0, *) {
        NavigationView {
            PlatformContextDemoView()
        }
    } else {
        Text("PlatformContextDemoView requires iOS 14.0+")
    }
}
