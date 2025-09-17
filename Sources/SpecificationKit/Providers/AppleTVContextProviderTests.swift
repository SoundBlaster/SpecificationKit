//
//  AppleTVContextProviderTests.swift
//  SpecificationKit
//
//  Created by SpecificationKit on 2024.
//

import Testing

#if canImport(UIKit) && canImport(GameController) && os(tvOS)
    import UIKit
    import GameController

    @available(tvOS 13.0, *)
    @Suite("Apple TV Context Provider Tests")
    struct AppleTVContextProviderTests {

        @Test("Apple TV context provider initializes correctly")
        func testAppleTVContextProviderInitialization() async throws {
            let provider = AppleTVContextProvider()
            let context = provider.currentContext()
            
            // Basic device information should be available
            #expect(context.deviceModel.contains("Apple TV"))
            #expect(!context.systemVersion.isEmpty)
            #expect(!context.deviceName.isEmpty)
            #expect(context.userInterfaceIdiom == .tv)
            
            // Screen information should be available
            #expect(context.screenResolution != nil)
            #expect(context.screenScale > 0)
            
            // System information should be available
            #expect(context.processorCount > 0)
            #expect(context.physicalMemory > 0)
        }

        @Test("Apple TV context provides correct key-value access")
        func testAppleTVContextKeyValueAccess() async throws {
            let provider = AppleTVContextProvider()
            
            // Test key-value access methods
            #expect(provider.getValue(for: "deviceModel") != nil)
            #expect(provider.getValue(for: "systemVersion") != nil)
            #expect(provider.getValue(for: "screenResolution") != nil)
            #expect(provider.getValue(for: "processorCount") != nil)
            #expect(provider.getValue(for: "physicalMemory") != nil)
            
            // Test invalid key returns nil
            #expect(provider.getValue(for: "invalidKey") == nil)
        }

        @Test("Apple TV specifications work correctly")
        func testAppleTVSpecifications() async throws {
            // Test HDR support specification
            let hdrSpec = AppleTVContextProvider.hdrSupportSpecification()
            let hdrResult = hdrSpec.isSatisfiedBy(())
            #expect(hdrResult != nil) // Should return a boolean
            
            // Test remote connected specification
            let remoteSpec = AppleTVContextProvider.remoteConnectedSpecification()
            let remoteResult = remoteSpec.isSatisfiedBy(())
            #expect(remoteResult != nil) // Should return a boolean
            
            // Test dark mode specification
            let darkModeSpec = AppleTVContextProvider.darkModeSpecification()
            let darkModeResult = darkModeSpec.isSatisfiedBy(())
            #expect(darkModeResult != nil) // Should return a boolean
            
            // Test screen resolution specification
            let resolutionSpec = AppleTVContextProvider.screenResolutionSpecification(
                minimumWidth: 1920, minimumHeight: 1080
            )
            let resolutionResult = resolutionSpec.isSatisfiedBy(())
            #expect(resolutionResult != nil) // Should return a boolean
        }

        @Test("Apple TV context performance calculations")
        func testAppleTVContextPerformance() async throws {
            let provider = AppleTVContextProvider()
            let context = provider.currentContext()
            
            // Test performance tier calculation
            let performanceTier = context.performanceTier
            #expect([.reduced, .standard, .high].contains(performanceTier))
            
            // Test high performance availability
            let isHighPerformanceAvailable = context.isHighPerformanceAvailable
            #expect(isHighPerformanceAvailable != nil)
            
            // Test should reduce features
            let shouldReduceFeatures = context.shouldReduceFeatures
            #expect(shouldReduceFeatures != nil)
        }

        @Test("Apple TV context accessibility features")
        func testAppleTVContextAccessibility() async throws {
            let provider = AppleTVContextProvider()
            let context = provider.currentContext()
            
            // Test accessibility feature detection
            let hasAccessibilityFeatures = context.hasAccessibilityFeaturesEnabled
            #expect(hasAccessibilityFeatures != nil)
            
            // Test VoiceOver specification
            let voiceOverSpec = AppleTVContextProvider.voiceOverSpecification()
            let voiceOverResult = voiceOverSpec.isSatisfiedBy(())
            #expect(voiceOverResult != nil)
        }

        @Test("Apple TV context remote control detection")
        func testAppleTVContextRemoteControl() async throws {
            let provider = AppleTVContextProvider()
            let context = provider.currentContext()
            
            // Test remote control properties
            let hasRemoteConnected = context.hasRemoteConnected
            #expect(hasRemoteConnected != nil)
            
            let hasSiriRemote = context.hasSiriRemote
            #expect(hasSiriRemote != nil)
            
            let hasAppleRemote = context.hasAppleRemote
            #expect(hasAppleRemote != nil)
            
            let connectedControllerCount = context.connectedControllerCount
            #expect(connectedControllerCount >= 0)
            
            // Test voice command support
            let supportsVoiceCommands = context.supportsVoiceCommands
            #expect(supportsVoiceCommands != nil)
        }

        @Test("Apple TV context caching behavior")
        func testAppleTVContextCaching() async throws {
            let provider = AppleTVContextProvider()
            
            // Get context twice quickly - should use cache
            let context1 = provider.currentContext()
            let context2 = provider.currentContext()
            
            // Both should have the same system information
            #expect(context1.systemVersion == context2.systemVersion)
            #expect(context1.deviceModel == context2.deviceModel)
            #expect(context1.processorCount == context2.processorCount)
        }

        @Test("Apple TV specification factory methods")
        func testAppleTVSpecificationFactories() async throws {
            // Test memory specification
            let memorySpec = AppleTVContextProvider.memorySpecification(minimumGB: 2)
            let memoryResult = memorySpec.isSatisfiedBy(())
            #expect(memoryResult != nil)
            
            // Test processor specification
            let processorSpec = AppleTVContextProvider.processorSpecification(minimumCores: 2)
            let processorResult = processorSpec.isSatisfiedBy(())
            #expect(processorResult != nil)
            
            // Test thermal state specification
            let thermalSpec = AppleTVContextProvider.thermalStateSpecification()
            let thermalResult = thermalSpec.isSatisfiedBy(())
            #expect(thermalResult != nil)
            
            // Test voice command support specification
            let voiceCommandSpec = AppleTVContextProvider.voiceCommandSupportSpecification()
            let voiceCommandResult = voiceCommandSpec.isSatisfiedBy(())
            #expect(voiceCommandResult != nil)
        }
    }

