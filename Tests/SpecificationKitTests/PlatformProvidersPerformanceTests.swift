//
//  PlatformProvidersPerformanceTests.swift
//  SpecificationKit
//
//  Created by SpecificationKit on 2025.
//

import XCTest

@testable import SpecificationKit

/// Performance tests for platform-specific context providers
/// Validates <1ms evaluation requirement per specifications
final class PlatformProvidersPerformanceTests: XCTestCase {

    func testDeviceContextProviderPerformance() {
        #if canImport(UIKit) && (os(iOS) || os(tvOS))
            if #available(iOS 13.0, tvOS 13.0, *) {
                let provider = DeviceContextProvider()

                measure {
                    for _ in 0..<1000 {
                        _ = provider.currentContext()
                    }
                }

                // Test individual specification performance
                let darkModeSpec = DeviceContextProvider.darkModeSpecification()

                measure {
                    for _ in 0..<10000 {
                        _ = darkModeSpec.isSatisfiedBy("test")
                    }
                }
            }
        #endif
    }

    func testLocationContextProviderPerformance() {
        #if canImport(CoreLocation) && (os(iOS) || os(watchOS))
            if #available(iOS 14.0, watchOS 7.0, *) {
                let config = LocationContextProvider.Configuration(
                    accuracy: kCLLocationAccuracyKilometer,
                    distanceFilter: 100.0,
                    requestPermission: false,
                    fallbackLocation: nil
                )
                let provider = LocationContextProvider(configuration: config)

                measure {
                    for _ in 0..<1000 {
                        _ = provider.currentContext()
                    }
                }
            }
        #endif
    }

    func testPlatformSpecificationPerformance() {
        let specs = [
            PlatformContextProviders.createDeviceCapabilitySpec(.darkMode),
            PlatformContextProviders.createDeviceCapabilitySpec(.location),
            PlatformContextProviders.createDeviceCapabilitySpec(.healthKit),
            PlatformContextProviders.createBatterySpec(threshold: 0.2),
            PlatformContextProviders.createPerformanceSpec(),
        ]

        measure {
            for _ in 0..<1000 {
                for spec in specs {
                    _ = spec.isSatisfiedBy("test")
                }
            }
        }
    }

    func testSingleSpecificationEvaluationTime() {
        let spec = PlatformContextProviders.createDeviceCapabilitySpec(.darkMode)

        // Test that single evaluation is < 1ms
        let startTime = CFAbsoluteTimeGetCurrent()
        _ = spec.isSatisfiedBy("test")
        let endTime = CFAbsoluteTimeGetCurrent()

        let evaluationTime = (endTime - startTime) * 1000  // Convert to milliseconds
        XCTAssertLessThan(
            evaluationTime, 1.0, "Specification evaluation must be < 1ms, was \(evaluationTime)ms")
    }
}
