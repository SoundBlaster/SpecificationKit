# macOS System Context Provider

Access macOS system state and preferences for context-aware applications.

## Overview

The `MacOSSystemContextProvider` integrates with AppKit and macOS system APIs to provide real-time system state information for specification evaluation. It monitors system preferences, power state, and system resources to enable context-aware application behavior on macOS.

## Getting Started

### Basic System Information

Access macOS system state through the provider:

```swift
import SpecificationKit

@available(macOS 10.15, *)
let systemProvider = MacOSSystemContextProvider()

// Dark mode detection
@Satisfies(provider: systemProvider, using: MacOSSystemContextProvider.darkModeSpecification())
var isDarkModeEnabled: Bool

// Battery state (for MacBooks)
@Satisfies(provider: systemProvider, using: MacOSSystemContextProvider.onBatterySpecification())
var isOnBattery: Bool

// Performance tier detection
let context = systemProvider.currentContext()
let performanceTier = context.performanceTier // .low, .medium, or .high
```

### System Specifications

Use factory methods for common system checks:

```swift
// Dark mode specification
let darkModeSpec = PlatformContextProviders.createMacOSSystemSpec(.darkMode)

// Battery state specification
let batterySpec = PlatformContextProviders.createMacOSSystemSpec(.onBattery)

// Memory requirement specification (8GB minimum)
let memorySpec = PlatformContextProviders.createMacOSSystemSpec(.highMemory(minimumGB: 8))

// CPU requirement specification (4 cores minimum)
let cpuSpec = PlatformContextProviders.createMacOSSystemSpec(.multiCore(minimumCores: 4))

// Dock position specification
let dockSpec = PlatformContextProviders.createMacOSDockSpec(.bottom)

// Performance tier specification
let performanceSpec = PlatformContextProviders.createMacOSPerformanceSpec(.medium)
```

### Cross-Platform Integration

Use the unified factory for cross-platform applications:

```swift
// Works on macOS, returns false on other platforms
let macOSFeatureSpec = PlatformContextProviders.createMacOSSystemSpec(.darkMode)

@Satisfies(using: macOSFeatureSpec)
var supportsMacOSFeatures: Bool

// Check platform capabilities
if PlatformContextProviders.supportsMacOSSystemPreferences {
    // Safe to use macOS-specific features
}
```

## Available Context Properties

The `MacOSSystemContext` provides comprehensive system information:

### UI and Appearance
- `isDarkModeEnabled: Bool?` - Whether dark mode is active
- `isReduceMotionEnabled: Bool?` - Accessibility reduce motion setting
- `menuBarHeight: CGFloat?` - Height of the menu bar in points
- `dockPosition: String?` - Current dock position ("bottom", "left", "right")

### System Information
- `systemUptime: TimeInterval?` - System uptime in seconds
- `operatingSystemVersion: String?` - macOS version (e.g., "15.1.0")
- `processorCount: Int?` - Number of CPU cores
- `physicalMemory: UInt64?` - Physical memory in bytes

### Power Management
- `isOnBattery: Bool?` - Whether running on battery power (MacBooks)

### Computed Properties
- `performanceTier: PerformanceTier` - System performance tier (.low, .medium, .high)
- `isHighPerformanceAvailable: Bool` - Whether high-performance features should be enabled
- `shouldReduceFeatures: Bool` - Whether features should be reduced due to system constraints
- `hasAccessibilityFeaturesEnabled: Bool` - Whether accessibility features affect UI

## Performance Tiers

The provider automatically categorizes system performance:

```swift
let context = systemProvider.currentContext()

switch context.performanceTier {
case .high:
    // 16GB+ RAM, 8+ cores - Enable all features
    enableAdvancedFeatures()
case .medium:
    // 8GB+ RAM, 4+ cores - Enable most features
    enableStandardFeatures()
case .low:
    // <8GB RAM or <4 cores - Basic features only
    enableBasicFeatures()
}
```

