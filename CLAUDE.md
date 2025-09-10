# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Building and Testing
- `swift build` - Build the main library
- `swift test` - Run all tests
- `swift package resolve` - Resolve dependencies
- `swift build -v` - Build with verbose output
- `swift test -v` - Run tests with verbose output

### Demo Application
- `cd DemoApp && swift build` - Build the demo app
- `cd DemoApp && swift run SpecificationKitDemo` - Run the SwiftUI demo
- `cd DemoApp && swift run SpecificationKitDemo --cli` - Run the CLI demo

### Testing Specific Areas
- Use `swift test --filter <TestClassName>` for specific test classes
- Use `swift test --filter <TestMethod>` for specific test methods

## Architecture Overview

SpecificationKit implements the Specification Pattern with a layered architecture:

### Core Layer (`Sources/SpecificationKit/Core/`)
- **Specification.swift**: Main `Specification` protocol defining `isSatisfiedBy(_:)`
- **AnySpecification.swift**: Type-erased wrapper for specifications
- **SpecificationOperators.swift**: Logical operators (`.and()`, `.or()`, `.not()`)
- **DecisionSpec.swift**: Protocol for specifications that return typed results beyond boolean
- **AsyncSpecification.swift**: Async specification support
- **ContextProviding.swift**: Protocol for context providers

### Specifications Layer (`Sources/SpecificationKit/Specs/`)
Built-in specification implementations:
- **MaxCountSpec**: Counter-based limits
- **TimeSinceEventSpec**: Time-based conditions
- **CooldownIntervalSpec**: Cooldown periods
- **PredicateSpec**: Custom predicate-based specs
- **FirstMatchSpec**: First-match evaluation with results
- **DateRangeSpec**, **DateComparisonSpec**: Date-based conditions
- **FeatureFlagSpec**, **UserSegmentSpec**, **SubscriptionStatusSpec**: Context-based flags

### Property Wrappers (`Sources/SpecificationKit/Wrappers/`)
- **@Satisfies**: Boolean specification evaluation
- **@Decides**: Non-optional decision results with fallback
- **@Maybe**: Optional decision results
- **@ObservedSatisfies**: SwiftUI-reactive specification evaluation
- **@AsyncSatisfies**: Async specification support

### Context Providers (`Sources/SpecificationKit/Providers/`)
- **DefaultContextProvider**: Thread-safe production provider with counters, flags, events
- **EnvironmentContextProvider**: SwiftUI environment bridge
- **MockContextProvider**: Testing utilities
- **EvaluationContext**: Context data structure

### Macros (`Sources/SpecificationKitMacros/`)
- **@specs**: Composite specification synthesis
- **@AutoContext**: Automatic context provider injection
- Comprehensive macro diagnostics for proper usage

### Definitions (`Sources/SpecificationKit/Definitions/`)
- **CompositeSpec**: Predefined composite specifications
- **AutoContextSpecification**: Base for auto-context specs

## Key Concepts

### Specification Pattern
All specs implement `Specification` protocol with `isSatisfiedBy(_:)` method. Compose using `.and()`, `.or()`, `.not()` operators.

### Decision Specifications
Beyond boolean results, `DecisionSpec` protocol returns typed values. Use `FirstMatchSpec` for priority-based decisions.

### Context Providers
Inject context through `ContextProviding` protocol. `DefaultContextProvider.shared` is the standard instance.

### Property Wrappers
Declarative syntax for specification evaluation:
- `@Satisfies(using: spec)` for boolean results
- `@Decides([(spec, result)], or: fallback)` for non-optional decisions
- `@Maybe([(spec, result)])` for optional decisions

### Async Support
Use `AnyAsyncSpecification` or `AsyncSpecification` for async evaluation. Property wrappers support `.evaluateAsync()`.

## Testing Approach

- Unit tests in `Tests/SpecificationKitTests/`
- Macro tests use swift-macro-testing framework
- Mock providers for controlled test scenarios
- Integration tests for macro expansion and diagnostics
- Tests for all major components: specs, wrappers, providers, async features

## Code Conventions

- Swift 5.9+ features
- Follow Swift API Design Guidelines
- Thread-safe implementations where applicable
- Comprehensive documentation for public APIs
- Property wrappers use underscore prefix for projected values
- Macro diagnostics provide clear error messages and suggestions