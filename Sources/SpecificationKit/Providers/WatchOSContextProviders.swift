//
//  WatchOSContextProviders.swift
//  SpecificationKit
//
//  Created by SpecificationKit on 2025.
//

import Foundation

#if canImport(WatchKit) && os(watchOS)
    import WatchKit
#endif

#if canImport(HealthKit) && os(watchOS)
    import HealthKit
#endif

#if canImport(Combine)
    import Combine
#endif

/// A context provider that offers access to HealthKit data on watchOS.
///
/// `HealthContextProvider` provides a comprehensive interface for accessing health and fitness
/// data through HealthKit on watchOS devices. It handles permission requests, data queries,
/// and provides real-time health metrics that can be used in specifications.
///
/// ## Key Features
///
/// - **Automatic Permission Handling**: Requests necessary HealthKit permissions
/// - **Real-Time Metrics**: Provides current heart rate, step count, and activity data
/// - **Async Support**: All health queries use async/await for clean integration
/// - **Privacy Compliant**: Respects HealthKit privacy guidelines and user consent
/// - **Performance Optimized**: Efficient queries with minimal battery impact
///
/// ## Usage Examples
///
/// ### Basic Health Data Access
/// ```swift
/// let healthProvider = HealthContextProvider()
///
/// // Use in specifications
/// let heartRateSpec = PredicateSpec<HealthContext> { context in
///     guard let heartRate = context.currentHeartRate else { return false }
///     return heartRate > 100 // Elevated heart rate
/// }
///
/// @Satisfies(using: heartRateSpec, context: healthProvider)
/// var hasElevatedHeartRate: Bool
/// ```
///
/// ### Activity-Based Specifications
/// ```swift
/// let activitySpec = PredicateSpec<HealthContext> { context in
///     guard let steps = context.todayStepCount else { return false }
///     return steps >= 10000 // Daily step goal
/// }
///
/// @Satisfies(using: activitySpec, context: healthProvider)
/// var hasMetStepGoal: Bool
/// ```
///
/// ### Workout Detection
/// ```swift
/// let workoutSpec = PredicateSpec<HealthContext> { context in
///     guard let lastWorkout = context.lastWorkout else { return false }
///     let timeSinceWorkout = Date().timeIntervalSince(lastWorkout)
///     return timeSinceWorkout < 3600 // Within last hour
/// }
/// ```
#if canImport(HealthKit) && os(watchOS)
    @available(watchOS 6.0, *)
    public final class HealthContextProvider: NSObject, ContextProviding {

        /// Configuration options for health data collection
        public struct Configuration {
            /// The health data types to request read access for
            let readTypes: Set<HKObjectType>
            /// Whether to request permissions automatically on initialization
            let requestPermissionsOnInit: Bool
            /// Fallback values to use when health data is unavailable
            let fallbackValues: [String: Any]

            /// Default configuration with common health metrics
            public static let `default` = Configuration(
                readTypes: [
                    HKObjectType.quantityType(forIdentifier: .heartRate)!,
                    HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
                    HKObjectType.quantityType(forIdentifier: .stepCount)!,
                    HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
                    HKObjectType.workoutType(),
                ],
                requestPermissionsOnInit: true,
                fallbackValues: [:]
            )

            /// Configuration for fitness tracking focus
            public static let fitness = Configuration(
                readTypes: [
                    HKObjectType.quantityType(forIdentifier: .stepCount)!,
                    HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
                    HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
                    HKObjectType.workoutType(),
                ],
                requestPermissionsOnInit: true,
                fallbackValues: [
                    "todayStepCount": 0.0,
                    "activeCalories": 0.0,
                ]
            )

            /// Configuration for heart rate monitoring
            public static let heartRate = Configuration(
                readTypes: [
                    HKObjectType.quantityType(forIdentifier: .heartRate)!,
                    HKObjectType.quantityType(forIdentifier: .restingHeartRate)!,
                    HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
                ],
                requestPermissionsOnInit: true,
                fallbackValues: [
                    "currentHeartRate": 75.0,
                    "restingHeartRate": 60.0,
                ]
            )
        }

        private let configuration: Configuration
        private let healthStore = HKHealthStore()
        private var isAuthorized = false
        private var cachedValues: [String: Any] = [:]
        private let cacheQueue = DispatchQueue(label: "health-context-cache", qos: .utility)

        /// Initialize with custom configuration
        /// - Parameter configuration: The configuration to use
        public init(configuration: Configuration = .default) {
            self.configuration = configuration
            super.init()

            if configuration.requestPermissionsOnInit {
                Task {
                    await requestHealthAuthorization()
                }
            }
        }

        /// Requests authorization for health data access
        /// - Returns: Whether authorization was granted
        @discardableResult
        public func requestHealthAuthorization() async -> Bool {
            return await withCheckedContinuation { continuation in
                healthStore.requestAuthorization(toShare: [], read: configuration.readTypes) {
                    [weak self] success, error in
                    self?.isAuthorized = success && error == nil
                    continuation.resume(returning: self?.isAuthorized ?? false)
                }
            }
        }

        public func currentContext() -> [String: Any] {
            var context: [String: Any] = [:]

            // Add cached values
            cacheQueue.sync {
                context.merge(cachedValues) { _, new in new }
            }

            // Add fallback values for missing keys
            for (key, value) in configuration.fallbackValues {
                if context[key] == nil {
                    context[key] = value
                }
            }

            // Add authorization status
            context["isHealthKitAuthorized"] = isAuthorized
            context["healthKitAvailable"] = HKHealthStore.isHealthDataAvailable()

            return context
        }

        public func getValue(for key: String) -> Any? {
            // Check cache first
            if let cachedValue = cacheQueue.sync(execute: { cachedValues[key] }) {
                return cachedValue
            }

            // Return fallback value if available
            if let fallback = configuration.fallbackValues[key] {
                return fallback
            }

            // For non-async context, return nil and trigger async update
            Task {
                _ = await getAsyncValue(for: key)
            }

            return nil
        }

        /// Async version of getValue for real-time health data
        /// - Parameter key: The health data key to retrieve
        /// - Returns: The health data value or nil if unavailable
        public func getAsyncValue(for key: String) async -> Any? {
            guard isAuthorized else {
                return configuration.fallbackValues[key]
            }

            let value: Any?

            switch key {
            case "currentHeartRate":
                value = await getCurrentHeartRate()
            case "restingHeartRate":
                value = await getRestingHeartRate()
            case "todayStepCount":
                value = await getTodayStepCount()
            case "activeCalories":
                value = await getActiveCalories()
            case "lastWorkout":
                value = await getLastWorkout()
            case "sleepHours":
                value = await getSleepHours()
            case "weeklyStepAverage":
                value = await getWeeklyStepAverage()
            case "heartRateVariability":
                value = await getHeartRateVariability()
            default:
                value = configuration.fallbackValues[key]
            }

            // Cache the result
            if let value = value {
                cacheQueue.async {
                    self.cachedValues[key] = value
                }
            }

            return value
        }

        // MARK: - Health Data Queries

        private func getCurrentHeartRate() async -> Double? {
            return await withCheckedContinuation { continuation in
                let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
                let sortDescriptor = NSSortDescriptor(
                    key: HKSampleSortIdentifierEndDate, ascending: false)
                let query = HKSampleQuery(
                    sampleType: heartRateType,
                    predicate: nil,
                    limit: 1,
                    sortDescriptors: [sortDescriptor]
                ) { _, samples, error in
                    guard let sample = samples?.first as? HKQuantitySample, error == nil else {
                        continuation.resume(returning: nil)
                        return
                    }

                    let heartRate = sample.quantity.doubleValue(
                        for: HKUnit.count().unitDivided(by: HKUnit.minute()))
                    continuation.resume(returning: heartRate)
                }

                healthStore.execute(query)
            }
        }

        private func getRestingHeartRate() async -> Double? {
            return await withCheckedContinuation { continuation in
                let restingHeartRateType = HKQuantityType.quantityType(
                    forIdentifier: .restingHeartRate)!
                let sortDescriptor = NSSortDescriptor(
                    key: HKSampleSortIdentifierEndDate, ascending: false)
                let query = HKSampleQuery(
                    sampleType: restingHeartRateType,
                    predicate: nil,
                    limit: 1,
                    sortDescriptors: [sortDescriptor]
                ) { _, samples, error in
                    guard let sample = samples?.first as? HKQuantitySample, error == nil else {
                        continuation.resume(returning: nil)
                        return
                    }

                    let restingHeartRate = sample.quantity.doubleValue(
                        for: HKUnit.count().unitDivided(by: HKUnit.minute()))
                    continuation.resume(returning: restingHeartRate)
                }

                healthStore.execute(query)
            }
        }

        private func getTodayStepCount() async -> Double? {
            return await withCheckedContinuation { continuation in
                let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
                let calendar = Calendar.current
                let now = Date()
                let startOfDay = calendar.startOfDay(for: now)

                let predicate = HKQuery.predicateForSamples(
                    withStart: startOfDay, end: now, options: .strictStartDate)

                let query = HKStatisticsQuery(
                    quantityType: stepType,
                    quantitySamplePredicate: predicate,
                    options: .cumulativeSum
                ) { _, result, error in
                    guard let result = result, let sum = result.sumQuantity(), error == nil else {
                        continuation.resume(returning: nil)
                        return
                    }

                    let steps = sum.doubleValue(for: HKUnit.count())
                    continuation.resume(returning: steps)
                }

                healthStore.execute(query)
            }
        }

        private func getActiveCalories() async -> Double? {
            return await withCheckedContinuation { continuation in
                let activeEnergyType = HKQuantityType.quantityType(
                    forIdentifier: .activeEnergyBurned)!
                let calendar = Calendar.current
                let now = Date()
                let startOfDay = calendar.startOfDay(for: now)

                let predicate = HKQuery.predicateForSamples(
                    withStart: startOfDay, end: now, options: .strictStartDate)

                let query = HKStatisticsQuery(
                    quantityType: activeEnergyType,
                    quantitySamplePredicate: predicate,
                    options: .cumulativeSum
                ) { _, result, error in
                    guard let result = result, let sum = result.sumQuantity(), error == nil else {
                        continuation.resume(returning: nil)
                        return
                    }

                    let calories = sum.doubleValue(for: HKUnit.kilocalorie())
                    continuation.resume(returning: calories)
                }

                healthStore.execute(query)
            }
        }

        private func getLastWorkout() async -> Date? {
            return await withCheckedContinuation { continuation in
                let workoutType = HKWorkoutType.workoutType()
                let sortDescriptor = NSSortDescriptor(
                    key: HKSampleSortIdentifierEndDate, ascending: false)
                let query = HKSampleQuery(
                    sampleType: workoutType,
                    predicate: nil,
                    limit: 1,
                    sortDescriptors: [sortDescriptor]
                ) { _, samples, error in
                    guard let workout = samples?.first as? HKWorkout, error == nil else {
                        continuation.resume(returning: nil)
                        return
                    }

                    continuation.resume(returning: workout.endDate)
                }

                healthStore.execute(query)
            }
        }

        private func getSleepHours() async -> Double? {
            return await withCheckedContinuation { continuation in
                let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)!
                let calendar = Calendar.current
                let now = Date()
                let startOfYesterday = calendar.startOfDay(
                    for: calendar.date(byAdding: .day, value: -1, to: now)!)

                let predicate = HKQuery.predicateForSamples(
                    withStart: startOfYesterday, end: now, options: .strictStartDate)

                let query = HKSampleQuery(
                    sampleType: sleepType,
                    predicate: predicate,
                    limit: HKObjectQueryNoLimit,
                    sortDescriptors: nil
                ) { _, samples, error in
                    guard let samples = samples as? [HKCategorySample], error == nil else {
                        continuation.resume(returning: nil)
                        return
                    }

                    let sleepSamples = samples.filter {
                        $0.value == HKCategoryValueSleepAnalysis.asleep.rawValue
                    }
                    let totalSleepTime = sleepSamples.reduce(0) {
                        $0 + $1.endDate.timeIntervalSince($1.startDate)
                    }
                    let sleepHours = totalSleepTime / 3600.0

                    continuation.resume(returning: sleepHours)
                }

                healthStore.execute(query)
            }
        }

        private func getWeeklyStepAverage() async -> Double? {
            return await withCheckedContinuation { continuation in
                let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
                let calendar = Calendar.current
                let now = Date()
                let weekAgo = calendar.date(byAdding: .day, value: -7, to: now)!

                let predicate = HKQuery.predicateForSamples(
                    withStart: weekAgo, end: now, options: .strictStartDate)

                let query = HKStatisticsCollectionQuery(
                    quantityType: stepType,
                    quantitySamplePredicate: predicate,
                    options: .cumulativeSum,
                    anchorDate: weekAgo,
                    intervalComponents: DateComponents(day: 1)
                )

                query.initialResultsHandler = { _, results, error in
                    guard let results = results, error == nil else {
                        continuation.resume(returning: nil)
                        return
                    }

                    var totalSteps: Double = 0
                    var daysWithData = 0

                    results.enumerateStatistics(from: weekAgo, to: now) { statistics, _ in
                        if let sum = statistics.sumQuantity() {
                            totalSteps += sum.doubleValue(for: HKUnit.count())
                            daysWithData += 1
                        }
                    }

                    let average = daysWithData > 0 ? totalSteps / Double(daysWithData) : 0
                    continuation.resume(returning: average)
                }

                healthStore.execute(query)
            }
        }

        private func getHeartRateVariability() async -> Double? {
            return await withCheckedContinuation { continuation in
                let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
                let sortDescriptor = NSSortDescriptor(
                    key: HKSampleSortIdentifierEndDate, ascending: false)
                let query = HKSampleQuery(
                    sampleType: hrvType,
                    predicate: nil,
                    limit: 1,
                    sortDescriptors: [sortDescriptor]
                ) { _, samples, error in
                    guard let sample = samples?.first as? HKQuantitySample, error == nil else {
                        continuation.resume(returning: nil)
                        return
                    }

                    let hrv = sample.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli))
                    continuation.resume(returning: hrv)
                }

                healthStore.execute(query)
            }
        }

        // MARK: - Cache Management

        /// Clears all cached health data
        public func clearCache() {
            cacheQueue.async {
                self.cachedValues.removeAll()
            }
        }

        /// Refreshes all cached health data
        public func refreshCache() async {
            clearCache()

            // Pre-populate cache with common values
            let keys = ["currentHeartRate", "todayStepCount", "activeCalories"]
            for key in keys {
                _ = await getAsyncValue(for: key)
            }
        }
    }
