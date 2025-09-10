codex
I added a friendly diagnostic when a type using @specs doesn’t declare its conte
xt typealias T, plus extra validations and tests.

What I changed
- Macro diagnostics
  - File: Sources/SpecificationKitMacros/SpecMacro.swift
  - New warning: If the attached type lacks a typealias T, the macro emits a war
ning suggesting to add one (e.g., typealias T = EvaluationContext).
  - Validation: Keeps existing empty-arguments error and adds an error if @specs
 is applied to a non-Specification type.
  - Generated code now uses the associated type T in member signatures:
    - composite: AnySpecification<T>
    - public func isSatisfiedBy(_ candidate: T) -> Bool

- Tests
  - File: Tests/SpecificationKitTests/SpecsMacroDiagnosticsTests.swift
  - Cases:
    - Empty args → error diagnostic.
    - Non-Spec type → error diagnostic.
    - Missing typealias T → warning diagnostic with a friendly suggestion.
  - Test target dependencies updated to include SwiftSyntaxMacrosTestSupport.

- Package updates
  - File: Package.swift
  - Added SwiftDiagnostics to macro target dependencies (for emitting diagnostic
s).
  - Test target now depends on SwiftSyntaxMacrosTestSupport and SpecificationKit
Macros.

- TODO progress
  - We have helpful diagnostics for @specs: empty args, non-Spec host, and missi
ng T suggestion.
  - If you want, I can mark the “Emit helpful compile-time diagnostics on @specs
 validation failure” item as done.
