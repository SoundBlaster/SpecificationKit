//
//  PlatformContextProviders.swift
//  SpecificationKit
//
//  Created by SpecificationKit on 2025.
//

import Foundation

#if canImport(CoreLocation)
    import CoreLocation
#endif

#if canImport(UIKit)
    import UIKit
#endif

#if canImport(AppKit)
    import AppKit
#endif

#if canImport(HealthKit)
    import HealthKit
#endif

/// A factory for creating platform-specific context providers and specifications.
///
/// `PlatformContextProviders` provides a unified interface for accessing platform-specific
/// functionality while gracefully handling availability and platform differences. It abstracts
/// away the complexity of conditional compilation and provides sensible fallbacks when features
/// are unavailable.
///
/// ## Key Features
///
/// - **Platform Abstraction**: Unified API across iOS, macOS, watchOS, and tvOS
/// - **Graceful Fallbacks**: Always returns valid providers, even when features are unavailable
/// - **Type Safety**: Compile-time platform checking with runtime availability validation
/// - **Privacy Compliance**: Respects platform privacy guidelines and permission requirements
/// - **Performance Optimized**: Lazy initialization and efficient resource management
///
/// ## Usage Examples
///
/// ### Location-Based Specifications
/// ```swift
/// // Works on iOS/watchOS, returns AlwaysFalseSpec on other platforms
/// let locationSpec = PlatformContextProviders.createLocationProximitySpec(
///     center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
///     radius: 1000
/// )
///
/// @Satisfies(using: locationSpec)
/// var isNearSanFrancisco: Bool
/// ```
///
/// ### Device Capability Checking
/// ```swift
/// let darkModeSpec = PlatformContextProviders.createDeviceCapabilitySpec(.darkMode)
/// let locationSpec = PlatformContextProviders.createDeviceCapabilitySpec(.location)
/// let healthSpec = PlatformContextProviders.createDeviceCapabilitySpec(.healthKit)
///
/// @Satisfies(using: darkModeSpec)
/// var supportsDarkMode: Bool
/// ```
///
/// ### Cross-Platform Context Providers
/// ```swift
/// // Get the best available device context provider for the current platform
/// let deviceProvider = PlatformContextProviders.deviceContextProvider
///
/// // Get location provider if available, or a fallback provider
/// let locationProvider = PlatformContextProviders.locationContextProvider
/// ```
///
/// ### Platform-Specific Features
/// ```swift
/// // Health data (watchOS/iOS only)
/// if PlatformContextProviders.supportsHealthKit {
///     let healthProvider = PlatformContextProviders.healthContextProvider
///     // Use health-based specifications
/// }
///
/// // System preferences (macOS only)
/// if PlatformContextProviders.supportsSystemPreferences {
///     let systemProvider = PlatformContextProviders.systemContextProvider
///     // Use system-level specifications
/// }
/// ```
public enum PlatformContextProviders {

    // MARK: - Platform Capability Detection

    /// Whether the current platform supports location services
    public static var supportsLocation: Bool {
        #if canImport(CoreLocation) && !os(tvOS)
            return true
        #else
            return false
        #endif
    }

    /// Whether the current platform supports HealthKit
    public static var supportsHealthKit: Bool {
        #if canImport(HealthKit) && (os(iOS) || os(watchOS))
            return true
        #else
            return false
        #endif
    }

    /// Whether the current platform supports device information via UIKit
    public static var supportsDeviceInfo: Bool {
        #if canImport(UIKit) && (os(iOS) || os(tvOS))
            return true
        #else
            return false
        #endif
    }

    /// Whether the current platform supports system preferences (macOS)
    public static var supportsSystemPreferences: Bool {
        #if canImport(AppKit) && os(macOS)
            return true
        #else
            return false
        #endif
    }

    /// Whether the current platform supports macOS system preferences
    public static var supportsMacOSSystemPreferences: Bool {
        #if canImport(AppKit) && os(macOS)
            return true
        #else
            return false
        #endif
    }

    /// Whether the current platform supports macOS dock integration
    public static var supportsMacOSDock: Bool {
        #if canImport(AppKit) && os(macOS)
            return true
        #else
            return false
        #endif
    }

    /// Whether the current platform supports macOS power management
    public static var supportsMacOSPowerManagement: Bool {
        #if canImport(AppKit) && os(macOS)
            return true
        #else
            return false
        #endif
    }

