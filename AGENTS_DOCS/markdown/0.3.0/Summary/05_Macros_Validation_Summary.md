codex
Added validations to @specs and corresponding diagnostics tests, and improved th
e macro output.

What I changed
- Macro improvements
  - File: Sources/SpecificationKitMacros/SpecMacro.swift
  - Validations:
    - Errors when used with empty arguments (existing).
    - New: Errors when applied to a type not conforming to Specification.
  - Generated code now references the associated type T, not EvaluationContext:
    - composite: AnySpecification<T>
    - func isSatisfiedBy(_ candidate: T) -> Bool
  - Rationale: Supports any Context, improves correctness.

- Diagnostics tests
  - File: Tests/SpecificationKitTests/SpecsMacroDiagnosticsTests.swift
  - Uses SwiftSyntaxMacrosTestSupport:
    - Empty args → emits diagnostic.
    - Applied to non-Spec type → emits diagnostic.
  - Package.swift updated to add test dependency: SwiftSyntaxMacrosTestSupport and SpecificationKitMacros to test the macro.

- Test suite
  - All tests pass, including new diagnostics and earlier integration tests.

Notes
- We still can’t validate “all arguments are Specification and share the same Co
ntext” at macro expansion time due to lack of type info. The macro now generates
 type-generic members (T) so type mismatches surface as normal compiler errors.
- If you want stricter diagnostics, we can add additional syntax-only checks (e.
g., require the attached type to declare typealias T), but these would be best-e
ffort and could be noisy.
