# PRD: SpecificationCore — Platform-Independent Specification Pattern Foundation

## Document Metadata

| Field | Value |
|-------|-------|
| **Project** | SpecificationCore |
| **Version** | 1.0.0 |
| **Status** | Draft |
| **Author** | AI Agent |
| **Created** | 2025-11-16 |
| **Parent Project** | SpecificationKit |
| **Type** | Package Extraction / Modularization |

---

## 1. Objective

Extract and isolate platform-independent core logic from **SpecificationKit** into a separate Swift Package named **SpecificationCore**. This package will contain foundational protocols, base implementations, macros, and property wrappers necessary for building platform-specific and extended specification libraries.

**Primary Goals:**

1. Create a minimal, platform-independent Swift Package containing only fundamental specification pattern components
2. Eliminate dependency on platform-specific frameworks (SwiftUI, Combine when optional, UIKit, AppKit, WatchKit)
3. Provide a stable, extensible foundation for future platform-specific packages (SpecificationKit-iOS, SpecificationKit-macOS, etc.)
4. Reduce code duplication across platform implementations
5. Minimize API surface area to core functionality only
6. Maintain backward compatibility path for existing SpecificationKit consumers

**Success Metrics:**

- SpecificationCore compiles on all Swift-supported platforms (iOS, macOS, tvOS, watchOS, Linux, Windows)
- Zero dependencies on platform-specific frameworks in core module
- < 5,000 lines of code in SpecificationCore (versus ~14,415 in current SpecificationKit)
- All existing SpecificationKit tests pass after migration
- Build time improvement of at least 20% for projects using only core functionality
- Clear migration path documented for existing users

---

## 2. Non-Goals

**Explicitly Out of Scope:**

1. **Platform-Specific Providers**: No macOS, iOS, watchOS, tvOS-specific context providers in core
2. **SwiftUI Integration**: No SwiftUI-dependent property wrappers (@ObservedSatisfies, @ObservedDecides, @ObservedMaybe)
3. **UI Framework Dependencies**: No UIKit, AppKit, or other UI framework imports
4. **Advanced Domain Specs**: Business-specific specifications (FeatureFlagSpec, SubscriptionStatusSpec, UserSegmentSpec) remain in SpecificationKit
5. **Performance Profiling Tools**: PerformanceProfiler, SpecificationTracer stay in SpecificationKit
6. **Example Code**: Discount examples and demonstration code excluded from core
7. **Documentation Tutorials**: DoCC tutorials remain in SpecificationKit
8. **Breaking Changes**: No breaking API changes to existing SpecificationKit public API
9. **Combine Mandatory Dependency**: Combine remains optional, not required for core functionality
10. **Network/Storage Integration**: NetworkContextProvider, PersistentContextProvider excluded

---

## 3. Constraints

### 3.1 Platform Independence

- **Requirement**: SpecificationCore MUST compile on all platforms supported by Swift Package Manager
- **Allowed Dependencies**: Foundation framework only (required), Combine (optional via `#if canImport(Combine)`)
- **Macro Dependencies**: swift-syntax package for macro implementation
- **Platform Directive Usage**: Use `#if canImport(...)` for optional framework support, never `#if os(...)`

### 3.2 API Stability

- **Backward Compatibility**: Existing SpecificationKit API remains unchanged
- **Semantic Versioning**: SpecificationCore follows SemVer 2.0.0 strictly
- **Migration Period**: Minimum 6 months deprecation warnings before removing any public API
- **Documentation**: All breaking changes documented in CHANGELOG.md with migration guide

### 3.3 Zero-Trust Security

- **Thread Safety**: All mutable state protected by appropriate synchronization primitives
- **Input Validation**: All public APIs validate inputs before processing
- **Type Safety**: Leverage Swift type system to prevent invalid states
- **Memory Safety**: No unsafe pointer operations, no force unwrapping in production code
- **Audit Trail**: All state mutations logged when debug mode enabled

### 3.4 Performance

- **Compile Time**: Core module compiles in < 10 seconds on CI machines
- **Runtime Overhead**: Specification evaluation adds < 1μs overhead vs direct predicate
- **Memory Footprint**: Type-erased wrappers add < 24 bytes overhead per instance
- **Optimization**: Use `@inlinable` for performance-critical paths
- **Lazy Evaluation**: Context providers compute values on-demand

### 3.5 Testing

- **Code Coverage**: Minimum 90% line coverage for all core components
- **Test Independence**: Tests must not depend on execution order
- **Platform Testing**: CI runs tests on macOS, Linux, iOS simulator
- **Macro Testing**: All macros tested with swift-macro-testing framework
- **Performance Tests**: Benchmark suite for critical paths

---

## 4. Architecture Overview

### 4.1 Package Structure

