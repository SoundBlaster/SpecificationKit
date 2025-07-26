# 📋 SpecificationKit

A powerful Swift library implementing the **Specification Pattern** with support for context providers, property wrappers, and composable business rules. Perfect for feature flags, conditional logic, banner display rules, and complex business requirements.

[![Swift 5.9+](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)
[![iOS 13.0+](https://img.shields.io/badge/iOS-13.0+-blue.svg)](https://developer.apple.com/ios/)
[![macOS 10.15+](https://img.shields.io/badge/macOS-10.15+-blue.svg)](https://developer.apple.com/macos/)
[![Swift Package Manager](https://img.shields.io/badge/SPM-compatible-brightgreen.svg)](https://swift.org/package-manager/)

## ✨ Features

- 🧩 **Composable Specifications** - Build complex business rules from simple, reusable components
- 🎯 **Property Wrapper Support** - Declarative syntax with `@Satisfies` for clean integration
- 🔄 **Context Providers** - Flexible context injection and dependency management
- 🧪 **Testing Support** - Built-in mock providers and test utilities
- 📱 **Cross-Platform** - Works on iOS, macOS, tvOS, and watchOS
- 🔒 **Type-Safe** - Leverages Swift's type system for compile-time safety
- ⚡ **Performance Optimized** - Lightweight and efficient evaluation

## 📦 Installation

### Swift Package Manager

Add SpecificationKit to your project in Xcode:

1. Go to **File** → **Add Package Dependencies**
2. Enter the repository URL: `https://github.com/youruser/SpecificationKit`
3. Select the version you want to use

Or add it to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/youruser/SpecificationKit", from: "1.0.0")
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

### Property Wrapper Usage

```swift
class BannerController {
    // Simple specification with default context provider
    @Satisfies(using: TimeSinceEventSpec.sinceAppLaunch(seconds: 10))
    var canShowAfterDelay: Bool

    // Complex composite specification
    @Satisfies(using: CompositeSpec.promoBanner)
    var shouldShowPromoBanner: Bool

    func checkBannerStatus() {
        if shouldShowPromoBanner {
            displayPromoBanner()
        }
    }
}
```

## 🧱 Core Components

### Specifications

The library includes several built-in specifications:

#### TimeSinceEventSpec
Checks if enough time has passed since an event occurred.

```swift
// Check if 5 minutes passed since app launch
let spec = TimeSinceEventSpec.sinceAppLaunch(minutes: 5)

// Check if 24 hours passed since last notification
let cooldown = TimeSinceEventSpec(eventKey: "last_notification", hours: 24)
```

#### MaxCountSpec
Ensures a counter hasn't exceeded a maximum value.

```swift
// Allow maximum 3 banner displays
let spec = MaxCountSpec(counterKey: "banner_count", limit: 3)

// One-time only actions
let onceOnly = MaxCountSpec.onlyOnce("onboarding_completed")
```

#### CooldownIntervalSpec
Implements cooldown periods between events.

```swift
// 7-day cooldown between promotions
let spec = CooldownIntervalSpec.weekly("promo_shown")

// Custom cooldown period
let custom = CooldownIntervalSpec(eventKey: "feature_used", minutes: 30)
```

#### PredicateSpec
Flexible specification using custom predicates.

```swift
// Custom business logic
let spec = PredicateSpec<EvaluationContext> { context in
    context.flag(for: "premium_user") && context.counter(for: "usage_count") > 10
}

// Time-based conditions
let businessHours = PredicateSpec<EvaluationContext>.currentHour(in: 9...17)
```

### Context Providers

#### DefaultContextProvider
Production-ready context provider with thread-safe state management.

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

#### MockContextProvider
Perfect for unit testing with controllable state.

```swift
let mockProvider = MockContextProvider()
    .withCounter("test_counter", value: 5)
    .withFlag("test_flag", value: true)
    .withEvent("test_event", date: Date())

// Use in tests
let spec = MaxCountSpec(counterKey: "test_counter", limit: 10)
let context = mockProvider.currentContext()
XCTAssertTrue(spec.isSatisfiedBy(context))
```

## 🎯 Advanced Usage

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
        let notCompletedYet = PredicateSpec<EvaluationContext>.flag(
            "onboarding_completed", equals: false
        )
        
        composite = AnySpecification(
            userEngaged.and(firstWeek).and(notCompletedYet)
        )
    }
    
    func isSatisfiedBy(_ context: EvaluationContext) -> Bool {
        composite.isSatisfiedBy(context)
    }
}
```

### Builder Pattern

```swift
let complexSpec = Satisfies<EvaluationContext>.builder(
    provider: DefaultContextProvider.shared
)
.with(TimeSinceEventSpec.sinceAppLaunch(minutes: 2))
.with(MaxCountSpec(counterKey: "attempts", limit: 3))
.with { context in context.flag(for: "feature_enabled") }
.buildAll()
```

### SwiftUI Integration

```swift
struct ContentView: View {
    @Satisfies(using: CompositeSpec.promoBanner)
    var shouldShowPromo: Bool
    
    var body: some View {
        VStack {
            if shouldShowPromo {
                PromoBannerView()
            }
            
            MainContentView()
        }
    }
}
```

## 🧪 Testing

SpecificationKit includes comprehensive testing utilities:

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

## 📱 Demo App

The repository includes a complete SwiftUI demo app showing real-world usage:

```bash
cd DemoApp
swift run SpecificationKitDemo
```

The demo showcases:
- Real-time specification evaluation
- Context provider management
- Property wrapper integration
- Interactive state manipulation

## 🏗️ Architecture

SpecificationKit follows a clean, layered architecture:

```
┌─────────────────────────────────────┐
│           Application Layer          │
│      (@Satisfies, SwiftUI Views)    │
├─────────────────────────────────────┤
│         Property Wrapper Layer      │
│           (@Satisfies)              │
├─────────────────────────────────────┤
│        Definitions Layer            │
│      (CompositeSpec, etc.)          │
├─────────────────────────────────────┤
│         Specifications Layer        │
│  (TimeSinceEventSpec, MaxCountSpec) │
├─────────────────────────────────────┤
│           Context Layer             │
│    (EvaluationContext, Providers)   │
├─────────────────────────────────────┤
│             Core Layer              │
│   (Specification Protocol, Operators)│
└─────────────────────────────────────┘
```

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

- 📖 [Documentation](https://youruser.github.io/SpecificationKit)
- 💬 [Discussions](https://github.com/youruser/SpecificationKit/discussions)
- 🐛 [Issue Tracker](https://github.com/youruser/SpecificationKit/issues)

## 🙏 Acknowledgments

- Inspired by the [Specification Pattern](https://en.wikipedia.org/wiki/Specification_pattern)
- Built with modern Swift features and best practices
- Designed for real-world iOS/macOS application needs

---

**Made with ❤️ by the SpecificationKit team**