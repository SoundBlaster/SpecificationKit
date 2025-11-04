# Changelog

All notable changes to SpecificationKit will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed
- Restored non-circular Core Location region evaluation on macOS and watchOS by
  calling `CLRegion.contains(_:)` directly without relying on runtime
  indirection, preserving behavior from earlier releases.

## [3.0.0] - 2025-09-18

### Added - Major Release Features

#### 🏗 Phase 0: Foundation Infrastructure (Complete)
- **Performance Benchmarking Infrastructure**: Comprehensive performance testing framework
  - XCTest-based performance benchmarks for specification evaluation
  - Memory allocation profiling and optimization
  - Baseline comparison framework for regression detection
  - Automated CI/CD performance validation
- **Macro Development Enhancements**: Enhanced macro system capabilities
  - Parameter-based specification construction support
  - Improved compilation-time error diagnostics
  - Better type inference for macro-generated code
- **Context Provider Foundation**: Core infrastructure for v3.0.0 context providers
  - Enhanced `ContextProviding` protocol with async support
  - Thread-safe context management patterns
  - Foundation for network and persistent providers

#### 🔄 Phase 1: Reactive Property Wrapper Ecosystem (Complete)
- **@ObservedDecides**: SwiftUI-reactive decision wrapper with automatic updates
  - `DynamicProperty` integration for seamless SwiftUI updates
  - Real-time context change propagation via `ContextUpdatesProviding`
  - Publisher projection for manual observation (`$wrappedValue`)
- **@ObservedMaybe**: Optional decision results with reactive updates
  - Optional decision evaluation with automatic UI updates
  - Nil-safe reactive patterns for SwiftUI integration
  - Combine publisher support for advanced reactive flows
- **@CachedSatisfies**: Intelligent caching wrapper with TTL support
  - Time-to-live (TTL) based cache expiration
  - Manual cache invalidation capabilities
  - Memory pressure handling and automatic cleanup
  - Thread-safe actor-based cache implementation
- **@ConditionalSatisfies**: Runtime specification selection wrapper
  - Dynamic specification switching based on runtime conditions
  - Predicate-based specification selection logic
  - Fallback specification support for robust evaluation
- **AnySpecification Optimization**: Enhanced performance for type-erased specifications
  - Reduced dynamic dispatch overhead
  - `@inlinable` annotations for compiler optimization
  - Memory allocation optimizations

#### 📊 Phase 2: Advanced Specification Types (Complete)
- **WeightedSpec**: Probabilistic specification selection with statistical validation
  - Weighted random selection with configurable probability distributions
  - Statistical accuracy validation with chi-square testing
  - Expected value and variance calculations for numeric results
  - Comprehensive edge case handling (zero weights, normalization)
- **HistoricalSpec**: Time-series data analysis and trend evaluation
  - Multiple analysis windows: lastN, timeRange, sliding window
  - Statistical aggregation: average, median, trend analysis, seasonality detection
  - Missing data interpolation with linear and custom interpolators
  - Integration with persistent data providers
- **ComparativeSpec**: Relative comparison specifications with flexible operators
  - Range comparisons (between, greaterThan, lessThan, equalTo)
  - Percentile-based ranking against historical data
  - Tolerance-based fuzzy matching for floating-point comparisons
  - Integration with `HistoricalSpec` for dynamic baseline comparison
- **ThresholdSpec**: Dynamic and contextual threshold evaluation
  - Fixed, adaptive, and contextual threshold types
  - Runtime threshold calculation with custom providers
  - Percentile-based thresholds from data distributions
  - Context keyPath-based threshold extraction

#### 🌐 Phase 3A: Context Provider System (Complete - 3/3)
- **NetworkContextProvider**: Production-ready network-based context provider
  - Configurable retry policies: exponential backoff, fixed delay, and custom retry logic
  - TTL-based caching with thread-safe actor implementation for optimal performance
  - Comprehensive error handling with automatic fallback to cached data when network fails
  - Swift 6 concurrency compliance with full `@Sendable` conformance
  - Combine integration for reactive context updates via `ContextUpdatesProviding`
  - JSON parsing with type-safe data extraction for all `EvaluationContext` fields
  - Automatic periodic refresh with configurable intervals
  - Support for custom fallback values when network and cache are unavailable
- **PersistentContextProvider**: Core Data-backed context provider for offline-first applications
  - Full Core Data integration with automatic model management and migration support
  - Thread-safe async/await API for all persistence operations using serial dispatch queue
  - Support for multiple data types: strings, numbers, dates, arrays, dictionaries, and custom types
  - Data expiration with automatic TTL-based cleanup for temporary values
  - Multiple store types: SQLite, in-memory (for testing), and binary data stores
  - Migration policies: automatic, manual with custom managers, or no migration
  - File protection and encryption support for sensitive data on supported platforms
  - Combine and AsyncStream integration for reactive change notifications
  - Comprehensive test coverage with 31 unit tests including concurrent access validation
  - In-memory model generation for seamless testing without external dependencies
