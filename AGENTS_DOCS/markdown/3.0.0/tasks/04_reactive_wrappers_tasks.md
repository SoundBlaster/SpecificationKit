# SwiftUI/Reactive Specialist Tasks

## Agent Profile
- **Primary Skills**: SwiftUI, Combine, property wrappers, state management
- **Secondary Skills**: Reactive programming, performance optimization, thread safety
- **Complexity Level**: High (4/5)

## Task Overview

### Task 3.1.1: Enhanced Property Wrapper Ecosystem
**Objective**: Implement reactive, cached, and conditional property wrappers
**Priority**: High
**Dependencies**: None (can start immediately)
**Timeline**: 10 days

---

## 3.1.1: Reactive Wrapper Implementation

### @ObservedDecides Implementation
**Timeline**: 4 days

#### API Design Target
```swift
@propertyWrapper
public struct ObservedDecides<Context, Result>: DynamicProperty {
    @StateObject private var publisher: DecisionPublisher<Context, Result>
    private let contextProvider: any ContextProviding
    
    public var wrappedValue: Result { publisher.currentValue }
    public var projectedValue: Published<Result>.Publisher { 
        publisher.$currentValue 
    }
    
    public init(
        _ decisions: [(any Specification<Context>, Result)],
        or fallback: Result,
        provider: any ContextProviding = DefaultContextProvider.shared
    ) {
        self.contextProvider = provider
        self._publisher = StateObject(wrappedValue: 
            DecisionPublisher(decisions: decisions, fallback: fallback, provider: provider)
        )
    }
}
```

#### Supporting Infrastructure
```swift
@MainActor
final class DecisionPublisher<Context, Result>: ObservableObject {
    @Published var currentValue: Result
    
    private let decisions: [(any Specification<Context>, Result)]
    private let fallback: Result
    private let provider: any ContextProviding
    private var cancellables = Set<AnyCancellable>()
    
    init(decisions: [(any Specification<Context>, Result)], 
         fallback: Result, 
         provider: any ContextProviding) {
        
        self.decisions = decisions
        self.fallback = fallback
        self.provider = provider
        
        // Initial evaluation
        self.currentValue = Self.evaluate(decisions: decisions, 
                                        fallback: fallback, 
                                        provider: provider)
        
        // Set up reactive updates
        setupReactiveUpdates()
    }
    
    private func setupReactiveUpdates() {
        // Listen to context changes and re-evaluate
        provider.contextChanges
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateValue()
            }
            .store(in: &cancellables)
    }
}
```

#### Acceptance Test Template
```swift
func testObservedDecidesReactivity() {
    let provider = MockContextProvider()
    let spec = FeatureFlagSpec(key: "testFlag")
    
    @ObservedDecides([(spec, "enabled")], or: "disabled", provider: provider)
    var featureState: String
    
    // Initial state
    XCTAssertEqual(featureState, "disabled")
    
    // Change context
    provider.setFlag("testFlag", value: true)
    
    // Verify reactive update
    expectation { featureState == "enabled" }
}
```

### @ObservedMaybe Implementation
**Timeline**: 3 days

#### API Design
```swift
@propertyWrapper
public struct ObservedMaybe<Context, Result>: DynamicProperty {
    @StateObject private var publisher: MaybePublisher<Context, Result>
    
    public var wrappedValue: Result? { publisher.currentValue }
    public var projectedValue: Published<Result?>.Publisher { 
        publisher.$currentValue 
    }
    
    public init(
        _ decisions: [(any Specification<Context>, Result)],
        provider: any ContextProviding = DefaultContextProvider.shared
    ) {
        self._publisher = StateObject(wrappedValue: 
            MaybePublisher(decisions: decisions, provider: provider)
        )
    }
}
```

---

## 3.1.2: Caching Implementation

### @CachedSatisfies with TTL Support
**Timeline**: 2 days

#### Technical Specifications
```swift
@propertyWrapper
public struct CachedSatisfies<Context>: DynamicProperty {
    @State private var cachedResult: CachedValue<Bool>?
    
    private let specification: any Specification<Context>
    private let ttl: TimeInterval
    private let contextProvider: any ContextProviding
    
    public var wrappedValue: Bool {
        if let cached = cachedResult, !cached.isExpired {
            return cached.value
        }
        
        let result = specification.isSatisfiedBy(contextProvider.context)
        cachedResult = CachedValue(value: result, ttl: ttl)
        return result
    }
    
    public init(
        using specification: any Specification<Context>,
        ttl: TimeInterval = 60.0,
        provider: any ContextProviding = DefaultContextProvider.shared
    ) {
        self.specification = specification
        self.ttl = ttl
        self.contextProvider = provider
    }
    
    // Manual cache invalidation
    public func invalidateCache() {
        cachedResult = nil
    }
}
```

#### Thread-Safe Cache Implementation
```swift
struct CachedValue<T> {
    let value: T
    let timestamp: Date
    let ttl: TimeInterval
    
    var isExpired: Bool {
        Date().timeIntervalSince(timestamp) > ttl
    }
}

actor CacheManager<T> {
    private var cache: [String: CachedValue<T>] = [:]
    
    func getValue(for key: String) -> T? {
        cache[key]?.isExpired == false ? cache[key]?.value : nil
    }
    
    func setValue(_ value: T, for key: String, ttl: TimeInterval) {
        cache[key] = CachedValue(value: value, timestamp: Date(), ttl: ttl)
    }
    
    func invalidate(key: String) {
        cache[key] = nil
    }
    
    func clearExpired() {
        cache = cache.filter { !$0.value.isExpired }
    }
}
```

