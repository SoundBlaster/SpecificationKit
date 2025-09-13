# Platform Integration Specialist Tasks

## Agent Profile
- **Primary Skills**: iOS/macOS/watchOS/tvOS APIs, platform-specific patterns, privacy compliance
- **Secondary Skills**: CloudKit, Core Location, HealthKit, system frameworks integration
- **Complexity Level**: Medium-High (3-4/5)

## Task Overview

### Platform-Specific Features & Context Providers
**Objective**: Implement platform-specific context providers and integrations
**Priority**: Medium
**Dependencies**: Context provider infrastructure
**Timeline**: 12 days total

---

## 5.1: iOS-Specific Context Providers

### Timeline: 4 days

#### LocationContextProvider Implementation
```swift
import CoreLocation
import Combine

@available(iOS 14.0, *)
public final class LocationContextProvider: NSObject, ContextProviding {
    public struct Configuration {
        let accuracy: CLLocationAccuracy
        let distanceFilter: CLLocationDistance
        let requestPermission: Bool
        let fallbackLocation: CLLocation?
        
        public static let `default` = Configuration(
            accuracy: kCLLocationAccuracyBest,
            distanceFilter: 10.0, // 10 meters
            requestPermission: true,
            fallbackLocation: nil
        )
    }
    
    private let configuration: Configuration
    private let locationManager: CLLocationManager
    private var currentLocation: CLLocation?
    private let locationSubject = CurrentValueSubject<CLLocation?, Never>(nil)
    
    public init(configuration: Configuration = .default) {
        self.configuration = configuration
        self.locationManager = CLLocationManager()
        
        super.init()
        
        setupLocationManager()
        
        if configuration.requestPermission {
            requestLocationPermission()
        }
    }
    
    public func getValue(for key: String) -> Any? {
        switch key {
        case "currentLocation":
            return currentLocation
        case "latitude":
            return currentLocation?.coordinate.latitude
        case "longitude":
            return currentLocation?.coordinate.longitude
        case "accuracy":
            return currentLocation?.horizontalAccuracy
        case "timestamp":
            return currentLocation?.timestamp
        case "altitude":
            return currentLocation?.altitude
        case "speed":
            return currentLocation?.speed
        case "course":
            return currentLocation?.course
        default:
            return nil
        }
    }
    
    public var contextChanges: AnyPublisher<String, Never> {
        locationSubject
            .compactMap { $0 }
            .map { _ in "location" }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
}
```

#### Location Manager Integration
```swift
extension LocationContextProvider: CLLocationManagerDelegate {
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = configuration.accuracy
        locationManager.distanceFilter = configuration.distanceFilter
    }
    
    private func requestLocationPermission() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            // Use fallback location if available
            currentLocation = configuration.fallbackLocation
            locationSubject.send(currentLocation)
        case .authorizedWhenInUse, .authorizedAlways:
            startLocationUpdates()
        @unknown default:
            break
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        currentLocation = location
        locationSubject.send(location)
    }
    
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            startLocationUpdates()
        case .denied, .restricted:
            currentLocation = configuration.fallbackLocation
            locationSubject.send(currentLocation)
        default:
            break
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error)")
        currentLocation = configuration.fallbackLocation
        locationSubject.send(currentLocation)
    }
    
    private func startLocationUpdates() {
        guard CLLocationManager.locationServicesEnabled() else { return }
        locationManager.startUpdatingLocation()
    }
    
    public func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
    }
}
```

