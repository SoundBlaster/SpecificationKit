# SpecificationCore TODO Matrix

## Document Metadata

| Field | Value |
|-------|-------|
| **Project** | SpecificationCore |
| **Type** | Task Breakdown |
| **Status** | Active |
| **Created** | 2025-11-16 |
| **Related** | PRD.md, Workplan.md |

---

## Priority Legend

- **P0**: Critical - Blocks release, must be done first
- **P1**: High - Core functionality, required for v1.0
- **P2**: Medium - Important but not blocking
- **P3**: Low - Nice-to-have, future enhancement

## Task Type Legend

- **[Setup]**: Infrastructure and scaffolding
- **[Move]**: File migration from SpecificationKit
- **[Refactor]**: Code modification during migration
- **[API-Cut]**: API surface reduction
- **[Test]**: Testing task
- **[Validation]**: Quality assurance
- **[Docs]**: Documentation task
- **[Release]**: Release management

---

## Phase 1: SpecificationCore Package Creation (Week 1-2)

### 1.1 Package Infrastructure (P0)

#### Setup Tasks

- [ ] **[P0] [Setup]** Create `SpecificationCore/` root directory
- [ ] **[P0] [Setup]** Create `Package.swift` manifest
  - Swift 5.10+ tools version minimum
  - Platforms: iOS 13+, macOS 10.15+, tvOS 13+, watchOS 6+
  - Foundation dependency
  - swift-syntax 510.0.0+ dependency
  - Products: SpecificationCore library
  - Targets: SpecificationCore, SpecificationCoreMacros, SpecificationCoreTests
- [ ] **[P0] [Setup]** Create directory structure
  - `Sources/SpecificationCore/Core/`
  - `Sources/SpecificationCore/Context/`
  - `Sources/SpecificationCore/Specs/`
  - `Sources/SpecificationCore/Wrappers/`
  - `Sources/SpecificationCore/Definitions/`
  - `Sources/SpecificationCoreMacros/`
  - `Tests/SpecificationCoreTests/CoreTests/`
  - `Tests/SpecificationCoreTests/ContextTests/`
  - `Tests/SpecificationCoreTests/SpecTests/`
  - `Tests/SpecificationCoreTests/WrapperTests/`
  - `Tests/SpecificationCoreTests/MacroTests/`
- [ ] **[P0] [Docs]** Create README.md with overview, installation, quick start
- [ ] **[P0] [Docs]** Create CHANGELOG.md (initial 0.1.0 entry)
- [ ] **[P0] [Setup]** Create LICENSE file (match SpecificationKit license)
- [ ] **[P0] [Setup]** Create `.gitignore` for Swift Package
- [ ] **[P2] [Setup]** Create `.swiftformat` configuration
- [ ] **[P0] [Validation]** Verify `swift package resolve` succeeds
- [ ] **[P0] [Validation]** Verify `swift build` succeeds (empty targets)

### 1.2 Core Protocols Migration (P0)

#### Specification Protocol

- [ ] **[P0] [Move]** Copy `Core/Specification.swift` from SpecificationKit
  - Base `Specification<T>` protocol
  - `isSatisfiedBy(_:)` method
  - `AndSpecification`, `OrSpecification`, `NotSpecification` structs
  - Extension methods: `.and(_:)`, `.or(_:)`, `.not()`
- [ ] **[P0] [Validation]** Verify no platform-specific imports (only Foundation)
- [ ] **[P0] [Test]** Create `CoreTests/SpecificationTests.swift`
  - Test boolean logic (and, or, not)
  - Test composition (nested specs)
  - Test short-circuit evaluation
  - Test thread safety (concurrent evaluation)
- [ ] **[P1] [Docs]** Add inline documentation examples
- [ ] **[P1] [Validation]** Achieve 95%+ test coverage

#### DecisionSpec Protocol

- [ ] **[P0] [Move]** Copy `Core/DecisionSpec.swift` from SpecificationKit
  - `DecisionSpec<Context, Result>` protocol
  - `decide(_:) -> Result?` method
  - `BooleanDecisionAdapter` struct
  - `PredicateDecisionSpec` struct
  - `AnyDecisionSpec` type erasure
  - `.returning(_:)` extension on Specification
- [ ] **[P0] [Test]** Create `CoreTests/DecisionSpecTests.swift`
  - Test decision returning
  - Test boolean adapter
  - Test predicate decision
  - Test type erasure
  - Test nil results
- [ ] **[P1] [Validation]** Achieve 95%+ test coverage

#### AsyncSpecification Protocol

- [ ] **[P0] [Move]** Copy `Core/AsyncSpecification.swift` from SpecificationKit
  - `AsyncSpecification<T>` protocol
  - `isSatisfiedBy(_:) async throws -> Bool` method
  - `AnyAsyncSpecification` type erasure
  - Sync-to-async bridge extension
- [ ] **[P0] [Test]** Create `CoreTests/AsyncSpecificationTests.swift`
  - Test async evaluation
  - Test error propagation
  - Test sync-to-async bridge
  - Test cancellation support
  - Test concurrent async evaluation
- [ ] **[P1] [Validation]** Verify no memory leaks with Instruments
- [ ] **[P1] [Validation]** Achieve 95%+ test coverage

