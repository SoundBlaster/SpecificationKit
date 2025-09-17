//
//  PlatformContextProvidersTests.swift
//  SpecificationKit
//
//  Created by SpecificationKit on 2025.
//

import XCTest

@testable import SpecificationKit

#if canImport(CoreLocation)
    import CoreLocation
#endif

#if canImport(UIKit)
    import UIKit
#endif

/// Tests for platform-specific context providers
final class PlatformContextProvidersTests: XCTestCase {

    // MARK: - Platform Capability Tests

    func testPlatformCapabilityDetection() {
        // Test capability detection matches expected platform behavior
        #if canImport(CoreLocation) && !os(tvOS)
            XCTAssertTrue(PlatformContextProviders.supportsLocation)
        #else
            XCTAssertFalse(PlatformContextProviders.supportsLocation)
        #endif

        #if canImport(HealthKit) && (os(iOS) || os(watchOS))
            XCTAssertTrue(PlatformContextProviders.supportsHealthKit)
        #else
            XCTAssertFalse(PlatformContextProviders.supportsHealthKit)
        #endif

        #if canImport(UIKit) && (os(iOS) || os(tvOS))
            XCTAssertTrue(PlatformContextProviders.supportsDeviceInfo)
        #else
            XCTAssertFalse(PlatformContextProviders.supportsDeviceInfo)
        #endif

        #if canImport(AppKit) && os(macOS)
            XCTAssertTrue(PlatformContextProviders.supportsSystemPreferences)
        #else
            XCTAssertFalse(PlatformContextProviders.supportsSystemPreferences)
        #endif

        #if canImport(WatchKit) && os(watchOS)
            XCTAssertTrue(PlatformContextProviders.supportsWatchKit)
        #else
            XCTAssertFalse(PlatformContextProviders.supportsWatchKit)
        #endif
    }

    // MARK: - Context Provider Factory Tests

    func testDeviceContextProviderFactory() {
        let provider = PlatformContextProviders.deviceContextProvider
        XCTAssertNotNil(provider)

        // Provider should always return some form of context
        let context = provider.currentContext()
        XCTAssertNotNil(context)
    }

    func testLocationContextProviderFactory() {
        let provider = PlatformContextProviders.locationContextProvider
        XCTAssertNotNil(provider)

        // Provider should always return some form of context
        let context = provider.currentContext()
        XCTAssertNotNil(context)
    }

    // MARK: - Specification Factory Tests

    func testLocationProximitySpecFactory() {
        let coordinate = LocationCoordinate(latitude: 37.7749, longitude: -122.4194)
        let spec = PlatformContextProviders.createLocationProximitySpec(
            center: coordinate,
            radius: 1000
        )

        XCTAssertNotNil(spec)

        // Should return false on platforms without location support
        #if !canImport(CoreLocation) || os(tvOS)
            XCTAssertFalse(spec.isSatisfiedBy("test"))
        #endif
    }

    func testDeviceCapabilitySpecs() {
        // Test all device capabilities
        let capabilities: [DeviceCapability] = [
            .location, .healthKit, .darkMode, .lowPowerMode, .voiceOver,
        ]

        for capability in capabilities {
            let spec = PlatformContextProviders.createDeviceCapabilitySpec(capability)
            XCTAssertNotNil(spec, "Should create spec for capability: \(capability)")

            // Specs should be callable without crashing
            _ = spec.isSatisfiedBy("test")
        }
    }

    func testBatterySpec() {
        let spec = PlatformContextProviders.createBatterySpec(threshold: 0.5)
        XCTAssertNotNil(spec)

        // Should be callable without crashing
        _ = spec.isSatisfiedBy("test")
    }

    func testPerformanceSpec() {
        let spec = PlatformContextProviders.createPerformanceSpec()
        XCTAssertNotNil(spec)

        // Should be callable without crashing
        _ = spec.isSatisfiedBy("test")
    }

    // MARK: - LocationCoordinate Tests

    func testLocationCoordinateCreation() {
        let coordinate = LocationCoordinate(latitude: 37.7749, longitude: -122.4194)
        XCTAssertEqual(coordinate.latitude, 37.7749)
        XCTAssertEqual(coordinate.longitude, -122.4194)
    }

