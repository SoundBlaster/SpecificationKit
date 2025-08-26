# Feature Summary: Rename `@Spec` → `@Decides`

- Canonical decision wrapper is now `@Decides<Context, Result>`.
- `@Spec` remains available as a deprecated alias to preserve source compatibility.
- README and examples updated to use `@Decides`.
- Tests added for `@Decides` and one legacy test ensures `@Spec` alias still compiles.
- Rationale: clearer semantics, aligned with `DecisionSpec`, and consistent with `@Satisfies` naming.
- Migration: replace occurrences of `@Spec` with `@Decides`. Deprecation warnings guide the change.