#### ContextProviding Protocol

- [ ] **[P0] [Move]** Copy `Core/ContextProviding.swift` from SpecificationKit
  - `ContextProviding<Context>` protocol
  - `currentContext() -> Context` method
  - `currentContextAsync() async throws -> Context` default implementation
  - `GenericContextProvider` struct
  - `StaticContextProvider` struct
- [ ] **[P0] [Refactor]** Make Combine support optional
  - Wrap `ContextUpdatesProviding` protocol in `#if canImport(Combine)`
  - Wrap `contextUpdates`, `contextStream` in conditional compilation
- [ ] **[P0] [Test]** Create `CoreTests/ContextProvidingTests.swift`
  - Test generic provider
  - Test static provider
  - Test async bridging
  - Test Combine features (conditional)
- [ ] **[P1] [Validation]** Test compiles without Combine on Linux
- [ ] **[P1] [Validation]** Achieve 95%+ test coverage

#### AnySpecification Type Erasure

- [ ] **[P0] [Move]** Copy `Core/AnySpecification.swift` from SpecificationKit
  - `AnySpecification<T>` struct
  - Storage enum (predicate, specification, constantTrue, constantFalse)
  - `@inlinable` methods for performance
  - Collection extensions (allSatisfied, anySatisfied)
- [ ] **[P0] [Test]** Create `CoreTests/AnySpecificationTests.swift`
  - Test type erasure
  - Test constant optimizations
  - Test collection combinators
  - Test performance (< 50ns overhead)
- [ ] **[P1] [Validation]** Benchmark against direct predicate calls
- [ ] **[P1] [Validation]** Achieve 95%+ test coverage

#### AnyContextProvider Type Erasure

- [ ] **[P1] [Move]** Create `Core/AnyContextProvider.swift` (if not in SpecificationKit)
  - `AnyContextProvider<Context>` struct
  - Type-erased ContextProviding wrapper
  - Generic initializers
- [ ] **[P1] [Test]** Create `CoreTests/AnyContextProviderTests.swift`
  - Test type erasure
  - Test context retrieval
- [ ] **[P2] [Validation]** Achieve 90%+ test coverage

### 1.3 Context Infrastructure Migration (P0)

#### EvaluationContext

- [ ] **[P0] [Move]** Copy `Providers/EvaluationContext.swift` to `Context/EvaluationContext.swift`
  - Struct with properties: currentDate, launchDate, userData, counters, events, flags, segments
  - Convenience accessors: `counter(for:)`, `event(for:)`, `flag(for:)`, `userData(for:as:)`, `timeSinceEvent(_:)`
  - Computed properties: `timeSinceLaunch`, `calendar`, `timeZone`
  - Builder methods: `withUserData(_:)`, `withCounters(_:)`, `withEvents(_:)`, `withFlags(_:)`, `withCurrentDate(_:)`
- [ ] **[P0] [Test]** Create `ContextTests/EvaluationContextTests.swift`
  - Test property access
  - Test convenience methods
  - Test builder pattern (immutability)
  - Test date arithmetic
  - Test nil handling
- [ ] **[P1] [Validation]** Benchmark context creation (< 1μs)
- [ ] **[P1] [Validation]** Achieve 90%+ test coverage

#### ContextValue

- [ ] **[P1] [Move]** Copy `Providers/ContextValue.swift` to `Context/ContextValue.swift`
  - Dynamic value wrapper (if exists)
- [ ] **[P1] [Test]** Create `ContextTests/ContextValueTests.swift`
  - Test value wrapping
  - Test type casting
- [ ] **[P2] [Validation]** Achieve 90%+ test coverage

#### DefaultContextProvider

- [ ] **[P0] [Move]** Copy `Providers/DefaultContextProvider.swift` to `Context/DefaultContextProvider.swift`
  - Class with shared singleton
  - Thread-safe mutable state (NSLock)
  - Counter operations: setCounter, incrementCounter, decrementCounter, getCounter, resetCounter
  - Event operations: recordEvent, getEvent, removeEvent
  - Flag operations: setFlag, toggleFlag, getFlag
  - UserData operations: setUserData, getUserData, removeUserData
  - Bulk operations: clearAll, clearCounters, clearEvents, clearFlags, clearUserData
  - Context registration: register, unregister
- [ ] **[P0] [Refactor]** Make Combine support optional
  - Wrap `#if canImport(Combine)` around objectWillChange, contextUpdates, contextStream
  - Conditional send() calls
- [ ] **[P0] [Test]** Create `ContextTests/DefaultContextProviderTests.swift`
  - Test counter operations
  - Test event operations
  - Test flag operations
  - Test userData operations
  - Test bulk operations
  - Test thread safety (concurrent mutations)
  - Test Combine features (conditional)
- [ ] **[P0] [Validation]** Run TSan (Thread Sanitizer) - must pass
- [ ] **[P1] [Validation]** Stress test with 1000 concurrent threads
- [ ] **[P1] [Validation]** Benchmark operations (counter inc < 100ns)
- [ ] **[P1] [Validation]** Achieve 90%+ test coverage

#### MockContextProvider