    #if canImport(CoreLocation)
        func testLocationCoordinateCoreLocationConversion() {
            let clCoordinate = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
            let coordinate = LocationCoordinate(clCoordinate)

            XCTAssertEqual(coordinate.latitude, 37.7749)
            XCTAssertEqual(coordinate.longitude, -122.4194)

            let convertedBack = coordinate.coreLocationCoordinate
            XCTAssertEqual(convertedBack.latitude, 37.7749)
            XCTAssertEqual(convertedBack.longitude, -122.4194)
        }
    #endif

    // MARK: - BasicDeviceContext Tests

    func testBasicDeviceContext() {
        let context = BasicDeviceContext()
        XCTAssertFalse(context.systemName.isEmpty)
        XCTAssertFalse(context.systemVersion.isEmpty)

        // Should contain recognizable system name
        let validNames = ["macOS", "iOS", "watchOS", "tvOS", "Unknown"]
        XCTAssertTrue(validNames.contains(context.systemName))

        // Version should be in format x.y.z
        let versionComponents = context.systemVersion.split(separator: ".")
        XCTAssertGreaterThanOrEqual(versionComponents.count, 2)
    }

    // MARK: - EmptyLocationContext Tests

    func testEmptyLocationContext() {
        let context = EmptyLocationContext()
        XCTAssertNil(context.currentLocation)
        XCTAssertFalse(context.isLocationAvailable)
    }

    // MARK: - Permission Helper Tests

    func testLocationPermissionCheck() {
        let hasPermission = PlatformContextProviders.hasLocationPermission

        // Should not crash and return a boolean
        XCTAssertTrue(hasPermission == true || hasPermission == false)

        #if !canImport(CoreLocation) || !(os(iOS) || os(watchOS))
            // Should be false on platforms without location support
            XCTAssertFalse(hasPermission)
        #endif
    }

    func testHealthPermissionCheck() {
        let hasPermission = PlatformContextProviders.hasHealthPermission()

        // Should not crash and return a boolean
        XCTAssertTrue(hasPermission == true || hasPermission == false)

        #if !canImport(HealthKit) || !(os(iOS) || os(watchOS))
            // Should be false on platforms without HealthKit support
            XCTAssertFalse(hasPermission)
        #endif
    }

    // MARK: - Integration Tests

    func testDeviceContextProviderIntegration() {
        #if canImport(UIKit) && (os(iOS) || os(tvOS))
            if #available(iOS 13.0, tvOS 13.0, *) {
                let provider = DeviceContextProvider()
                let context = provider.currentContext()

                // Verify basic properties are populated
                XCTAssertFalse(context.deviceModel.isEmpty)
                XCTAssertFalse(context.systemVersion.isEmpty)
                XCTAssertFalse(context.deviceName.isEmpty)

                // Verify convenience properties work
                _ = context.isiPhone
                _ = context.isiPad
                _ = context.isHighPerformanceAvailable
                _ = context.shouldReduceFeatures
                _ = context.hasAccessibilityFeaturesEnabled
            }
        #endif
    }

    func testLocationContextProviderIntegration() {
        #if canImport(CoreLocation) && (os(iOS) || os(watchOS))
            if #available(iOS 14.0, watchOS 7.0, *) {
                let config = LocationContextProvider.Configuration(
                    accuracy: kCLLocationAccuracyKilometer,
                    distanceFilter: 100.0,
                    requestPermission: false,  // Don't request permissions in tests
                    fallbackLocation: CLLocation(latitude: 37.7749, longitude: -122.4194)
                )

                let provider = LocationContextProvider(configuration: config)
                let context = provider.currentContext()

                // Context should be valid
                XCTAssertNotNil(context)

                // Convenience properties should work
                _ = context.latitude
                _ = context.longitude
                _ = context.accuracy
                _ = context.timestamp
                _ = context.altitude
                _ = context.speed
                _ = context.course

                // Provider methods should not crash
                _ = provider.isLocationAvailable
                _ = provider.authorizationStatus
            }
        #endif
    }

    // MARK: - Specification Usage Tests

    func testSpecificationUsagePatterns() {
        // Test that specifications can be evaluated without crashing
        let darkModeSpec = PlatformContextProviders.createDeviceCapabilitySpec(.darkMode)
        let batterySpec = PlatformContextProviders.createBatterySpec(threshold: 0.2)
        let performanceSpec = PlatformContextProviders.createPerformanceSpec()

        // All should be evaluable without crashing
        _ = darkModeSpec.isSatisfiedBy("test")
        _ = batterySpec.isSatisfiedBy("test")
        _ = performanceSpec.isSatisfiedBy("test")
    }

    // MARK: - Error Handling Tests

    func testGracefulDegradation() {
        // Test that the system gracefully handles unsupported platforms

        // These should never crash, even on unsupported platforms
        let deviceProvider = PlatformContextProviders.deviceContextProvider
        let locationProvider = PlatformContextProviders.locationContextProvider

        let deviceContext = deviceProvider.currentContext()
        let locationContext = locationProvider.currentContext()

        XCTAssertNotNil(deviceContext)
        XCTAssertNotNil(locationContext)

        // Specifications should also not crash
        let specs = [
            PlatformContextProviders.createDeviceCapabilitySpec(.location),
            PlatformContextProviders.createDeviceCapabilitySpec(.healthKit),
            PlatformContextProviders.createDeviceCapabilitySpec(.darkMode),
            PlatformContextProviders.createBatterySpec(),
            PlatformContextProviders.createPerformanceSpec(),
        ]

        for spec in specs {
            // Should not crash when evaluated
            _ = spec.isSatisfiedBy("test")
        }
    }
}

