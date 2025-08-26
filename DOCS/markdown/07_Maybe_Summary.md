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