#### Memory Pressure Handling
```swift
extension CachedSatisfies {
    private func handleMemoryPressure() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { _ in
            invalidateCache()
        }
    }
}
```

---

## 3.1.3: Conditional Logic Implementation

### @ConditionalSatisfies with Runtime Selection
**Timeline**: 1 day

#### API Design
```swift
@propertyWrapper
public struct ConditionalSatisfies<Context>: DynamicProperty {
    private let conditions: [(predicate: () -> Bool, specification: any Specification<Context>)]
    private let fallback: any Specification<Context>
    private let contextProvider: any ContextProviding
    
    public var wrappedValue: Bool {
        let activeSpec = conditions.first { $0.predicate() }?.specification ?? fallback
        return activeSpec.isSatisfiedBy(contextProvider.context)
    }
    
    public init(
        conditions: [(predicate: () -> Bool, specification: any Specification<Context>)],
        fallback: any Specification<Context>,
        provider: any ContextProviding = DefaultContextProvider.shared
    ) {
        self.conditions = conditions
        self.fallback = fallback
        self.contextProvider = provider
    }
}
```

#### Usage Example
```swift
struct AdaptiveFeatureView: View {
    @ConditionalSatisfies(
        conditions: [
            ({ UIDevice.current.userInterfaceIdiom == .pad }, PadFeatureSpec()),
            ({ UIAccessibility.isVoiceOverRunning }, AccessibilityFeatureSpec())
        ],
        fallback: DefaultFeatureSpec()
    )
    var shouldShowFeature: Bool
    
    var body: some View {
        Group {
            if shouldShowFeature {
                FeatureView()
            } else {
                PlaceholderView()
            }
        }
    }
}
```

---

## Integration Examples & Best Practices

### SwiftUI Integration Examples
```swift
struct ReactiveSpecificationDemo: View {
    @ObservedDecides([
        (UserSubscriptionSpec(), "premium"),
        (UserTrialSpec(), "trial")
    ], or: "basic")
    var userTier: String
    
    @ObservedMaybe([
        (LocationPermissionSpec(), "location-enabled"),
        (CameraPermissionSpec(), "camera-enabled")
    ])
    var availableFeatures: String?
    
    @CachedSatisfies(using: ExpensiveAnalyticsSpec(), ttl: 300)
    var analyticsEnabled: Bool
    
    var body: some View {
        VStack {
            Text("User Tier: \(userTier)")
            
            if let features = availableFeatures {
                Text("Features: \(features)")
            }
            
            if analyticsEnabled {
                AnalyticsView()
            }
        }
        .onReceive($userTier) { newTier in
            // React to tier changes
            handleTierChange(newTier)
        }
    }
}
```

### Performance Optimization
```swift
// Minimize re-evaluations with intelligent caching
@propertyWrapper
struct SmartCachedSatisfies<Context>: DynamicProperty {
    @State private var lastContext: Context?
    @State private var cachedResult: Bool?
    
    public var wrappedValue: Bool {
        let currentContext = contextProvider.context
        
        // Only re-evaluate if context changed
        if !contextEqual(lastContext, currentContext) {
            cachedResult = specification.isSatisfiedBy(currentContext)
            lastContext = currentContext
        }
        
        return cachedResult ?? false
    }
}
```

## Implementation Guidelines

### Code Quality Standards
- **Swift 6 Compliance**: All property wrappers must support strict concurrency
- **Thread Safety**: All shared state must be properly synchronized
- **Performance**: Reactive updates should have minimal overhead
- **Testing**: >90% test coverage with comprehensive SwiftUI integration tests

### Testing Strategy
```swift
class ReactiveWrapperTests: XCTestCase {
    func testObservedDecidesReactivity() {
        // Test reactive behavior with context changes
    }
    
    func testCacheExpiration() {
        // Test TTL functionality and memory management
    }
    
    func testConditionalSelection() {
        // Test runtime specification selection
    }
    
    func testSwiftUIIntegration() {
        // Test property wrapper behavior in SwiftUI views
    }
}
```

### Performance Requirements
- **Reactive Update Latency**: <16ms for UI-blocking updates
- **Cache Hit Performance**: <0.1ms for cached evaluations
- **Memory Usage**: Bounded cache with automatic cleanup
- **Thread Contention**: Zero blocking on main thread

## Dependencies & Coordination

### External Dependencies
- Combine framework for reactive programming
- SwiftUI for property wrapper integration
- Foundation for caching and timing

### Coordination Points
- **Performance Team**: Benchmark reactive wrapper overhead
- **Testing Team**: SwiftUI testing infrastructure setup
- **Documentation Team**: Usage examples and best practices
- **Platform Team**: iOS/macOS specific reactive patterns

## Success Metrics
- **Feature Completion**: 100% of reactive wrapper functionality
- **SwiftUI Integration**: Seamless integration with SwiftUI lifecycle
- **Performance**: <5% overhead vs non-reactive equivalents
- **Developer Experience**: Intuitive API with comprehensive documentation