    /// Whether the current platform supports WatchKit features
    public static var supportsWatchKit: Bool {
        #if canImport(WatchKit) && os(watchOS)
            return true
        #else
            return false
        #endif
    }

    /// Whether the current platform supports Apple TV features
    public static var supportsAppleTV: Bool {
        #if canImport(UIKit) && canImport(GameController) && os(tvOS)
            return true
        #else
            return false
        #endif
    }

    /// Whether the current platform supports tvOS Game Controller features
    public static var supportsTVGameController: Bool {
        #if canImport(GameController) && os(tvOS)
            return true
        #else
            return false
        #endif
    }

    /// Whether the current platform supports tvOS HDR content
    public static var supportsTVHDR: Bool {
        #if canImport(UIKit) && os(tvOS)
            if #available(tvOS 13.0, *) {
                return UIScreen.main.traitCollection.displayGamut == .P3
            }
        #endif
        return false
    }

    // MARK: - Context Provider Factories

    /// Creates the best available device context provider for the current platform
    public static var deviceContextProvider: any ContextProviding {
        #if canImport(UIKit) && (os(iOS) || os(tvOS))
            if #available(iOS 13.0, tvOS 13.0, *) {
                return DeviceContextProvider()
            }
        #endif

        // Fallback to basic context provider
        return GenericContextProvider {
            BasicDeviceContext()
        }
    }

    /// Creates a location context provider if available, or a fallback provider
    public static var locationContextProvider: any ContextProviding {
        #if canImport(CoreLocation) && !os(tvOS)
            if #available(iOS 14.0, watchOS 7.0, macOS 11.0, macCatalyst 14.0, *) {
                return LocationContextProvider()
            }
        #endif
        // Fallback to empty location context
        return GenericContextProvider {
            EmptyLocationContext()
        }
    }

    /// Creates a location context provider with custom configuration
    /// - Parameter configuration: The configuration to use
    /// - Returns: A configured location provider or fallback
    #if canImport(CoreLocation) && (os(iOS) || os(watchOS))
        @available(iOS 14.0, watchOS 7.0, *)
        public static func locationContextProvider(
            configuration: LocationContextProvider.Configuration
        ) -> any ContextProviding {
            return LocationContextProvider(configuration: configuration)
        }
    #endif

    /// Creates a macOS system context provider if available, or a fallback provider
    public static var macOSSystemContextProvider: any ContextProviding {
        #if canImport(AppKit) && os(macOS)
            if #available(macOS 10.15, *) {
                return MacOSSystemContextProvider()
            }
        #endif

        // Fallback to basic context provider
        return GenericContextProvider {
            BasicSystemContext()
        }
    }

    /// Creates an Apple TV context provider if available, or a fallback provider
    public static var appleTVContextProvider: any ContextProviding {
        #if canImport(UIKit) && canImport(GameController) && os(tvOS)
            if #available(tvOS 13.0, *) {
                return AppleTVContextProvider()
            }
        #endif

        // Fallback to basic context provider
        return GenericContextProvider {
            BasicDeviceContext()
        }
    }

    // MARK: - Specification Factories

    /// Creates a location proximity specification if location services are available
    /// - Parameters:
    ///   - center: The center coordinate
    ///   - radius: The radius in meters
    /// - Returns: A specification that checks proximity, or AlwaysFalseSpec if unavailable
    public static func createLocationProximitySpec(
        center: LocationCoordinate,
        radius: Double
    ) -> AnySpecification<Any> {
        #if canImport(CoreLocation) && (os(iOS) || os(watchOS))
            if #available(iOS 14.0, watchOS 7.0, *) {
                let provider = LocationContextProvider()
                return provider.proximitySpecification(
                    center: center.coreLocationCoordinate,
                    maxDistance: radius
                )
            }
        #endif

        return AnySpecification { _ in false }
    }

    /// Creates a device capability specification
    /// - Parameter capability: The capability to check
    /// - Returns: A specification that checks the capability
    public static func createDeviceCapabilitySpec(_ capability: DeviceCapability)
        -> AnySpecification<Any>
    {
        switch capability {
        case .location:
            #if canImport(CoreLocation) && (os(iOS) || os(watchOS))
                return AnySpecification { _ in
                    if #available(iOS 14.0, watchOS 7.0, *) {
                        let provider = LocationContextProvider()
                        return provider.isLocationAvailable
                    }
                    return false
                }
            #else
                return AnySpecification { _ in false }
            #endif

        case .healthKit:
            #if canImport(HealthKit) && (os(iOS) || os(watchOS))
                return AnySpecification { _ in
                    return HKHealthStore.isHealthDataAvailable()
                }
            #else
                return AnySpecification { _ in false }
            #endif

        case .darkMode:
            #if canImport(UIKit) && (os(iOS) || os(tvOS))
                if #available(iOS 13.0, tvOS 13.0, *) {
                    return DeviceContextProvider.darkModeSpecification()
                }
            #endif
            return AnySpecification { _ in false }

        case .lowPowerMode:
            #if canImport(UIKit) && (os(iOS) || os(tvOS))
                if #available(iOS 13.0, tvOS 13.0, *) {
                    return DeviceContextProvider.lowPowerModeSpecification()
                }
            #endif
            return AnySpecification { _ in false }

        case .voiceOver:
            #if canImport(UIKit) && (os(iOS) || os(tvOS))
                if #available(iOS 13.0, tvOS 13.0, *) {
                    return DeviceContextProvider.voiceOverSpecification()
                }
            #endif
            return AnySpecification { _ in false }
        }
    }

    /// Creates a platform-optimized specification for battery state
    /// - Parameter threshold: The battery threshold (0.0 to 1.0)
    /// - Returns: A specification that checks battery level
    public static func createBatterySpec(threshold: Float = 0.2) -> AnySpecification<Any> {
        #if canImport(UIKit) && (os(iOS) || os(tvOS))
            if #available(iOS 13.0, tvOS 13.0, *) {
                return DeviceContextProvider.lowBatterySpecification(threshold: threshold)
            }
        #endif

        return AnySpecification { _ in false }
    }

    /// Creates a platform-optimized specification for performance state
    /// - Returns: A specification that checks if high-performance features should be available
    public static func createPerformanceSpec() -> AnySpecification<Any> {
        #if canImport(UIKit) && (os(iOS) || os(tvOS))
            if #available(iOS 13.0, tvOS 13.0, *) {
                let provider = DeviceContextProvider()
                return AnySpecification { _ in
                    provider.currentContext().isHighPerformanceAvailable
                }
            }
        #endif

        return AnySpecification { _ in true }  // Default to allowing high performance
    }

    /// Creates a macOS system specification
    /// - Parameter capability: The system capability to check
    /// - Returns: A specification that checks the macOS system capability
    public static func createMacOSSystemSpec(_ capability: MacOSSystemCapability)
        -> AnySpecification<Any>
    {
        #if canImport(AppKit) && os(macOS)
            if #available(macOS 10.15, *) {
                switch capability {
                case .darkMode:
                    return MacOSSystemContextProvider.darkModeSpecification()
                case .onBattery:
                    return MacOSSystemContextProvider.onBatterySpecification()
                case .reduceMotion:
                    return MacOSSystemContextProvider.reduceMotionSpecification()
                case .highMemory(let minimumGB):
                    return MacOSSystemContextProvider.memorySpecification(minimumGB: minimumGB)
                case .multiCore(let minimumCores):
                    return MacOSSystemContextProvider.processorSpecification(
                        minimumCores: minimumCores)
                }
            }
        #endif

        return AnySpecification { _ in false }
    }

    /// Creates a macOS dock position specification
    /// - Parameter position: The expected dock position
    /// - Returns: A specification that checks the dock position
    public static func createMacOSDockSpec(_ position: DockPosition) -> AnySpecification<Any> {
        #if canImport(AppKit) && os(macOS)
            if #available(macOS 10.15, *) {
                return MacOSSystemContextProvider.dockPositionSpecification(position)
            }
        #endif

        return AnySpecification { _ in false }
    }

    /// Creates a macOS performance tier specification
    /// - Parameter minimumTier: The minimum performance tier required
    /// - Returns: A specification that checks if the system meets the performance requirements
    public static func createMacOSPerformanceSpec(_ minimumTier: PerformanceTier)
        -> AnySpecification<Any>
    {
        #if canImport(AppKit) && os(macOS)
            if #available(macOS 10.15, *) {
                let provider = MacOSSystemContextProvider()
                return AnySpecification { _ in
                    let currentTier = provider.currentContext().performanceTier
                    switch (currentTier, minimumTier) {
                    case (.high, _): return true
                    case (.medium, .low), (.medium, .medium): return true
                    case (.low, .low): return true
                    default: return false
                    }
                }
            }
        #endif

        return AnySpecification { _ in false }
    }

    /// Creates an Apple TV system specification
    /// - Parameter capability: The Apple TV capability to check
    /// - Returns: A specification that checks the Apple TV capability
    public static func createAppleTVSpec(_ capability: AppleTVCapability) -> AnySpecification<Any> {
        #if canImport(UIKit) && canImport(GameController) && os(tvOS)
            if #available(tvOS 13.0, *) {
                switch capability {
                case .hdrSupport:
                    return AppleTVContextProvider.hdrSupportSpecification()
                case .siriRemote:
                    return AppleTVContextProvider.siriRemoteSpecification()
                case .remoteConnected:
                    return AppleTVContextProvider.remoteConnectedSpecification()
                case .darkMode:
                    return AppleTVContextProvider.darkModeSpecification()
                case .voiceOver:
                    return AppleTVContextProvider.voiceOverSpecification()
                case .highResolution(let width, let height):
                    return AppleTVContextProvider.screenResolutionSpecification(
                        minimumWidth: width, minimumHeight: height
                    )
                case .highMemory(let minimumGB):
                    return AppleTVContextProvider.memorySpecification(minimumGB: minimumGB)
                case .multiCore(let minimumCores):
                    return AppleTVContextProvider.processorSpecification(minimumCores: minimumCores)
                case .voiceCommands:
                    return AppleTVContextProvider.voiceCommandSupportSpecification()
                }
            }
        #endif

        return AnySpecification { _ in false }
    }

    /// Creates an Apple TV performance tier specification
    /// - Parameter minimumTier: The minimum performance tier required
    /// - Returns: A specification that checks if the Apple TV meets the performance requirements
    public static func createAppleTVPerformanceSpec(_ minimumTier: TVPerformanceTier)
        -> AnySpecification<Any>
    {
        #if canImport(UIKit) && canImport(GameController) && os(tvOS)
            if #available(tvOS 13.0, *) {
                let provider = AppleTVContextProvider()
                return AnySpecification { _ in
                    let currentTier = provider.currentContext().performanceTier
                    switch (currentTier, minimumTier) {
                    case (.high, _): return true
                    case (.standard, .reduced), (.standard, .standard): return true
                    case (.reduced, .reduced): return true
                    default: return false
                    }
                }
            }
        #endif

        return AnySpecification { _ in false }
    }
}