// MARK: - Mock Tests for Platform-Specific Behavior

#if canImport(UIKit) && (os(iOS) || os(tvOS))
    @available(iOS 13.0, tvOS 13.0, *)
    final class DeviceContextProviderTests: XCTestCase {

        func testDeviceContextCreation() {
            let provider = DeviceContextProvider()
            let context = provider.currentContext()

            // Basic device information should be available
            XCTAssertFalse(context.deviceModel.isEmpty)
            XCTAssertFalse(context.systemVersion.isEmpty)
            XCTAssertFalse(context.deviceName.isEmpty)

            // Numeric values should be within expected ranges
            if let batteryLevel = context.batteryLevel {
                XCTAssertGreaterThanOrEqual(batteryLevel, 0.0)
                XCTAssertLessThanOrEqual(batteryLevel, 1.0)
            }

            XCTAssertGreaterThanOrEqual(context.screenBrightness, 0.0)
            XCTAssertLessThanOrEqual(context.screenBrightness, 1.0)

            XCTAssertGreaterThan(context.screenScale, 0.0)
            XCTAssertGreaterThan(context.processorCount, 0)
            XCTAssertGreaterThan(context.physicalMemory, 0)
        }

        func testDeviceContextCaching() {
            let provider = DeviceContextProvider()

            let context1 = provider.currentContext()
            let context2 = provider.currentContext()

            // Contexts should be equivalent when created quickly
            XCTAssertEqual(context1.deviceModel, context2.deviceModel)
            XCTAssertEqual(context1.systemVersion, context2.systemVersion)
            XCTAssertEqual(context1.deviceName, context2.deviceName)
        }

        func testConvenienceSpecifications() {
            let darkModeSpec = DeviceContextProvider.darkModeSpecification()
            let lowPowerSpec = DeviceContextProvider.lowPowerModeSpecification()
            let voiceOverSpec = DeviceContextProvider.voiceOverSpecification()
            let lowBatterySpec = DeviceContextProvider.lowBatterySpecification(threshold: 0.5)
            let thermalSpec = DeviceContextProvider.thermalStateSpecification()

            // All specs should be evaluable
            _ = darkModeSpec.isSatisfiedBy("test")
            _ = lowPowerSpec.isSatisfiedBy("test")
            _ = voiceOverSpec.isSatisfiedBy("test")
            _ = lowBatterySpec.isSatisfiedBy("test")
            _ = thermalSpec.isSatisfiedBy("test")
        }
    }
#endif

// MARK: - macOS-Specific Tests