```
SpecificationCore/
├── Package.swift
├── README.md
├── CHANGELOG.md
├── Sources/
│   ├── SpecificationCore/
│   │   ├── Core/
│   │   │   ├── Specification.swift          # Base protocol + And/Or/Not
│   │   │   ├── DecisionSpec.swift           # Decision protocol + adapters
│   │   │   ├── AsyncSpecification.swift     # Async spec protocol
│   │   │   ├── ContextProviding.swift       # Context provider protocol
│   │   │   ├── AnySpecification.swift       # Type erasure
│   │   │   └── AnyContextProvider.swift     # Type-erased provider
│   │   ├── Context/
│   │   │   ├── EvaluationContext.swift      # Context data structure
│   │   │   ├── ContextValue.swift           # Dynamic value wrapper
│   │   │   ├── DefaultContextProvider.swift # Thread-safe provider
│   │   │   └── MockContextProvider.swift    # Testing utility
│   │   ├── Specs/
│   │   │   ├── PredicateSpec.swift          # Closure-based spec
│   │   │   ├── FirstMatchSpec.swift         # Priority evaluation
│   │   │   ├── MaxCountSpec.swift           # Counter limit
│   │   │   ├── CooldownIntervalSpec.swift   # Time cooldown
│   │   │   ├── TimeSinceEventSpec.swift     # Event timing
│   │   │   ├── DateRangeSpec.swift          # Date range check
│   │   │   └── DateComparisonSpec.swift     # Date comparison
│   │   ├── Wrappers/
│   │   │   ├── Satisfies.swift              # Boolean evaluation
│   │   │   ├── Decides.swift                # Non-optional decision
│   │   │   ├── Maybe.swift                  # Optional decision
│   │   │   └── AsyncSatisfies.swift         # Async evaluation
│   │   └── Definitions/
│   │       ├── AutoContextSpecification.swift
│   │       └── CompositeSpec.swift
│   └── SpecificationCoreMacros/
│       ├── MacroPlugin.swift
│       ├── SpecMacro.swift                  # @specs macro
│       └── AutoContextMacro.swift           # @AutoContext macro
└── Tests/
    └── SpecificationCoreTests/
        ├── CoreTests/
        ├── ContextTests/
        ├── SpecTests/
        ├── WrapperTests/
        └── MacroTests/
```

### 4.2 Component Dependency Graph

```
┌─────────────────────────────────────────────────────────────┐
│                     SpecificationCore                        │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌───────────────────────────────────────────────────────┐  │
│  │ Foundation Layer (Protocols)                          │  │
│  │  - Specification<T>                                   │  │
│  │  - DecisionSpec<Context, Result>                      │  │
│  │  - AsyncSpecification<T>                              │  │
│  │  - ContextProviding<Context>                          │  │
│  └───────────────────────────────────────────────────────┘  │
│                           │                                  │
│                           ▼                                  │
│  ┌───────────────────────────────────────────────────────┐  │
│  │ Type Erasure Layer                                    │  │
│  │  - AnySpecification<T>                                │  │
│  │  - AnyAsyncSpecification<T>                           │  │
│  │  - AnyDecisionSpec<Context, Result>                   │  │
│  │  - AnyContextProvider<Context>                        │  │
│  └───────────────────────────────────────────────────────┘  │
│                           │                                  │
│                           ▼                                  │
│  ┌───────────────────────────────────────────────────────┐  │
│  │ Context Infrastructure                                │  │
│  │  - EvaluationContext (struct)                         │  │
│  │  - DefaultContextProvider (thread-safe)               │  │
│  │  - MockContextProvider (testing)                      │  │
│  └───────────────────────────────────────────────────────┘  │
│                           │                                  │
│                           ▼                                  │
│  ┌───────────────────────────────────────────────────────┐  │
│  │ Basic Specifications                                  │  │
│  │  - PredicateSpec, FirstMatchSpec                      │  │
│  │  - MaxCountSpec, CooldownIntervalSpec                 │  │
│  │  - TimeSinceEventSpec, DateRangeSpec                  │  │
│  └───────────────────────────────────────────────────────┘  │
│                           │                                  │
│                           ▼                                  │
│  ┌───────────────────────────────────────────────────────┐  │
│  │ Property Wrappers (Platform-Independent)              │  │
│  │  - @Satisfies, @Decides, @Maybe                       │  │
│  │  - @AsyncSatisfies                                    │  │
│  └───────────────────────────────────────────────────────┘  │
│                           │                                  │
│                           ▼                                  │
│  ┌───────────────────────────────────────────────────────┐  │
│  │ Macro Support                                         │  │
│  │  - @specs (composite synthesis)                       │  │
│  │  - @AutoContext (provider injection)                  │  │
│  └───────────────────────────────────────────────────────┘  │
│                                                               │
└─────────────────────────────────────────────────────────────┘
         │
         │ (imports)
         ▼
┌─────────────────────────────────────────────────────────────┐
│                   SpecificationKit                           │
│  (Platform-specific extensions, SwiftUI wrappers,            │
│   advanced specs, UI integrations, examples)                 │
└─────────────────────────────────────────────────────────────┘
```

### 4.3 Core API Surface

**Total Public Types: ~25 types**

#### 4.3.1 Core Protocols (6 types)