#endif

/// A context provider that offers access to WatchKit device information on watchOS.
///
/// `WatchContextProvider` provides comprehensive device information specific to Apple Watch,
/// including hardware details, user preferences, and device state that can be used in
/// specifications for watchOS applications.
///
/// ## Key Features
///
/// - **Device Information**: Model, name, system version, and hardware details
/// - **User Preferences**: Crown orientation, wrist location, and accessibility settings
/// - **Device State**: Water lock status, screen properties, and system capabilities
/// - **Real-Time Updates**: Current device state and user configuration
///
/// ## Usage Examples
///
/// ### Device Capability Checking
/// ```swift
/// let watchProvider = WatchContextProvider()
///
/// let crownSpec = PredicateSpec<WatchContext> { context in
///     return context.crownOrientation == .right // Right crown orientation
/// }
///
/// @Satisfies(using: crownSpec, context: watchProvider)
/// var hasRightCrown: Bool
/// ```
///
/// ### Screen Size Adaptation
/// ```swift
/// let screenSpec = PredicateSpec<WatchContext> { context in
///     guard let bounds = context.screenBounds else { return false }
///     return bounds.width >= 44.0 // Large screen watch
/// }
///
/// @Satisfies(using: screenSpec, context: watchProvider)
/// var hasLargeScreen: Bool
/// ```
#if canImport(WatchKit) && os(watchOS)
    @available(watchOS 6.0, *)
    public final class WatchContextProvider: ContextProviding {

        private let device = WKInterfaceDevice.current()

        public init() {}

        public func currentContext() -> [String: Any] {
            var context: [String: Any] = [:]

            // Add all device information
            context["watchModel"] = device.model
            context["watchName"] = device.name
            context["systemVersion"] = device.systemVersion
            context["screenScale"] = device.screenScale
            context["screenBounds"] = device.screenBounds
            context["crownOrientation"] = device.crownOrientation.rawValue
            context["wristLocation"] = device.wristLocation.rawValue
            context["isWaterLockEnabled"] = device.isWaterLockEnabled
            context["systemName"] = "watchOS"
            context["deviceIdentifier"] = device.name
            context["supportsHaptics"] = true
            context["screenWidth"] = device.screenBounds.width
            context["screenHeight"] = device.screenBounds.height
            context["isLargeScreen"] = device.screenBounds.width >= 44.0
            context["isSmallScreen"] = device.screenBounds.width < 40.0

            return context
        }

        public func getValue(for key: String) -> Any? {
            switch key {
            case "watchModel":
                return device.model
            case "watchName":
                return device.name
            case "systemVersion":
                return device.systemVersion
            case "screenScale":
                return device.screenScale
            case "screenBounds":
                return device.screenBounds
            case "crownOrientation":
                return device.crownOrientation.rawValue
            case "wristLocation":
                return device.wristLocation.rawValue
            case "isWaterLockEnabled":
                return device.isWaterLockEnabled
            case "systemName":
                return "watchOS"
            case "deviceIdentifier":
                return device.name  // Best available identifier
            case "supportsHaptics":
                return true  // All Apple Watches support haptic feedback
            case "screenWidth":
                return device.screenBounds.width
            case "screenHeight":
                return device.screenBounds.height
            case "isLargeScreen":
                return device.screenBounds.width >= 44.0
            case "isSmallScreen":
                return device.screenBounds.width < 40.0
            default:
                return nil
            }
        }

        /// Creates a specification for checking crown orientation
        /// - Parameter orientation: The expected crown orientation
        /// - Returns: A specification that checks crown orientation
        public static func crownOrientationSpec(_ orientation: WKCrownOrientation)
            -> AnySpecification<Any>
        {
            return AnySpecification { context in
                let provider = WatchContextProvider()
                guard let currentOrientation = provider.getValue(for: "crownOrientation") as? Int
                else { return false }
                return currentOrientation == orientation.rawValue
            }
        }

        /// Creates a specification for checking wrist location
        /// - Parameter location: The expected wrist location
        /// - Returns: A specification that checks wrist location
        public static func wristLocationSpec(_ location: WKWristLocation) -> AnySpecification<Any> {
            return AnySpecification { context in
                let provider = WatchContextProvider()
                guard let currentLocation = provider.getValue(for: "wristLocation") as? Int else {
                    return false
                }
                return currentLocation == location.rawValue
            }
        }

        /// Creates a specification for checking screen size category
        /// - Parameter sizeCategory: The minimum screen size category
        /// - Returns: A specification that checks screen size
        public static func screenSizeSpec(_ sizeCategory: WatchScreenSize) -> AnySpecification<Any>
        {
            return AnySpecification { context in
                let provider = WatchContextProvider()
                guard let bounds = provider.getValue(for: "screenBounds") as? CGRect else {
                    return false
                }

                switch sizeCategory {
                case .small:
                    return bounds.width >= 38.0
                case .medium:
                    return bounds.width >= 40.0
                case .large:
                    return bounds.width >= 44.0
                case .extraLarge:
                    return bounds.width >= 45.0
                }
            }
        }

        /// Creates a specification for water lock status
        /// - Parameter isEnabled: Whether water lock should be enabled
        /// - Returns: A specification that checks water lock status
        public static func waterLockSpec(isEnabled: Bool) -> AnySpecification<Any> {
            return AnySpecification { context in
                let provider = WatchContextProvider()
                guard let waterLockEnabled = provider.getValue(for: "isWaterLockEnabled") as? Bool
                else { return false }
                return waterLockEnabled == isEnabled
            }
        }
    }

    /// Watch screen size categories for specifications
    public enum WatchScreenSize {
        case small  // 38mm and similar
        case medium  // 40mm and similar
        case large  // 44mm and similar
        case extraLarge  // 45mm and larger
    }
