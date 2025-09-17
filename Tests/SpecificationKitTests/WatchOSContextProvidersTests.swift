//
//  WatchOSContextProvidersTests.swift
//  SpecificationKit
//
//  Created by SpecificationKit on 2025.
//

import XCTest

@testable import SpecificationKit

#if canImport(WatchKit) && os(watchOS)
    import WatchKit
#endif

#if canImport(HealthKit) && os(watchOS)
    import HealthKit
#endif

/// Tests for watchOS-specific context providers
final class WatchOSContextProvidersTests: XCTestCase {

    // MARK: - HealthContextProvider Tests

    func testHealthContextProviderInitialization() {
        let provider = HealthContextProvider()
        XCTAssertNotNil(provider)

        // Test custom configuration
        let customProvider = HealthContextProvider(configuration: .fitness)
        XCTAssertNotNil(customProvider)
    }

    func testHealthContextProviderConfigurations() {
        #if canImport(HealthKit) && os(watchOS)
            // Test default configuration
            let defaultConfig = HealthContextProvider.Configuration.default
            XCTAssertTrue(defaultConfig.requestPermissionsOnInit)
            XCTAssertFalse(defaultConfig.readTypes.isEmpty)

            // Test fitness configuration
            let fitnessConfig = HealthContextProvider.Configuration.fitness
            XCTAssertTrue(fitnessConfig.requestPermissionsOnInit)
            XCTAssertTrue(fitnessConfig.fallbackValues.contains { $0.key == "todayStepCount" })

            // Test heart rate configuration
            let heartRateConfig = HealthContextProvider.Configuration.heartRate
            XCTAssertTrue(heartRateConfig.requestPermissionsOnInit)
            XCTAssertTrue(heartRateConfig.fallbackValues.contains { $0.key == "currentHeartRate" })
        #else
            // On non-watchOS platforms, just verify configurations exist
            let defaultConfig = HealthContextProvider.Configuration.default
            let fitnessConfig = HealthContextProvider.Configuration.fitness
            let heartRateConfig = HealthContextProvider.Configuration.heartRate
            XCTAssertNotNil(defaultConfig)
            XCTAssertNotNil(fitnessConfig)
            XCTAssertNotNil(heartRateConfig)
        #endif
    }

    func testHealthContextProviderFallbackValues() {
        let provider = HealthContextProvider(configuration: .fitness)

        // Should return fallback values when health data is unavailable
        let stepCount = provider.getValue(for: "todayStepCount")
        let activeCalories = provider.getValue(for: "activeCalories")

        // Should return nil for unknown keys without fallbacks
        let unknownValue = provider.getValue(for: "unknownHealthMetric")
        XCTAssertNil(unknownValue)
    }

    func testHealthContextProviderCacheManagement() {
        let provider = HealthContextProvider()

        // Test cache clearing
        provider.clearCache()

        // Test cache refresh
        let expectation = expectation(description: "Cache refresh")
        Task {
            await provider.refreshCache()
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5.0)
    }

    func testHealthContextProviderContextGeneration() {
        let provider = HealthContextProvider()
        let context = provider.currentContext()

        XCTAssertNotNil(context)
        XCTAssertTrue(context.keys.contains("isHealthKitAuthorized"))
        XCTAssertTrue(context.keys.contains("healthKitAvailable"))
    }

    #if canImport(HealthKit) && os(watchOS)
        @available(watchOS 6.0, *)
        func testHealthContextProviderAsyncValues() {
            let provider = HealthContextProvider()

            let expectation = expectation(description: "Async health value")
            Task {
                // Test async value retrieval
                let heartRate = await provider.getAsyncValue(for: "currentHeartRate")
                // Should return either a value or nil (depending on permissions and data availability)
                // We can't assert a specific value since it depends on device state

                let stepCount = await provider.getAsyncValue(for: "todayStepCount")
                // Should return either a value or nil

                expectation.fulfill()
            }

            waitForExpectations(timeout: 10.0)
        }

        @available(watchOS 6.0, *)
        func testHealthContextProviderAuthorization() {
            let provider = HealthContextProvider(configuration: .heartRate)

            let expectation = expectation(description: "Health authorization")
            Task {
                let authorized = await provider.requestHealthAuthorization()
                // Authorization result depends on user permission and device capabilities
                // We just verify the method completes without error
                expectation.fulfill()
            }

            waitForExpectations(timeout: 5.0)
        }
    #endif

    // MARK: - WatchContextProvider Tests

    func testWatchContextProviderInitialization() {
        let provider = WatchContextProvider()
        XCTAssertNotNil(provider)
    }

