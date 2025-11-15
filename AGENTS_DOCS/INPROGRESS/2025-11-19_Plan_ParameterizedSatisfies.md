# Planning Notes — Parameterized @Satisfies Initializers (2025-11-19)

## Status: ✅ COMPLETED (2025-11-15)

## Goals
- Provide wrapper initializers that accept a specification type and labeled arguments while preserving compatibility with existing auto-context and manual-context overloads.

## Research Checklist
- [x] Review `Satisfies.swift` overload resolution rules and identify safe entry points for a type + argument initializer.
- [x] Confirm macro-generated calls from `SatisfiesMacro.swift` can target the new initializer without additional codegen changes.
- [x] Evaluate type inference behavior for specs requiring multiple labeled parameters or defaulted arguments.

## Implementation Summary

### Approach Taken
Implemented factory-pattern initializers that accept a specification type and a trailing closure for constructing the specification with parameters:

```swift
@Satisfies(using: CooldownIntervalSpec.self) {
    CooldownIntervalSpec(eventKey: "banner", cooldownInterval: 10)
}
var canShowBanner: Bool
```

### Added Initializers
1. **Factory-based initializers** (3 variants):
   - Default provider: `init(using:factory:)` for `EvaluationContext`
   - Custom provider: `init(provider:using:factory:)`
   - Manual context: `init(context:asyncContext:using:factory:)`

2. **Macro-friendly initializers** (3 variants with `@_disfavoredOverload`):
   - `init(_specification:)` for default provider
   - `init(_provider:_specification:)` for custom provider
   - `init(_context:_asyncContext:_specification:)` for manual context

### Test Coverage
Added comprehensive tests in `SatisfiesWrapperTests.swift`:
- CooldownIntervalSpec with default provider (pass/fail cases)
- MaxCountSpec with default provider (pass/fail cases)
- TimeSinceEventSpec with default provider
- Custom provider support
- Manual context support

### Questions Resolved
- **Error surfacing**: Rely on Swift compiler diagnostics for parameter mismatches (type-safe by design)
- **Overload ambiguity**: Using `@_disfavoredOverload` for macro-friendly variants prevents conflicts

## Files Modified
- `Sources/SpecificationKit/Wrappers/Satisfies.swift` - Added 6 new initializers
- `Tests/SpecificationKitTests/SatisfiesWrapperTests.swift` - Added 7 parameterized wrapper tests
- `AGENTS_DOCS/markdown/3.0.0/00_3.0.0_TODO_SpecificationKit.md` - Marked P1 item complete

## Future Enhancement Opportunities
- Macro transformation for inline attribute syntax: `@Satisfies(using: Spec.self, param1: value1, param2: value2)`
- Additional convenience overloads for common parameter patterns