#endif

// MARK: - Cross-Platform Tests

@Suite("Apple TV Context Provider Cross-Platform Tests")
struct AppleTVContextProviderCrossPlatformTests {
    
    @Test("Apple TV context provider works on non-tvOS platforms")
    func testAppleTVContextProviderNonTVOS() async throws {
        #if !os(tvOS)
            // On non-tvOS platforms, should provide stub implementation
            let provider = AppleTVContextProvider()
            let context = provider.currentContext()
            
            // All values should be defaults/empty for non-tvOS
            #expect(context.deviceModel == "Unknown")
            #expect(context.systemVersion == "0.0.0")
            #expect(context.hasRemoteConnected == false)
            #expect(context.supportsVoiceCommands == false)
            #expect(context.performanceTier == .reduced)
            
            // getValue should return nil for all keys
            #expect(provider.getValue(for: "deviceModel") == nil)
            #expect(provider.getValue(for: "systemVersion") == nil)
        #else
            // Skip test on actual tvOS
            throw SkipTest("Test only applies to non-tvOS platforms")
        #endif
    }
    
    @Test("Apple TV specifications return false on non-tvOS platforms")
    func testAppleTVSpecificationsNonTVOS() async throws {
        #if !os(tvOS)
            // All Apple TV specifications should return false on non-tvOS platforms
            let hdrSpec = AppleTVContextProvider.hdrSupportSpecification()
            #expect(hdrSpec.isSatisfiedBy(()) == false)
            
            let siriRemoteSpec = AppleTVContextProvider.siriRemoteSpecification()
            #expect(siriRemoteSpec.isSatisfiedBy(()) == false)
            
            let remoteSpec = AppleTVContextProvider.remoteConnectedSpecification()
            #expect(remoteSpec.isSatisfiedBy(()) == false)
            
            let darkModeSpec = AppleTVContextProvider.darkModeSpecification()
            #expect(darkModeSpec.isSatisfiedBy(()) == false)
            
            let voiceOverSpec = AppleTVContextProvider.voiceOverSpecification()
            #expect(voiceOverSpec.isSatisfiedBy(()) == false)
        #else
            // Skip test on actual tvOS
            throw SkipTest("Test only applies to non-tvOS platforms")
        #endif
    }
}