```swift
public protocol Specification<T>
public protocol DecisionSpec<Context, Result>
public protocol AsyncSpecification<T>
public protocol ContextProviding<Context>
public protocol ContextUpdatesProviding  // Optional Combine support
```

#### 4.3.2 Type Erasure (4 types)

```swift
public struct AnySpecification<T>: Specification
public struct AnyAsyncSpecification<T>: AsyncSpecification
public struct AnyDecisionSpec<Context, Result>: DecisionSpec
public struct AnyContextProvider<Context>: ContextProviding
```

#### 4.3.3 Context Types (3 types)

```swift
public struct EvaluationContext
public struct ContextValue
public class DefaultContextProvider: ContextProviding
public class MockContextProvider: ContextProviding  // Testing only
```

#### 4.3.4 Basic Specifications (7 types)

```swift
public struct PredicateSpec<T>: Specification
public struct FirstMatchSpec<Context, Result>: DecisionSpec
public struct MaxCountSpec: Specification
public struct CooldownIntervalSpec: Specification
public struct TimeSinceEventSpec: Specification
public struct DateRangeSpec: Specification
public struct DateComparisonSpec: Specification
```

#### 4.3.5 Property Wrappers (4 types)

```swift
@propertyWrapper public struct Satisfies<S: Specification>
@propertyWrapper public struct Decides<Context, Result>
@propertyWrapper public struct Maybe<Context, Result>
@propertyWrapper public struct AsyncSatisfies<S: AsyncSpecification>
```

#### 4.3.6 Macros (2 macros)

```swift
@attached(member) public macro specs() = #externalMacro(...)
@attached(memberAttribute) public macro AutoContext() = #externalMacro(...)
```

---

## 5. Detailed Component Specifications

### 5.1 Core Protocols

**File**: `Sources/SpecificationCore/Core/Specification.swift`

**Requirements**:

1. Base `Specification` protocol with `isSatisfiedBy(_:)` method
2. Composite specifications: `AndSpecification`, `OrSpecification`, `NotSpecification`
3. Extension methods: `.and(_:)`, `.or(_:)`, `.not()`
4. Thread-safe, stateless, deterministic evaluation
5. Generic over candidate type `T`
6. Comprehensive documentation with examples

**Acceptance Criteria**:

- [ ] Protocol compiles without platform-specific imports
- [ ] Composite specs support short-circuit evaluation
- [ ] Extension methods inferred correctly by compiler
- [ ] All public APIs have documentation coverage
- [ ] Unit tests achieve > 95% coverage

### 5.2 Decision Specifications

**File**: `Sources/SpecificationCore/Core/DecisionSpec.swift`

**Requirements**:

1. `DecisionSpec` protocol with `decide(_:) -> Result?` method
2. Bridge from `Specification` to `DecisionSpec` via `.returning(_:)` extension
3. `BooleanDecisionAdapter` for adapting boolean specs
4. `PredicateDecisionSpec` for closure-based decisions
5. Type-erased `AnyDecisionSpec` wrapper

**Acceptance Criteria**:

- [ ] DecisionSpec returns optional results correctly
- [ ] Boolean specs can be converted to decision specs
- [ ] Type erasure preserves decision semantics
- [ ] Generic constraints compile without ambiguity
- [ ] Performance overhead < 50ns per decide() call

### 5.3 Async Specifications

**File**: `Sources/SpecificationCore/Core/AsyncSpecification.swift`

**Requirements**:

1. `AsyncSpecification` protocol with async/throws `isSatisfiedBy(_:)`
2. `AnyAsyncSpecification` type erasure
3. Bridge from sync `Specification` to `AsyncSpecification`
4. Error propagation support
5. Structured concurrency compatible

**Acceptance Criteria**:

- [ ] Async specs work with Swift async/await
- [ ] Error handling propagates correctly
- [ ] Sync-to-async bridge adds no blocking
- [ ] Cancellation supported via Task cancellation
- [ ] Memory leaks prevented (tested with instruments)

### 5.4 Context Providing

**File**: `Sources/SpecificationCore/Core/ContextProviding.swift`

**Requirements**:

1. `ContextProviding` protocol with `currentContext()` method
2. Async variant `currentContextAsync()` with default implementation
3. Optional `ContextUpdatesProviding` protocol (Combine-based)
4. `GenericContextProvider` and `StaticContextProvider` implementations
5. Thread-safe context retrieval

**Acceptance Criteria**:

- [ ] Compiles without Combine when not available
- [ ] Async variant bridges to sync correctly
- [ ] Generic provider captures closures safely
- [ ] Static provider optimized for value types
- [ ] No race conditions under concurrent access

### 5.5 Evaluation Context

**File**: `Sources/SpecificationCore/Context/EvaluationContext.swift`

**Requirements**:

1. Struct containing: currentDate, launchDate, userData, counters, events, flags, segments
2. Convenience accessors: `counter(for:)`, `event(for:)`, `flag(for:)`, `userData(for:as:)`
3. Builder methods: `withUserData(_:)`, `withCounters(_:)`, etc.
4. Computed properties: `timeSinceLaunch`, `calendar`, `timeZone`
5. Value semantics (struct with copy-on-write for dictionaries)

