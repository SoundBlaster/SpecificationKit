codex
Here’s a concise TODO and the completed refactor to your preferred naming.

Mini TODO
- Rename DecidesOr → Decides (non-optional, supports or: and default value). com
pleted
- Rename optional Decides → Maybe (optional result). completed
- Update tests to new names and syntax. completed
- Update README examples and wording. completed

What I changed
- Non-optional wrapper: Decides
  - File: Sources/SpecificationKit/Wrappers/Decides.swift
  - Syntax:
    - @Decides(FirstMatchSpec([...]), or: 0) var value: Int
    - @Decides(FirstMatchSpec([...] )) var value: Int = 0 (default-value shortha
nd)
  - Also supports using:, firstMatch:, decide:, build:, each with or: fallback o
verloads.

- Optional wrapper: Maybe
  - File: Sources/SpecificationKit/Wrappers/Maybe.swift
  - Syntax:
    - @Maybe(FirstMatchSpec([...])) var value: Int?
  - No crashes, no force-casts; returns nil when nothing matches.

- Deprecated alias file remains: Sources/SpecificationKit/Wrappers/Spec.swift
  - typealias Spec = Decides (deprecated), aligning past name to the new non-opt
ional default (breaking changes acceptable per your note).

- Tests
  - Replaced old wrapper tests:
    - New: Tests/SpecificationKitTests/DecidesWrapperTests.swift (uses or: and d
efault-value shorthand).
    - Optional wrapper tested via existing decision tests where applicable.
  - All tests pass via swift test.

- README
  - Examples now show:
    - Optional: @Maybe(FirstMatchSpec([...])) var discount: Int?
    - Non-optional: @Decides(FirstMatchSpec([...]), or: 0) var discount: Int
    - Builder example uses @Decides(..., or: 0)
  - Feature list mentions @Satisfies, @Decides (non-optional), and @Maybe (optio
nal).

Notes
- The new API is clean and expressive:
  - Use Maybe when you want to propagate “no decision”.
  - Use Decides when you always want a value (either matched or fallback).

## Tests

codex
Added comprehensive tests for the optional wrapper Maybe and verified they pass.

What I changed
- Tests/SpecificationKitTests/MaybeWrapperTests.swift
  - test_Maybe_returnsNil_whenNoMatch: Verifies nil when no specs match.
  - test_Maybe_returnsMatchedValue_whenMatchExists: Verifies returning the match
ed result.
  - test_Maybe_projectedValue_matchesWrappedValue: Checks that $value equals wra
pped value.
  - test_Maybe_withDecideClosure: Uses the decide: closure initializer.
  - test_Maybe_builder_buildsOptionalSpec: Validates the builder pattern returns
 an optional result.

Notes
- Used @Maybe([...]) pairs convenience to align with Maybe’s EvaluationContext i
nitializers.
- Tests isolate DefaultContextProvider state with clearAll() in setUp().

Result
- All tests pass: Decides, Maybe, DecisionSpec, FirstMatchSpec, and existing sui
tes.
