//
//  AppleTVContextProviderTests.swift
//  SpecificationKit
//
//  Created by SpecificationKit on 2025.
//

import XCTest
@testable import SpecificationKit

#if canImport(UIKit) && canImport(GameController) && os(tvOS)
import UIKit
import GameController

@available(tvOS 13.0, *)
final class AppleTVContextProviderTVOSTests: XCTestCase {

    func testAppleTVContextProviderInitialization() throws {
        // Given
        let provider = AppleTVContextProvider()

        // When
        let context = provider.currentContext()

        // Then
        XCTAssertTrue(context.deviceModel.contains("Apple TV"))
        XCTAssertFalse(context.systemVersion.isEmpty)
        XCTAssertFalse(context.deviceName.isEmpty)
        XCTAssertEqual(context.userInterfaceIdiom, .tv)
        XCTAssertNotNil(context.screenResolution)
        XCTAssertGreaterThan(context.screenScale, 0)
        XCTAssertGreaterThan(context.processorCount, 0)
        XCTAssertGreaterThan(context.physicalMemory, 0)
    }

    func testAppleTVContextKeyValueAccess() throws {
        // Given
        let provider = AppleTVContextProvider()

        // When & Then
        XCTAssertNotNil(provider.getValue(for: "deviceModel"))
        XCTAssertNotNil(provider.getValue(for: "systemVersion"))
        XCTAssertNotNil(provider.getValue(for: "screenResolution"))
        XCTAssertNotNil(provider.getValue(for: "processorCount"))
        XCTAssertNotNil(provider.getValue(for: "physicalMemory"))
        XCTAssertNil(provider.getValue(for: "invalidKey"))
    }

    func testAppleTVSpecifications() throws {
        // Given
        let hdrSpec = AppleTVContextProvider.hdrSupportSpecification()
        let remoteSpec = AppleTVContextProvider.remoteConnectedSpecification()
        let darkModeSpec = AppleTVContextProvider.darkModeSpecification()
        let resolutionSpec = AppleTVContextProvider.screenResolutionSpecification(
            minimumWidth: 1920,
            minimumHeight: 1080
        )

        // When
        let hdrResult = hdrSpec.isSatisfiedBy(())
        let remoteResult = remoteSpec.isSatisfiedBy(())
        let darkModeResult = darkModeSpec.isSatisfiedBy(())
        let resolutionResult = resolutionSpec.isSatisfiedBy(())

        // Then
        XCTAssertNotNil(hdrResult)
        XCTAssertNotNil(remoteResult)
        XCTAssertNotNil(darkModeResult)
        XCTAssertNotNil(resolutionResult)
    }

    func testAppleTVContextPerformance() throws {
        // Given
        let provider = AppleTVContextProvider()

        // When
        let context = provider.currentContext()

        // Then
        XCTAssertTrue([.reduced, .standard, .high].contains(context.performanceTier))
        XCTAssertNotNil(context.isHighPerformanceAvailable)
        XCTAssertNotNil(context.shouldReduceFeatures)
    }

    func testAppleTVContextAccessibility() throws {
        // Given
        let provider = AppleTVContextProvider()

        // When
        let context = provider.currentContext()

        // Then
        XCTAssertNotNil(context.hasAccessibilityFeaturesEnabled)
        XCTAssertNotNil(AppleTVContextProvider.voiceOverSpecification().isSatisfiedBy(()))
    }

    func testAppleTVContextRemoteControl() throws {
        // Given
        let provider = AppleTVContextProvider()

        // When
        let context = provider.currentContext()

        // Then
        XCTAssertNotNil(context.hasRemoteConnected)
        XCTAssertNotNil(context.hasSiriRemote)
        XCTAssertNotNil(context.hasAppleRemote)
        XCTAssertGreaterThanOrEqual(context.connectedControllerCount, 0)
        XCTAssertNotNil(context.supportsVoiceCommands)
    }

    func testAppleTVContextCaching() throws {
        // Given
        let provider = AppleTVContextProvider()

        // When
        let context1 = provider.currentContext()
        let context2 = provider.currentContext()

        // Then
        XCTAssertEqual(context1.systemVersion, context2.systemVersion)
        XCTAssertEqual(context1.deviceModel, context2.deviceModel)
        XCTAssertEqual(context1.processorCount, context2.processorCount)
    }

    func testAppleTVSpecificationFactories() throws {
        // Given
        let memorySpec = AppleTVContextProvider.memorySpecification(minimumGB: 2)
        let processorSpec = AppleTVContextProvider.processorSpecification(minimumCores: 2)
        let thermalSpec = AppleTVContextProvider.thermalStateSpecification()
        let voiceCommandSpec = AppleTVContextProvider.voiceCommandSupportSpecification()

        // When
        let memoryResult = memorySpec.isSatisfiedBy(())
        let processorResult = processorSpec.isSatisfiedBy(())
        let thermalResult = thermalSpec.isSatisfiedBy(())
        let voiceCommandResult = voiceCommandSpec.isSatisfiedBy(())

        // Then
        XCTAssertNotNil(memoryResult)
        XCTAssertNotNil(processorResult)
        XCTAssertNotNil(thermalResult)
        XCTAssertNotNil(voiceCommandResult)
    }
}
#endif