**Acceptance Criteria**:

- [ ] All properties publicly accessible
- [ ] Builder pattern creates new instances (immutability)
- [ ] Dictionary lookups return sensible defaults
- [ ] Date arithmetic correct across timezones
- [ ] Performance: context creation < 1μs

### 5.6 Default Context Provider

**File**: `Sources/SpecificationCore/Context/DefaultContextProvider.swift`

**Requirements**:

1. Thread-safe singleton: `DefaultContextProvider.shared`
2. Mutable state: counters, events, flags, userData, contextProviders
3. Counter operations: `setCounter(_:to:)`, `incrementCounter(_:by:)`, `decrementCounter(_:by:)`, `getCounter(_:)`, `resetCounter(_:)`
4. Event operations: `recordEvent(_:)`, `recordEvent(_:at:)`, `getEvent(_:)`, `removeEvent(_:)`
5. Flag operations: `setFlag(_:to:)`, `toggleFlag(_:)`, `getFlag(_:)`
6. UserData operations: `setUserData(_:to:)`, `getUserData(_:as:)`, `removeUserData(_:)`
7. Bulk operations: `clearAll()`, `clearCounters()`, `clearEvents()`, `clearFlags()`, `clearUserData()`
8. Context registration: `register(contextKey:provider:)`, `unregister(contextKey:)`
9. Combine support (optional): `objectWillChange` publisher, `contextUpdates`, `contextStream`
10. Lock-based synchronization (NSLock)

**Acceptance Criteria**:

- [ ] All operations thread-safe (tested with TSan)
- [ ] Singleton accessible globally
- [ ] Combine features compile conditionally
- [ ] No deadlocks under concurrent load
- [ ] Memory usage < 10KB for 100 counters/flags

### 5.7 Basic Specifications

**Files**: `Sources/SpecificationCore/Specs/*.swift`

**7.1 PredicateSpec**:

- Wraps closure `(T) -> Bool`
- Generic over candidate type
- Inlinable for performance

**7.2 FirstMatchSpec**:

- Evaluates array of `(DecisionSpec, Result)` pairs
- Returns first matching result
- Short-circuit evaluation

**7.3 MaxCountSpec**:

- Checks `context.counter(for: key) <= maximumCount`
- Requires `EvaluationContext`
- Counter key configurable

**7.4 CooldownIntervalSpec**:

- Checks time since event > interval
- Requires `EvaluationContext`
- Event key and interval configurable

**7.5 TimeSinceEventSpec**:

- Checks time since event meets criteria
- Comparison operators: ==, <, >, <=, >=
- Requires `EvaluationContext`

**7.6 DateRangeSpec**:

- Checks date in range [start, end]
- Supports open/closed intervals
- Timezone-aware comparisons

**7.7 DateComparisonSpec**:

- Compares dates with operators
- Calendar component comparisons
- Supports relative dates

**Acceptance Criteria (All Specs)**:

- [ ] Each spec has dedicated test file
- [ ] Edge cases covered (nil events, zero counters, etc.)
- [ ] Documentation examples compile
- [ ] Performance benchmarks pass (< 1μs evaluation)
- [ ] Thread-safe evaluation

### 5.8 Property Wrappers

**Files**: `Sources/SpecificationCore/Wrappers/*.swift`

**8.1 @Satisfies**:

```swift
@propertyWrapper
public struct Satisfies<S: Specification> {
    private let specification: S
    private let provider: any ContextProviding<S.T>

    public var wrappedValue: Bool { get }
    public var projectedValue: Self { get }
}
```

**8.2 @Decides**:

```swift
@propertyWrapper
public struct Decides<Context, Result> {
    private let decisions: [(any DecisionSpec<Context, Result>, Result)]
    private let fallback: Result
    private let provider: any ContextProviding<Context>

    public var wrappedValue: Result { get }
    public var projectedValue: Self { get }
}
```

**8.3 @Maybe**:

```swift
@propertyWrapper
public struct Maybe<Context, Result> {
    private let decisions: [(any DecisionSpec<Context, Result>, Result)]
    private let provider: any ContextProviding<Context>

    public var wrappedValue: Result? { get }
    public var projectedValue: Self { get }
}
```

**8.4 @AsyncSatisfies**:

```swift
@propertyWrapper
public struct AsyncSatisfies<S: AsyncSpecification> {
    private let specification: S
    private let provider: any ContextProviding<S.T>

    public func evaluate() async throws -> Bool
    public var projectedValue: Self { get }
}
```

**Acceptance Criteria (All Wrappers)**:

- [ ] Property wrapper syntax compiles in Swift 5.10+
- [ ] Projected values accessible via `$` prefix
- [ ] No SwiftUI dependencies
- [ ] Thread-safe concurrent reads
- [ ] Documentation includes usage examples

### 5.9 Macros

**Files**: `Sources/SpecificationCoreMacros/*.swift`

**9.1 @specs Macro**:

- Attached member macro
- Synthesizes composite specifications from struct properties
- Generates `.and()`, `.or()` combinations
- Validates property types are `Specification` conforming