## Battery-Aware Features

For MacBooks, optimize features based on power state:

```swift
struct PowerOptimizedSpec: Specification {
    func isSatisfiedBy(_ context: MacOSSystemContext) -> Bool {
        // Reduce features when on battery
        if context.isOnBattery == true {
            return false
        }
        
        // Ensure sufficient performance
        return context.isHighPerformanceAvailable
    }
}

@Satisfies(provider: systemProvider, using: PowerOptimizedSpec())
var canRunPowerIntensiveFeatures: Bool
```

## System Health Monitoring

Monitor system health for optimal performance:

```swift
let context = systemProvider.currentContext()

// Check if system can handle intensive tasks
if context.isHighPerformanceAvailable {
    startBackgroundProcessing()
}

// Adapt to system constraints
if context.shouldReduceFeatures {
    disableAnimations()
    reduceBackgroundActivity()
}

// Adapt to accessibility settings
if context.hasAccessibilityFeaturesEnabled {
    enableAccessibilityOptimizations()
}
```

## Reactive Updates

The provider supports reactive programming with Combine:

```swift
@available(macOS 10.15, *)
final class SystemAwareViewModel: ObservableObject {
    @Published var isDarkMode = false
    @Published var isHighPerformance = false
    
    private let systemProvider = MacOSSystemContextProvider()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // React to system changes
        systemProvider.contextUpdates
            .sink { [weak self] in
                self?.updateFromSystem()
            }
            .store(in: &cancellables)
        
        updateFromSystem()
    }
    
    private func updateFromSystem() {
        let context = systemProvider.currentContext()
        isDarkMode = context.isDarkModeEnabled == true
        isHighPerformance = context.isHighPerformanceAvailable
    }
}
```

## Configuration and Caching

The provider uses intelligent caching for optimal performance:

- **Cache Duration**: 1 second TTL for system state
- **Automatic Refresh**: Updates on system notifications
- **Thread Safety**: All operations are thread-safe
- **Testing Support**: Graceful fallbacks in test environments

## Platform Capabilities

Check for macOS-specific capabilities:

```swift
// Check if running on macOS with system preferences support
if PlatformContextProviders.supportsMacOSSystemPreferences {
    // Use macOS-specific features
}

// Check for dock integration support
if PlatformContextProviders.supportsMacOSDock {
    // Use dock-related specifications
}

// Check for power management support
if PlatformContextProviders.supportsMacOSPowerManagement {
    // Use battery-aware features
}
```

## Best Practices

### Performance Optimization

1. **Cache Results**: Use `@CachedSatisfies` for expensive specifications
2. **Batch Evaluations**: Group related specifications together
3. **Monitor Resources**: Use performance tier to adapt feature complexity
4. **Respect Constraints**: Reduce features when `shouldReduceFeatures` is true

### Power Efficiency

1. **Battery Awareness**: Reduce background activity when on battery
2. **Performance Adaptation**: Scale features based on performance tier
3. **Smart Caching**: Leverage built-in caching for repeated evaluations
4. **Resource Monitoring**: Monitor memory and CPU usage

### Accessibility Compliance

1. **Motion Sensitivity**: Respect reduce motion settings
2. **Performance Adaptation**: Ensure features work well with accessibility tools
3. **Graceful Degradation**: Provide alternatives when features are reduced

## Testing

The provider includes testing-friendly features:

```swift
// Safe for test environments
let provider = MacOSSystemContextProvider()

// Returns sensible defaults in test environments
let context = provider.currentContext()

// All specifications work in tests with fallback values
let spec = PlatformContextProviders.createMacOSSystemSpec(.darkMode)
let result = spec.isSatisfiedBy("test") // Works without crashing
```

## See Also

- ``PlatformContextProviders``
- ``DeviceContextProvider``
- ``ContextProviding``
- ``ReactiveWrappers``