- **CompositeContextProvider**: Multi-provider composition with merge strategies
  - Multiple merge strategies: `preferFirst`, `preferLast`, `custom`
  - Conflict resolution for overlapping context keys
  - Set union operations for segments across providers
  - Type-erased provider support with `AnyContextProvider`

#### 🔍 Phase 3B: Platform-Specific Context Providers (Partial - 1/4 Complete)
- **AppleTVContextProvider**: tvOS-specific context provider for Apple TV applications ✅
  - Device information: Model detection, tvOS version, interface idiom validation
  - Display properties: Screen resolution, scale factor, HDR support detection (P3 color gamut)
  - Remote control detection: Siri Remote, Apple TV Remote, game controller monitoring
  - System performance: Thermal state, memory, CPU cores, performance tier classification
  - Accessibility features: VoiceOver, Switch Control, reduce motion preferences
  - Platform integration with `PlatformContextProviders` factory methods
  - Cross-platform compatibility with graceful fallback behavior
  - Comprehensive test suite with 30+ unit tests covering all capabilities

#### 🔍 Phase 4A: Developer Testing Tools (Partial - 2/3 Complete)
- **SpecificationTracer**: Comprehensive execution tracing and debugging utilities ✅
  - Hierarchical tracing with parent-child evaluation relationships
  - Precise timing measurements for performance analysis (microsecond precision)
  - Visual representation with tree-based output and DOT graph generation for Graphviz
  - Thread-safe operation with concurrent tracing across multiple threads
  - Zero-overhead when disabled for production performance
  - Trace session management with start/stop controls and metadata collection
  - Composite specification tracing with short-circuit detection for AND/OR operations
  - Export capabilities for external analysis and debugging workflows
  - Statistical analysis with performance baselines and slow execution identification
- **MockSpecificationBuilder**: Test-time specification doubles with rich telemetry ✅
  - Fluent API for always-true/false, predicate-driven, delayed, random, or sequenced behaviours
  - Synthetic latency and fatal-error simulation to validate resilience paths
  - Thread-safe call recording with captured contexts, timestamps, and results
  - Convenience factories for flaky or slow mocks and resettable state between tests

### Enhanced
- **Swift 6 Compatibility**: Full concurrency support across all components
  - `@Sendable` conformance for all shared types
  - Actor isolation for thread-safe operations
  - Structured concurrency patterns
  - Zero data races under strict concurrency checking
- **Performance Optimizations**: Significant performance improvements
  - <1ms specification evaluation for simple specs
  - <5% property wrapper overhead vs direct evaluation
  - <10% memory usage increase vs v2.0.0 baseline
  - Optimized type erasure with `@inlinable` annotations

### Pending Implementation (50% Progress - 15/28 phases complete)
- **Phase 3B**: Platform-specific context providers (iOS/macOS/watchOS) - AppleTVContextProvider complete ✅
- **Phase 4A**: Developer testing tools (MockSpecificationBuilder, Profiling) - Tracer & Builder complete ✅
- **Phase 4B**: Comprehensive documentation (DocC, tutorials, migration guides)
- **Phase 5**: Release preparation (package metadata, quality assurance, distribution)

### Deferred
- **@AutoContext Enhancement**: Deferred until Swift toolchain evolution provides better macro introspection capabilities
- **Macro System**: Complete macro infrastructure with `@specs` and `@AutoContext` attached macros
  - `@specs` macro for automatic composite specification generation with `.and()`/`.or()` composition
  - `@AutoContext` macro for automatic context provider injection with static `contextProvider` property
  - Comprehensive macro diagnostics with helpful error messages and suggestions
  - Type safety validation ensuring specification context compatibility across `@specs` arguments
  - Async bridge `isSatisfiedByAsync(_:)` generation in `@specs` output
  - Default initializer synthesis in `@AutoContext` when missing
  - Generic type support with associated type `T` in macro-generated code
  - Macro integration tests and diagnostics validation
- **New Specification Types**: 
  - `DateRangeSpec` for date range validation using `EvaluationContext.currentDate`
  - `FeatureFlagSpec` for feature flag evaluation with `EvaluationContext.flags`
  - `UserSegmentSpec` with `UserSegment` enum and `EvaluationContext.segments`
  - `SubscriptionStatusSpec` using `EvaluationContext.userData` state
  - `DateComparisonSpec` for event-based date comparisons with `.before`/`.after` operations
  - `FirstMatchSpec` for priority-based decision making with typed results
  - All new specs conform to `Specification` with explicit `Context` types
  - Comprehensive unit tests for typical and edge cases for each new spec
- **Decision Specification System**: 
  - `DecisionSpec` protocol for specifications that return typed results beyond boolean
  - `@Decides` property wrapper for non-optional decision results with fallback values
  - `@Maybe` property wrapper for optional decision results
  - Priority-based evaluation with first-match semantics
  - Builder pattern support for complex decision logic
  - Integration with macro system for composite decision specifications
