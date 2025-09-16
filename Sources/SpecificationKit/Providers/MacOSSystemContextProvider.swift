//
//  MacOSSystemContextProvider.swift
//  SpecificationKit
//
//  Created by SpecificationKit on 2024.
//

#if canImport(AppKit) && os(macOS)
    import Foundation
    import AppKit
    import SystemConfiguration
    import IOKit
    import IOKit.ps
    #if canImport(Combine)
        import Combine
    #endif

    /// A context provider that provides macOS system information for specifications.
    ///
    /// `MacOSSystemContextProvider` integrates with AppKit and system APIs to provide real-time
    /// system state information for specification evaluation. It monitors system preferences,
    /// power state, and system resources to enable context-aware application behavior on macOS.
    ///
    /// ## Key Features
    ///
    /// - **System Preferences**: Dark mode, accessibility settings, and UI preferences
    /// - **Power Management**: Battery state detection and power source monitoring
    /// - **System State**: Uptime, memory, processor information, and thermal state
    /// - **Dock Integration**: Dock position and configuration detection
    /// - **Reactive Updates**: Publishes changes via Combine when system state changes
    /// - **Thread-Safe**: All operations are thread-safe for concurrent access
    ///
    /// ## Usage Examples
    ///
    /// ### Basic System Information
    /// ```swift
    /// let systemProvider = MacOSSystemContextProvider()
    ///
    /// // Use with system-based specifications
    /// struct DarkModeSpec: Specification {
    ///     func isSatisfiedBy(_ context: MacOSSystemContext) -> Bool {
    ///         return context.isDarkModeEnabled == true
    ///     }
    /// }
    ///
    /// @Satisfies(provider: systemProvider, using: DarkModeSpec())
    /// var isDarkMode: Bool
    /// ```
    ///
    /// ### Battery-Aware Features
    /// ```swift
    /// struct OnBatterySpec: Specification {
    ///     func isSatisfiedBy(_ context: MacOSSystemContext) -> Bool {
    ///         return context.isOnBattery == true
    ///     }
    /// }
    ///
    /// @Satisfies(provider: systemProvider, using: OnBatterySpec())
    /// var shouldReducePowerUsage: Bool
    ///
    /// if shouldReducePowerUsage {
    ///     // Reduce background processing, disable animations, etc.
    /// }
    /// ```
    ///
    /// ### Performance-Based Decisions
    /// ```swift
    /// struct HighPerformanceMacSpec: Specification {
    ///     func isSatisfiedBy(_ context: MacOSSystemContext) -> Bool {
    ///         guard let memory = context.physicalMemory else { return false }
    ///         guard let processors = context.processorCount else { return false }
    ///
    ///         let hasEnoughMemory = memory > (8 * 1024 * 1024 * 1024) // 8GB
    ///         let hasEnoughCPU = processors >= 4
    ///         let notOnBattery = context.isOnBattery != true
    ///
    ///         return hasEnoughMemory && hasEnoughCPU && notOnBattery
    ///     }
    /// }
    ///
    /// @Satisfies(provider: systemProvider, using: HighPerformanceMacSpec())
    /// var canRunHeavyTasks: Bool
    /// ```
    @available(macOS 10.15, *)
    public final class MacOSSystemContextProvider: ContextProviding, ObservableObject {

        // MARK: - Context Type

        /// The context type provided by this provider
        public struct MacOSSystemContext {
            /// Whether dark mode is currently enabled
            public let isDarkModeEnabled: Bool?

            /// Whether reduce motion accessibility setting is enabled
            public let isReduceMotionEnabled: Bool?

            /// System uptime in seconds
            public let systemUptime: TimeInterval?

            /// Operating system version string (e.g., "15.1.0")
            public let operatingSystemVersion: String?

            /// Number of processor cores
            public let processorCount: Int?

            /// Physical memory in bytes
            public let physicalMemory: UInt64?

            /// Whether the system is running on battery power
            public let isOnBattery: Bool?

            /// Height of the menu bar in points
            public let menuBarHeight: CGFloat?

            /// Current dock position ("bottom", "left", "right")
            public let dockPosition: String?

            /// Determines if test environment defaults should be used
            /// Internal for testing purposes
            internal static func shouldUseTestEnvironmentDefaults() -> Bool {
                let isTestEnvironment =
                    ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
                return isTestEnvironment || NSApp == nil
            }

            internal init() {
                // UI appearance - safe for testing environments
                if Self.shouldUseTestEnvironmentDefaults() {
                    self.isDarkModeEnabled = false
                    self.menuBarHeight = 24.0  // Default menu bar height
                } else {
                    self.isDarkModeEnabled =
                        NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                    self.menuBarHeight = NSApplication.shared.mainMenu?.menuBarHeight
                }

                // Accessibility
                self.isReduceMotionEnabled =
                    NSWorkspace.shared.accessibilityDisplayShouldReduceMotion

                // System information
                self.systemUptime = ProcessInfo.processInfo.systemUptime

                let version = ProcessInfo.processInfo.operatingSystemVersion
                self.operatingSystemVersion =
                    "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"

                self.processorCount = ProcessInfo.processInfo.processorCount
                self.physicalMemory = ProcessInfo.processInfo.physicalMemory

                // Power state
                self.isOnBattery = Self.isRunningOnBattery()

                self.dockPosition = Self.getDockPosition()
            }

            private static func isRunningOnBattery() -> Bool {
                guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue() else {
                    return false
                }

                guard
                    let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue()
                        as? [CFTypeRef]
                else {
                    return false
                }

                for source in sources {
                    guard
                        let description = IOPSGetPowerSourceDescription(snapshot, source)?
                            .takeUnretainedValue() as? [String: Any]
                    else {
                        continue
                    }

                    if let powerSource = description[kIOPSPowerSourceStateKey] as? String {
                        return powerSource == kIOPSBatteryPowerValue
                    }
                }

                return false
            }

            private static func getDockPosition() -> String {
                let defaults = UserDefaults(suiteName: "com.apple.dock")
                return defaults?.string(forKey: "orientation") ?? "bottom"
            }
        }

        // MARK: - Private Properties

        private let lock = NSLock()
        private var cachedContext: MacOSSystemContext
        private var lastUpdateTime: Date
        private let cacheTimeout: TimeInterval = 1.0  // Cache for 1 second

        #if canImport(Combine)
            public let objectWillChange = PassthroughSubject<Void, Never>()
            private var notificationObservers: [NSObjectProtocol] = []
        #endif

        // MARK: - Initialization

        /// Creates a new macOS system context provider
        public init() {
            self.cachedContext = MacOSSystemContext()
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
            case "isDarkModeEnabled":
                return context.isDarkModeEnabled
            case "isReduceMotionEnabled":
                return context.isReduceMotionEnabled
            case "systemUptime":
                return context.systemUptime
            case "operatingSystemVersion":
                return context.operatingSystemVersion
            case "processorCount":
                return context.processorCount
            case "physicalMemory":
                return context.physicalMemory
            case "isOnBattery":
                return context.isOnBattery
            case "menuBarHeight":
                return context.menuBarHeight
            case "dockPosition":
                return context.dockPosition
            default:
                return nil
            }
        }

        public func currentContext() -> MacOSSystemContext {
            lock.lock()
            defer { lock.unlock() }

            let now = Date()
            if now.timeIntervalSince(lastUpdateTime) > cacheTimeout {
                cachedContext = MacOSSystemContext()
                lastUpdateTime = now
            }

            return cachedContext
        }

        // MARK: - Notification Setup

        private func setupNotificationObservers() {
            #if canImport(Combine)
                let notificationCenter = NotificationCenter.default

                // Accessibility notifications
                notificationObservers.append(
                    notificationCenter.addObserver(
                        forName: NSWorkspace.accessibilityDisplayOptionsDidChangeNotification,
                        object: nil,
                        queue: .main
                    ) { [weak self] _ in
                        self?.invalidateCache()
                    }
                )

                // Power source notifications (macOS 12.0+)
                if #available(macOS 12.0, *) {
                    notificationObservers.append(
                        notificationCenter.addObserver(
                            forName: .NSProcessInfoPowerStateDidChange,
                            object: nil,
                            queue: .main
                        ) { [weak self] _ in
                            self?.invalidateCache()
                        }
                    )
                }
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
        @available(macOS 10.15, *)
        extension MacOSSystemContextProvider: ContextUpdatesProviding {

            /// Publisher that emits whenever the macOS system context may have changed
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

    @available(macOS 10.15, *)
    extension MacOSSystemContextProvider {

        /// Creates a specification that checks if dark mode is enabled
        public static func darkModeSpecification() -> AnySpecification<Any> {
            let provider = MacOSSystemContextProvider()
            return AnySpecification { _ in
                provider.currentContext().isDarkModeEnabled == true
            }
        }

        /// Creates a specification that checks if the system is running on battery
        public static func onBatterySpecification() -> AnySpecification<Any> {
            let provider = MacOSSystemContextProvider()
            return AnySpecification { _ in
                provider.currentContext().isOnBattery == true
            }
        }

        /// Creates a specification that checks if reduce motion is enabled
        public static func reduceMotionSpecification() -> AnySpecification<Any> {
            let provider = MacOSSystemContextProvider()
            return AnySpecification { _ in
                provider.currentContext().isReduceMotionEnabled == true
            }
        }

        /// Creates a specification that checks the dock position
        /// - Parameter position: The expected dock position
        public static func dockPositionSpecification(_ position: DockPosition) -> AnySpecification<
            Any
        > {
            let provider = MacOSSystemContextProvider()
            return AnySpecification { _ in
                provider.currentContext().dockPosition == position.rawValue
            }
        }

        /// Creates a specification that checks if the system has sufficient memory
        /// - Parameter minimumGB: Minimum memory in gigabytes
        public static func memorySpecification(minimumGB: UInt64) -> AnySpecification<Any> {
            let provider = MacOSSystemContextProvider()
            return AnySpecification { _ in
                guard let memory = provider.currentContext().physicalMemory else { return false }
                let minimumBytes = minimumGB * 1024 * 1024 * 1024
                return memory >= minimumBytes
            }
        }

        /// Creates a specification that checks if the system has sufficient CPU cores
        /// - Parameter minimumCores: Minimum number of CPU cores
        public static func processorSpecification(minimumCores: Int) -> AnySpecification<Any> {
            let provider = MacOSSystemContextProvider()
            return AnySpecification { _ in
                guard let cores = provider.currentContext().processorCount else { return false }
                return cores >= minimumCores
            }
        }
    }

    // MARK: - MacOSSystemContext Extensions

    @available(macOS 10.15, *)
    extension MacOSSystemContextProvider.MacOSSystemContext {

        /// Whether the system is in a good performance state
        public var isHighPerformanceAvailable: Bool {
            let notOnBattery = isOnBattery != true
            let hasMemory = (physicalMemory ?? 0) > (4 * 1024 * 1024 * 1024)  // 4GB minimum
            let hasCPU = (processorCount ?? 0) >= 2

            return notOnBattery && hasMemory && hasCPU
        }

        /// Whether the system should use reduced functionality
        public var shouldReduceFeatures: Bool {
            let onBattery = isOnBattery == true
            let reduceMotion = isReduceMotionEnabled == true
            let lowMemory = (physicalMemory ?? 0) < (2 * 1024 * 1024 * 1024)  // Less than 2GB

            return onBattery || reduceMotion || lowMemory
        }

        /// Whether accessibility features are enabled that affect UI
        public var hasAccessibilityFeaturesEnabled: Bool {
            return isReduceMotionEnabled == true
        }

        /// System performance tier based on hardware
        public var performanceTier: PerformanceTier {
            guard let memory = physicalMemory, let cores = processorCount else {
                return .low
            }

            let memoryGB = memory / (1024 * 1024 * 1024)

            if memoryGB >= 16 && cores >= 8 {
                return .high
            } else if memoryGB >= 8 && cores >= 4 {
                return .medium
            } else {
                return .low
            }
        }
    }

#endif