- [ ] **[P1] [Move]** Copy `Providers/MockContextProvider.swift` to `Context/MockContextProvider.swift`
  - Simplified mock implementation for testing
- [ ] **[P1] [Test]** Create `ContextTests/MockContextProviderTests.swift`
  - Test mock behavior
  - Test test helper methods
- [ ] **[P2] [Validation]** Achieve 85%+ test coverage

### 1.4 Basic Specifications Migration (P0)

#### PredicateSpec

- [ ] **[P0] [Move]** Copy `Specs/PredicateSpec.swift`
  - Generic over candidate type T
  - Closure-based `(T) -> Bool` predicate
  - `@inlinable` for performance
- [ ] **[P0] [Test]** Create `SpecTests/PredicateSpecTests.swift`
  - Test closure evaluation
  - Test composition
  - Test performance (< 1μs)
- [ ] **[P1] [Validation]** Achieve 95%+ test coverage

#### FirstMatchSpec

- [ ] **[P0] [Move]** Copy `Specs/FirstMatchSpec.swift`
  - Array of `(DecisionSpec, Result)` pairs
  - First-match priority evaluation
  - Short-circuit on first match
- [ ] **[P0] [Test]** Create `SpecTests/FirstMatchSpecTests.swift`
  - Test first-match logic
  - Test short-circuit evaluation
  - Test empty array
  - Test no matches (nil result)
- [ ] **[P1] [Validation]** Achieve 95%+ test coverage

#### MaxCountSpec

- [ ] **[P0] [Move]** Copy `Specs/MaxCountSpec.swift`
  - Counter key parameter
  - Maximum count parameter
  - Evaluates `context.counter(for: key) <= maximumCount`
  - Requires `EvaluationContext`
- [ ] **[P0] [Test]** Create `SpecTests/MaxCountSpecTests.swift`
  - Test counter limit checks
  - Test zero counter
  - Test exact limit
  - Test over limit
- [ ] **[P1] [Validation]** Achieve 95%+ test coverage

#### CooldownIntervalSpec

- [ ] **[P0] [Move]** Copy `Specs/CooldownIntervalSpec.swift`
  - Event key parameter
  - Time interval parameter
  - Evaluates `timeSinceEvent(key) > interval`
  - Requires `EvaluationContext`
- [ ] **[P0] [Test]** Create `SpecTests/CooldownIntervalSpecTests.swift`
  - Test cooldown logic
  - Test missing event (nil)
  - Test exact interval boundary
  - Test timezone handling
- [ ] **[P1] [Validation]** Achieve 95%+ test coverage

#### TimeSinceEventSpec

- [ ] **[P0] [Move]** Copy `Specs/TimeSinceEventSpec.swift`
  - Event key parameter
  - Time interval parameter
  - Comparison operator parameter
  - Evaluates time comparisons
  - Requires `EvaluationContext`
- [ ] **[P0] [Test]** Create `SpecTests/TimeSinceEventSpecTests.swift`
  - Test all comparison operators
  - Test missing event
  - Test edge cases
- [ ] **[P1] [Validation]** Achieve 95%+ test coverage

#### DateRangeSpec

- [ ] **[P0] [Move]** Copy `Specs/DateRangeSpec.swift`
  - Start date parameter
  - End date parameter
  - Open/closed interval support
  - Timezone-aware comparisons
- [ ] **[P0] [Test]** Create `SpecTests/DateRangeSpecTests.swift`
  - Test date in range
  - Test date out of range
  - Test boundary conditions
  - Test timezone handling
- [ ] **[P1] [Validation]** Achieve 95%+ test coverage

#### DateComparisonSpec

- [ ] **[P0] [Move]** Copy `Specs/DateComparisonSpec.swift`
  - Comparison date parameter
  - Comparison operator parameter
  - Calendar component comparisons
  - Relative date support
- [ ] **[P0] [Test]** Create `SpecTests/DateComparisonSpecTests.swift`
  - Test all comparison operators
  - Test calendar components
  - Test relative dates
- [ ] **[P1] [Validation]** Achieve 95%+ test coverage

### 1.5 Property Wrappers Migration (P0)

#### @Satisfies Wrapper

- [ ] **[P0] [Move]** Copy `Wrappers/Satisfies.swift`
  - Generic over `Specification` type
  - Context provider parameter
  - Computed `wrappedValue: Bool`
  - Projected value `$` access
- [ ] **[P0] [Refactor]** Remove SwiftUI dependencies (if any)
  - No `@Published`, no `ObservableObject`
  - Platform-independent only
- [ ] **[P0] [Test]** Create `WrapperTests/SatisfiesTests.swift`
  - Test property wrapper syntax
  - Test evaluation
  - Test projected value
  - Test context provider injection
- [ ] **[P1] [Validation]** Achieve 90%+ test coverage

#### @Decides Wrapper

- [ ] **[P0] [Move]** Copy `Wrappers/Decides.swift`
  - Generic over Context, Result
  - Array of decisions parameter
  - Fallback result parameter
  - Computed `wrappedValue: Result` (non-optional)