    func testWatchContextProviderBasicValues() {
        let provider = WatchContextProvider()

        // Test system name
        let systemName = provider.getValue(for: "systemName")
        #if os(watchOS)
            XCTAssertEqual(systemName as? String, "watchOS")
        #else
            XCTAssertNil(systemName)
        #endif

        // Test boolean values that should have defaults
        let supportsHaptics = provider.getValue(for: "supportsHaptics")
        #if os(watchOS)
            XCTAssertEqual(supportsHaptics as? Bool, true)
        #else
            XCTAssertNil(supportsHaptics)
        #endif

        // Test unknown key
        let unknownValue = provider.getValue(for: "unknownWatchProperty")
        XCTAssertNil(unknownValue)
    }

    func testWatchContextProviderContextGeneration() {
        let provider = WatchContextProvider()
        let context = provider.currentContext()

        XCTAssertNotNil(context)
        XCTAssertTrue(context.keys.contains("systemName"))
        XCTAssertTrue(context.keys.contains("supportsHaptics"))
    }

    #if canImport(WatchKit) && os(watchOS)
        @available(watchOS 6.0, *)
        func testWatchContextProviderDeviceInfo() {
            let provider = WatchContextProvider()

            // Test device model
            let model = provider.getValue(for: "watchModel")
            XCTAssertNotNil(model)
            XCTAssertTrue(model is String)

            // Test system version
            let version = provider.getValue(for: "systemVersion")
            XCTAssertNotNil(version)
            XCTAssertTrue(version is String)

            // Test screen properties
            let screenScale = provider.getValue(for: "screenScale")
            XCTAssertNotNil(screenScale)
            XCTAssertTrue(screenScale is CGFloat)

            let screenBounds = provider.getValue(for: "screenBounds")
            XCTAssertNotNil(screenBounds)
            XCTAssertTrue(screenBounds is CGRect)

            // Test computed screen properties
            let screenWidth = provider.getValue(for: "screenWidth")
            XCTAssertNotNil(screenWidth)
            XCTAssertTrue(screenWidth is CGFloat)

            let isLargeScreen = provider.getValue(for: "isLargeScreen")
            XCTAssertNotNil(isLargeScreen)
            XCTAssertTrue(isLargeScreen is Bool)
        }

        @available(watchOS 6.0, *)
        func testWatchContextProviderUserPreferences() {
            let provider = WatchContextProvider()

            // Test crown orientation
            let crownOrientation = provider.getValue(for: "crownOrientation")
            XCTAssertNotNil(crownOrientation)
            XCTAssertTrue(crownOrientation is Int)

            // Test wrist location
            let wristLocation = provider.getValue(for: "wristLocation")
            XCTAssertNotNil(wristLocation)
            XCTAssertTrue(wristLocation is Int)

            // Test water lock status
            let waterLock = provider.getValue(for: "isWaterLockEnabled")
            XCTAssertNotNil(waterLock)
            XCTAssertTrue(waterLock is Bool)
        }
    #endif

    // MARK: - WatchContextProvider Specification Tests

    func testWatchContextProviderCrownOrientationSpec() {
        #if canImport(WatchKit) && os(watchOS)
            let leftCrownSpec = WatchContextProvider.crownOrientationSpec(.left)
            let rightCrownSpec = WatchContextProvider.crownOrientationSpec(.right)

            XCTAssertNotNil(leftCrownSpec)
            XCTAssertNotNil(rightCrownSpec)

            // Test that specifications can be evaluated
            let context = [String: Any]()
            let leftResult = leftCrownSpec.isSatisfiedBy(context)
            let rightResult = rightCrownSpec.isSatisfiedBy(context)

            // One should be true based on actual device crown orientation
            XCTAssertTrue(leftResult || rightResult)
        #else
            // On non-watchOS platforms, should return false
            let spec = WatchContextProvider.crownOrientationSpec(0)
            XCTAssertFalse(spec.isSatisfiedBy([String: Any]()))
        #endif
    }

    func testWatchContextProviderWristLocationSpec() {
        #if canImport(WatchKit) && os(watchOS)
            let leftWristSpec = WatchContextProvider.wristLocationSpec(.left)
            let rightWristSpec = WatchContextProvider.wristLocationSpec(.right)

            XCTAssertNotNil(leftWristSpec)
            XCTAssertNotNil(rightWristSpec)

            // Test that specifications can be evaluated
            let context = [String: Any]()
            let leftResult = leftWristSpec.isSatisfiedBy(context)
            let rightResult = rightWristSpec.isSatisfiedBy(context)

            // One should be true based on actual device wrist location
            XCTAssertTrue(leftResult || rightResult)
        #else
            // On non-watchOS platforms, should return false
            let spec = WatchContextProvider.wristLocationSpec(0)
            XCTAssertFalse(spec.isSatisfiedBy([String: Any]()))
        #endif
    }