#### Device Context Provider
```swift
import UIKit

public final class DeviceContextProvider: ContextProviding {
    public func getValue(for key: String) -> Any? {
        switch key {
        case "deviceModel":
            return UIDevice.current.model
        case "systemVersion":
            return UIDevice.current.systemVersion
        case "deviceName":
            return UIDevice.current.name
        case "userInterfaceIdiom":
            return UIDevice.current.userInterfaceIdiom.rawValue
        case "batteryLevel":
            UIDevice.current.isBatteryMonitoringEnabled = true
            return UIDevice.current.batteryLevel
        case "batteryState":
            UIDevice.current.isBatteryMonitoringEnabled = true
            return UIDevice.current.batteryState.rawValue
        case "isLowPowerModeEnabled":
            return ProcessInfo.processInfo.isLowPowerModeEnabled
        case "thermalState":
            return ProcessInfo.processInfo.thermalState.rawValue
        case "screenBrightness":
            return UIScreen.main.brightness
        case "screenScale":
            return UIScreen.main.scale
        case "isVoiceOverRunning":
            return UIAccessibility.isVoiceOverRunning
        case "isDarkModeEnabled":
            if #available(iOS 13.0, *) {
                return UITraitCollection.current.userInterfaceStyle == .dark
            }
            return false
        default:
            return nil
        }
    }
}
```

---

## 5.2: macOS-Specific Context Providers

### Timeline: 3 days

#### System Preferences Context Provider
```swift
#if canImport(AppKit)
import AppKit
import SystemConfiguration

@available(macOS 10.15, *)
public final class MacOSSystemContextProvider: ContextProviding {
    public func getValue(for key: String) -> Any? {
        switch key {
        case "isDarkModeEnabled":
            return NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        case "isReduceMotionEnabled":
            return NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        case "systemUptime":
            return ProcessInfo.processInfo.systemUptime
        case "operatingSystemVersion":
            let version = ProcessInfo.processInfo.operatingSystemVersion
            return "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
        case "processorCount":
            return ProcessInfo.processInfo.processorCount
        case "physicalMemory":
            return ProcessInfo.processInfo.physicalMemory
        case "isOnBattery":
            return isRunningOnBattery()
        case "menuBarHeight":
            return NSApplication.shared.mainMenu?.menuBarHeight
        case "dockPosition":
            return getDockPosition()
        default:
            return nil
        }
    }
    
    private func isRunningOnBattery() -> Bool {
        // Check if running on battery power
        let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue()
        let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef] ?? []
        
        for source in sources {
            let description = IOPSGetPowerSourceDescription(snapshot, source)?.takeUnretainedValue() as? [String: Any]
            if let powerSource = description?[kIOPSPowerSourceStateKey] as? String {
                return powerSource == kIOPSBatteryPowerValue
            }
        }
        return false
    }
    
    private func getDockPosition() -> String {
        let defaults = UserDefaults(suiteName: "com.apple.dock")
        let orientation = defaults?.string(forKey: "orientation") ?? "bottom"
        return orientation
    }
}
#endif
```

---

## 5.3: watchOS-Specific Context Providers

### Timeline: 3 days