**9.2 @AutoContext Macro**:

- Attached member attribute macro
- Injects `DefaultContextProvider.shared` automatically
- Reduces boilerplate in context-dependent specs
- Validates specification requires context

**Acceptance Criteria**:

- [ ] Macros tested with swift-macro-testing
- [ ] Diagnostic messages clear and actionable
- [ ] Expansion generates valid Swift code
- [ ] Fix-its provided for common errors
- [ ] Integration tests in main package

---

## 6. Dependencies

### 6.1 Required Dependencies

| Dependency | Version | Purpose | License |
|------------|---------|---------|---------|
| Foundation | Platform | Date, threading, collections | Apple |
| swift-syntax | 510.0.0+ | Macro implementation | Apache 2.0 |

### 6.2 Optional Dependencies

| Dependency | Version | Purpose | License |
|------------|---------|---------|---------|
| Combine | Platform | Reactive updates (optional) | Apple |

### 6.3 Development Dependencies

| Dependency | Version | Purpose | License |
|------------|---------|---------|---------|
| swift-macro-testing | 0.4.0+ | Macro testing utilities | MIT |
| XCTest | Platform | Unit testing | Apple |

---

## 7. Compatibility Matrix

### 7.1 Platform Support

| Platform | Minimum Version | Status |
|----------|----------------|--------|
| iOS | 13.0 | Supported |
| macOS | 10.15 | Supported |
| tvOS | 13.0 | Supported |
| watchOS | 6.0 | Supported |
| Linux | Ubuntu 20.04+ | Supported |
| Windows | Windows 10+ | Supported (with Swift 5.9+) |

### 7.2 Swift Version Support

| Swift Version | Status | Notes |
|---------------|--------|-------|
| 5.9 | Not Supported | Requires explicit justification to lower minimum version |
| 5.10 | Minimum | Required by SpecificationCore and SpecificationKit; improved macro diagnostics |
| 6.0 | Supported | Full concurrency checking |

---

## 8. Migration Plan

### 8.1 Phase 1: SpecificationCore Extraction (Week 1-2)

**Goal**: Create new package with core components

**Tasks**:

1. Create SpecificationCore package structure
2. Copy core protocols to new package
3. Copy context infrastructure to new package
4. Copy basic specs to new package
5. Copy property wrappers (platform-independent only)
6. Copy macros to new package
7. Update Package.swift dependencies
8. Configure CI/CD for new package

**Deliverables**:

- [ ] SpecificationCore compiles independently
- [ ] All core tests pass in new package
- [ ] CI builds SpecificationCore successfully

### 8.2 Phase 2: SpecificationKit Refactoring (Week 3-4)

**Goal**: Make SpecificationKit depend on SpecificationCore

**Tasks**:

1. Add SpecificationCore as dependency to SpecificationKit
2. Remove duplicated code from SpecificationKit
3. Re-export core APIs for backward compatibility
4. Update platform-specific providers to use core protocols
5. Update SwiftUI wrappers to use core types
6. Migrate tests to use appropriate package
7. Update documentation to reference both packages

**Deliverables**:

- [ ] SpecificationKit builds with SpecificationCore dependency
- [ ] All SpecificationKit tests pass
- [ ] Zero breaking changes to public API
- [ ] Documentation updated

### 8.3 Phase 3: Validation & Documentation (Week 5)

**Goal**: Ensure migration correctness and update docs

**Tasks**:

1. Run full test suite on all platforms
2. Benchmark performance before/after
3. Update README files
4. Create migration guide
5. Update API documentation
6. Release notes preparation
7. Version tagging

**Deliverables**:

- [ ] Test coverage maintained at 90%+
- [ ] Performance regressions < 5%
- [ ] Migration guide published
- [ ] Release candidate tagged

### 8.4 Phase 4: Release & Deprecation (Week 6+)

**Goal**: Publish packages and begin deprecation cycle

**Tasks**:

1. Publish SpecificationCore 1.0.0
2. Publish SpecificationKit 4.0.0 (depends on Core)
3. Announce deprecation timeline
4. Monitor GitHub issues for migration problems
5. Provide community support
6. Plan future platform-specific packages

**Deliverables**:

- [ ] Packages published to SPM registry
- [ ] Release announcement posted
- [ ] Community feedback addressed
- [ ] Roadmap for SpecificationKit-iOS, etc.

---

## 9. Security Considerations

### 9.1 Thread Safety

**Requirement**: All mutable state must be protected

**Implementation**:

- `DefaultContextProvider` uses `NSLock` for all mutations
- `EvaluationContext` is immutable struct (value semantics)
- Property wrappers are stateless (compute on demand)
- No global mutable state outside `DefaultContextProvider.shared`

**Verification**:

- [ ] TSan (Thread Sanitizer) passes on all tests
- [ ] Concurrent stress tests (1000+ threads) pass
- [ ] No data races detected

### 9.2 Input Validation

**Requirement**: Validate all public API inputs

**Implementation**:

- Counter keys: empty string validation
- Event keys: empty string validation
- Date ranges: start <= end validation
- Counts: negative value prevention
- Type casting: safe downcasting with `as?`

**Verification**:

- [ ] Fuzz testing on public APIs
- [ ] Edge case tests (empty strings, nil, max values)
- [ ] Assertion failures in debug builds

### 9.3 Memory Safety

**Requirement**: No unsafe operations

**Implementation**:

- No `unsafeBitCast`, `UnsafePointer` usage
- No force unwrapping (`!`) in production code
- No force-try (`try!`) except in tests
- No implicit optional unwrapping in stored properties
- Prefer `guard let` and `if let` for optionals

**Verification**:

- [ ] ASan (Address Sanitizer) passes
- [ ] No compiler warnings
- [ ] Code review checklist enforced

### 9.4 Denial of Service Prevention

**Requirement**: Prevent resource exhaustion

**Implementation**:

- Counter limits: Int.max natural limit
- Dictionary size limits: no unbounded growth
- Event storage: manual cleanup required
- Specification depth: no limit (stack overflow possible, documented)

**Mitigation**:

- Document max recommended counters/flags (10,000)
- Provide `clearAll()` cleanup APIs
- Monitor memory usage in production

**Verification**:

- [ ] Stress tests with 100,000 counters
- [ ] Memory leak detection with Instruments
- [ ] Documentation warns about limits

---

## 10. Performance Requirements

### 10.1 Compilation Performance

| Metric | Target | Measurement |
|--------|--------|-------------|
| Clean build time (Debug) | < 10s | `swift build --clean` on CI |
| Incremental build (Debug) | < 2s | Change 1 file, rebuild |
| Clean build time (Release) | < 30s | `swift build -c release --clean` |

### 10.2 Runtime Performance

| Operation | Target | Measurement |
|-----------|--------|-------------|
| Specification.isSatisfiedBy() | < 1μs | Simple predicate spec |
| Context creation | < 1μs | DefaultContextProvider.currentContext() |
| Counter increment | < 100ns | incrementCounter() |
| Flag set | < 100ns | setFlag() |
| Type-erased evaluation | < 1.5μs | AnySpecification.isSatisfiedBy() |

### 10.3 Memory Performance

| Metric | Target | Measurement |
|--------|--------|-------------|
| AnySpecification size | 24 bytes | MemoryLayout.size |
| EvaluationContext (empty) | < 200 bytes | MemoryLayout.size |
| DefaultContextProvider | < 10KB + data | Instruments heap allocation |

---

## 11. Testing Strategy

### 11.1 Unit Tests

**Coverage Target**: 90% line coverage minimum

**Test Categories**:

1. **Core Protocol Tests** (CoreTests/)
   - Specification composition (and, or, not)
   - DecisionSpec behavior
   - AsyncSpecification async/await
   - ContextProviding implementations

2. **Context Tests** (ContextTests/)
   - EvaluationContext builders
   - DefaultContextProvider thread safety
   - MockContextProvider mocking

3. **Spec Tests** (SpecTests/)
   - Each spec type (7 files)
   - Edge cases (nil, zero, max)
   - Date/time handling across timezones

4. **Wrapper Tests** (WrapperTests/)
   - Property wrapper syntax
   - Projected value access
   - Context provider injection

5. **Macro Tests** (MacroTests/)
   - Expansion correctness
   - Diagnostic messages
   - Fix-it suggestions

### 11.2 Integration Tests

**Test Scenarios**:

1. Multi-spec composition (10+ specs combined)
2. Async spec with network simulation
3. Concurrent context mutations (1000 threads)
4. Property wrapper in real struct
5. Macro expansion in real project

### 11.3 Performance Tests

**Benchmark Suite**:

1. Specification evaluation (1M iterations)
2. Context creation (100K iterations)
3. Counter operations (1M operations)
4. Type-erased overhead comparison
5. Compile time tracking

### 11.4 Platform Tests

**CI Matrix**:

- macOS 13+ (Xcode 15+)
- Ubuntu 20.04 (Swift 5.10)
- Ubuntu 22.04 (Swift 6.0)
- iOS 17+ simulator
- watchOS 10+ simulator

---

## 12. Acceptance Criteria

### 12.1 Functional Requirements

- [ ] SpecificationCore compiles on all target platforms without errors or warnings
- [ ] All 25 core public types implemented and documented
- [ ] All basic specifications (7 types) implemented with tests
- [ ] All property wrappers (4 types) functional without SwiftUI
- [ ] Both macros (@specs, @AutoContext) expand correctly
- [ ] Thread safety verified with TSan on all mutable types
- [ ] Memory safety verified with ASan

### 12.2 Performance Requirements

- [ ] Core module compiles in < 10 seconds (Debug, CI)
- [ ] Specification evaluation < 1μs (simple predicate)
- [ ] Context creation < 1μs
- [ ] Type erasure overhead < 50% vs direct call
- [ ] No memory leaks detected (Instruments)

### 12.3 Quality Requirements

