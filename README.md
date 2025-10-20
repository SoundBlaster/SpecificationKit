# SpecificationKit

A powerful Swift library implementing the **Specification Pattern** with support for context providers, property wrappers, and composable business rules. Perfect for feature flags, conditional logic, banner display rules, and complex business requirements.

[![Swift 5.9+](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)
[![iOS 13.0+](https://img.shields.io/badge/iOS-13.0+-blue.svg)](https://developer.apple.com/ios/)
[![macOS 10.15+](https://img.shields.io/badge/macOS-10.15+-blue.svg)](https://developer.apple.com/macos/)
[![Swift Package Manager](https://img.shields.io/badge/SPM-compatible-brightgreen.svg)](https://swift.org/package-manager/)
[![Version 3.0.0](https://img.shields.io/badge/Version-3.0.0-green.svg)]()

## 📑 Table of Contents

- [Features](#-features)
- [What's New in v3.0.0](#-whats-new-in-v300)
- [Installation](#-installation)
- [Quick Start](#-quick-start)
  - [Basic Usage](#basic-usage)
  - [@specs Macro](#specs-macro-usage)
  - [Property Wrappers](#property-wrapper-usage)
  - [Async Specifications](#async-specifications)
  - [Observation in SwiftUI](#observation-in-swiftui)
- [Core Components](#-core-components)
  - [Built-in Specifications](#specifications)
  - [Context Providers](#context-providers)
- [Advanced Usage](#-advanced-usage)
  - [Decision Specifications](#decision-specifications)
  - [Custom Composite Specifications](#custom-composite-specifications)
  - [Builder Pattern](#builder-pattern)
  - [Conditional Specifications](#conditionalsatisfies-property-wrapper)
  - [Performance Optimization](#performance-optimization-with-caching)
- [Testing](#-testing)
- [Performance Benchmarks](#-performance-benchmarks)
- [Debugging and Tracing](#-debugging-and-tracing)
- [Demo App](#-demo-app)
- [Architecture](#-architecture)
- [Documentation](#-documentation)
- [Migration Guide](#-migration-spec--decides)
- [Contributing](#-contributing)
- [License](#-license)
- [Support](#-support)

## ✨ Features

- 🧩 **Composable Specifications** - Build complex business rules from simple, reusable components
- 🎯 **Property Wrapper Support** - Declarative syntax with `@Satisfies`, `@Decides`, `@Maybe`, `@CachedSatisfies`, and reactive wrappers `@ObservedSatisfies`, `@ObservedDecides`, `@ObservedMaybe` for SwiftUI
- 🔄 **Context Providers** - Flexible context injection and dependency management including `DefaultContextProvider`, `EnvironmentContextProvider`, `NetworkContextProvider`, `PersistentContextProvider`, and `CompositeContextProvider`
- 🚀 **Decision Specifications** - Return typed results beyond boolean values with `DecisionSpec` and `FirstMatchSpec`
- 🎲 **Advanced Specifications** - `WeightedSpec` for A/B testing, `HistoricalSpec` for time-series analysis, `ComparativeSpec` for relative comparisons, `ThresholdSpec` for dynamic thresholds
- 🧭 **Date & Flag Specs** - Built-ins: `DateRangeSpec`, `DateComparisonSpec`, `FeatureFlagSpec`, `UserSegmentSpec`, `SubscriptionStatusSpec`
- ⚙️ **Async Capable** - Evaluate rules asynchronously via `AsyncSpecification`, `AnyAsyncSpecification`, and async property wrappers
- 👀 **Observation for SwiftUI** - Auto-update views when context changes via `ContextUpdatesProviding`
- 🏆 **Conditional Evaluation** - Runtime specification selection with `@ConditionalSatisfies`
- 🧪 **Testing Support** - Built-in mock providers and `MockSpecificationBuilder` for comprehensive testing
- 📱 **Cross-Platform** - Works on iOS, macOS, tvOS, and watchOS with platform-specific providers
- 🔒 **Type-Safe** - Leverages Swift's type system for compile-time safety
- ⚡ **Performance Optimized** - Lightweight with `@inlinable` methods and specialized storage

## 📢 What's New in v3.0.0

### @ConditionalSatisfies - Runtime Specification Selection

Choose specifications dynamically based on runtime conditions:

```swift
@ConditionalSatisfies(
    condition: { context in context.flag(for: "use_strict_mode") },
    whenTrue: StrictValidationSpec(),
    whenFalse: BasicValidationSpec()
)
var validationPassed: Bool

// Platform-specific specs
@ConditionalSatisfies.iOS(
    iOS: MobileLayoutSpec(),
    other: DesktopLayoutSpec()
)
var shouldUseMobileLayout: Bool
```

### Advanced Specification Types

**WeightedSpec** for probability-based selection (A/B testing):
```swift
let abTestSpec = WeightedSpec([
    (FeatureFlagSpec(flag: "variant_a"), 0.5, "variant_a"),
    (FeatureFlagSpec(flag: "variant_b"), 0.3, "variant_b"),
    (FeatureFlagSpec(flag: "control"), 0.2, "control")
])
```

**HistoricalSpec** for time-series analysis:
```swift
let performanceSpec = HistoricalSpec(
    provider: MetricsHistoryProvider(),
    window: .lastN(30),
    aggregation: .median
)
```

**ThresholdSpec** for dynamic threshold evaluation:
```swift
let alertSpec = ThresholdSpec(
    keyPath: \.responseTime,
    threshold: .adaptive { getCurrentBaseline() },
    operator: .greaterThan
)
```

### Performance Optimizations

- **@inlinable Methods**: Cross-module compiler optimizations
- **Specialized Storage**: Different strategies for predicates, constants, and specifications
- **Collection Extensions**: Early-return optimizations for `allSatisfied()` and `anySatisfied()`
- **<0.1ms Evaluation**: Baseline performance for typical specifications

### Enhanced Reactive Wrappers

**@ObservedDecides** for reactive decision specifications:
```swift
@ObservedDecides([
    (PremiumUserSpec(), "premium_layout"),
    (TabletDeviceSpec(), "tablet_layout"),
    (CompactSizeSpec(), "mobile_layout")
], or: "default_layout")
var layoutType: String
```

**@ObservedMaybe** for reactive optional decisions:
```swift
@ObservedMaybe(provider: DefaultContextProvider.shared,
               firstMatch: [
                   (FeatureFlagSpec(flagKey: "feature_x"), "Enabled")
               ])
private var featureMessage: String?
```

### Performance Testing & Profiling

- **SpecificationProfiler**: Runtime performance analysis with microsecond precision
- **13 Performance Test Cases**: Comprehensive validation of optimization effectiveness
- **Benchmark Baselines**: Automated performance regression detection

### Platform-Specific Providers

Context providers for iOS, macOS, watchOS, and tvOS with platform-specific capabilities:

```swift
// Cross-platform device capability checking
let darkModeSpec = PlatformContextProviders.createDeviceCapabilitySpec(.darkMode)

@Satisfies(using: darkModeSpec)
var supportsDarkMode: Bool // Works on all platforms with graceful fallbacks
```

## 📦 Installation

### Swift Package Manager

Add SpecificationKit to your project in Xcode:

1. Go to **File** → **Add Package Dependencies**
2. Enter the repository URL: `https://github.com/SoundBlaster/SpecificationKit`
3. Select version `3.0.0` or later

Or add it to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/SoundBlaster/SpecificationKit", from: "3.0.0")
]
```

## 🚀 Quick Start

### Basic Usage

```swift
import SpecificationKit

// Define your context
let context = EvaluationContext(
    timeSinceLaunch: 15.0,
    counters: ["banner_shown": 1],
    events: ["last_banner": Date().addingTimeInterval(-3600)]
)

// Create specifications
let timeSinceLaunch = TimeSinceEventSpec.sinceAppLaunch(seconds: 10)
let maxShowCount = MaxCountSpec(counterKey: "banner_shown", limit: 3)
let cooldownPeriod = CooldownIntervalSpec(eventKey: "last_banner", hours: 1)

// Combine specifications
let canShowBanner = timeSinceLaunch.and(maxShowCount).and(cooldownPeriod)

// Evaluate
if canShowBanner.isSatisfiedBy(context) {
    print("Show the banner!")
}
```

### @specs Macro Usage

The `@specs` macro simplifies composite specification creation by automatically generating `init()` and `isSatisfiedBy(_:)` methods:

```swift
@specs(
    MaxCountSpec(counterKey: "display_count", limit: 3),
    TimeSinceEventSpec(eventKey: "last_shown", minimumInterval: 3600)
)
struct BannerSpec: Specification {
    typealias T = EvaluationContext
}

// Usage
let bannerSpec = BannerSpec()
if bannerSpec.isSatisfiedBy(context) {
    print("Show the banner!")
}
```

**Macro Diagnostics**: The macro validates argument types, detects mixed contexts, identifies async specs, and ensures proper protocol conformance with clear error messages.

### Property Wrapper Usage

```swift
class BannerController {
    // Simple boolean specification
    @Satisfies(using: TimeSinceEventSpec.sinceAppLaunch(seconds: 10))
    var canShowAfterDelay: Bool

    // Decision specification (non-optional)
    @Decides([
        (isVipSpec, 50),
        (promoSpec, 20),
        (birthdaySpec, 10)
    ], or: 0)
    var discountPercentage: Int

    // Decision specification (optional)
    @Maybe([
        (isVipSpec, 50),
        (promoSpec, 20),
        (birthdaySpec, 10)
    ])
    var discount: Int?

    func checkStatus() {
        if canShowAfterDelay {
            print("Showing banner with \(discountPercentage)% discount")
        }
    }
}
```

### Async Specifications

Evaluate specs asynchronously when inputs require awaiting:

```swift
// Async spec with delay
let asyncSpec = AnyAsyncSpecification<EvaluationContext> { ctx in
    try? await Task.sleep(nanoseconds: 50_000_000)
    return ctx.flag(for: "feature_enabled")
}

let result = try await asyncSpec.isSatisfiedBy(
    EvaluationContext(flags: ["feature_enabled": true])
)

// Async evaluation with provider
struct Gate {
    @Satisfies(provider: DefaultContextProvider.shared,
               predicate: { $0.flag(for: "feature_async") })
    var isOn: Bool

    func check() async throws -> Bool {
        try await _isOn.evaluateAsync()
    }
}
```

### Observation in SwiftUI

Use `@ObservedSatisfies` to keep views synchronized with provider changes:

```swift
struct ObservationExample: View {
    @ObservedSatisfies(provider: DefaultContextProvider.shared,
                       using: MaxCountSpec(counterKey: "attempts", limit: 3))
    private var underLimit: Bool

    var body: some View {
        VStack {
            Text(underLimit ? "Below limit" : "Limit reached")
            Button("+1") {
                _ = DefaultContextProvider.shared.incrementCounter("attempts")
            }
            Button("Reset") {
                DefaultContextProvider.shared.setCounter("attempts", to: 0)
            }
        }
    }
}
```

## 🧱 Core Components

### Specifications

#### TimeSinceEventSpec
Checks if enough time has passed since an event:

```swift
// Check if 5 minutes passed since app launch
let spec = TimeSinceEventSpec.sinceAppLaunch(minutes: 5)

// Check if 24 hours passed since last notification
let cooldown = TimeSinceEventSpec(eventKey: "last_notification", hours: 24)
```

#### MaxCountSpec
Ensures a counter hasn't exceeded a maximum value:

```swift
// Allow maximum 3 banner displays
let spec = MaxCountSpec(counterKey: "banner_count", limit: 3)

// One-time only actions
let onceOnly = MaxCountSpec.onlyOnce("onboarding_completed")
```

#### CooldownIntervalSpec
Implements cooldown periods between events:

```swift
// 7-day cooldown between promotions
let spec = CooldownIntervalSpec.weekly("promo_shown")

// Custom cooldown period
let custom = CooldownIntervalSpec(eventKey: "feature_used", minutes: 30)
```

#### PredicateSpec
Flexible specification using custom predicates:

```swift
// Custom business logic
let spec = PredicateSpec<EvaluationContext> { context in
    context.flag(for: "premium_user") && context.counter(for: "usage_count") > 10
}

// Time-based conditions
let businessHours = PredicateSpec<EvaluationContext>.currentHour(in: 9...17)
```

#### FirstMatchSpec
Evaluates specifications in priority order:

```swift
let discountSpec = FirstMatchSpec<UserContext, Int>([
    (isVipSpec, 50),
    (promoSpec, 20),
    (birthdaySpec, 10),
    (AlwaysTrueSpec(), 0) // fallback
])

let discount = discountSpec.decide(userContext) // e.g., 50 if user is VIP
```

#### Date & Flag Specifications

**DateRangeSpec** - Check if current date is within range:
```swift
let spec = DateRangeSpec(
    start: Date(timeIntervalSinceNow: -86400),
    end: Date(timeIntervalSinceNow: 86400)
)
```

**DateComparisonSpec** - Compare event date to reference:
```swift
let spec = DateComparisonSpec(eventKey: "last_login", comparison: .before, date: Date())
```

**FeatureFlagSpec** - Match boolean flags:
```swift
let enabled = FeatureFlagSpec(flagKey: "feature_enabled")
```

**UserSegmentSpec** - Check segment membership:
```swift
let isVip = UserSegmentSpec(.vip)
```

**SubscriptionStatusSpec** - Match subscription status:
```swift
let isPremium = SubscriptionStatusSpec(.premium)
```

### Context Providers

#### DefaultContextProvider
Production-ready context provider with thread-safe state management:

```swift
let provider = DefaultContextProvider.shared

// Manage counters
provider.incrementCounter("app_opens")
provider.setCounter("feature_usage", to: 5)

// Track events
provider.recordEvent("user_login")
provider.recordEvent("purchase_made", at: specificDate)

// Boolean flags
provider.setFlag("premium_user", to: true)
provider.toggleFlag("dark_mode")
```

#### EnvironmentContextProvider
Bridge SwiftUI `@Environment` and `@AppStorage` into `EvaluationContext`:

```swift
let envProvider = EnvironmentContextProvider()
envProvider.locale = locale // from @Environment(\.locale)
envProvider.interfaceStyle = (colorScheme == .dark ? "dark" : "light")
envProvider.flags["promo_enabled"] = promoEnabled // from @AppStorage
```

#### NetworkContextProvider
Fetch context from remote endpoints with caching and retry policies:

```swift
let config = NetworkContextProvider.Configuration(
    endpoint: URL(string: "https://api.yourservice.com/context")!,
    refreshInterval: 300,
    retryPolicy: .exponentialBackoff(maxAttempts: 3),
    fallbackValues: ["feature_enabled": true]
)

let networkProvider = NetworkContextProvider(configuration: config)
let context = try await networkProvider.currentContextAsync()
```

**Features**: Intelligent caching, retry policies, offline support, Swift 6 ready, reactive updates

#### PersistentContextProvider
Persist context data locally using Core Data:

```swift
let config = PersistentContextProvider.Configuration(
    modelName: "SpecificationContext",
    storeType: .sqliteStoreType,
    migrationPolicy: .automatic,
    encryptionEnabled: true
)

let persistentProvider = PersistentContextProvider(configuration: config)
await persistentProvider.setValue("premium", for: "user_tier")
await persistentProvider.setCounter(42, for: "login_count")
```

**Features**: Core Data integration, data expiration, thread safety, multiple data types, migration support, encryption

#### CompositeContextProvider
Combine multiple providers into a single context source:

```swift
let provider = CompositeContextProvider(
    providers: [defaults, env],
    strategy: .preferLast // Later providers override earlier ones
)
```

**Strategies**: `.preferLast`, `.preferFirst`, `.custom { [EvaluationContext] in ... }`

#### MockContextProvider
Perfect for unit testing with controllable state:

```swift
let mockProvider = MockContextProvider()
    .withCounter("test_counter", value: 5)
    .withFlag("test_flag", value: true)
    .withEvent("test_event", date: Date())
```

## 🎯 Advanced Usage

### Decision Specifications

```swift
struct RouteDecisionSpec: DecisionSpec {
    typealias Context = RequestContext
    typealias Result = Route

    func decide(_ context: RequestContext) -> Route? {
        if context.isAuthenticated {
            return .dashboard
        } else if context.hasSession {
            return .login
        } else {
            return .welcome
        }
    }
}

// Use with property wrappers
@Decides(decide: { ctx in
    if ctx.flag(for: "authenticated") { return .dashboard }
    if ctx.flag(for: "has_session") { return .login }
    return nil
}, or: .welcome)
var currentRoute: Route
```

### Custom Composite Specifications

```swift
struct OnboardingSpec: Specification {
    typealias T = EvaluationContext

    private let composite: AnySpecification<EvaluationContext>

    init() {
        let userEngaged = PredicateSpec<EvaluationContext>.counter(
            "screen_views", .greaterThanOrEqual, 3
        )
        let firstWeek = TimeSinceEventSpec.sinceAppLaunch(days: 7).not()
        let notCompleted = PredicateSpec<EvaluationContext>.flag(
            "onboarding_completed", equals: false
        )

        composite = AnySpecification(
            userEngaged.and(firstWeek).and(notCompleted)
        )
    }

    func isSatisfiedBy(_ context: EvaluationContext) -> Bool {
        composite.isSatisfiedBy(context)
    }
}
```

### Builder Pattern

```swift
// Boolean specification builder
let complexSpec = Satisfies<EvaluationContext>.builder(
    provider: DefaultContextProvider.shared
)
.with(TimeSinceEventSpec.sinceAppLaunch(minutes: 2))
.with(MaxCountSpec(counterKey: "attempts", limit: 3))
.with { context in context.flag(for: "feature_enabled") }
.buildAll()

// Decision specification builder
let discountSpec = FirstMatchSpec<UserContext, Int>.builder()
    .add(isVipSpec, result: 50)
    .add(promoSpec, result: 20)
    .add(birthdaySpec, result: 10)
    .fallback(0)
    .build()
```

### @ConditionalSatisfies Property Wrapper

Choose specifications dynamically at runtime:

```swift
// Condition-based selection
@ConditionalSatisfies(
    condition: { context in context.flag(for: "use_strict_mode") },
    whenTrue: StrictValidationSpec(),
    whenFalse: BasicValidationSpec()
)
var validationPassed: Bool

// Platform-specific selection
@ConditionalSatisfies.iOS(
    iOS: MobileLayoutSpec(),
    other: DesktopLayoutSpec()
)
var shouldUseMobileLayout: Bool

// Builder pattern for complex scenarios
@ConditionalSatisfies.builder()
    .when({ ctx in ctx.flag(for: "experimental") }, use: ExperimentalSpec())
    .when({ ctx in ctx.flag(for: "beta") }, use: BetaSpec())
    .otherwise(use: ProductionSpec())
var featureEnabled: Bool
```

### Performance Optimization with Caching

Use `@CachedSatisfies` to cache expensive evaluations with automatic TTL expiration:

```swift
class PerformanceController {
    // Cache result for 5 minutes
    @CachedSatisfies(using: ExpensiveAnalysisSpec(), ttl: 300.0)
    var analysisComplete: Bool

    // Cache user permission check for 60 seconds
    @CachedSatisfies(provider: DefaultContextProvider.shared,
                     predicate: { $0.flag(for: "user_premium") },
                     ttl: 60.0)
    var isPremiumUser: Bool
}
```

**Cache Management**:
```swift
// Force refresh
_analysisComplete.invalidateCache()

// Check cache status
if _analysisComplete.isCached {
    print("Using cached result")
}

// Get cache statistics
if let info = _analysisComplete.cacheInfo {
    print("Expires in: \(info.remainingTTL)s")
}
```

### SwiftUI Integration

```swift
struct ContentView: View {
    @Satisfies(using: CompositeSpec.promoBanner)
    var shouldShowPromo: Bool

    @Decides([
        (vipSpec, 50),
        (promoSpec, 20),
        (birthdaySpec, 10)
    ], or: 0)
    var discountPercentage: Int

    var body: some View {
        VStack {
            if shouldShowPromo {
                PromoBannerView(discountPercentage: discountPercentage)
            }
            MainContentView()
        }
    }
}
```

## 🧪 Testing

SpecificationKit includes comprehensive testing utilities including `MockSpecificationBuilder` for creating deterministic or intentionally flaky specifications:

```swift
let mock = MockSpecificationBuilder<EvaluationContext>()
    .withSequence([true, false])
    .withExecutionTime(0.01)
    .build()

XCTAssertTrue(mock.isSatisfiedBy(EvaluationContext()))
XCTAssertFalse(mock.isSatisfiedBy(EvaluationContext()))
XCTAssertEqual(mock.allResults, [true, false])

mock.reset()
```

**Convenience helpers**:
- `.alwaysTrue()` - Always returns true
- `.flaky(successRate:)` - Probabilistic results for testing edge cases
- `.slow(delay:)` - Add synthetic latency
- `.willThrow(_:)` - Surface fatal-error scenarios

**Testing with MockContextProvider**:

```swift
class MyFeatureTests: XCTestCase {
    func testBannerLogic() {
        // Given
        let mockProvider = MockContextProvider.launchDelayScenario(
            timeSinceLaunch: 30
        )
        .withCounter("banner_shown", value: 1)
        .withEvent("last_banner", date: Date().addingTimeInterval(-3600))

        let spec = CompositeSpec.promoBanner

        // When
        let result = spec.isSatisfiedBy(mockProvider.currentContext())

        // Then
        XCTAssertTrue(result)
        XCTAssertEqual(mockProvider.contextRequestCount, 1)
    }
}
```

## ⚡ Performance Benchmarks

SpecificationKit includes comprehensive performance benchmarking infrastructure to ensure optimal performance and detect regressions.

### Running Benchmarks

```bash
# Run all performance benchmarks
swift test --filter PerformanceBenchmarks

# Run specific categories
swift test --filter testSpecificationEvaluationPerformance
swift test --filter testMemoryUsageOptimization
swift test --filter testConcurrentAccessPerformance
```

### Benchmark Categories

**Specification Evaluation Performance**: Tests core evaluation of simple and composite specifications
- Target: **< 0.1ms per evaluation** for simple specifications

**Memory Usage Optimization**: Monitors memory allocation patterns
- Target: **< 1KB memory per specification evaluation**

**Concurrent Access Performance**: Validates thread-safe performance under load
- Ensures **linear performance scaling** with thread count

### Performance Profiler

Built-in runtime performance analysis:

```swift
let profiler = SpecificationProfiler.shared
let spec = MaxCountSpec(counterKey: "attempts", limit: 5)
let context = EvaluationContext(counters: ["attempts": 3])

// Profile evaluation
let result = profiler.profile(spec, context: context)

// Get performance data
let data = profiler.getProfileData()
print("Average time: \(data.averageTime)ms")
print("Memory usage: \(data.memoryUsage)KB")

// Generate detailed report
let report = profiler.generateReport()
print(report)
```

### Performance Baseline (Apple Silicon M1/M2)

| Operation | Performance | Memory |
|-----------|------------|--------|
| Simple Spec Evaluation | avg 0.05ms | 0.8KB |
| Composite Spec (5 components) | < 0.5ms | < 2KB |
| Context Provider Access | 0.02ms | 0.5KB |
| Property Wrapper Overhead | +2.3% | Negligible |

## 🔍 Debugging and Tracing

SpecificationKit v3.0.0 includes `SpecificationTracer` for detailed execution analysis:

```swift
let tracer = SpecificationTracer.shared
let sessionId = tracer.startTracing()

// Traced evaluation
let result = tracer.trace(specification: complexSpec, context: context)

if let session = tracer.stopTracing() {
    print("Traced \(session.entries.count) evaluations")
    print("Total time: \(session.totalExecutionTime * 1000)ms")

    // Print execution tree
    for tree in session.traceTree {
        tree.printTree()
    }

    // Generate DOT graph for Graphviz visualization
    let dotGraph = session.traceTree.first?.generateDotGraph()
}
```

**Features**:
- Hierarchical tracing with parent-child relationships
- Performance monitoring with precise timing
- Visual representation via tree and DOT graph generation
- Thread-safe concurrent tracing
- Zero overhead when disabled

## 📱 Demo App

The repository includes a complete SwiftUI demo app showing real-world usage:

```bash
cd DemoApp
swift run SpecificationKitDemo

# Or run CLI version
swift run SpecificationKitDemo --cli
```

**The demo showcases**:
- Real-time specification evaluation
- Context provider management
- Property wrapper integration
- Decisions screen (`@Decides`, `@Maybe`, `FirstMatchSpec`)
- Async Specs screen (delays, error handling)
- Environment Context screen (`@Environment`/`@AppStorage` bridging)
- Observation screen (live updates with `@ObservedSatisfies`)
- Context Composition screen (`CompositeContextProvider` strategies)

## 🏗️ Architecture

SpecificationKit follows a clean, layered architecture:

```
┌─────────────────────────────────────────┐
│ Application Layer                       │
│ (@Satisfies, @Decides, @Maybe, Views)   │
├─────────────────────────────────────────┤
│ Property Wrapper Layer                  │
│ (@Satisfies, @Decides, @Maybe,          │
│  @CachedSatisfies, @ObservedDecides,    │
│  @ConditionalSatisfies)                 │
├─────────────────────────────────────────┤
│ Definitions Layer                       │
│ (CompositeSpec, FirstMatchSpec,         │
│  WeightedSpec, ThresholdSpec)           │
├─────────────────────────────────────────┤
│ Specifications Layer                    │
│ (Specification, DecisionSpec)           │
├─────────────────────────────────────────┤
│ Context Layer                           │
│ (EvaluationContext, Providers)          │
├─────────────────────────────────────────┤
│ Core Layer                              │
│ (Specification Protocol, Operators)     │
└─────────────────────────────────────────┘
```

## 📖 Documentation

### API Documentation

Comprehensive DocC documentation is available online:

**🌐 [View Documentation](https://soundblaster.github.io/SpecificationKit/documentation/specificationkit/)**

The documentation includes:
- Complete API reference with examples
- Usage guides for all property wrappers
- Macro system documentation
- Context provider integration patterns
- SwiftUI and async/await examples

### Building Documentation Locally

```bash
# Generate static documentation website
swift package generate-documentation --target SpecificationKit \
  --output-path ./docs --transform-for-static-hosting

# Serve locally
cd docs && python3 -m http.server 8000
# Open http://localhost:8000 in your browser
```

**Xcode Documentation**:
- Open the project: `open Package.swift`
- **Product → Build Documentation** (⌃⇧⌘D)

## 🔁 Migration: @Spec → @Decides

Use `@Decides` instead of `@Spec` for decision specifications. The old `@Spec` remains available as a deprecated alias and will be removed in a future release.

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

SpecificationKit is available under the MIT license. See [LICENSE](LICENSE) for details.

## 📞 Support

- 📖 [Documentation](https://SoundBlaster.github.io/SpecificationKit)
- 💬 [Discussions](https://github.com/SoundBlaster/SpecificationKit/discussions)
- 🐛 [Issue Tracker](https://github.com/SoundBlaster/SpecificationKit/issues)

## 🙏 Acknowledgments

- Inspired by the [Specification Pattern](https://en.wikipedia.org/wiki/Specification_pattern)
- Built with modern Swift features and best practices
- Designed for real-world iOS/macOS application needs

---

**Made with ❤️ by the SpecificationKit team**