#### Health & Fitness Context Provider
```swift
#if canImport(WatchKit) && canImport(HealthKit)
import WatchKit
import HealthKit

@available(watchOS 6.0, *)
public final class HealthContextProvider: NSObject, ContextProviding {
    private let healthStore = HKHealthStore()
    private var isAuthorized = false
    
    private let readTypes: Set<HKObjectType> = [
        HKObjectType.quantityType(forIdentifier: .heartRate)!,
        HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
        HKObjectType.quantityType(forIdentifier: .stepCount)!,
        HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
    ]
    
    public override init() {
        super.init()
        requestHealthAuthorization()
    }
    
    public func getValue(for key: String) async -> Any? {
        guard isAuthorized else { return nil }
        
        switch key {
        case "currentHeartRate":
            return await getCurrentHeartRate()
        case "todayStepCount":
            return await getTodayStepCount()
        case "activeCalories":
            return await getActiveCalories()
        case "lastWorkout":
            return await getLastWorkout()
        case "sleepHours":
            return await getSleepHours()
        default:
            return nil
        }
    }
    
    private func requestHealthAuthorization() {
        healthStore.requestAuthorization(toShare: [], read: readTypes) { [weak self] success, error in
            self?.isAuthorized = success
        }
    }
    
    private func getCurrentHeartRate() async -> Double? {
        return await withCheckedContinuation { continuation in
            let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
            let query = HKSampleQuery(sampleType: heartRateType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, error in
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let heartRate = sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute()))
                continuation.resume(returning: heartRate)
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
            
            let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
            
            let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
                guard let result = result, let sum = result.sumQuantity() else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let steps = sum.doubleValue(for: HKUnit.count())
                continuation.resume(returning: steps)
            }
            
            healthStore.execute(query)
        }
    }
}

// WatchKit specific context provider
@available(watchOS 6.0, *)
public final class WatchContextProvider: ContextProviding {
    public func getValue(for key: String) -> Any? {
        switch key {
        case "watchModel":
            return WKInterfaceDevice.current().model
        case "watchName":
            return WKInterfaceDevice.current().name
        case "systemVersion":
            return WKInterfaceDevice.current().systemVersion
        case "screenScale":
            return WKInterfaceDevice.current().screenScale
        case "screenBounds":
            return WKInterfaceDevice.current().screenBounds
        case "crownOrientation":
            return WKInterfaceDevice.current().crownOrientation.rawValue
        case "wristLocation":
            return WKInterfaceDevice.current().wristLocation.rawValue
        case "isWaterLockEnabled":
            return WKInterfaceDevice.current().isWaterLockEnabled
        default:
            return nil
        }
    }
}
#endif
```

---

## 5.4: tvOS-Specific Context Providers

### Timeline: 2 days

#### Apple TV Context Provider
```swift
#if canImport(TVServices)
import UIKit
import TVServices

@available(tvOS 13.0, *)
public final class AppleTVContextProvider: ContextProviding {
    public func getValue(for key: String) -> Any? {
        switch key {
        case "deviceModel":
            return UIDevice.current.model
        case "systemVersion":
            return UIDevice.current.systemVersion
        case "userInterfaceIdiom":
            return UIDevice.current.userInterfaceIdiom.rawValue
        case "screenResolution":
            let screen = UIScreen.main
            return "\(screen.bounds.width)x\(screen.bounds.height)"
        case "screenScale":
            return UIScreen.main.scale
        case "isDarkModeEnabled":
            return UITraitCollection.current.userInterfaceStyle == .dark
        case "isVoiceOverRunning":
            return UIAccessibility.isVoiceOverRunning
        case "preferredContentSizeCategory":
            return UIApplication.shared.preferredContentSizeCategory.rawValue
        case "hasRemote":
            return hasAppleRemote()
        case "hasSiriRemote":
            return hasSiriRemote()
        default:
            return nil
        }
    }
    
    private func hasAppleRemote() -> Bool {
        // Check for Apple TV remote presence
        return GCController.controllers().contains { controller in
            controller.microGamepad != nil
        }
    }
    
    private func hasSiriRemote() -> Bool {
        // Check for Siri Remote capabilities
        return GCController.controllers().contains { controller in
            controller.microGamepad?.allowsRotation == true
        }
    }
}
#endif
```

---

## 5.5: Cross-Platform Integration Patterns

### Platform-Specific Specification Factory
```swift
public final class PlatformSpecificationFactory {
    public static func createLocationSpec(radius: Double, center: CLLocationCoordinate2D) -> any Specification<LocationContext> {
        #if os(iOS) || os(watchOS)
        return LocationProximitySpec(center: center, radius: radius)
        #else
        return AlwaysFalseSpec<LocationContext>()
        #endif
    }
    
    public static func createHealthSpec(metric: HealthMetric, threshold: Double) -> any Specification<HealthContext> {
        #if os(watchOS)
        return HealthThresholdSpec(metric: metric, threshold: threshold)
        #else
        return AlwaysFalseSpec<HealthContext>()
        #endif
    }
    
    public static func createDeviceCapabilitySpec(capability: DeviceCapability) -> any Specification<DeviceContext> {
        switch capability {
        case .location:
            #if os(iOS) || os(watchOS)
            return DeviceCapabilitySpec(capability: .location)
            #else
            return AlwaysFalseSpec<DeviceContext>()
            #endif
        case .healthKit:
            #if os(watchOS) || os(iOS)
            return DeviceCapabilitySpec(capability: .healthKit)
            #else
            return AlwaysFalseSpec<DeviceContext>()
            #endif
        case .darkMode:
            #if os(iOS) || os(macOS) || os(tvOS)
            return DeviceCapabilitySpec(capability: .darkMode)
            #else
            return AlwaysFalseSpec<DeviceContext>()
            #endif
        }
    }
}
```