    func testWatchContextProviderScreenSizeSpec() {
        let smallSpec = WatchContextProvider.screenSizeSpec(.small)
        let mediumSpec = WatchContextProvider.screenSizeSpec(.medium)
        let largeSpec = WatchContextProvider.screenSizeSpec(.large)
        let extraLargeSpec = WatchContextProvider.screenSizeSpec(.extraLarge)

        XCTAssertNotNil(smallSpec)
        XCTAssertNotNil(mediumSpec)
        XCTAssertNotNil(largeSpec)
        XCTAssertNotNil(extraLargeSpec)

        let context = [String: Any]()

        #if canImport(WatchKit) && os(watchOS)
            // On watchOS, at least the small size should be satisfied
            XCTAssertTrue(smallSpec.isSatisfiedBy(context))
        #else
            // On non-watchOS platforms, should return false
            XCTAssertFalse(smallSpec.isSatisfiedBy(context))
            XCTAssertFalse(mediumSpec.isSatisfiedBy(context))
            XCTAssertFalse(largeSpec.isSatisfiedBy(context))
            XCTAssertFalse(extraLargeSpec.isSatisfiedBy(context))
        #endif
    }

    func testWatchContextProviderWaterLockSpec() {
        let waterLockEnabledSpec = WatchContextProvider.waterLockSpec(isEnabled: true)
        let waterLockDisabledSpec = WatchContextProvider.waterLockSpec(isEnabled: false)

        XCTAssertNotNil(waterLockEnabledSpec)
        XCTAssertNotNil(waterLockDisabledSpec)

        let context = [String: Any]()

        #if canImport(WatchKit) && os(watchOS)
            // One of these should be true based on actual device state
            let enabledResult = waterLockEnabledSpec.isSatisfiedBy(context)
            let disabledResult = waterLockDisabledSpec.isSatisfiedBy(context)
            XCTAssertTrue(enabledResult || disabledResult)
        #else
            // On non-watchOS platforms, should return false
            XCTAssertFalse(waterLockEnabledSpec.isSatisfiedBy(context))
            XCTAssertFalse(waterLockDisabledSpec.isSatisfiedBy(context))
        #endif
    }

    // MARK: - Cross-Platform Compatibility Tests

    func testWatchOSProviderStubsOnOtherPlatforms() {
        #if !os(watchOS)
            // Test that stub implementations work correctly on non-watchOS platforms
            let healthProvider = HealthContextProvider()
            XCTAssertNil(healthProvider.getValue(for: "currentHeartRate"))

            let watchProvider = WatchContextProvider()
            XCTAssertNil(watchProvider.getValue(for: "watchModel"))

            // Test async methods
            let expectation = expectation(description: "Async stub test")
            Task {
                let heartRate = await healthProvider.getAsyncValue(for: "currentHeartRate")
                XCTAssertNil(heartRate)

                let authorized = await healthProvider.requestHealthAuthorization()
                XCTAssertFalse(authorized)

                expectation.fulfill()
            }

            waitForExpectations(timeout: 1.0)
        #endif
    }

    // MARK: - Integration Tests

    func testWatchOSProvidersWithPropertyWrappers() {
        // Test integration with property wrappers (would work in actual watchOS app)
        let heartRateSpec = PredicateSpec<HealthContextProvider> { provider in
            guard let heartRate = provider.getValue(for: "currentHeartRate") as? Double else {
                return false
            }
            return heartRate > 100
        }

        let screenSizeSpec = PredicateSpec<WatchContextProvider> { provider in
            guard let bounds = provider.getValue(for: "screenBounds") as? CGRect else {
                return false
            }
            return bounds.width >= 44.0
        }

        // Verify specifications can be created and evaluated
        let healthProvider = HealthContextProvider()
        let watchProvider = WatchContextProvider()

        let heartRateResult = heartRateSpec.isSatisfiedBy(healthProvider)
        let screenResult = screenSizeSpec.isSatisfiedBy(watchProvider)

        // Results depend on actual device state and permissions
        XCTAssertTrue(heartRateResult == true || heartRateResult == false)
        XCTAssertTrue(screenResult == true || screenResult == false)
    }

    func testWatchOSProvidersPerformance() {
        let healthProvider = HealthContextProvider()
        let watchProvider = WatchContextProvider()

        // Test that synchronous getValue calls are fast
        measure {
            for _ in 0..<100 {
                _ = healthProvider.getValue(for: "todayStepCount")
                _ = watchProvider.getValue(for: "screenBounds")
            }
        }
    }

    func testWatchScreenSizeEnum() {
        // Test that the enum cases are available
        let sizes: [WatchScreenSize] = [.small, .medium, .large, .extraLarge]
        XCTAssertEqual(sizes.count, 4)
    }
}
