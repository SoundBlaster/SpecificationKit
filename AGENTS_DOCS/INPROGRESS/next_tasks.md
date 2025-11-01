# Next Tasks — Parameterized @Satisfies Planning

## 🧱 Prototype Parameterized Wrapper Initializer
- Audit `Sources/SpecificationKit/Wrappers/Satisfies.swift` and sketch an initializer that accepts a spec type plus labeled arguments, forwarding them through without breaking existing overloads.
- Verify compatibility with `@Satisfies` macro expansions emitted from `Sources/SpecificationKitMacros/SatisfiesMacro.swift` so macro clients automatically benefit from the new initializer.

## 🧪 Extend Coverage and Documentation
- Add unit coverage in `Tests/SpecificationKitTests/SatisfiesWrapperTests.swift` and `Tests/SpecificationKitTests/SatisfiesMacroComprehensiveTests.swift` demonstrating labeled arguments on spec types.
- Refresh user-facing docs or README snippets to highlight the simplified attribute usage once the initializer lands.

