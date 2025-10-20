# Apple TV Context Provider

Access Apple TV system state and capabilities for context-aware tvOS applications.

## Overview

The `AppleTVContextProvider` integrates with UIKit and tvOS system APIs to provide real-time Apple TV state information for specification evaluation. It monitors device capabilities, remote control availability, display properties, and system performance to enable context-aware application behavior on tvOS.

## Getting Started

### Basic Apple TV Information

Access Apple TV system state through the provider:

```swift
import SpecificationKit

@available(tvOS 13.0, *)
let tvProvider = AppleTVContextProvider()

// HDR content support
@Satisfies(provider: tvProvider, using: AppleTVContextProvider.hdrSpecification())
var supportsHDR: Bool

// Siri Remote detection
@Satisfies(provider: tvProvider, using: AppleTVContextProvider.siriRemoteSpecification())
var hasSiriRemote: Bool

// Performance tier detection
let context = tvProvider.currentContext()
let performanceTier = context.performanceTier // .reduced, .standard, or .high
```

### Apple TV Specifications

Use factory methods for common Apple TV checks:

```swift
// HDR content specification
let hdrSpec = PlatformContextProviders.createAppleTVSpec(.hdrSupport)

// Remote control specification
let siriRemoteSpec = PlatformContextProviders.createAppleTVSpec(.siriRemote)

// Performance tier specification
let highPerformanceSpec = PlatformContextProviders.createAppleTVPerformanceSpec(.high)

// Game controller specification
let gameControllerSpec = PlatformContextProviders.createAppleTVSpec(.gameController)

// Voice command specification
let voiceSpec = PlatformContextProviders.createAppleTVSpec(.voiceCommands)
```

### Cross-Platform Integration

Use the unified factory for cross-platform applications:

```swift
// Works on tvOS, returns false on other platforms
let appleTVFeatureSpec = PlatformContextProviders.createAppleTVSpec(.hdrSupport)

@Satisfies(using: appleTVFeatureSpec)
var supportsAppleTVFeatures: Bool

// Check platform capabilities
if PlatformContextProviders.supportsAppleTV {
    // Safe to use Apple TV-specific features
}
```

## Available Context Properties

The `AppleTVContext` provides comprehensive Apple TV information:

### Device Information
- `deviceModel: String?` - Apple TV model (e.g., "Apple TV HD", "Apple TV 4K")
- `systemVersion: String?` - tvOS version (e.g., "17.1.0")
- `deviceName: String?` - User-assigned device name
- `userInterfaceIdiom: UIUserInterfaceIdiom` - Interface idiom (.tv)

### Display Properties
- `screenResolution: CGSize?` - Screen resolution in points
- `screenScale: CGFloat?` - Screen scale factor
- `supportsHDR: Bool?` - HDR content support detection

### Remote Control and Input
- `hasRemoteConnected: Bool?` - Generic remote connectivity status
- `hasSiriRemote: Bool?` - Siri Remote detection (touchpad + microphone)
- `hasGameController: Bool?` - Game controller availability
- `gameControllerCount: Int?` - Number of connected game controllers
- `supportsVoiceCommands: Bool?` - Voice command capability

### System Performance
- `thermalState: ProcessInfo.ThermalState?` - Thermal state monitoring
- `physicalMemory: UInt64?` - Physical memory in bytes
- `processorCount: Int?` - Number of CPU cores

### Accessibility
- `isVoiceOverRunning: Bool?` - VoiceOver status
- `isReduceMotionEnabled: Bool?` - Reduce motion preference
- `isSwitchControlRunning: Bool?` - Switch Control detection

### Computed Properties
- `performanceTier: TVPerformanceTier` - Performance tier (.reduced, .standard, .high)
- `supportsHighQualityContent: Bool` - Whether high-quality content should be enabled
- `supportsAdvancedInput: Bool` - Whether advanced input features are available
- `hasAccessibilityFeaturesEnabled: Bool` - Whether accessibility features affect UI

## Performance Tiers

The provider automatically categorizes Apple TV performance:

```swift
let context = tvProvider.currentContext()

switch context.performanceTier {
case .high:
    // Apple TV 4K (3rd gen), 4GB+ RAM, 6+ cores - Enable all features
    enableAdvancedFeatures()
case .standard:
    // Apple TV 4K (1st/2nd gen), 3GB+ RAM, 4+ cores - Enable most features
    enableStandardFeatures()
case .reduced:
    // Apple TV HD or older, <3GB RAM - Basic features only
    enableBasicFeatures()
}
```