- [ ] **[P0] [Refactor]** Remove SwiftUI dependencies (if any)
- [ ] **[P0] [Test]** Create `WrapperTests/DecidesTests.swift`
  - Test decision evaluation
  - Test fallback logic
  - Test projected value
- [ ] **[P1] [Validation]** Achieve 90%+ test coverage

#### @Maybe Wrapper

- [ ] **[P0] [Move]** Copy `Wrappers/Maybe.swift`
  - Generic over Context, Result
  - Array of decisions parameter
  - Computed `wrappedValue: Result?` (optional)
- [ ] **[P0] [Refactor]** Remove SwiftUI dependencies (if any)
- [ ] **[P0] [Test]** Create `WrapperTests/MaybeTests.swift`
  - Test optional result
  - Test no matches (nil)
  - Test projected value
- [ ] **[P1] [Validation]** Achieve 90%+ test coverage

#### @AsyncSatisfies Wrapper

- [ ] **[P1] [Move]** Copy `Wrappers/AsyncSatisfies.swift`
  - Generic over `AsyncSpecification` type
  - Async evaluation method
  - Error propagation
- [ ] **[P1] [Refactor]** Remove SwiftUI dependencies (if any)
- [ ] **[P1] [Test]** Create `WrapperTests/AsyncSatisfiesTests.swift`
  - Test async evaluation
  - Test error handling
  - Test cancellation
- [ ] **[P2] [Validation]** Achieve 90%+ test coverage

### 1.6 Macros Migration (P0)

#### Macro Plugin

- [ ] **[P0] [Move]** Copy `SpecificationKitMacros/MacroPlugin.swift` to `SpecificationCoreMacros/MacroPlugin.swift`
  - Rename target to SpecificationCoreMacros
  - Register @specs and @AutoContext macros
- [ ] **[P0] [Validation]** Verify macro plugin compiles

#### @specs Macro

- [ ] **[P0] [Move]** Copy `SpecificationKitMacros/SpecMacro.swift` to `SpecificationCoreMacros/SpecMacro.swift`
  - Attached member macro
  - Composite specification synthesis
  - Diagnostic messages
  - Fix-its for common errors
- [ ] **[P0] [Test]** Create `MacroTests/SpecMacroTests.swift`
  - Use swift-macro-testing framework
  - Test valid expansions
  - Test invalid inputs (diagnostics)
  - Test fix-its
- [ ] **[P1] [Validation]** Integration test in SpecificationCoreTests
- [ ] **[P1] [Validation]** Achieve 90%+ test coverage

#### @AutoContext Macro

- [ ] **[P0] [Move]** Copy `SpecificationKitMacros/AutoContextMacro.swift` to `SpecificationCoreMacros/AutoContextMacro.swift`
  - Member attribute macro
  - DefaultContextProvider.shared injection
  - Diagnostic messages
- [ ] **[P0] [Test]** Create `MacroTests/AutoContextMacroTests.swift`
  - Test valid expansions
  - Test diagnostics
  - Test integration
- [ ] **[P1] [Validation]** Achieve 90%+ test coverage

### 1.7 Definitions Migration (P1)

#### AutoContextSpecification

- [ ] **[P1] [Move]** Copy `Definitions/AutoContextSpecification.swift`
  - Base protocol for auto-context specs
- [ ] **[P1] [Test]** Create `DefinitionsTests/AutoContextSpecificationTests.swift`
  - Test protocol conformance
  - Test integration with macro
- [ ] **[P2] [Validation]** Achieve 85%+ test coverage

#### CompositeSpec

- [ ] **[P1] [Move]** Copy `Definitions/CompositeSpec.swift` (if platform-independent)
  - Predefined composite specifications
- [ ] **[P1] [Test]** Create `DefinitionsTests/CompositeSpecTests.swift`
  - Test predefined composites
- [ ] **[P2] [Validation]** Achieve 85%+ test coverage

### 1.8 CI/CD Pipeline Setup (P0)

#### GitHub Actions Workflows

- [ ] **[P0] [Setup]** Create `.github/workflows/ci.yml`
  - Build on macOS (Xcode 15, Xcode 16)
  - Build on Linux (Ubuntu 20.04, Ubuntu 22.04, Swift 5.10, Swift 6.0)
  - Run tests on all platforms
  - Run TSan (Thread Sanitizer)
  - Run ASan (Address Sanitizer)
  - Run UBSan (Undefined Behavior Sanitizer)
  - Run swift-format linter
  - Generate code coverage report
  - Upload coverage to Codecov or similar
- [ ] **[P1] [Setup]** Create `.github/workflows/release.yml`
  - Trigger on tags (v*.*.*)
  - Build release binaries
  - Generate release notes from CHANGELOG
  - Create GitHub release
  - Publish to SPM registry (if available)
- [ ] **[P1] [Setup]** Configure branch protection rules
  - Require CI passing
  - Require code review
  - Protect main branch
- [ ] **[P2] [Setup]** Configure code coverage reporting
  - Codecov integration
  - Coverage badge in README

#### CI Validation

- [ ] **[P0] [Validation]** Verify CI runs on push to main
- [ ] **[P0] [Validation]** Verify all checks pass
- [ ] **[P0] [Validation]** Verify sanitizers enabled
- [ ] **[P1] [Validation]** Verify coverage reports generated

