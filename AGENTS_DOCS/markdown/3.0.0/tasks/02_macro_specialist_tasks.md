# Macro Development Specialist Tasks

## Agent Profile
- **Primary Skills**: Swift macros, compiler plugins, generic programming
- **Secondary Skills**: Type system design, diagnostics, error handling
- **Complexity Level**: High (4-5/5)

## Task Overview

### P1.1: Macro System Enhancement
**Objective**: Support constructing specs via wrapper parameters
**Priority**: High
**Dependencies**: None
**Timeline**: 7 days

#### Implementation Target
```swift
// Current state (manual construction required)
@Satisfies(using: CooldownIntervalSpec(interval: 10))
var canPerformAction: Bool

// Target state (automatic construction via parameters)
@Satisfies(using: CooldownIntervalSpec.self, interval: 10)
var canPerformAction: Bool
```

#### Technical Approach
1. **Extend wrapper attribute parsing** to accept constructor parameters
2. **Update macro expansion** to instantiate specs with arguments
3. **Implement generic constraints** for parameter type inference
4. **Add comprehensive diagnostics** for parameter type mismatches

#### Detailed Implementation Steps

##### Step 1: Attribute Parser Enhancement
```swift
// Extend MacroExpansionContext to handle parameter extraction
struct SpecificationParameterParser {
    func extractParameters(from attribute: AttributeSyntax) -> [ParameterInfo] {
        // Parse constructor parameters from macro attribute
        // Handle type inference and validation
    }
}
```

##### Step 2: Code Generation Updates
```swift
// Update macro expansion to generate spec instantiation
extension SatisfiesMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> ExprSyntax {
        // Generate: SpecType(param1: value1, param2: value2)
        // Instead of: using predefined instance
    }
}
```

##### Step 3: Type Inference System
```swift
// Implement parameter type validation
struct TypeInferenceEngine {
    func validateParameterTypes<T: Specification>(
        specType: T.Type,
        parameters: [Any]
    ) -> ValidationResult {
        // Ensure parameter types match spec constructor requirements
    }
}
```

#### Acceptance Criteria
- [ ] `@Satisfies(using: CooldownIntervalSpec.self, interval: 10)` compiles successfully
- [ ] Parameter types are inferred correctly from spec constructor
- [ ] Comprehensive unit test coverage for all parameter combinations
- [ ] Clear diagnostic messages for type mismatches
- [ ] Documentation updated with new syntax examples

#### Test Cases Required
```swift
class MacroParameterTests: XCTestCase {
    func testParameterConstruction() {
        // Test various parameter combinations
    }
    
    func testTypeInference() {
        // Test automatic type inference
    }
    
    func testDiagnosticMessages() {
        // Test error messages for invalid parameters
    }
}
```

---

### Blocked Task: @AutoContext Enhancement
**Status**: ⚠️ **BLOCKED** - Requires Swift toolchain evolution
**Timeline**: Deferred until Swift conformance macro support

#### Technical Challenge
Current Swift macro system lacks sufficient introspection capabilities for:
- Runtime type validation of context conformance
- Dynamic protocol requirement checking
- Generic constraint enforcement at compile time

#### Workaround Strategy
1. **Document expected behavior** in placeholder implementation
2. **Create runtime validation fallback** for development builds
3. **Implement comprehensive unit tests** for expected behavior
4. **Track Swift Evolution proposals** for conformance macro support

#### Placeholder Implementation
```swift
// Temporary implementation until toolchain support
@attached(member, names: named(contextProvider))
public macro AutoContext() = #externalMacro(
    module: "SpecificationKitMacros",
    type: "AutoContextMacro"
)

// Runtime validation fallback
extension AutoContextSpecification {
    func validateContextConformance() {
        #if DEBUG
        // Runtime checks for development
        assert(Context.self is ContextProviding.Type, 
               "Context must conform to ContextProviding")
        #endif
    }
}
```

---

## Implementation Guidelines

### Code Quality Standards
- **Swift 6 Compliance**: All macro code must compile without warnings
- **Error Handling**: Comprehensive diagnostic messages with fix suggestions
- **Performance**: Macro expansion should add <10% to compilation time
- **Testing**: >95% test coverage including edge cases and error conditions

### Diagnostic Message Standards
```swift
// Example of high-quality diagnostic
struct MacroDiagnostic {
    let message: String
    let severity: DiagnosticSeverity
    let fixIt: String?
}

// Good diagnostic example
let diagnostic = MacroDiagnostic(
    message: "Parameter type 'String' doesn't match expected type 'TimeInterval' for 'interval' parameter",
    severity: .error,
    fixIt: "Change parameter to numeric type: interval: 10.0"
)
```

### Testing Strategy
1. **Unit Tests**: Test macro expansion with various inputs
2. **Integration Tests**: Test compiled macro output behavior
3. **Negative Tests**: Test error handling and diagnostics
4. **Performance Tests**: Measure compilation time impact

### Documentation Requirements
- **API Documentation**: Complete DocC coverage for all public macros
- **Usage Examples**: Comprehensive examples for each supported pattern
- **Migration Guide**: Steps for updating from manual to macro-based construction
- **Troubleshooting**: Common issues and solutions

## Dependencies & Coordination

### External Dependencies
- Swift macro toolchain stability
- Compatibility with Xcode versions 15.0+
- Integration with existing SpecificationKit architecture

### Coordination Points
- **Performance Team**: Ensure macro expansion doesn't impact compilation benchmarks
- **Testing Team**: Coordinate on test infrastructure for macro validation
- **Documentation Team**: Align on example formats and API documentation style

## Success Metrics
- **Feature Completion**: 100% of P1 macro tasks completed
- **Quality**: Zero critical bugs in macro expansion
- **Performance**: <10% compilation time increase
- **Developer Experience**: Positive feedback on new syntax from early adopters

## Risk Mitigation
- **Toolchain Dependencies**: Alternative runtime approaches documented
- **Breaking Changes**: Backward compatibility maintained with existing syntax
- **Complexity Management**: Incremental rollout with feature flags
- **Testing Coverage**: Comprehensive test suite before release