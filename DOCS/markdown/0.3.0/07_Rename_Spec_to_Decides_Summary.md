# Feature Summary: Rename `@Spec` → `@Decides`

- Canonical decision wrapper is now `@Decides<Context, Result>`.
- `@Spec` remains available as a deprecated alias to preserve source compatibility.
- README and examples updated to use `@Decides`.
- Tests added for `@Decides` and one legacy test ensures `@Spec` alias still compiles.
- Rationale: clearer semantics, aligned with `DecisionSpec`, and consistent with `@Satisfies` naming.
- Migration: replace occurrences of `@Spec` with `@Decides`. Deprecation warnings guide the change.

## codex

I’ve implemented the @Decides rename per 06_Rename_Spec_PRD.md and kept @Spec as
 a deprecated alias. I also fixed examples/tests to compile cleanly.

**What Changed**
- New wrapper: `Decides<Context, Result>` (full replacement for `Spec`).
- Deprecated alias: `@available(*, deprecated, message: "Use @Decides instead")
typealias Spec = Decides`.
- Builder renamed: `DecidesBuilder` with alias `SpecBuilder` deprecated.

**Code Updates**
- Added: `Sources/SpecificationKit/Wrappers/Decides.swift`
- Replaced: `Sources/SpecificationKit/Wrappers/Spec.swift` → now only has deprec
ated typealiases.
- Fixed examples using `FirstMatchSpec`:
  - `Sources/SpecificationKit/Examples/DiscountExample.swift` now uses `FirstMat
chSpec.withFallback([...], fallback: 0)`.
  - `Sources/SpecificationKit/Definitions/DiscountDecisionExample.swift`:
    - Uses `withFallback` for the tier spec.
    - Replaced the property-wrapper example with a simple service example (the o
ld wrapper example relied on non-available context injection).
- Kept default-provider convenience inits for `Decides` only when `Context == Ev
aluationContext` to avoid generic mismatches.

**Docs**
- README: replaced all usages of `@Spec` with `@Decides`; added a short “Migrati
on: @Spec → @Decides” note.
- Added summary file: `DOCS/markdown/0.3.0/07_Rename_Spec_to_Decides_Summary.md`
.

**Tests**
- New: `Tests/SpecificationKitTests/DecidesWrapperTests.swift` covering:
  - `@Decides` with `EvaluationContext`
  - One legacy test using `@Spec` (alias) to ensure it compiles.
- Updated to use `withFallback` instead of mixing `AlwaysTrueSpec` into typed ar
rays:
  - `Tests/SpecificationKitTests/FirstMatchSpecTests.swift`
  - `Tests/SpecificationKitTests/DecisionSpecTests.swift`
- Ran `swift test`: all tests pass.

**Notes**
- API remains source-compatible; `@Spec` compiles with deprecation warnings.
- If you want, I can:
  - Add a “Release Notes 0.3.0” doc stub.
  - Update version references in README/badges to 0.3.0.
