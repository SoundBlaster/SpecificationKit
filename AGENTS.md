# Repository Guidelines

## Project Structure & Module Organization
SpecificationKit is a Swift package with library code under `Sources/SpecificationKit/`. Use `Core/` for shared protocols and operators, `Specs/` for concrete spec types, `Providers/` for context providers, and `Wrappers/` for property wrappers such as `@Satisfies` and `@Spec`. Reference composites live in `Definitions/`, while `Examples/` and `DemoApp/` demonstrate usage. Tests reside in `Tests/SpecificationKitTests/` and docs in `DOCS/markdown/`. Keep UI code out of the library; limit demo changes to `DemoApp/`.

## Build, Test, and Development Commands
- `swift build`: compile the library and surface compiler warnings.
- `swift test`: run the full XCTest suite; add `--filter NameOfTest` to scope.
- `swift test --enable-code-coverage`: generate coverage data when validating major changes.
- `cd DemoApp && swift run SpecificationKitDemo`: run the showcase app.
- `swift package resolve`: refresh dependencies if Package.resolved drifts.

## Coding Style & Naming Conventions
Follow Swift API Design Guidelines with four-space indentation and spaces (no tabs). Name types with UpperCamelCase and functions, variables, and cases with lowerCamelCase. Suffix all specs with `Spec` (e.g., `CooldownIntervalSpec`) and place them in `Specs/`. Public APIs should carry concise `///` doc comments. Favor small, composable specs that reuse utilities from `Core/`.

## Testing Guidelines
XCTest backs the suite. Mirror production types in test filenames (e.g., `FirstMatchSpecTests.swift`), and prefix methods with `test`. Structure test bodies with `// Given`, `// When`, `// Then` comments and use `MockContextProvider` for deterministic contexts. Ensure new specs ship with coverage of nominal and edge scenarios.

## Commit & Pull Request Guidelines
Commit messages use imperative subjects ≤72 characters, optionally prefixed with scope tags such as `Core:`. PRs should describe intent, note behavioral changes, link issues, and confirm `swift build` and `swift test` run cleanly. Include minimal before/after snippets or demo steps when altering spec behavior.