#endif

// MARK: - Stub Types for Cross-Platform Compilation

#if !os(watchOS)
    /// Stub for HealthContextProvider on non-watchOS platforms
    public final class HealthContextProvider: ContextProviding {
        public struct Configuration {
            public static let `default` = Configuration()
            public static let fitness = Configuration()
            public static let heartRate = Configuration()
        }

        public init(configuration: Configuration = .default) {}

        public func currentContext() -> [String: Any] {
            return [
                "isHealthKitAuthorized": false,
                "healthKitAvailable": false,
            ]
        }

        public func getValue(for key: String) -> Any? {
            return nil
        }

        public func getAsyncValue(for key: String) async -> Any? {
            return nil
        }

        @discardableResult
        public func requestHealthAuthorization() async -> Bool {
            return false
        }

        public func clearCache() {}
        public func refreshCache() async {}
    }

    /// Stub for WatchContextProvider on non-watchOS platforms
    public final class WatchContextProvider: ContextProviding {
        public init() {}

        public func currentContext() -> [String: Any] {
            return [
                "systemName": "Non-watchOS",
                "supportsHaptics": false,
                "isLargeScreen": false,
                "isSmallScreen": false,
            ]
        }

        public func getValue(for key: String) -> Any? {
            return nil
        }

        public static func crownOrientationSpec(_ orientation: Int) -> AnySpecification<Any> {
            return AnySpecification { _ in false }
        }

        public static func wristLocationSpec(_ location: Int) -> AnySpecification<Any> {
            return AnySpecification { _ in false }
        }

        public static func screenSizeSpec(_ sizeCategory: WatchScreenSize) -> AnySpecification<Any>
        {
            return AnySpecification { _ in false }
        }

        public static func waterLockSpec(isEnabled: Bool) -> AnySpecification<Any> {
            return AnySpecification { _ in false }
        }
    }

    /// Watch screen size categories (stub for non-watchOS)
    public enum WatchScreenSize {
        case small, medium, large, extraLarge
    }
#endif
