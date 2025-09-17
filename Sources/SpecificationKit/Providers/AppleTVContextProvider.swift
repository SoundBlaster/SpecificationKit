//
//  AppleTVContextProvider.swift
//  SpecificationKit
//
//  Created by SpecificationKit on 2024.
//

#if canImport(UIKit) && canImport(GameController) && os(tvOS)
    import Foundation
    import UIKit
    import GameController
    #if canImport(Combine)
        import Combine
    #endif

    /// A context provider that provides tvOS and Apple TV system information for specifications.
    ///
    /// `AppleTVContextProvider` integrates with UIKit, GameController, and tvOS-specific APIs to provide
    /// real-time system state information for specification evaluation. It monitors TV-specific settings,
    /// remote control state, display properties, and system resources to enable context-aware Apple TV
    /// application behavior.
    ///
    /// ## Key Features
    ///
    /// - **TV Display**: Screen resolution, scale, HDR support, and display mode detection
    /// - **Remote Control**: Siri Remote, Apple TV Remote, and third-party controller detection
    /// - **System Preferences**: Dark mode, accessibility settings, and content size preferences
    /// - **Performance Monitoring**: Memory usage, thermal state, and performance indicators
    /// - **Accessibility**: VoiceOver, Switch Control, and other accessibility features
    /// - **Reactive Updates**: Publishes changes via Combine when system state changes
    /// - **Thread-Safe**: All operations are thread-safe for concurrent access
    ///
    /// ## Usage Examples
    ///
    /// ### Basic TV Information
    /// ```swift
    /// let tvProvider = AppleTVContextProvider()
    ///
    /// // Use with TV-based specifications
    /// struct HighResolutionSpec: Specification {
    ///     func isSatisfiedBy(_ context: AppleTVContext) -> Bool {
    ///         guard let resolution = context.screenResolution else { return false }
    ///         return resolution.width >= 1920 && resolution.height >= 1080
    ///     }
    /// }
    ///
    /// @Satisfies(provider: tvProvider, using: HighResolutionSpec())
    /// var isHighResolution: Bool
    /// ```
    ///
    /// ### Remote Control Detection
    /// ```swift
    /// struct SiriRemoteSpec: Specification {
    ///     func isSatisfiedBy(_ context: AppleTVContext) -> Bool {
    ///         return context.hasSiriRemote == true
    ///     }
    /// }
    ///
    /// @Satisfies(provider: tvProvider, using: SiriRemoteSpec())
    /// var shouldUseSiriRemoteFeatures: Bool
    /// ```
    ///
    /// ### Performance-Based Decisions
    /// ```swift
    /// struct HighPerformanceTVSpec: Specification {
    ///     func isSatisfiedBy(_ context: AppleTVContext) -> Bool {
    ///         let hasGoodPerformance = context.isHighPerformanceAvailable
    ///         let hasHDR = context.supportsHDR == true
    ///         let goodThermals = context.thermalState == .nominal || context.thermalState == .fair
    ///         
    ///         return hasGoodPerformance && hasHDR && goodThermals
    ///     }
    /// }
    ///
    /// @Satisfies(provider: tvProvider, using: HighPerformanceTVSpec())
    /// var canRunHDRContent: Bool
    /// ```
    ///
    /// ### Accessibility-Aware UI
    /// ```swift
    /// struct TVAccessibilitySpec: Specification {
    ///     func isSatisfiedBy(_ context: AppleTVContext) -> Bool {
    ///         return context.isVoiceOverRunning == true || context.isSwitchControlRunning == true
    ///     }
    /// }
    ///
    /// @Satisfies(provider: tvProvider, using: TVAccessibilitySpec())
    /// var shouldOptimizeForAccessibility: Bool
    /// ```
    @available(tvOS 13.0, *)
    public final class AppleTVContextProvider: ContextProviding, ObservableObject {

        // MARK: - Context Type

        /// The context type provided by this provider
        public struct AppleTVContext {
            /// The device model (e.g., "Apple TV")
            public let deviceModel: String

            /// The tvOS system version (e.g., "17.0")
            public let systemVersion: String

            /// The user-assigned Apple TV name
            public let deviceName: String

            /// The interface idiom (should be .tv for Apple TV)
            public let userInterfaceIdiom: UIUserInterfaceIdiom

            /// Screen resolution in points
            public let screenResolution: CGSize?

            /// Screen scale factor
            public let screenScale: CGFloat

            /// Whether the display supports HDR content
            public let supportsHDR: Bool?

            /// Whether dark mode is enabled
            public let isDarkModeEnabled: Bool

            /// Whether VoiceOver is currently running
            public let isVoiceOverRunning: Bool

            /// Whether Switch Control is enabled
            public let isSwitchControlRunning: Bool

            /// Whether reduce motion is enabled
            public let isReduceMotionEnabled: Bool

            /// Current thermal state of the device
            public let thermalState: ProcessInfo.ThermalState

            /// Number of processor cores
            public let processorCount: Int

            /// Physical memory in bytes
            public let physicalMemory: UInt64

            /// Preferred content size category
            public let preferredContentSizeCategory: UIContentSizeCategory

            /// Whether any remote control is connected
            public let hasRemoteConnected: Bool

            /// Whether a Siri Remote is connected (has touchpad and microphone)
            public let hasSiriRemote: Bool

            /// Whether a standard Apple TV Remote is connected
            public let hasAppleRemote: Bool

            /// Number of connected game controllers
            public let connectedControllerCount: Int

            /// Whether the system supports voice commands
            public let supportsVoiceCommands: Bool

            internal init() {
                // Device information
                self.deviceModel = UIDevice.current.model
                self.systemVersion = UIDevice.current.systemVersion
                self.deviceName = UIDevice.current.name
                self.userInterfaceIdiom = UIDevice.current.userInterfaceIdiom

                // Display properties
                let screen = UIScreen.main
                self.screenResolution = screen.bounds.size
                self.screenScale = screen.scale
                
                // Check for HDR support (tvOS 13+)
                if #available(tvOS 13.0, *) {
                    self.supportsHDR = screen.traitCollection.displayGamut == .P3
                } else {
                    self.supportsHDR = false
                }

                // Accessibility
                self.isVoiceOverRunning = UIAccessibility.isVoiceOverRunning
                self.isSwitchControlRunning = UIAccessibility.isSwitchControlRunning
                self.isReduceMotionEnabled = UIAccessibility.isReduceMotionEnabled

                // UI appearance
                self.isDarkModeEnabled = UITraitCollection.current.userInterfaceStyle == .dark
                self.preferredContentSizeCategory = UIApplication.shared.preferredContentSizeCategory

                // System state
                self.thermalState = ProcessInfo.processInfo.thermalState
                self.processorCount = ProcessInfo.processInfo.processorCount
                self.physicalMemory = ProcessInfo.processInfo.physicalMemory

                // Remote control and game controller information
                let controllers = GCController.controllers()
                self.connectedControllerCount = controllers.count
                self.hasRemoteConnected = !controllers.isEmpty
                
                // Check for specific remote types
                let (hasSiri, hasApple) = Self.detectRemoteTypes(controllers)
                self.hasSiriRemote = hasSiri
                self.hasAppleRemote = hasApple
                
                // Voice command support (assuming true for tvOS with Siri Remote)
                self.supportsVoiceCommands = hasSiri
            }

            private static func detectRemoteTypes(_ controllers: [GCController]) -> (hasSiri: Bool, hasApple: Bool) {
                var hasSiriRemote = false
                var hasAppleRemote = false
                
                for controller in controllers {
                    // Siri Remote has a microGamepad and supports rotation
                    if let microGamepad = controller.microGamepad,
                       microGamepad.allowsRotation {
                        hasSiriRemote = true
                    }
                    // Apple TV Remote has microGamepad but may not support rotation
                    else if controller.microGamepad != nil {
                        hasAppleRemote = true
                    }
                }
                
                return (hasSiriRemote, hasAppleRemote)
            }
        }

        // MARK: - Private Properties

        private let lock = NSLock()
        private var cachedContext: AppleTVContext
        private var lastUpdateTime: Date
        private let cacheTimeout: TimeInterval = 2.0  // Cache for 2 seconds (longer for TV)

        #if canImport(Combine)
            public let objectWillChange = PassthroughSubject<Void, Never>()
            private var notificationObservers: [NSObjectProtocol] = []
        #endif

        // MARK: - Initialization

        /// Creates a new Apple TV context provider
        public init() {
            self.cachedContext = AppleTVContext()
            self.lastUpdateTime = Date()

            setupNotificationObservers()
        }

        deinit {
            #if canImport(Combine)
                notificationObservers.forEach { NotificationCenter.default.removeObserver($0) }
            #endif
        }

        // MARK: - ContextProviding

        public func getValue(for key: String) -> Any? {
            let context = currentContext()

            switch key {
            case "deviceModel":
                return context.deviceModel
            case "systemVersion":
                return context.systemVersion
            case "deviceName":
                return context.deviceName
            case "userInterfaceIdiom":
                return context.userInterfaceIdiom.rawValue
            case "screenResolution":
                return context.screenResolution
            case "screenScale":
                return context.screenScale
            case "supportsHDR":
                return context.supportsHDR
            case "isDarkModeEnabled":
                return context.isDarkModeEnabled
            case "isVoiceOverRunning":
                return context.isVoiceOverRunning
            case "isSwitchControlRunning":
                return context.isSwitchControlRunning
            case "isReduceMotionEnabled":
                return context.isReduceMotionEnabled
            case "thermalState":
                return context.thermalState.rawValue
            case "processorCount":
                return context.processorCount
            case "physicalMemory":
                return context.physicalMemory
            case "preferredContentSizeCategory":
                return context.preferredContentSizeCategory.rawValue
            case "hasRemoteConnected":
                return context.hasRemoteConnected
            case "hasSiriRemote":
                return context.hasSiriRemote
            case "hasAppleRemote":
                return context.hasAppleRemote
            case "connectedControllerCount":
                return context.connectedControllerCount
            case "supportsVoiceCommands":
                return context.supportsVoiceCommands
            default:
                return nil
            }
        }

        public func currentContext() -> AppleTVContext {
            lock.lock()
            defer { lock.unlock() }

            let now = Date()
            if now.timeIntervalSince(lastUpdateTime) > cacheTimeout {
                cachedContext = AppleTVContext()
                lastUpdateTime = now
            }

            return cachedContext
        }

        // MARK: - Notification Setup

        private func setupNotificationObservers() {
            #if canImport(Combine)
                let notificationCenter = NotificationCenter.default

                // Game controller notifications
                notificationObservers.append(
                    notificationCenter.addObserver(
                        forName: .GCControllerDidConnect,
                        object: nil,
                        queue: .main
                    ) { [weak self] _ in
                        self?.invalidateCache()
                    }
                )

                notificationObservers.append(
                    notificationCenter.addObserver(
                        forName: .GCControllerDidDisconnect,
                        object: nil,
                        queue: .main
                    ) { [weak self] _ in
                        self?.invalidateCache()
                    }
                )

                // Accessibility notifications
                notificationObservers.append(
                    notificationCenter.addObserver(
                        forName: UIAccessibility.voiceOverStatusDidChangeNotification,
                        object: nil,
                        queue: .main
                    ) { [weak self] _ in
                        self?.invalidateCache()
                    }
                )

                notificationObservers.append(
                    notificationCenter.addObserver(
                        forName: UIAccessibility.switchControlStatusDidChangeNotification,
                        object: nil,
                        queue: .main
                    ) { [weak self] _ in
                        self?.invalidateCache()
                    }
                )

                notificationObservers.append(
                    notificationCenter.addObserver(
                        forName: UIAccessibility.reduceMotionStatusDidChangeNotification,
                        object: nil,
                        queue: .main
                    ) { [weak self] _ in
                        self?.invalidateCache()
                    }
                )

                // Thermal state notifications
                notificationObservers.append(
                    notificationCenter.addObserver(
                        forName: .NSProcessInfoThermalStateDidChange,
                        object: nil,
                        queue: .main
                    ) { [weak self] _ in
                        self?.invalidateCache()
                    }
                )

                // Content size category notifications
                notificationObservers.append(
                    notificationCenter.addObserver(
                        forName: UIContentSizeCategory.didChangeNotification,
                        object: nil,
                        queue: .main
                    ) { [weak self] _ in
                        self?.invalidateCache()
                    }
                )

                // Display trait change notifications (for dark mode, etc.)
                notificationObservers.append(
                    notificationCenter.addObserver(
                        forName: UIApplication.didBecomeActiveNotification,
                        object: nil,
                        queue: .main
                    ) { [weak self] _ in
                        // Force refresh when app becomes active to catch display changes
                        self?.invalidateCache()
                    }
                )
            #endif
        }

        private func invalidateCache() {
            lock.lock()
            defer { lock.unlock() }

            lastUpdateTime = Date.distantPast  // Force refresh on next access

            #if canImport(Combine)
                objectWillChange.send()
            #endif
        }
    }

    // MARK: - Combine Support

    #if canImport(Combine)
        @available(tvOS 13.0, *)
        extension AppleTVContextProvider: ContextUpdatesProviding {

            /// Publisher that emits whenever the Apple TV context may have changed
            public var contextUpdates: AnyPublisher<Void, Never> {
                objectWillChange.eraseToAnyPublisher()
            }

            /// Async stream of context updates
            public var contextStream: AsyncStream<Void> {
                AsyncStream { continuation in
                    let subscription = objectWillChange.sink { _ in
                        continuation.yield(())
                    }
                    continuation.onTermination = { _ in
                        _ = subscription
                    }
                }
            }
        }
    #endif

    // MARK: - Convenience Extensions

    @available(tvOS 13.0, *)
    extension AppleTVContextProvider {

        /// Creates a specification that checks if the Apple TV has HDR support
        public static func hdrSupportSpecification() -> AnySpecification<Any> {
            let provider = AppleTVContextProvider()
            return AnySpecification { _ in
                provider.currentContext().supportsHDR == true
            }
        }

        /// Creates a specification that checks if a Siri Remote is connected
        public static func siriRemoteSpecification() -> AnySpecification<Any> {
            let provider = AppleTVContextProvider()
            return AnySpecification { _ in
                provider.currentContext().hasSiriRemote
            }
        }

        /// Creates a specification that checks if any remote is connected
        public static func remoteConnectedSpecification() -> AnySpecification<Any> {
            let provider = AppleTVContextProvider()
            return AnySpecification { _ in
                provider.currentContext().hasRemoteConnected
            }
        }

        /// Creates a specification that checks if dark mode is enabled
        public static func darkModeSpecification() -> AnySpecification<Any> {
            let provider = AppleTVContextProvider()
            return AnySpecification { _ in
                provider.currentContext().isDarkModeEnabled
            }
        }

        /// Creates a specification that checks if VoiceOver is enabled
        public static func voiceOverSpecification() -> AnySpecification<Any> {
            let provider = AppleTVContextProvider()
            return AnySpecification { _ in
                provider.currentContext().isVoiceOverRunning
            }
        }

        /// Creates a specification that checks thermal state
        /// - Parameter allowedStates: The thermal states that should return true
        public static func thermalStateSpecification(
            allowedStates: Set<ProcessInfo.ThermalState> = [.nominal, .fair]
        ) -> AnySpecification<Any> {
            let provider = AppleTVContextProvider()
            return AnySpecification { _ in
                allowedStates.contains(provider.currentContext().thermalState)
            }
        }

        /// Creates a specification that checks screen resolution
        /// - Parameters:
        ///   - minimumWidth: Minimum width in points
        ///   - minimumHeight: Minimum height in points
        public static func screenResolutionSpecification(
            minimumWidth: CGFloat,
            minimumHeight: CGFloat = 0
        ) -> AnySpecification<Any> {
            let provider = AppleTVContextProvider()
            return AnySpecification { _ in
                guard let resolution = provider.currentContext().screenResolution else { return false }
                return resolution.width >= minimumWidth && resolution.height >= minimumHeight
            }
        }

        /// Creates a specification that checks if the system has sufficient memory
        /// - Parameter minimumGB: Minimum memory in gigabytes
        public static func memorySpecification(minimumGB: UInt64) -> AnySpecification<Any> {
            let provider = AppleTVContextProvider()
            return AnySpecification { _ in
                let memory = provider.currentContext().physicalMemory
                let minimumBytes = minimumGB * 1024 * 1024 * 1024
                return memory >= minimumBytes
            }
        }

        /// Creates a specification that checks if the system has sufficient CPU cores
        /// - Parameter minimumCores: Minimum number of CPU cores
        public static func processorSpecification(minimumCores: Int) -> AnySpecification<Any> {
            let provider = AppleTVContextProvider()
            return AnySpecification { _ in
                let cores = provider.currentContext().processorCount
                return cores >= minimumCores
            }
        }

        /// Creates a specification that checks if voice commands are supported
        public static func voiceCommandSupportSpecification() -> AnySpecification<Any> {
            let provider = AppleTVContextProvider()
            return AnySpecification { _ in
                provider.currentContext().supportsVoiceCommands
            }
        }
    }

    // MARK: - AppleTVContext Extensions

    @available(tvOS 13.0, *)
    extension AppleTVContextProvider.AppleTVContext {

        /// Whether the Apple TV is in a good performance state
        public var isHighPerformanceAvailable: Bool {
            let thermalGood = thermalState == .nominal || thermalState == .fair
            let hasMemory = physicalMemory > (2 * 1024 * 1024 * 1024)  // 2GB minimum
            let hasCPU = processorCount >= 2

            return thermalGood && hasMemory && hasCPU
        }

        /// Whether the Apple TV should use reduced functionality
        public var shouldReduceFeatures: Bool {
            let thermalStressed = thermalState == .serious || thermalState == .critical
            let lowMemory = physicalMemory < (1 * 1024 * 1024 * 1024)  // Less than 1GB

            return thermalStressed || lowMemory
        }

        /// Whether accessibility features are enabled that affect UI
        public var hasAccessibilityFeaturesEnabled: Bool {
            return isVoiceOverRunning || isSwitchControlRunning || isReduceMotionEnabled
        }

        /// System performance tier based on hardware and thermal state
        public var performanceTier: TVPerformanceTier {
            guard let memory = physicalMemory as UInt64? else {
                return .standard
            }

            let memoryGB = memory / (1024 * 1024 * 1024)
            let thermalGood = thermalState == .nominal || thermalState == .fair

            if memoryGB >= 4 && processorCount >= 4 && thermalGood {
                return .high
            } else if memoryGB >= 2 && processorCount >= 2 && thermalGood {
                return .standard
            } else {
                return .reduced
            }
        }

        /// Whether the display supports high-quality content (4K or HDR)
        public var supportsHighQualityContent: Bool {
            guard let resolution = screenResolution else { return false }
            
            let is4K = resolution.width >= 3840 || resolution.height >= 2160
            let hasHDR = supportsHDR == true
            
            return is4K || hasHDR
        }

        /// Whether input methods support advanced interactions
        public var supportsAdvancedInput: Bool {
            return hasSiriRemote || connectedControllerCount > 1
        }
    }

    // MARK: - Supporting Types