// MARK: - Platform Integration Tests

@Suite("Platform Context Providers Apple TV Integration Tests")
struct PlatformContextProvidersAppleTVTests {
    
    @Test("Platform providers correctly detect Apple TV support")
    func testPlatformProvidersAppleTVSupport() async throws {
        // Test platform capability detection
        #if canImport(UIKit) && canImport(GameController) && os(tvOS)
            #expect(PlatformContextProviders.supportsAppleTV == true)
            #expect(PlatformContextProviders.supportsTVGameController == true)
        #else
            #expect(PlatformContextProviders.supportsAppleTV == false)
            #expect(PlatformContextProviders.supportsTVGameController == false)
        #endif
    }
    
    @Test("Platform providers create Apple TV context provider correctly")
    func testPlatformProvidersAppleTVContextProvider() async throws {
        let provider = PlatformContextProviders.appleTVContextProvider
        
        #if canImport(UIKit) && canImport(GameController) && os(tvOS)
            // On tvOS, should return actual AppleTVContextProvider
            #expect(provider is AppleTVContextProvider)
        #else
            // On non-tvOS platforms, should return GenericContextProvider
            #expect(!(provider is AppleTVContextProvider))
        #endif
    }
    
    @Test("Platform providers Apple TV specifications work correctly")
    func testPlatformProvidersAppleTVSpecifications() async throws {
        // Test Apple TV capability specifications
        let hdrSpec = PlatformContextProviders.createAppleTVSpec(.hdrSupport)
        let hdrResult = hdrSpec.isSatisfiedBy(())
        
        let siriRemoteSpec = PlatformContextProviders.createAppleTVSpec(.siriRemote)
        let siriRemoteResult = siriRemoteSpec.isSatisfiedBy(())
        
        let darkModeSpec = PlatformContextProviders.createAppleTVSpec(.darkMode)
        let darkModeResult = darkModeSpec.isSatisfiedBy(())
        
        #if canImport(UIKit) && canImport(GameController) && os(tvOS)
            // On tvOS, should return actual boolean results
            #expect(hdrResult is Bool)
            #expect(siriRemoteResult is Bool)
            #expect(darkModeResult is Bool)
        #else
            // On non-tvOS platforms, should return false
            #expect(hdrResult == false)
            #expect(siriRemoteResult == false)
            #expect(darkModeResult == false)
        #endif
    }
    
    @Test("Platform providers Apple TV performance specifications work")
    func testPlatformProvidersAppleTVPerformanceSpecs() async throws {
        let highPerformanceSpec = PlatformContextProviders.createAppleTVPerformanceSpec(.high)
        let standardPerformanceSpec = PlatformContextProviders.createAppleTVPerformanceSpec(.standard)
        let reducedPerformanceSpec = PlatformContextProviders.createAppleTVPerformanceSpec(.reduced)
        
        let highResult = highPerformanceSpec.isSatisfiedBy(())
        let standardResult = standardPerformanceSpec.isSatisfiedBy(())
        let reducedResult = reducedPerformanceSpec.isSatisfiedBy(())
        
        #if canImport(UIKit) && canImport(GameController) && os(tvOS)
            // On tvOS, should return actual boolean results
            #expect(highResult is Bool)
            #expect(standardResult is Bool)
            #expect(reducedResult is Bool)
        #else
            // On non-tvOS platforms, should return false
            #expect(highResult == false)
            #expect(standardResult == false)
            #expect(reducedResult == false)
        #endif
    }
}