---

## Phase 2: SpecificationKit Refactoring (Week 3-4)

### 2.1 Dependency Integration (P0)

- [ ] **[P0] [Refactor]** Update `SpecificationKit/Package.swift`
  - Add SpecificationCore dependency (local path or git URL)
  - Add SpecificationCore to target dependencies
- [ ] **[P0] [Refactor]** Create `Sources/SpecificationKit/CoreReexports.swift`
  - Add `@_exported import SpecificationCore`
  - Ensure backward compatibility
- [ ] **[P0] [Validation]** Verify `import SpecificationKit` still works
- [ ] **[P0] [Validation]** Verify existing code compiles without changes

### 2.2 Code Removal (P0)

#### Remove Duplicate Core Files

- [ ] **[P0] [API-Cut]** Delete `Sources/SpecificationKit/Core/Specification.swift`
- [ ] **[P0] [API-Cut]** Delete `Sources/SpecificationKit/Core/DecisionSpec.swift`
- [ ] **[P0] [API-Cut]** Delete `Sources/SpecificationKit/Core/AsyncSpecification.swift`
- [ ] **[P0] [API-Cut]** Delete `Sources/SpecificationKit/Core/ContextProviding.swift`
- [ ] **[P0] [API-Cut]** Delete `Sources/SpecificationKit/Core/AnySpecification.swift`
- [ ] **[P0] [API-Cut]** Delete `Sources/SpecificationKit/Core/AnyContextProvider.swift` (if exists)
- [ ] **[P0] [API-Cut]** Delete `Sources/SpecificationKit/Core/` directory (if empty)

#### Remove Duplicate Context Files

- [ ] **[P0] [API-Cut]** Delete `Sources/SpecificationKit/Providers/EvaluationContext.swift`
- [ ] **[P0] [API-Cut]** Delete `Sources/SpecificationKit/Providers/ContextValue.swift`
- [ ] **[P0] [API-Cut]** Delete `Sources/SpecificationKit/Providers/DefaultContextProvider.swift`
- [ ] **[P0] [API-Cut]** Delete `Sources/SpecificationKit/Providers/MockContextProvider.swift`

#### Remove Duplicate Spec Files

- [ ] **[P0] [API-Cut]** Delete `Sources/SpecificationKit/Specs/PredicateSpec.swift`
- [ ] **[P0] [API-Cut]** Delete `Sources/SpecificationKit/Specs/FirstMatchSpec.swift`
- [ ] **[P0] [API-Cut]** Delete `Sources/SpecificationKit/Specs/MaxCountSpec.swift`
- [ ] **[P0] [API-Cut]** Delete `Sources/SpecificationKit/Specs/CooldownIntervalSpec.swift`
- [ ] **[P0] [API-Cut]** Delete `Sources/SpecificationKit/Specs/TimeSinceEventSpec.swift`
- [ ] **[P0] [API-Cut]** Delete `Sources/SpecificationKit/Specs/DateRangeSpec.swift`
- [ ] **[P0] [API-Cut]** Delete `Sources/SpecificationKit/Specs/DateComparisonSpec.swift`

#### Remove Duplicate Wrapper Files

- [ ] **[P0] [API-Cut]** Delete `Sources/SpecificationKit/Wrappers/Satisfies.swift` (base version)
- [ ] **[P0] [API-Cut]** Delete `Sources/SpecificationKit/Wrappers/Decides.swift` (base version)
- [ ] **[P0] [API-Cut]** Delete `Sources/SpecificationKit/Wrappers/Maybe.swift` (base version)
- [ ] **[P0] [API-Cut]** Delete `Sources/SpecificationKit/Wrappers/AsyncSatisfies.swift` (base version)

#### Remove Duplicate Definition Files

- [ ] **[P1] [API-Cut]** Delete `Sources/SpecificationKit/Definitions/AutoContextSpecification.swift`
- [ ] **[P1] [API-Cut]** Delete `Sources/SpecificationKit/Definitions/CompositeSpec.swift` (if moved)

#### Validation After Removal

- [ ] **[P0] [Validation]** Run `swift build` - must succeed
- [ ] **[P0] [Validation]** Run `swift test` - must pass
- [ ] **[P0] [Validation]** No duplicate symbols

### 2.3 Platform-Specific Updates (P1)

#### Update Platform Providers

- [ ] **[P1] [Refactor]** Update `Providers/MacOSSystemContextProvider.swift`
  - Import SpecificationCore
  - Use core types (EvaluationContext, ContextProviding)
- [ ] **[P1] [Refactor]** Update `Providers/WatchOSContextProviders.swift`
- [ ] **[P1] [Refactor]** Update `Providers/AppleTVContextProvider.swift`
- [ ] **[P1] [Refactor]** Update `Providers/DeviceContextProvider.swift`
- [ ] **[P1] [Refactor]** Update `Providers/LocationContextProvider.swift`
- [ ] **[P1] [Refactor]** Update `Providers/NetworkContextProvider.swift`
- [ ] **[P1] [Refactor]** Update `Providers/PersistentContextProvider.swift`
- [ ] **[P1] [Refactor]** Update `Providers/PlatformContextProviders.swift`
- [ ] **[P1] [Refactor]** Update `Providers/EnvironmentContextProvider.swift` (SwiftUI)
- [ ] **[P1] [Refactor]** Update `Providers/CompositeContextProvider.swift`
- [ ] **[P1] [Validation]** Run platform-specific tests
- [ ] **[P1] [Validation]** Verify imports correct