### Privacy Compliance Framework
```swift
public final class PrivacyComplianceManager {
    public enum PermissionType {
        case location
        case health
        case camera
        case microphone
        case contacts
        case calendar
    }
    
    public static func requestPermission(for type: PermissionType) async -> Bool {
        switch type {
        case .location:
            #if os(iOS) || os(watchOS)
            return await requestLocationPermission()
            #else
            return false
            #endif
        case .health:
            #if os(watchOS) || os(iOS)
            return await requestHealthPermission()
            #else
            return false
            #endif
        default:
            return false
        }
    }
    
    #if os(iOS) || os(watchOS)
    private static func requestLocationPermission() async -> Bool {
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
    
    public static func hasPermission(for type: PermissionType) -> Bool {
        switch type {
        case .location:
            #if os(iOS) || os(watchOS)
            return CLLocationManager.locationServicesEnabled() && 
                   CLLocationManager.authorizationStatus() != .denied
            #else
            return false
            #endif
        case .health:
            #if os(watchOS) || os(iOS)
            return HKHealthStore.isHealthDataAvailable()
            #else
            return false
            #endif
        default:
            return false
        }
    }
}
```

## Implementation Guidelines

### Privacy & Security Standards
- **Permission Requests**: Always request permissions before accessing sensitive data
- **Data Minimization**: Only collect necessary data for specifications
- **Secure Storage**: Use Keychain for sensitive context data
- **User Control**: Provide clear opt-out mechanisms

### Platform-Specific Best Practices
```swift
// iOS: Respect app lifecycle and background restrictions
#if os(iOS)
extension LocationContextProvider {
    func handleAppDidEnterBackground() {
        // Reduce location accuracy to preserve battery
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
    }
    
    func handleAppWillEnterForeground() {
        // Restore full accuracy
        locationManager.desiredAccuracy = configuration.accuracy
    }
}
#endif

// watchOS: Optimize for battery and limited resources
#if os(watchOS)
extension HealthContextProvider {
    func optimizeForWatchOS() {
        // Use workout sessions for efficient health data collection
        // Minimize background processing
    }
}
#endif
```

### Testing Strategy
```swift
class PlatformIntegrationTests: XCTestCase {
    func testLocationProviderAccuracy() {
        #if os(iOS)
        // Test location provider on iOS
        #endif
    }
    
    func testHealthDataIntegration() {
        #if os(watchOS)
        // Test HealthKit integration
        #endif
    }
    
    func testPrivacyCompliance() {
        // Test permission handling across platforms
    }
}
```

## Dependencies & Coordination

### Platform-Specific Dependencies
- **iOS**: CoreLocation, UIKit, HealthKit
- **macOS**: AppKit, SystemConfiguration, IOKit
- **watchOS**: WatchKit, HealthKit, WorkoutKit
- **tvOS**: TVServices, GameController

### Coordination Points
- **Context Provider Team**: Integration with base context provider architecture
- **Privacy Team**: Ensure compliance with platform privacy guidelines
- **Testing Team**: Platform-specific testing infrastructure
- **Documentation Team**: Platform-specific usage examples

## Success Metrics
- **Platform Coverage**: Support for iOS, macOS, watchOS, tvOS key features
- **Privacy Compliance**: 100% compliance with platform privacy guidelines
- **Performance**: Efficient resource usage on constrained devices (watchOS)
- **User Experience**: Seamless permission handling and graceful degradation