//
//  PlatformProvidersConcurrencyTests.swift
//  SpecificationKit
//
//  Created by SpecificationKit on 2025.
//

import XCTest

@testable import SpecificationKit

/// Thread safety tests for platform-specific context providers
/// Validates thread-safe API requirement
final class PlatformProvidersConcurrencyTests: XCTestCase {

    func testDeviceContextProviderConcurrency() {
        #if canImport(UIKit) && (os(iOS) || os(tvOS))
            if #available(iOS 13.0, tvOS 13.0, *) {
                let provider = DeviceContextProvider()
                let expectation = XCTestExpectation(description: "Concurrent access")
                expectation.expectedFulfillmentCount = 100

                let queue = DispatchQueue.global(qos: .userInitiated)

                // Test concurrent context access
                for _ in 0..<100 {
                    queue.async {
                        _ = provider.currentContext()
                        expectation.fulfill()
                    }
                }

                wait(for: [expectation], timeout: 5.0)
            }
        #endif
    }

    func testLocationContextProviderConcurrency() {
        #if canImport(CoreLocation) && (os(iOS) || os(watchOS))
            if #available(iOS 14.0, watchOS 7.0, *) {
                let config = LocationContextProvider.Configuration(
                    accuracy: kCLLocationAccuracyKilometer,
                    distanceFilter: 100.0,
                    requestPermission: false,
                    fallbackLocation: nil
                )
                let provider = LocationContextProvider(configuration: config)
                let expectation = XCTestExpectation(description: "Concurrent location access")
                expectation.expectedFulfillmentCount = 100

                let queue = DispatchQueue.global(qos: .userInitiated)

                // Test concurrent context access
                for _ in 0..<100 {
                    queue.async {
                        _ = provider.currentContext()
                        _ = provider.isLocationAvailable
                        expectation.fulfill()
                    }
                }

                wait(for: [expectation], timeout: 5.0)
            }
        #endif
    }

    func testPlatformSpecificationsConcurrency() {
        let specs = [
            PlatformContextProviders.createDeviceCapabilitySpec(.darkMode),
            PlatformContextProviders.createDeviceCapabilitySpec(.location),
            PlatformContextProviders.createBatterySpec(threshold: 0.2),
            PlatformContextProviders.createPerformanceSpec(),
        ]

        let expectation = XCTestExpectation(description: "Concurrent specification evaluation")
        expectation.expectedFulfillmentCount = 400  // 100 iterations * 4 specs

        let queue = DispatchQueue.global(qos: .userInitiated)

        // Test concurrent specification evaluation
        for _ in 0..<100 {
            queue.async {
                for spec in specs {
                    _ = spec.isSatisfiedBy("test")
                    expectation.fulfill()
                }
            }
        }

        wait(for: [expectation], timeout: 10.0)
    }

    func testConcurrentProviderFactoryAccess() {
        let expectation = XCTestExpectation(description: "Concurrent factory access")
        expectation.expectedFulfillmentCount = 200

        let queue = DispatchQueue.global(qos: .userInitiated)

        // Test concurrent factory method calls
        for _ in 0..<50 {
            queue.async {
                _ = PlatformContextProviders.deviceContextProvider
                expectation.fulfill()
            }

            queue.async {
                _ = PlatformContextProviders.locationContextProvider
                expectation.fulfill()
            }

            queue.async {
                _ = PlatformContextProviders.createDeviceCapabilitySpec(.darkMode)
                expectation.fulfill()
            }

            queue.async {
                _ = PlatformContextProviders.createBatterySpec()
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 10.0)
    }

    func testLocationCoordinateThreadSafety() {
        let coordinate = LocationCoordinate(latitude: 37.7749, longitude: -122.4194)
        let expectation = XCTestExpectation(description: "Concurrent coordinate access")
        expectation.expectedFulfillmentCount = 100

        let queue = DispatchQueue.global(qos: .userInitiated)

        // Test concurrent coordinate property access
        for _ in 0..<100 {
            queue.async {
                _ = coordinate.latitude
                _ = coordinate.longitude
                #if canImport(CoreLocation)
                    _ = coordinate.coreLocationCoordinate
                #endif
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 5.0)
    }
}
