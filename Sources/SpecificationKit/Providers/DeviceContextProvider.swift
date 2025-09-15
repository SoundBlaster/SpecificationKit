//
//  DeviceContextProvider.swift
//  SpecificationKit
//
//  Created by SpecificationKit on 2024.
//

#if canImport(UIKit) && (os(iOS) || os(tvOS))
    import Foundation
    import UIKit
    #if canImport(Combine)
        import Combine
    #endif

    /// A context provider that provides device and system information for specifications on iOS and tvOS.
    ///
    /// `DeviceContextProvider` integrates with UIKit and system APIs to provide real-time device state
    /// information for specification evaluation. It monitors device properties, system state, and
    /// accessibility settings to enable context-aware application behavior.
    ///
    /// ## Key Features
    ///
    /// - **Device Information**: Model, name, system version, and hardware details
    /// - **Battery Monitoring**: Battery level, charging state, and low power mode
    /// - **System State**: Thermal state, memory pressure, and performance indicators
    /// - **Accessibility**: VoiceOver, reduce motion, and other accessibility settings
    /// - **Display Properties**: Screen brightness, scale, dark mode, and orientation
    /// - **Reactive Updates**: Publishes changes via Combine when state changes
    /// - **Thread-Safe**: All operations are thread-safe for concurrent access
    ///
    /// ## Usage Examples
    ///
    /// ### Basic Device Information
    /// ```swift
    /// let deviceProvider = DeviceContextProvider()
    ///
    /// // Use with device-based specifications
    /// struct iPadOnlySpec: Specification {
    ///     func isSatisfiedBy(_ context: DeviceContext) -> Bool {
    ///         return context.userInterfaceIdiom == .pad
    ///     }
    /// }
    ///
    /// @Satisfies(provider: deviceProvider, using: iPadOnlySpec())
    /// var isiPad: Bool
    /// ```
    ///
    /// ### Battery-Aware Features
    /// ```swift
    /// struct LowBatterySpec: Specification {
    ///     func isSatisfiedBy(_ context: DeviceContext) -> Bool {
    ///         guard let batteryLevel = context.batteryLevel else { return false }
    ///         return batteryLevel < 0.2 || context.isLowPowerModeEnabled == true
    ///     }
    /// }
    ///
    /// @Satisfies(provider: deviceProvider, using: LowBatterySpec())
    /// var shouldReduceFeatures: Bool
    ///
    /// if shouldReduceFeatures {
    ///     // Disable animations, reduce background processing, etc.
    /// }
    /// ```
    ///
    /// ### Accessibility-Aware UI
    /// ```swift
    /// struct VoiceOverEnabledSpec: Specification {
    ///     func isSatisfiedBy(_ context: DeviceContext) -> Bool {
    ///         return context.isVoiceOverRunning == true
    ///     }
    /// }
    ///
    /// @Satisfies(provider: deviceProvider, using: VoiceOverEnabledSpec())
    /// var shouldOptimizeForVoiceOver: Bool
    /// ```
    ///
    /// ### Dark Mode Support
    /// ```swift
    /// struct DarkModeSpec: Specification {
    ///     func isSatisfiedBy(_ context: DeviceContext) -> Bool {
    ///         return context.isDarkModeEnabled == true
    ///     }
    /// }
    ///
    /// @ObservedSatisfies(provider: deviceProvider, using: DarkModeSpec())
    /// var isDarkMode: Bool
    /// ```
    ///
    /// ### Performance-Based Specifications
    /// ```swift
    /// struct HighPerformanceAvailableSpec: Specification {
    ///     func isSatisfiedBy(_ context: DeviceContext) -> Bool {
    ///         let thermalGood = context.thermalState == .nominal || context.thermalState == .fair
    ///         let batteryGood = (context.batteryLevel ?? 1.0) > 0.3
    ///         let notLowPower = context.isLowPowerModeEnabled != true
    ///
    ///         return thermalGood && batteryGood && notLowPower
    ///     }
    /// }
    ///
    /// @Satisfies(provider: deviceProvider, using: HighPerformanceAvailableSpec())
    /// var canRunHighPerformanceFeatures: Bool
    /// ```
    ///
    /// ## Device Context Structure
    ///
    /// The `DeviceContext` provides comprehensive device and system information:
    /// - **Device Identity**: `deviceModel`, `systemVersion`, `deviceName`
    /// - **Hardware**: `userInterfaceIdiom`, `screenScale`, `screenBrightness`
    /// - **Power**: `batteryLevel`, `batteryState`, `isLowPowerModeEnabled`
    /// - **Performance**: `thermalState`, `processorCount`, `physicalMemory`
    /// - **Accessibility**: `isVoiceOverRunning`, `isReduceMotionEnabled`
    /// - **UI State**: `isDarkModeEnabled`, `preferredContentSizeCategory`
    ///
    /// ## Automatic Monitoring
    ///
    /// The provider automatically monitors system notifications for:
    /// - Battery level and state changes
    /// - Thermal state changes
    /// - Low power mode transitions
    /// - Accessibility setting changes
    /// - UI appearance changes (dark mode, etc.)
    @available(iOS 13.0, tvOS 13.0, *)
    public final class DeviceContextProvider: ContextProviding {

        // MARK: - Context Type

        /// The context type provided by this provider
        public struct DeviceContext {
            /// The device model (e.g., "iPhone", "iPad", "Apple TV")
            public let deviceModel: String

            /// The system version (e.g., "17.0")
            public let systemVersion: String

            /// The user-assigned device name
            public let deviceName: String

            /// The interface idiom (phone, pad, tv, etc.)
            public let userInterfaceIdiom: UIUserInterfaceIdiom

            /// Battery level (0.0 to 1.0, nil if unavailable)
            public let batteryLevel: Float?

            /// Current battery state
            public let batteryState: UIDevice.BatteryState?

            /// Whether low power mode is enabled
            public let isLowPowerModeEnabled: Bool

            /// Current thermal state of the device
            public let thermalState: ProcessInfo.ThermalState

            /// Current screen brightness (0.0 to 1.0)
            public let screenBrightness: CGFloat

            /// Screen scale factor
            public let screenScale: CGFloat

            /// Whether VoiceOver is currently running
            public let isVoiceOverRunning: Bool

            /// Whether dark mode is enabled
            public let isDarkModeEnabled: Bool

            /// Whether reduce motion is enabled
            public let isReduceMotionEnabled: Bool

            /// Number of processor cores
            public let processorCount: Int

            /// Physical memory in bytes
            public let physicalMemory: UInt64

            /// Preferred content size category
            public let preferredContentSizeCategory: UIContentSizeCategory

            internal init() {
                // Device information
                self.deviceModel = UIDevice.current.model
                self.systemVersion = UIDevice.current.systemVersion
                self.deviceName = UIDevice.current.name
                self.userInterfaceIdiom = UIDevice.current.userInterfaceIdiom

                // Battery information
                UIDevice.current.isBatteryMonitoringEnabled = true
                self.batteryLevel =
                    UIDevice.current.batteryLevel >= 0 ? UIDevice.current.batteryLevel : nil
                self.batteryState = UIDevice.current.batteryState

                // System state
                self.isLowPowerModeEnabled = ProcessInfo.processInfo.isLowPowerModeEnabled
                self.thermalState = ProcessInfo.processInfo.thermalState
                self.processorCount = ProcessInfo.processInfo.processorCount
                self.physicalMemory = ProcessInfo.processInfo.physicalMemory

                // Display properties
                self.screenBrightness = UIScreen.main.brightness
                self.screenScale = UIScreen.main.scale

                // Accessibility
                self.isVoiceOverRunning = UIAccessibility.isVoiceOverRunning
                self.isReduceMotionEnabled = UIAccessibility.isReduceMotionEnabled

                // UI appearance
                self.isDarkModeEnabled = UITraitCollection.current.userInterfaceStyle == .dark
                self.preferredContentSizeCategory =
                    UIApplication.shared.preferredContentSizeCategory
            }
        }

        // MARK: - Private Properties

        private let lock = NSLock()
        private var cachedContext: DeviceContext
        private var lastUpdateTime: Date
        private let cacheTimeout: TimeInterval = 1.0  // Cache for 1 second

        #if canImport(Combine)
            public let objectWillChange = PassthroughSubject<Void, Never>()
            private var notificationObservers: [NSObjectProtocol] = []
        #endif

        // MARK: - Initialization

        /// Creates a new device context provider
        public init() {
            self.cachedContext = DeviceContext()
            self.lastUpdateTime = Date()

            setupNotificationObservers()
        }

        deinit {
            #if canImport(Combine)
                notificationObservers.forEach { NotificationCenter.default.removeObserver($0) }
            #endif
        }

        // MARK: - ContextProviding

        public func currentContext() -> DeviceContext {
            lock.lock()
            defer { lock.unlock() }

            let now = Date()
            if now.timeIntervalSince(lastUpdateTime) > cacheTimeout {
                cachedContext = DeviceContext()
                lastUpdateTime = now
            }

            return cachedContext
        }

        // MARK: - Notification Setup

        private func setupNotificationObservers() {
            #if canImport(Combine)
                let notificationCenter = NotificationCenter.default

                // Battery notifications
                notificationObservers.append(
                    notificationCenter.addObserver(
                        forName: UIDevice.batteryLevelDidChangeNotification,
                        object: nil,
                        queue: .main
                    ) { [weak self] _ in
                        self?.invalidateCache()
                    }
                )

                notificationObservers.append(
                    notificationCenter.addObserver(
                        forName: UIDevice.batteryStateDidChangeNotification,
                        object: nil,
                        queue: .main
                    ) { [weak self] _ in
                        self?.invalidateCache()
                    }
                )

                // Low power mode notifications
                notificationObservers.append(
                    notificationCenter.addObserver(
                        forName: .NSProcessInfoPowerStateDidChange,
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
                        forName: UIAccessibility.reduceMotionStatusDidChangeNotification,
                        object: nil,
                        queue: .main
                    ) { [weak self] _ in
                        self?.invalidateCache()
                    }
                )

                // Screen brightness notifications
                notificationObservers.append(
                    notificationCenter.addObserver(
                        forName: UIScreen.brightnessDidChangeNotification,
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
        @available(iOS 13.0, tvOS 13.0, *)
        extension DeviceContextProvider: ContextUpdatesProviding {

            /// Publisher that emits whenever the device context may have changed
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

    @available(iOS 13.0, tvOS 13.0, *)
    extension DeviceContextProvider {

        /// Creates a specification that checks if the device is an iPad
        public static func iPadSpecification() -> AnySpecification<Any> {
            let provider = DeviceContextProvider()
            return AnySpecification { _ in
                provider.currentContext().userInterfaceIdiom == .pad
            }
        }

        /// Creates a specification that checks if the device is an iPhone
        public static func iPhoneSpecification() -> AnySpecification<Any> {
            let provider = DeviceContextProvider()
            return AnySpecification { _ in
                provider.currentContext().userInterfaceIdiom == .phone
            }
        }

        /// Creates a specification that checks if dark mode is enabled
        public static func darkModeSpecification() -> AnySpecification<Any> {
            let provider = DeviceContextProvider()
            return AnySpecification { _ in
                provider.currentContext().isDarkModeEnabled
            }
        }

        /// Creates a specification that checks if the device is in low power mode
        public static func lowPowerModeSpecification() -> AnySpecification<Any> {
            let provider = DeviceContextProvider()
            return AnySpecification { _ in
                provider.currentContext().isLowPowerModeEnabled
            }
        }

        /// Creates a specification that checks if battery level is below a threshold
        /// - Parameter threshold: Battery level threshold (0.0 to 1.0)
        public static func lowBatterySpecification(threshold: Float = 0.2) -> AnySpecification<Any>
        {
            let provider = DeviceContextProvider()
            return AnySpecification { _ in
                let context = provider.currentContext()
                guard let batteryLevel = context.batteryLevel else { return false }
                return batteryLevel < threshold
            }
        }

        /// Creates a specification that checks if VoiceOver is enabled
        public static func voiceOverSpecification() -> AnySpecification<Any> {
            let provider = DeviceContextProvider()
            return AnySpecification { _ in
                provider.currentContext().isVoiceOverRunning
            }
        }

        /// Creates a specification that checks thermal state
        /// - Parameter allowedStates: The thermal states that should return true
        public static func thermalStateSpecification(
            allowedStates: Set<ProcessInfo.ThermalState> = [.nominal, .fair]
        ) -> AnySpecification<Any> {
            let provider = DeviceContextProvider()
            return AnySpecification { _ in
                allowedStates.contains(provider.currentContext().thermalState)
            }
        }
    }

    // MARK: - DeviceContext Extensions

    @available(iOS 13.0, tvOS 13.0, *)
    extension DeviceContextProvider.DeviceContext {

        /// Whether the device is an iPad
        public var isiPad: Bool {
            return userInterfaceIdiom == .pad
        }

        /// Whether the device is an iPhone
        public var isiPhone: Bool {
            return userInterfaceIdiom == .phone
        }

        /// Whether the device is in a good performance state
        public var isHighPerformanceAvailable: Bool {
            let thermalGood = thermalState == .nominal || thermalState == .fair
            let batteryGood = (batteryLevel ?? 1.0) > 0.3
            let notLowPower = !isLowPowerModeEnabled

            return thermalGood && batteryGood && notLowPower
        }

        /// Whether the device should use reduced functionality
        public var shouldReduceFeatures: Bool {
            let lowBattery = (batteryLevel ?? 1.0) < 0.2
            let thermalStressed = thermalState == .serious || thermalState == .critical

            return isLowPowerModeEnabled || lowBattery || thermalStressed
        }

        /// Whether accessibility features are enabled that affect UI
        public var hasAccessibilityFeaturesEnabled: Bool {
            return isVoiceOverRunning || isReduceMotionEnabled
        }
    }

#endif