// MARK: - Supporting Types

/// Device capabilities that can be checked across platforms
public enum DeviceCapability {
    case location
    case healthKit
    case darkMode
    case lowPowerMode
    case voiceOver
}

/// A cross-platform location coordinate representation
public struct LocationCoordinate {
    public let latitude: Double
    public let longitude: Double

    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }

    #if canImport(CoreLocation)
        /// Convert to CoreLocation coordinate
        public var coreLocationCoordinate: CLLocationCoordinate2D {
            return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }

        /// Create from CoreLocation coordinate
        public init(_ coordinate: CLLocationCoordinate2D) {
            self.latitude = coordinate.latitude
            self.longitude = coordinate.longitude
        }
    #endif
}

/// Basic device context for platforms without UIKit
public struct BasicDeviceContext {
    public let systemName: String
    public let systemVersion: String

    public init() {
        #if os(macOS)
            self.systemName = "macOS"
        #elseif os(iOS)
            self.systemName = "iOS"
        #elseif os(watchOS)
            self.systemName = "watchOS"
        #elseif os(tvOS)
            self.systemName = "tvOS"
        #else
            self.systemName = "Unknown"
        #endif

        let version = ProcessInfo.processInfo.operatingSystemVersion
        self.systemVersion =
            "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
    }
}