- [ ] Test coverage ≥ 90% line coverage
- [ ] All public APIs have documentation comments
- [ ] README includes quick start guide
- [ ] CHANGELOG documents all changes
- [ ] Migration guide from SpecificationKit provided
- [ ] API reference generated with DocC

### 12.4 Compatibility Requirements

- [ ] SpecificationKit 2.0 builds with SpecificationCore dependency
- [ ] All SpecificationKit existing tests pass (no regressions)
- [ ] Zero breaking changes to SpecificationKit public API
- [ ] Backward compatibility maintained for 6 months
- [ ] Version tagged for SemVer compliance

### 12.5 Security Requirements

- [ ] No data races (TSan clean)
- [ ] No memory corruption (ASan clean)
- [ ] No force unwrapping in production code
- [ ] All inputs validated in public APIs
- [ ] Denial-of-service mitigations documented

### 12.6 Documentation Requirements

- [ ] README.md with overview and quick start
- [ ] CHANGELOG.md with version history
- [ ] API reference (DocC or similar)
- [ ] Migration guide (SpecificationKit → Core)
- [ ] Architecture decision records (ADRs)
- [ ] Performance benchmark results published

---

## 13. Open Questions

### 13.1 Versioning Strategy

**Question**: Should SpecificationCore start at 1.0.0 or 0.1.0?

**Options**:

- **A**: Start at 1.0.0 to signal production-ready stability
- **B**: Start at 0.1.0 for beta period, graduate to 1.0.0 after validation

**Recommendation**: Option B - start at 0.1.0, stabilize for 1 month, then 1.0.0

### 13.2 Combine Dependency Strategy

**Question**: Should Combine support be in core or separate package?

**Options**:

- **A**: Keep in core with `#if canImport(Combine)`
- **B**: Separate package `SpecificationCore-Combine`
- **C**: Remove Combine entirely, async/await only

**Recommendation**: Option A - conditional compilation maintains simplicity

### 13.3 Macro Packaging

**Question**: Should macros be in same package or separate?

**Options**:

- **A**: Same package (current SPM standard)
- **B**: Separate `SpecificationCore-Macros` package

**Recommendation**: Option A - SPM best practice for macros

### 13.4 Linux/Windows Support Priority

**Question**: Should Linux/Windows be P0 or P1?

**Options**:

- **A**: P0 - block 1.0.0 release on Linux/Windows CI passing
- **B**: P1 - best-effort support, community-driven

**Recommendation**: Option B - focus on Apple platforms first, Linux/Windows community-validated

---

## 14. Success Metrics (3 Months Post-Launch)

| Metric | Target | Measurement Method |
|--------|--------|-------------------|
| GitHub Stars | 100+ | GitHub API |
| SPM Dependents | 10+ projects | Swift Package Index |
| Build Time Reduction | 20%+ | CI benchmarks |
| Issue Resolution Time | < 7 days | GitHub metrics |
| Breaking Bug Reports | < 5 | GitHub issues |
| Documentation Completeness | 100% public APIs | DocC coverage |
| Community PRs | 5+ merged | GitHub stats |

---

## 15. Risks and Mitigations

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Breaking existing SpecificationKit users | Medium | High | Comprehensive test suite, gradual migration path, 6-month deprecation |
| Performance regression | Low | High | Benchmark suite in CI, performance gates |
| Macro complexity | Medium | Medium | Extensive macro tests, clear diagnostics, fallback to manual code |
| Platform incompatibility | Low | Medium | CI matrix on all platforms, community testing |
| Security vulnerability | Low | High | Thread sanitizer, address sanitizer, code review, input validation |
| Documentation gaps | Medium | Low | Documentation coverage tools, community feedback |
| Maintenance burden | Medium | Medium | Clear contributor guidelines, automated releases |

---

## Appendix A: File Migration Matrix