#if canImport(AppKit) && os(macOS)
    import AppKit
    import SystemConfiguration

    @available(macOS 10.15, *)
    final class MacOSSystemContextProviderTests: XCTestCase {

        func testMacOSSystemContextProviderCreation() {
            let provider = MacOSSystemContextProvider()
            let context = provider.currentContext()

            XCTAssertNotNil(context)

            // Test basic system properties
            if let isDarkMode = context.isDarkModeEnabled {
                XCTAssertTrue(isDarkMode == true || isDarkMode == false)
            }

            if let systemUptime = context.systemUptime {
                XCTAssertGreaterThan(systemUptime, 0)
            }

            if let osVersion = context.operatingSystemVersion {
                XCTAssertFalse(osVersion.isEmpty)
                // Should be in format like "15.1.0"
                let components = osVersion.split(separator: ".")
                XCTAssertGreaterThanOrEqual(components.count, 2)
            }

            if let processorCount = context.processorCount {
                XCTAssertGreaterThan(processorCount, 0)
            }

            if let physicalMemory = context.physicalMemory {
                XCTAssertGreaterThan(physicalMemory, 0)
            }
        }

        func testMacOSSystemContextValues() {
            let provider = MacOSSystemContextProvider()

            // Test individual getValue calls
            let isDarkMode = provider.getValue(for: "isDarkModeEnabled") as? Bool
            let systemUptime = provider.getValue(for: "systemUptime") as? TimeInterval
            let osVersion = provider.getValue(for: "operatingSystemVersion") as? String
            let processorCount = provider.getValue(for: "processorCount") as? Int
            let physicalMemory = provider.getValue(for: "physicalMemory") as? UInt64
            let isOnBattery = provider.getValue(for: "isOnBattery") as? Bool
            let dockPosition = provider.getValue(for: "dockPosition") as? String

            // Dark mode should be a valid boolean
            if let isDarkMode = isDarkMode {
                XCTAssertTrue(isDarkMode == true || isDarkMode == false)
            }

            // System uptime should be positive
            if let systemUptime = systemUptime {
                XCTAssertGreaterThan(systemUptime, 0)
            }

            // OS version should be properly formatted
            if let osVersion = osVersion {
                XCTAssertFalse(osVersion.isEmpty)
                XCTAssertTrue(osVersion.contains("."))
            }

            // Processor count should be positive
            if let processorCount = processorCount {
                XCTAssertGreaterThan(processorCount, 0)
                XCTAssertLessThanOrEqual(processorCount, 128)  // Reasonable upper bound
            }

            // Physical memory should be positive
            if let physicalMemory = physicalMemory {
                XCTAssertGreaterThan(physicalMemory, 0)
            }

            // Battery state should be boolean
            if let isOnBattery = isOnBattery {
                XCTAssertTrue(isOnBattery == true || isOnBattery == false)
            }

            // Dock position should be valid
            if let dockPosition = dockPosition {
                let validPositions = ["bottom", "left", "right"]
                XCTAssertTrue(validPositions.contains(dockPosition))
            }
        }

        func testMacOSSystemContextProviderCaching() {
            let provider = MacOSSystemContextProvider()

            let context1 = provider.currentContext()
            let context2 = provider.currentContext()

            // Core system properties should be consistent across calls
            XCTAssertEqual(context1.operatingSystemVersion, context2.operatingSystemVersion)
            XCTAssertEqual(context1.processorCount, context2.processorCount)
            XCTAssertEqual(context1.physicalMemory, context2.physicalMemory)
        }

        func testMacOSSystemContextProviderInvalidKeys() {
            let provider = MacOSSystemContextProvider()

            let invalidValue = provider.getValue(for: "nonExistentKey")
            XCTAssertNil(invalidValue)

            let emptyValue = provider.getValue(for: "")
            XCTAssertNil(emptyValue)
        }

        func testMacOSSpecificationFactories() {
            // Test that macOS-specific specifications can be created
            let darkModeSpec = PlatformContextProviders.createMacOSSystemSpec(.darkMode)
            let batterySpec = PlatformContextProviders.createMacOSSystemSpec(.onBattery)
            let dockSpec = PlatformContextProviders.createMacOSDockSpec(.bottom)

            XCTAssertNotNil(darkModeSpec)
            XCTAssertNotNil(batterySpec)
            XCTAssertNotNil(dockSpec)

            // Specifications should be evaluable
            _ = darkModeSpec.isSatisfiedBy("test")
            _ = batterySpec.isSatisfiedBy("test")
            _ = dockSpec.isSatisfiedBy("test")
        }

        func testMacOSSystemCapabilityDetection() {
            // Verify that macOS-specific capabilities are properly detected
            XCTAssertTrue(PlatformContextProviders.supportsMacOSSystemPreferences)
            XCTAssertTrue(PlatformContextProviders.supportsMacOSDock)
            XCTAssertTrue(PlatformContextProviders.supportsMacOSPowerManagement)
        }

        func testMacOSSystemContextEnvironmentDetection() {
            // Test that the environment detection method works correctly

            // The method should return true in test environment (since we're running tests)
            let shouldUseDefaults = MacOSSystemContextProvider.MacOSSystemContext
                .shouldUseTestEnvironmentDefaults()
            XCTAssertTrue(
                shouldUseDefaults, "Should use test environment defaults when running tests")

            // Test that we can create a context successfully
            let context = MacOSSystemContextProvider.MacOSSystemContext()
            XCTAssertNotNil(context)

            // In test environment, these should have default values
            XCTAssertEqual(context.isDarkModeEnabled, false)
            XCTAssertEqual(context.menuBarHeight, 24.0)
        }
    }
