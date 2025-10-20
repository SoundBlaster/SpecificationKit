# Platform-Specific Context Providers

Build context-aware applications with platform-native APIs.

## Overview

SpecificationKit v3.0.0 introduces platform-specific context providers that leverage native iOS, macOS, watchOS, and tvOS APIs to create powerful context-aware specifications. These providers offer seamless integration with device capabilities while maintaining cross-platform compatibility through graceful fallbacks.

## Getting Started

### iOS Device Integration

Use `DeviceContextProvider` to access device state, battery information, and system settings:

```swift
import SpecificationKit

@available(iOS 13.0, *)
let deviceProvider = DeviceContextProvider()

// Battery-aware features
@Satisfies(provider: deviceProvider, using: DeviceContextProvider.lowBatterySpecification(threshold: 0.2))
var shouldReduceFeatures: Bool

// Dark mode detection
@Satisfies(provider: deviceProvider, using: DeviceContextProvider.darkModeSpecification())
var isDarkModeEnabled: Bool

// Device type detection
struct iPadOnlyFeature: Specification {
    func isSatisfiedBy(_ context: DeviceContextProvider.DeviceContext) -> Bool {
        return context.isiPad
    }
}
```

### Location Services Integration

Use `LocationContextProvider` for location-based specifications:

```swift
@available(iOS 14.0, watchOS 7.0, *)
let locationProvider = LocationContextProvider(
    configuration: .batteryOptimized // Optimized for battery life
)

// Proximity-based features
let storeProximitySpec = locationProvider.proximitySpecification(
    center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
    maxDistance: 1000 // 1km radius
)

@Satisfies(provider: locationProvider, using: storeProximitySpec)
var isNearStore: Bool
```

### macOS System Integration

Use `MacOSSystemContextProvider` for macOS-specific system state:

```swift
@available(macOS 10.15, *)
let systemProvider = MacOSSystemContextProvider()

// Dark mode detection
@Satisfies(provider: systemProvider, using: MacOSSystemContextProvider.darkModeSpecification())
var isDarkModeEnabled: Bool

// Battery state (MacBooks)
@Satisfies(provider: systemProvider, using: MacOSSystemContextProvider.onBatterySpecification())
var isOnBattery: Bool

// Performance tier detection
let context = systemProvider.currentContext()
switch context.performanceTier {
case .high: enableAdvancedFeatures()
case .medium: enableStandardFeatures()
case .low: enableBasicFeatures()
}
```

### Cross-Platform Compatibility

Use `PlatformContextProviders` factory for cross-platform applications:

```swift
// Works on all platforms with graceful fallbacks
let darkModeSpec = PlatformContextProviders.createDeviceCapabilitySpec(.darkMode)
let locationSpec = PlatformContextProviders.createDeviceCapabilitySpec(.location)
let batterySpec = PlatformContextProviders.createBatterySpec(threshold: 0.3)

// macOS-specific specifications
let macOSMemorySpec = PlatformContextProviders.createMacOSSystemSpec(.highMemory(minimumGB: 8))
let macOSDockSpec = PlatformContextProviders.createMacOSDockSpec(.bottom)

@Satisfies(using: darkModeSpec)
var supportsDarkMode: Bool // false on unsupported platforms

@Satisfies(using: batterySpec)
var isLowBattery: Bool // false on platforms without battery APIs

@Satisfies(using: macOSMemorySpec)
var hasEnoughMemory: Bool // false on non-macOS platforms
```

## Privacy and Permissions

Platform providers handle privacy requirements automatically:

```swift
// Check permissions before using features
if PlatformContextProviders.hasLocationPermission {
    // Safe to use location-based features
}

// Request permissions asynchronously
let granted = await PlatformContextProviders.requestLocationPermission()
if granted {
    // Permission granted, start location updates
}

// Capability detection
if PlatformContextProviders.supportsLocation {
    // Platform supports location services
}
```

## Configuration Options

### Device Provider Configuration

The `DeviceContextProvider` automatically monitors system notifications for optimal performance:

- **Battery State**: Monitors battery level and charging state changes
- **Thermal State**: Tracks device thermal conditions
- **Accessibility**: Observes VoiceOver and reduce motion settings
- **System UI**: Monitors dark mode and content size changes

### Location Provider Configuration

Configure `LocationContextProvider` for your use case:

```swift
// High precision for navigation apps
let navigationConfig = LocationContextProvider.Configuration.highPrecision

// Battery optimized for background features
let backgroundConfig = LocationContextProvider.Configuration.batteryOptimized

// Privacy-focused with reduced accuracy (iOS 14+)
let privacyConfig = LocationContextProvider.Configuration.privacyFocused

// Custom configuration
let customConfig = LocationContextProvider.Configuration(
    accuracy: kCLLocationAccuracyNearestTenMeters,
    distanceFilter: 50.0,
    requestPermission: false, // Handle permissions manually
    fallbackLocation: CLLocation(latitude: 0, longitude: 0)
)
```

## Performance

All platform providers are optimized for performance:

- **<1ms Evaluation**: Specifications evaluate in under 1 millisecond
- **Smart Caching**: Context data is cached efficiently with appropriate TTL
- **Thread Safety**: All operations are thread-safe for concurrent access
- **Battery Efficient**: Location services use optimized settings
- **Memory Efficient**: Minimal memory overhead with lazy initialization

## Platform Support

| Platform | Device Info | Location | Battery | Health | System Prefs |
|----------|-------------|----------|---------|--------|--------------|
| iOS      | ✅          | ✅       | ✅      | ✅     | ❌           |
| iPadOS   | ✅          | ✅       | ✅      | ❌     | ❌           |
| watchOS  | ✅          | ✅       | ✅      | ✅     | ❌           |
| tvOS     | ✅          | ❌       | ❌      | ❌     | ❌           |
| macOS    | ❌          | ❌       | ✅      | ❌     | ✅           |

## Best Practices

### Privacy Compliance

1. **Request Minimal Permissions**: Only request permissions you actually need
2. **Provide Fallbacks**: Always provide graceful fallbacks when permissions are denied
3. **Respect User Choice**: Don't repeatedly request denied permissions
4. **Use Appropriate Accuracy**: Choose the lowest accuracy level that meets your needs

### Performance Optimization

1. **Use Factory Methods**: Use `PlatformContextProviders` for cross-platform compatibility
2. **Configure Appropriately**: Choose the right configuration for your use case
3. **Cache Results**: Use `@CachedSatisfies` for expensive evaluations
4. **Stop When Not Needed**: Stop location updates when features are not active

### Error Handling

```swift
// Handle capability limitations gracefully
let locationSpec = PlatformContextProviders.createLocationProximitySpec(
    center: targetLocation,
    radius: 1000
)

// This will return false on platforms without location support
@Satisfies(using: locationSpec)
var isNearTarget: Bool

// Show appropriate UI based on capability
if PlatformContextProviders.supportsLocation {
    // Show location-based features
} else {
    // Show alternative features
}
```

## See Also

- ``DeviceContextProvider``
- ``LocationContextProvider``
- ``PlatformContextProviders``
- ``ReactiveWrappers``