## HDR Content Optimization

Optimize content delivery based on HDR capabilities:

```swift
struct HDRContentSpec: Specification {
    func isSatisfiedBy(_ context: AppleTVContext) -> Bool {
        // Enable HDR content only if supported and high performance
        return context.supportsHDR == true && 
               context.supportsHighQualityContent &&
               context.thermalState != .critical
    }
}

@Satisfies(provider: tvProvider, using: HDRContentSpec())
var shouldEnableHDRContent: Bool
```

## Remote Control Adaptation

Adapt UI based on available input methods:

```swift
struct AdvancedInputSpec: Specification {
    func isSatisfiedBy(_ context: AppleTVContext) -> Bool {
        // Enable advanced input features for Siri Remote
        return context.hasSiriRemote == true && 
               context.supportsAdvancedInput
    }
}

@Satisfies(provider: tvProvider, using: AdvancedInputSpec())
var canUseAdvancedInput: Bool

// Adapt UI based on remote capabilities
if canUseAdvancedInput {
    // Enable gestures, voice search, etc.
    SiriRemoteOptimizedView()
} else {
    // Use basic remote-friendly interface
    BasicRemoteView()
}
```

## Gaming Features

Adapt gaming features based on controller availability:

```swift
let context = tvProvider.currentContext()

// Check for game controllers
if context.hasGameController == true {
    enableGameControllerFeatures()
}

// Multi-controller games
if let controllerCount = context.gameControllerCount, controllerCount > 1 {
    enableMultiplayerMode()
}
```

## Reactive Updates

The provider supports reactive programming with Combine:

```swift
@available(tvOS 13.0, *)
final class AppleTVAwareViewModel: ObservableObject {
    @Published var supportsHDR = false
    @Published var hasAdvancedInput = false
    
    private let tvProvider = AppleTVContextProvider()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // React to system changes
        tvProvider.contextUpdates
            .sink { [weak self] in
                self?.updateFromSystem()
            }
            .store(in: &cancellables)
        
        updateFromSystem()
    }
    
    private func updateFromSystem() {
        let context = tvProvider.currentContext()
        supportsHDR = context.supportsHDR == true
        hasAdvancedInput = context.supportsAdvancedInput
    }
}
```

## Configuration and Caching

The provider uses intelligent caching for optimal performance:

- **Cache Duration**: 2 second TTL for system state (optimized for TV usage)
- **Automatic Refresh**: Updates on system notifications
- **Thread Safety**: All operations are thread-safe
- **Testing Support**: Graceful fallbacks in test environments

## Platform Capabilities

Check for Apple TV-specific capabilities:

```swift
// Check if running on Apple TV with full feature support
if PlatformContextProviders.supportsAppleTV {
    // Use Apple TV-specific features
}

// Check for HDR support
if PlatformContextProviders.supportsTVHDR {
    // Use HDR-related specifications
}

// Check for game controller support
if PlatformContextProviders.supportsTVGameController {
    // Use gaming features
}
```

## Best Practices

### Performance Optimization

1. **Cache Results**: Use `@CachedSatisfies` for expensive specifications
2. **Adapt to Performance**: Use performance tier to scale feature complexity
3. **Monitor Thermals**: Reduce features when thermal state is critical
4. **Optimize for TV**: Design for 10-foot interface and remote control

### Content Delivery

1. **HDR Awareness**: Only enable HDR when truly supported and beneficial
2. **Performance Scaling**: Adapt content quality based on performance tier
3. **Memory Conscious**: Monitor memory usage especially on older Apple TV models
4. **Thermal Management**: Reduce intensive operations during thermal throttling

### Accessibility Compliance

1. **VoiceOver Support**: Ensure features work well with VoiceOver
2. **Motion Sensitivity**: Respect reduce motion settings
3. **Focus Management**: Optimize focus navigation for TV interface
4. **Voice Commands**: Support voice interaction when available

## Testing

The provider includes testing-friendly features:

```swift
// Safe for test environments
let provider = AppleTVContextProvider()

// Returns sensible defaults in test environments
let context = provider.currentContext()

// All specifications work in tests with fallback values
let spec = PlatformContextProviders.createAppleTVSpec(.hdrSupport)
let result = spec.isSatisfiedBy("test") // Works without crashing
```

## See Also

- ``PlatformContextProviders``
- ``DeviceContextProvider``
- ``ContextProviding``
- ``ReactiveWrappers``