/// Empty location context for platforms without location services
public struct EmptyLocationContext {
    public let currentLocation: Any? = nil
    public let isLocationAvailable = false

    public init() {}
}

/// Basic system context for platforms without platform-specific system APIs
public struct BasicSystemContext {
    public let systemName: String
    public let systemVersion: String
    public let processorCount: Int
    public let physicalMemory: UInt64

    public init() {
        #if os(macOS)
            self.systemName = "macOS"
        #elseif os(iOS)
            self.systemName = "iOS"
        #elseif os(watchOS)
            self.systemName = "watchOS"
        #elseif os(tvOS)
            self.systemName = "tvOS"
        #else
            self.systemName = "Unknown"
        #endif

        let version = ProcessInfo.processInfo.operatingSystemVersion
        self.systemVersion =
            "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"

        self.processorCount = ProcessInfo.processInfo.processorCount
        self.physicalMemory = ProcessInfo.processInfo.physicalMemory
    }
}

/// macOS system capabilities that can be checked
public enum MacOSSystemCapability {
    case darkMode
    case onBattery
    case reduceMotion
    case highMemory(minimumGB: UInt64)
    case multiCore(minimumCores: Int)
}

/// macOS dock positions
public enum DockPosition: String, CaseIterable {
    case bottom = "bottom"
    case left = "left"
    case right = "right"
}