| Current Path (SpecificationKit) | New Path (SpecificationCore) | Action | Notes |
|----------------------------------|------------------------------|--------|-------|
| `Core/Specification.swift` | `Core/Specification.swift` | **Move** | No changes |
| `Core/DecisionSpec.swift` | `Core/DecisionSpec.swift` | **Move** | No changes |
| `Core/AsyncSpecification.swift` | `Core/AsyncSpecification.swift` | **Move** | No changes |
| `Core/ContextProviding.swift` | `Core/ContextProviding.swift` | **Move** | Combine optional |
| `Core/AnySpecification.swift` | `Core/AnySpecification.swift` | **Move** | No changes |
| `Core/AnyContextProvider.swift` | `Core/AnyContextProvider.swift` | **Move** | If exists |
| `Providers/EvaluationContext.swift` | `Context/EvaluationContext.swift` | **Move** | Rename directory |
| `Providers/ContextValue.swift` | `Context/ContextValue.swift` | **Move** | Rename directory |
| `Providers/DefaultContextProvider.swift` | `Context/DefaultContextProvider.swift` | **Move** | Combine optional |
| `Providers/MockContextProvider.swift` | `Context/MockContextProvider.swift` | **Move** | Testing only |
| `Specs/PredicateSpec.swift` | `Specs/PredicateSpec.swift` | **Move** | No changes |
| `Specs/FirstMatchSpec.swift` | `Specs/FirstMatchSpec.swift` | **Move** | No changes |
| `Specs/MaxCountSpec.swift` | `Specs/MaxCountSpec.swift` | **Move** | No changes |
| `Specs/CooldownIntervalSpec.swift` | `Specs/CooldownIntervalSpec.swift` | **Move** | No changes |
| `Specs/TimeSinceEventSpec.swift` | `Specs/TimeSinceEventSpec.swift` | **Move** | No changes |
| `Specs/DateRangeSpec.swift` | `Specs/DateRangeSpec.swift` | **Move** | No changes |
| `Specs/DateComparisonSpec.swift` | `Specs/DateComparisonSpec.swift` | **Move** | No changes |
| `Wrappers/Satisfies.swift` | `Wrappers/Satisfies.swift` | **Move** | Remove SwiftUI |
| `Wrappers/Decides.swift` | `Wrappers/Decides.swift` | **Move** | Remove SwiftUI |
| `Wrappers/Maybe.swift` | `Wrappers/Maybe.swift` | **Move** | Remove SwiftUI |
| `Wrappers/AsyncSatisfies.swift` | `Wrappers/AsyncSatisfies.swift` | **Move** | Remove SwiftUI |
| `Definitions/AutoContextSpecification.swift` | `Definitions/AutoContextSpecification.swift` | **Move** | No changes |
| `Definitions/CompositeSpec.swift` | `Definitions/CompositeSpec.swift` | **Move** | If platform-independent |
| `SpecificationKitMacros/SpecMacro.swift` | `SpecificationCoreMacros/SpecMacro.swift` | **Move** | Rename target |
| `SpecificationKitMacros/AutoContextMacro.swift` | `SpecificationCoreMacros/AutoContextMacro.swift` | **Move** | Rename target |
| `SpecificationKitMacros/MacroPlugin.swift` | `SpecificationCoreMacros/MacroPlugin.swift` | **Move** | Rename target |
| `Wrappers/ObservedSatisfies.swift` | — | **Keep in Kit** | SwiftUI dependency |
| `Wrappers/ObservedMaybe.swift` | — | **Keep in Kit** | SwiftUI dependency |
| `Wrappers/ObservedDecides.swift` | — | **Keep in Kit** | SwiftUI dependency |
| `Providers/MacOSSystemContextProvider.swift` | — | **Keep in Kit** | Platform-specific |
| `Providers/WatchOSContextProviders.swift` | — | **Keep in Kit** | Platform-specific |
| `Providers/AppleTVContextProvider.swift` | — | **Keep in Kit** | Platform-specific |
| `Providers/DeviceContextProvider.swift` | — | **Keep in Kit** | Platform-specific |
| `Providers/LocationContextProvider.swift` | — | **Keep in Kit** | Platform-specific |
| `Specs/FeatureFlagSpec.swift` | — | **Keep in Kit** | Domain-specific |
| `Specs/SubscriptionStatusSpec.swift` | — | **Keep in Kit** | Domain-specific |
| `Specs/UserSegmentSpec.swift` | — | **Keep in Kit** | Domain-specific |
| `Specs/WeightedSpec.swift` | — | **Keep in Kit** | Advanced feature |
| `Specs/HistoricalSpec.swift` | — | **Keep in Kit** | Advanced feature |
| `Specs/ComparativeSpec.swift` | — | **Keep in Kit** | Advanced feature |
| `Specs/ThresholdSpec.swift` | — | **Keep in Kit** | Advanced feature |
| `Utils/PerformanceProfiler.swift` | — | **Keep in Kit** | Utility |
| `Utils/SpecificationTracer.swift` | — | **Keep in Kit** | Utility |
| `Examples/DiscountExample.swift` | — | **Keep in Kit** | Example code |
| `Documentation.docc/*` | — | **Keep in Kit** | Tutorials |

---

## Appendix B: Glossary

| Term | Definition |
|------|------------|
| **Specification Pattern** | A design pattern for encapsulating business rules as composable objects that can be evaluated against candidates |
| **DecisionSpec** | A specification that returns typed results beyond boolean satisfaction |
| **Type Erasure** | A technique to hide concrete types behind protocol boundaries using `Any` wrappers |
| **Context Provider** | An object responsible for creating evaluation context containing runtime state |
| **Property Wrapper** | Swift language feature for abstracting property access patterns with custom logic |
| **Macro** | Compile-time code generation feature in Swift 5.9+ using swift-syntax |
| **Platform-Independent** | Code that compiles and runs on all Swift-supported platforms without platform-specific imports |
| **Thread-Safe** | Code that behaves correctly when accessed concurrently from multiple threads |
| **Inlinable** | Swift attribute allowing function implementation to be embedded at call sites for performance |
| **TSan** | Thread Sanitizer - tool for detecting data races |
| **ASan** | Address Sanitizer - tool for detecting memory errors |

---

## Document Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | 2025-11-16 | AI Agent | Initial PRD creation |

---

**END OF PRD**