#endif

#if canImport(CoreLocation) && !os(tvOS)
    @available(iOS 14.0, watchOS 7.0, macOS 11.0, macCatalyst 14.0, *)
    final class LocationContextProviderTests: XCTestCase {

        func testLocationContextProviderConfiguration() {
            let config = LocationContextProvider.Configuration(
                accuracy: kCLLocationAccuracyHundredMeters,
                distanceFilter: 50.0,
                requestPermission: false,
                fallbackLocation: CLLocation(latitude: 0, longitude: 0)
            )

            let provider = LocationContextProvider(configuration: config)

            XCTAssertNotNil(provider)

            let context = provider.currentContext()
            XCTAssertNotNil(context)
        }

        func testLocationContextProviderPresets() {
            let defaultConfig = LocationContextProvider.Configuration.default
            let batteryOptimized = LocationContextProvider.Configuration.batteryOptimized
            let highPrecision = LocationContextProvider.Configuration.highPrecision

            #if os(iOS)
                if #available(iOS 14.0, *) {
                    let privacyFocused = LocationContextProvider.Configuration.privacyFocused
                    XCTAssertFalse(privacyFocused.requestPermission)
                }
            #endif

            // All configs should have reasonable values
            XCTAssertGreaterThan(defaultConfig.distanceFilter, 0)
            XCTAssertGreaterThan(batteryOptimized.distanceFilter, 0)
            XCTAssertGreaterThan(highPrecision.distanceFilter, 0)

            // Battery optimized should be less precise than high precision
            XCTAssertGreaterThan(batteryOptimized.distanceFilter, highPrecision.distanceFilter)
        }

        func testLocationProximitySpecification() {
            let provider = LocationContextProvider()
            let center = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
            let spec = provider.proximitySpecification(center: center, maxDistance: 1000)

            XCTAssertNotNil(spec)
            _ = spec.isSatisfiedBy("test")
        }

        func testLocationRegionSpecification() {
            let provider = LocationContextProvider()
            let center = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
            let region = CLCircularRegion(center: center, radius: 1000, identifier: "test")
            let spec = provider.regionSpecification(region: region)

            XCTAssertNotNil(spec)
            _ = spec.isSatisfiedBy("test")
        }

        #if os(iOS) || os(macOS)
            @available(iOS 17.0, macOS 14.0, macCatalyst 17.0, *)
            func testLocationGeographicConditionSpecification() {
                let provider = LocationContextProvider()
                let center = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
                let condition = CLMonitor.CircularGeographicCondition(center: center, radius: 1000)
                let spec = provider.geographicConditionSpecification(condition: condition)

                XCTAssertNotNil(spec)
                _ = spec.isSatisfiedBy("test")
            }
        #endif
    }
#endif