#endif

// MARK: - Stub for Non-tvOS Platforms

#if !os(tvOS)
    import Foundation
    #if canImport(Combine)
        import Combine
    #endif
    #if canImport(CoreGraphics)
        import CoreGraphics
    #endif

    #if canImport(UIKit)
        import UIKit
    #else
        public enum UIUserInterfaceIdiom: String {
            case unspecified = "unspecified"
        }

        public enum UIContentSizeCategory: String {
            case medium = "UICTContentSizeCategoryM"
        }
    #endif

    #if !canImport(CoreGraphics)
        public struct CGSize {
            public var width: Double
            public var height: Double

            public init(width: Double, height: Double) {
                self.width = width
                self.height = height
            }
        }

        public typealias CGFloat = Double
    #endif

    #if canImport(Combine)
        typealias AppleTVObservableContext = ObservableObject
    #else
        protocol AppleTVObservableContext {}
    #endif

    /// Stub for AppleTVContextProvider on non-tvOS platforms
    public final class AppleTVContextProvider: ContextProviding, AppleTVObservableContext {
        public struct AppleTVContext {
            public let deviceModel = "Unknown"
            public let systemVersion = "0.0.0"
            public let deviceName = "Unknown"
            public let userInterfaceIdiom = UIUserInterfaceIdiom.unspecified
            public let screenResolution: CGSize? = nil
            public let screenScale: CGFloat = 1.0
            public let supportsHDR: Bool? = nil
            public let isDarkModeEnabled = false
            public let isVoiceOverRunning = false
            public let isSwitchControlRunning = false
            public let isReduceMotionEnabled = false
            public let thermalState = ProcessInfo.ThermalState.nominal
            public let processorCount = 1
            public let physicalMemory: UInt64 = 1024 * 1024 * 1024
            public let preferredContentSizeCategory = UIContentSizeCategory.medium
            public let hasRemoteConnected = false
            public let hasSiriRemote = false
            public let hasAppleRemote = false
            public let connectedControllerCount = 0
            public let supportsVoiceCommands = false

            public var isHighPerformanceAvailable: Bool { false }
            public var shouldReduceFeatures: Bool { true }
            public var hasAccessibilityFeaturesEnabled: Bool { false }
            public var performanceTier: TVPerformanceTier { .reduced }
            public var supportsHighQualityContent: Bool { false }
            public var supportsAdvancedInput: Bool { false }
        }

        #if canImport(Combine)
            public let objectWillChange = PassthroughSubject<Void, Never>()
        #endif

        public init() {}

        public func getValue(for key: String) -> Any? {
            return nil
        }

        public func currentContext() -> AppleTVContext {
            return AppleTVContext()
        }

        // Convenience specifications that return false on non-tvOS platforms
        public static func hdrSupportSpecification() -> AnySpecification<Any> {
            return AnySpecification { _ in false }
        }

        public static func siriRemoteSpecification() -> AnySpecification<Any> {
            return AnySpecification { _ in false }
        }

        public static func remoteConnectedSpecification() -> AnySpecification<Any> {
            return AnySpecification { _ in false }
        }

        public static func darkModeSpecification() -> AnySpecification<Any> {
            return AnySpecification { _ in false }
        }

        public static func voiceOverSpecification() -> AnySpecification<Any> {
            return AnySpecification { _ in false }
        }

        public static func thermalStateSpecification(
            allowedStates: Set<ProcessInfo.ThermalState> = [.nominal, .fair]
        ) -> AnySpecification<Any> {
            return AnySpecification { _ in false }
        }

        public static func screenResolutionSpecification(
            minimumWidth: CGFloat,
            minimumHeight: CGFloat = 0
        ) -> AnySpecification<Any> {
            return AnySpecification { _ in false }
        }

        public static func memorySpecification(minimumGB: UInt64) -> AnySpecification<Any> {
            return AnySpecification { _ in false }
        }

        public static func processorSpecification(minimumCores: Int) -> AnySpecification<Any> {
            return AnySpecification { _ in false }
        }

        public static func voiceCommandSupportSpecification() -> AnySpecification<Any> {
            return AnySpecification { _ in false }
        }
    }
#endif
