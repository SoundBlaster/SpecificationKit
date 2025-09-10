# Changelog

All notable changes to SpecificationKit will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Swift Package Index preparation (pending)
- Wrapper parameter-based spec construction (pending)
- Experimental macro prototypes (`@specsIf(condition:)` or `#composed(...)` or `@deriveSpec(from:)`) (pending)
- Performance benchmarks for specification composition and macro-generated code (pending)
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