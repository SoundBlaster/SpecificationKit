# SpecificationKit Code Style and Conventions

## Swift Style Guidelines
- Follow Swift API Design Guidelines
- Swift 5.9+ features and syntax
- Swift 6 compliance requirements for v3.0.0

## Naming Conventions
- Protocols: `Specification`, `ContextProviding`, `DecisionSpec`
- Property Wrappers: `@Satisfies`, `@Decides`, `@Maybe` with descriptive names
- Specifications: Suffix with `Spec` (e.g., `WeightedSpec`, `ThresholdSpec`)
- Context Providers: Suffix with `ContextProvider`

## Documentation
- Comprehensive DocC documentation for all public APIs
- Documentation files in Documentation.docc/
- Examples and usage patterns included
- 100% documentation coverage requirement for public APIs

## Thread Safety
- All public APIs must be thread-safe
- Concurrent access support required
- Performance requirements: <1ms for simple specifications

## Testing Requirements
- >90% unit test coverage for new features
- Comprehensive test suite in Tests/SpecificationKitTests/
- Performance benchmarks and validation
- Macro testing with swift-macro-testing framework

## Architecture Patterns
- Specification Pattern implementation
- Protocol-oriented design
- Composition over inheritance
- Property wrapper pattern for declarative syntax
- Context provider pattern for dependency injection