#### Update SwiftUI Wrappers

- [ ] **[P1] [Refactor]** Update `Wrappers/ObservedSatisfies.swift`
  - Import SpecificationCore
  - Use core Specification protocol
- [ ] **[P1] [Refactor]** Update `Wrappers/ObservedMaybe.swift`
- [ ] **[P1] [Refactor]** Update `Wrappers/ObservedDecides.swift`
- [ ] **[P1] [Refactor]** Update `Wrappers/ConditionalSatisfies.swift`
- [ ] **[P1] [Refactor]** Update `Wrappers/CachedSatisfies.swift`
- [ ] **[P1] [Refactor]** Update `Wrappers/Spec.swift` (if exists)
- [ ] **[P1] [Validation]** Run SwiftUI tests
- [ ] **[P1] [Validation]** Verify wrapper behavior unchanged

#### Update Advanced Specs

- [ ] **[P1] [Refactor]** Update `Specs/FeatureFlagSpec.swift`
- [ ] **[P1] [Refactor]** Update `Specs/SubscriptionStatusSpec.swift`
- [ ] **[P1] [Refactor]** Update `Specs/UserSegmentSpec.swift`
- [ ] **[P1] [Refactor]** Update `Specs/WeightedSpec.swift`
- [ ] **[P1] [Refactor]** Update `Specs/HistoricalSpec.swift`
- [ ] **[P1] [Refactor]** Update `Specs/ComparativeSpec.swift`
- [ ] **[P1] [Refactor]** Update `Specs/ThresholdSpec.swift`
- [ ] **[P1] [Validation]** Run spec tests

#### Update Utilities

- [ ] **[P2] [Refactor]** Update `Utils/PerformanceProfiler.swift`
- [ ] **[P2] [Refactor]** Update `Utils/SpecificationTracer.swift`
- [ ] **[P2] [Refactor]** Update `Utils/MockSpecificationBuilder.swift`

#### Update Examples

- [ ] **[P2] [Refactor]** Update `Examples/DiscountExample.swift`
- [ ] **[P2] [Refactor]** Update `Definitions/DiscountDecisionExample.swift`

### 2.4 Test Migration (P1)

#### Identify Core Tests to Remove

- [ ] **[P1] [API-Cut]** Remove core protocol tests from SpecificationKit
  - Specification composition tests
  - DecisionSpec tests
  - AsyncSpecification tests
  - ContextProviding tests
- [ ] **[P1] [API-Cut]** Remove context infrastructure tests
  - EvaluationContext tests
  - DefaultContextProvider tests
  - MockContextProvider tests
- [ ] **[P1] [API-Cut]** Remove basic spec tests
  - PredicateSpec, FirstMatchSpec, MaxCountSpec, etc.
- [ ] **[P1] [API-Cut]** Remove base wrapper tests
  - Satisfies, Decides, Maybe, AsyncSatisfies
- [ ] **[P1] [API-Cut]** Remove macro tests
  - @specs, @AutoContext

#### Keep Platform Tests

- [ ] **[P1] [Validation]** Keep SwiftUI wrapper tests
- [ ] **[P1] [Validation]** Keep platform provider tests
- [ ] **[P1] [Validation]** Keep advanced spec tests
- [ ] **[P1] [Validation]** Keep utility tests
- [ ] **[P1] [Validation]** Keep example tests

#### Run Full Test Suite

- [ ] **[P0] [Validation]** Run SpecificationCore tests - must pass
- [ ] **[P0] [Validation]** Run SpecificationKit tests - must pass
- [ ] **[P0] [Validation]** Verify coverage targets met
  - SpecificationCore: 90%+
  - SpecificationKit: 85%+

### 2.5 Documentation Updates (P1)

#### SpecificationCore Documentation

- [ ] **[P1] [Docs]** Finalize README.md
  - Overview and philosophy
  - Installation instructions (SPM)
  - Quick start guide
  - Basic examples
  - Link to API reference
  - Comparison with SpecificationKit
- [ ] **[P1] [Docs]** Finalize CHANGELOG.md
  - 0.1.0 release notes
  - Features included
  - Known limitations
- [ ] **[P1] [Docs]** Create API reference (DocC or inline docs)
  - All public types documented
  - Code examples for major features
  - Architecture overview
- [ ] **[P2] [Docs]** Create Contributing Guide (CONTRIBUTING.md)
  - How to contribute
  - Code style guidelines
  - Testing requirements
  - PR process

#### SpecificationKit Documentation

- [ ] **[P1] [Docs]** Update README.md
  - Note SpecificationCore dependency
  - Update installation instructions
  - Add "What's in SpecificationKit vs Core" section
  - Link to migration guide