- **Async Support**: Complete asynchronous specification evaluation
  - `AsyncSpecification` protocol with `associatedtype Context` and `isSatisfiedBy(_:) async throws -> Bool`
  - `AnyAsyncSpecification` type-erased wrapper for async specs
  - `@AsyncSatisfies` property wrapper for async evaluation
  - `evaluateAsync()` method on `@Satisfies` wrapper that awaits context and evaluation
  - Async context access via `currentContextAsync()` in context providers (avoiding overload ambiguity)
  - Default async implementations that bridge to synchronous versions
  - Comprehensive async tests covering delays, successes, and thrown errors
  - Async computed property `isSatisfied` for `@AutoContext` + `@specs` types using `contextProvider.currentContextAsync()`
- **SwiftUI Integration**: 
  - `EnvironmentContextProvider` for SwiftUI `@Environment`/`@AppStorage` integration into `EvaluationContext`
  - `@ObservedSatisfies` (`DynamicProperty`) for automatic UI updates on provider changes
  - Complete SwiftUI examples integrating `EnvironmentContextProvider` in views
  - SwiftUI environment integration examples in demo application
- **Observation System**: 
  - `ContextUpdatesProviding` protocol for context change notifications
  - Combine publisher support with `AnyPublisher<Void, Never>` for context updates
  - `AsyncStream` bridge for context updates via `contextUpdatesStream()`
  - `DefaultContextProvider` emits updates on all state mutations (counters/flags/events/userData/registrations)
  - `EnvironmentContextProvider` forwards `objectWillChange` to observation hooks
  - Live updating specifications that react to context changes
- **Enhanced Demo Application**: 
  - `AsyncDemoView` screen with delay/error toggles and navigation entry
  - Observation demo screen showcasing flags, counters, cooldowns, and composite spec live updates
  - SwiftUI environment integration examples
  - Comprehensive macro usage demonstrations (`@specs`, `@AutoContext`)
  - Demo app showcasing macros, AutoContext, and async context retrieval
- **Dependency Injection Support**: 
  - Global provider and initializer injection patterns
  - `@Satisfies` compatibility with any `ContextProviding` implementation
  - Flexible context provider architecture
- **CI/CD**: GitHub Actions workflows for building library, macros, and running tests on macOS
- **Comprehensive DocC Documentation**: 
  - Complete API documentation for all public APIs with rich examples
  - GitHub Pages deployment automation via GitHub Actions workflow
  - Swift-DocC plugin integration with static hosting support
  - Enhanced documentation for property wrappers with real-world usage patterns
  - Macro system documentation with generated code examples
  - Context providers documentation with threading and state management
  - Built-in specifications documentation with business logic examples
  - Cross-references using DocC linking syntax and modern Swift patterns
  - Performance considerations and best practices throughout
- **Updated README Documentation**: 
  - Macro system documentation (`@specs`, `@AutoContext`)
  - Async Specs Quick Start guide
  - Macro diagnostics section with error examples
  - New specs and async features comprehensive documentation
  - Observation for SwiftUI integration guide
  - EnvironmentContextProvider usage examples

### Changed
- **Breaking**: Enhanced `ContextProviding` protocol with async context access via `currentContextAsync()`
- **Breaking**: Updated all built-in specifications to use explicit `Context` types
- **Breaking**: Property wrappers now support both sync and async evaluation patterns
- **Breaking**: `@specs` macro now generates members using associated type `T` (e.g., `AnySpecification<T>`, `isSatisfiedBy(_ candidate: T)`)
- Improved error handling and diagnostics throughout the framework
- Enhanced type safety for specification composition and context handling
- `@specs` macro now validates all arguments conform to `Specification` and share the same `Context`
- Default synchronous and asynchronous implementations for context providers (async bridges to sync by default)
- Updated README with comprehensive macro documentation and async features guide

### Fixed
- **Bugfix**: Feature flag specifications now properly handle missing flags as failures (dedicated test added)
- Improved thread safety in `DefaultContextProvider` with state mutation safety
- Enhanced macro expansion reliability and error reporting
- Fixed macro diagnostics to warn when attached type is missing `typealias T` with friendly suggestions
- Error handling when `@specs` is applied to non-`Specification` types

### Security
- All context providers implement thread-safe operations
- No sensitive data logging or exposure in specification evaluation

## [0.2.0] - 2024-06-01

### Added
- Initial support for Swift macros with `@specs` macro for composite specifications.
- Macro plugin target and registration.
- Macro integration in demo application.
- Core specification pattern and reusable specs.
- Property wrapper `@Satisfies` for declarative specification evaluation.

### Changed
- Updated documentation to include macro usage and examples.
- Improved test coverage for macro expansions and core specs.

### Fixed
- N/A

## [0.1.0] - 2024-05-01

### Added
- Core specification protocol and type erasure.
- Basic reusable specifications: `TimeSinceEventSpec`, `MaxCountSpec`, `CooldownIntervalSpec`, `PredicateSpec`.
- Context providing protocols and default/mock implementations.
- Property wrapper support for specifications.
- Example composite specifications and demo application.

### Changed
- Initial project setup and folder structure.

### Fixed
- N/A