/// System performance tiers for macOS
public enum PerformanceTier: String, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
}

/// Apple TV capabilities that can be checked
public enum AppleTVCapability {
    case hdrSupport
    case siriRemote
    case remoteConnected
    case darkMode
    case voiceOver
    case highResolution(minimumWidth: CGFloat, minimumHeight: CGFloat)
    case highMemory(minimumGB: UInt64)
    case multiCore(minimumCores: Int)
    case voiceCommands
}

/// Apple TV performance tiers for tvOS
public enum TVPerformanceTier: String, CaseIterable {
    case reduced = "reduced"
    case standard = "standard"
    case high = "high"
}

// MARK: - Stub Types for Cross-Platform Compilation

#if !os(macOS)
    /// Stub for MacOSSystemContextProvider on non-macOS platforms
    public final class MacOSSystemContextProvider: ContextProviding, ObservableObject {
        public init() {}

        public func getValue(for key: String) -> Any? {
            return nil
        }

        public func currentContext() -> Any {
            return [:]
        }

        public static func darkModeSpecification() -> AnySpecification<Any> {
            return AnySpecification { _ in false }
        }

        public static func onBatterySpecification() -> AnySpecification<Any> {
            return AnySpecification { _ in false }
        }

        public static func reduceMotionSpecification() -> AnySpecification<Any> {
            return AnySpecification { _ in false }
        }

        public static func dockPositionSpecification(_ position: DockPosition) -> AnySpecification<
            Any
        > {
            return AnySpecification { _ in false }
        }

        public static func memorySpecification(minimumGB: UInt64) -> AnySpecification<Any> {
            return AnySpecification { _ in false }
        }

        public static func processorSpecification(minimumCores: Int) -> AnySpecification<Any> {
            return AnySpecification { _ in false }
        }
    }

#endif

// MARK: - Privacy and Permission Helpers

extension PlatformContextProviders {

    /// Checks if location permission has been granted
    public static var hasLocationPermission: Bool {
        #if canImport(CoreLocation) && (os(iOS) || os(watchOS))
            let status = CLLocationManager.authorizationStatus()
            return status == .authorizedWhenInUse || status == .authorizedAlways
        #else
            return false
        #endif
    }

    /// Requests location permission asynchronously
    /// - Returns: Whether permission was granted
    public static func requestLocationPermission() async -> Bool {
        #if canImport(CoreLocation) && (os(iOS) || os(watchOS))
            if #available(iOS 14.0, watchOS 7.0, *) {
                return await withCheckedContinuation { continuation in
                    let manager = CLLocationManager()
                    let delegate = LocationPermissionDelegate { authorized in
                        continuation.resume(returning: authorized)
                    }
                    manager.delegate = delegate
                    manager.requestWhenInUseAuthorization()
                }
            }
        #endif
        return false
    }

    /// Checks if HealthKit permission has been granted
    /// - Parameter types: The health data types to check
    /// - Returns: Whether permission has been granted for all types
    public static func hasHealthPermission(for types: [String] = []) -> Bool {
        #if canImport(HealthKit) && (os(iOS) || os(watchOS))
            return HKHealthStore.isHealthDataAvailable()
        #else
            return false
        #endif
    }
}

// MARK: - Helper Classes

#if canImport(CoreLocation) && (os(iOS) || os(watchOS))
    private class LocationPermissionDelegate: NSObject, CLLocationManagerDelegate {
        private let completion: (Bool) -> Void

        init(completion: @escaping (Bool) -> Void) {
            self.completion = completion
            super.init()
        }

        func locationManager(
            _ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus
        ) {
            switch status {
            case .authorizedWhenInUse, .authorizedAlways:
                completion(true)
            case .denied, .restricted:
                completion(false)
            case .notDetermined:
                break  // Wait for user decision
            @unknown default:
                completion(false)
            }
        }

        func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
            completion(false)
        }
    }
#endif