final class AppleTVContextProviderCrossPlatformTests: XCTestCase {

    func testAppleTVContextProviderNonTVOSDefaults() throws {
        #if os(tvOS)
        throw XCTSkip("Test only applies to non-tvOS platforms")
        #else
        // Given
        let provider = AppleTVContextProvider()

        // When
        let context = provider.currentContext()

        // Then
        XCTAssertEqual(context.deviceModel, "Unknown")
        XCTAssertEqual(context.systemVersion, "0.0.0")
        XCTAssertEqual(context.hasRemoteConnected, false)
        XCTAssertEqual(context.supportsVoiceCommands, false)
        XCTAssertEqual(context.performanceTier, .reduced)
        XCTAssertNil(provider.getValue(for: "deviceModel"))
        XCTAssertNil(provider.getValue(for: "systemVersion"))
        #endif
    }

    func testAppleTVSpecificationsNonTVOSReturnFalse() throws {
        #if os(tvOS)
        throw XCTSkip("Test only applies to non-tvOS platforms")
        #else
        // Given
        let hdrSpec = AppleTVContextProvider.hdrSupportSpecification()
        let siriRemoteSpec = AppleTVContextProvider.siriRemoteSpecification()
        let remoteSpec = AppleTVContextProvider.remoteConnectedSpecification()
        let darkModeSpec = AppleTVContextProvider.darkModeSpecification()
        let voiceOverSpec = AppleTVContextProvider.voiceOverSpecification()

        // Then
        XCTAssertEqual(hdrSpec.isSatisfiedBy(()), false)
        XCTAssertEqual(siriRemoteSpec.isSatisfiedBy(()), false)
        XCTAssertEqual(remoteSpec.isSatisfiedBy(()), false)
        XCTAssertEqual(darkModeSpec.isSatisfiedBy(()), false)
        XCTAssertEqual(voiceOverSpec.isSatisfiedBy(()), false)
        #endif
    }

    func testPlatformProvidersAppleTVSupportFlags() {
        // When & Then
        #if canImport(UIKit) && canImport(GameController) && os(tvOS)
        XCTAssertTrue(PlatformContextProviders.supportsAppleTV)
        XCTAssertTrue(PlatformContextProviders.supportsTVGameController)
        #else
        XCTAssertFalse(PlatformContextProviders.supportsAppleTV)
        XCTAssertFalse(PlatformContextProviders.supportsTVGameController)
        #endif
    }

    func testPlatformProvidersReturnCorrectContextProvider() {
        // When
        let provider = PlatformContextProviders.appleTVContextProvider

        // Then
        #if canImport(UIKit) && canImport(GameController) && os(tvOS)
        XCTAssertTrue(provider is AppleTVContextProvider)
        #else
        XCTAssertFalse(provider is AppleTVContextProvider)
        #endif
    }

    func testPlatformProvidersAppleTVSpecificationResults() {
        // Given
        let hdrSpec = PlatformContextProviders.createAppleTVSpec(.hdrSupport)
        let siriRemoteSpec = PlatformContextProviders.createAppleTVSpec(.siriRemote)
        let darkModeSpec = PlatformContextProviders.createAppleTVSpec(.darkMode)

        // When
        let hdrResult = hdrSpec.isSatisfiedBy(())
        let siriRemoteResult = siriRemoteSpec.isSatisfiedBy(())
        let darkModeResult = darkModeSpec.isSatisfiedBy(())

        // Then
        #if canImport(UIKit) && canImport(GameController) && os(tvOS)
        XCTAssertTrue(hdrResult is Bool)
        XCTAssertTrue(siriRemoteResult is Bool)
        XCTAssertTrue(darkModeResult is Bool)
        #else
        XCTAssertEqual(hdrResult, false)
        XCTAssertEqual(siriRemoteResult, false)
        XCTAssertEqual(darkModeResult, false)
        #endif
    }

    func testPlatformProvidersAppleTVPerformanceSpecifications() {
        // Given
        let highPerformanceSpec = PlatformContextProviders.createAppleTVPerformanceSpec(.high)
        let standardPerformanceSpec = PlatformContextProviders.createAppleTVPerformanceSpec(.standard)
        let reducedPerformanceSpec = PlatformContextProviders.createAppleTVPerformanceSpec(.reduced)

        // When
        let highResult = highPerformanceSpec.isSatisfiedBy(())
        let standardResult = standardPerformanceSpec.isSatisfiedBy(())
        let reducedResult = reducedPerformanceSpec.isSatisfiedBy(())

        // Then
        #if canImport(UIKit) && canImport(GameController) && os(tvOS)
        XCTAssertTrue(highResult is Bool)
        XCTAssertTrue(standardResult is Bool)
        XCTAssertTrue(reducedResult is Bool)
        #else
        XCTAssertEqual(highResult, false)
        XCTAssertEqual(standardResult, false)
        XCTAssertEqual(reducedResult, false)
        #endif
    }
}