- [ ] **[P1] [Docs]** Update CHANGELOG.md
  - 2.0.0 release notes
  - SpecificationCore extraction
  - Breaking changes (if any)
  - Deprecation warnings (if any)
  - Migration guide link
- [ ] **[P1] [Docs]** Create Migration Guide (MIGRATION.md)
  - When to use Core vs Kit
  - Migration steps for existing users
  - Code examples (before/after)
  - FAQ section
  - Troubleshooting
- [ ] **[P1] [Docs]** Update API documentation
  - Re-exported types link to SpecificationCore
  - Platform-specific features documented
  - SwiftUI integration documented

#### Documentation Validation

- [ ] **[P1] [Validation]** Verify all code examples compile
- [ ] **[P1] [Validation]** Verify links work
- [ ] **[P1] [Validation]** Peer review documentation
- [ ] **[P1] [Validation]** Spell check and grammar review

### 2.6 Version Bumping (P0)

#### SpecificationCore Versioning

- [ ] **[P0] [Release]** Set version to 0.1.0 in Package.swift
- [ ] **[P0] [Release]** Update CHANGELOG.md with 0.1.0 entry
- [ ] **[P0] [Release]** Tag git release: `specificationcore-0.1.0`
- [ ] **[P0] [Release]** Create GitHub release with notes

#### SpecificationKit Versioning

- [ ] **[P0] [Release]** Set version to 2.0.0 in Package.swift
- [ ] **[P0] [Release]** Update CHANGELOG.md with 2.0.0 entry
- [ ] **[P0] [Release]** Tag git release: `specificationkit-2.0.0`
- [ ] **[P0] [Release]** Create GitHub release with notes

#### SemVer Compliance

- [ ] **[P0] [Validation]** Verify SemVer compliance
- [ ] **[P0] [Validation]** Verify dependency versions correct
- [ ] **[P0] [Validation]** Verify backward compatibility maintained

---

## Phase 3: Validation & Documentation (Week 5)

### 3.1 Comprehensive Testing (P0)

#### Multi-Platform Testing

- [ ] **[P0] [Validation]** Run tests on macOS 13+ (Xcode 15)
- [ ] **[P0] [Validation]** Run tests on macOS 14+ (Xcode 16)
- [ ] **[P0] [Validation]** Run tests on Ubuntu 20.04 (Swift 5.10)
- [ ] **[P0] [Validation]** Run tests on Ubuntu 22.04 (Swift 6.0)
- [ ] **[P0] [Validation]** Run tests on iOS 17+ simulator
- [ ] **[P0] [Validation]** Run tests on watchOS 10+ simulator
- [ ] **[P0] [Validation]** Run tests on tvOS 17+ simulator
- [ ] **[P0] [Validation]** All tests pass on all platforms

#### Sanitizer Testing

- [ ] **[P0] [Validation]** Run TSan (Thread Sanitizer) - must pass
- [ ] **[P0] [Validation]** Run ASan (Address Sanitizer) - must pass
- [ ] **[P0] [Validation]** Run UBSan (Undefined Behavior Sanitizer) - must pass
- [ ] **[P0] [Validation]** Fix any sanitizer warnings

#### Code Coverage Analysis

- [ ] **[P0] [Validation]** Generate coverage report for SpecificationCore
- [ ] **[P0] [Validation]** Verify SpecificationCore coverage ≥ 90%
- [ ] **[P0] [Validation]** Generate coverage report for SpecificationKit
- [ ] **[P0] [Validation]** Verify SpecificationKit coverage ≥ 85%
- [ ] **[P1] [Validation]** Identify uncovered code
- [ ] **[P1] [Validation]** Add tests for critical uncovered paths

#### Integration Testing

- [ ] **[P1] [Validation]** Create sample project using SpecificationCore only
- [ ] **[P1] [Validation]** Create sample project using SpecificationKit 2.0
- [ ] **[P1] [Validation]** Test all major features in sample projects
- [ ] **[P1] [Validation]** Test migration scenarios (1.x → 2.0)
- [ ] **[P1] [Validation]** Verify backward compatibility

### 3.2 Performance Benchmarking (P1)

#### Benchmark Suite

- [ ] **[P1] [Validation]** Run specification evaluation benchmark (1M iterations)
- [ ] **[P1] [Validation]** Run context creation benchmark (100K iterations)
- [ ] **[P1] [Validation]** Run counter operations benchmark (1M operations)
- [ ] **[P1] [Validation]** Run type-erased overhead benchmark
- [ ] **[P1] [Validation]** Track compile time (clean build, incremental)

#### Performance Comparison

- [ ] **[P1] [Validation]** Measure baseline (SpecificationKit original)
- [ ] **[P1] [Validation]** Measure new (SpecificationKit 2.0 + Core)
- [ ] **[P1] [Validation]** Verify performance regression < 5%
- [ ] **[P1] [Validation]** Verify build time improvement ≥ 20% for Core-only projects
- [ ] **[P1] [Docs]** Document benchmark results in CHANGELOG

### 3.3 Documentation Finalization (P1)

- [ ] **[P1] [Docs]** Final review of SpecificationCore README
- [ ] **[P1] [Docs]** Final review of SpecificationKit README
- [ ] **[P1] [Docs]** Final review of Migration Guide
- [ ] **[P1] [Docs]** Final review of CHANGELOG files
- [ ] **[P1] [Docs]** Final review of API documentation
- [ ] **[P1] [Docs]** Spell check and grammar review
- [ ] **[P1] [Docs]** Verify all code examples compile
- [ ] **[P1] [Docs]** Peer review by team member

### 3.4 Release Preparation (P0)

- [ ] **[P0] [Release]** Final version checks (0.1.0, 2.0.0)
- [ ] **[P0] [Release]** Final CHANGELOG review
- [ ] **[P0] [Release]** Tag releases in git
- [ ] **[P0] [Release]** Create GitHub releases with notes
- [ ] **[P1] [Release]** Prepare announcement blog post
- [ ] **[P1] [Release]** Prepare social media posts
- [ ] **[P1] [Release]** Prepare Swift forums announcement
- [ ] **[P1] [Release]** Notify existing users

---

## Phase 4: Release & Monitoring (Week 6+)

### 4.1 Public Release (P0)

- [ ] **[P0] [Release]** Publish SpecificationCore 0.1.0 to GitHub
- [ ] **[P0] [Release]** Publish SpecificationKit 2.0.0 to GitHub
- [ ] **[P1] [Release]** Submit to Swift Package Index
- [ ] **[P1] [Release]** Publish blog post
- [ ] **[P1] [Release]** Post on social media
- [ ] **[P1] [Release]** Post on Swift forums
- [ ] **[P1] [Release]** Notify community

### 4.2 Community Support (P1)

- [ ] **[P1] [Validation]** Monitor GitHub issues daily
- [ ] **[P1] [Validation]** Triage new issues within 24 hours
- [ ] **[P1] [Validation]** Respond to questions within 48 hours
- [ ] **[P1] [Validation]** Fix critical bugs within 1 week
- [ ] **[P1] [Validation]** Review pull requests within 1 week
- [ ] **[P1] [Docs]** Update migration guide based on feedback
- [ ] **[P2] [Docs]** Create additional examples if needed

### 4.3 Iterative Improvements (P2)

- [ ] **[P2] [Validation]** Collect usage feedback
- [ ] **[P2] [Validation]** Track GitHub issues and PRs
- [ ] **[P2] [Validation]** Monitor downloads and dependents
- [ ] **[P2] [Release]** Release patch versions (0.1.1, 0.1.2, etc.)
- [ ] **[P2] [Release]** Plan 1.0.0 stabilization (after 1 month)
- [ ] **[P2] [Docs]** Update roadmap

### 4.4 Future Planning (P3)

- [ ] **[P3] [Docs]** Plan SpecificationKit-iOS (SwiftUI-specific)
- [ ] **[P3] [Docs]** Plan SpecificationKit-macOS (AppKit-specific)
- [ ] **[P3] [Docs]** Plan SpecificationKit-Server (Linux-optimized)
- [ ] **[P3] [Docs]** Explore async context providers
- [ ] **[P3] [Docs]** Explore advanced composition operators
- [ ] **[P3] [Docs]** Community growth initiatives

---

## Summary Statistics

### Task Counts by Priority

- **P0 (Critical)**: 112 tasks
- **P1 (High)**: 87 tasks
- **P2 (Medium)**: 23 tasks
- **P3 (Low)**: 6 tasks

**Total Tasks**: 228

### Task Counts by Type

- **[Setup]**: 13 tasks
- **[Move]**: 52 tasks
- **[Refactor]**: 35 tasks
- **[API-Cut]**: 28 tasks
- **[Test]**: 45 tasks
- **[Validation]**: 75 tasks
- **[Docs]**: 24 tasks
- **[Release]**: 16 tasks

### Task Counts by Phase

- **Phase 1**: 98 tasks (Weeks 1-2)
- **Phase 2**: 85 tasks (Weeks 3-4)
- **Phase 3**: 31 tasks (Week 5)
- **Phase 4**: 14 tasks (Week 6+)

---

## Quick Reference Checklist

### Phase 1 Complete?

- [ ] Package infrastructure setup
- [ ] All core protocols migrated and tested
- [ ] All context infrastructure migrated and tested
- [ ] All basic specs migrated and tested
- [ ] All property wrappers migrated and tested
- [ ] All macros migrated and tested
- [ ] CI/CD pipeline functional
- [ ] SpecificationCore builds and tests pass

### Phase 2 Complete?

- [ ] SpecificationKit refactored to use SpecificationCore
- [ ] Duplicate code removed
- [ ] Platform-specific code updated
- [ ] Tests migrated appropriately
- [ ] Documentation updated
- [ ] Versions tagged

### Phase 3 Complete?

- [ ] Tests pass on all platforms
- [ ] Sanitizers clean
- [ ] Coverage targets met
- [ ] Performance benchmarks passing
- [ ] Documentation finalized
- [ ] Releases prepared

### Phase 4 Complete?

- [ ] Packages released publicly
- [ ] Announcement published
- [ ] Community support active
- [ ] Issues managed
- [ ] Roadmap defined

---

## Document Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | 2025-11-16 | AI Agent | Initial TODO matrix creation |

---

**END OF TODO MATRIX**
