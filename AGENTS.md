# Repository Guidelines

## Project Structure & Module Organization
SpecificationKit is a Swift package. Library sources live under `Sources/SpecificationKit/` with shared protocols in `Core/`, concrete specs in `Specs/`, context providers in `Providers/`, and property wrappers in `Wrappers/`. Composite reference specs belong in `Definitions/`. Usage examples sit in `Examples/` and the showcase app stays in `DemoApp/`. Tests mirror the library in `Tests/SpecificationKitTests/`, while documentation resides in `DOCS/markdown/`. Keep UI code scoped to `DemoApp/` and avoid leaking demo dependencies into the library target.

## Build, Test, and Development Commands
Run `swift build` at the root to compile the package and surface warnings. Use `swift test` for the full XCTest suite, or scope with `swift test --filter NameOfTest`. For coverage validation, run `swift test --enable-code-coverage`. Execute the demo via `cd DemoApp && swift run SpecificationKitDemo`. If dependencies drift, refresh them with `swift package resolve`.

## Coding Style & Naming Conventions
Follow Swift API Design Guidelines with four-space indentation and no tabs. Name types in UpperCamelCase, members in lowerCamelCase, and suffix every spec with `Spec` (e.g., `CooldownIntervalSpec`). Place new specs under `Sources/SpecificationKit/Specs/`. Public APIs require succinct `///` doc comments. Favor small, composable spec implementations and reuse utilities from `Core/` rather than duplicating logic.

## Testing Guidelines
XCTest powers the suite. Mirror production types in test filenames (e.g., `FirstMatchSpecTests.swift`) and prefix methods with `test`. Within each test, structure sections using `// Given`, `// When`, `// Then`. Use `MockContextProvider` to keep scenarios deterministic and cover both nominal and edge cases before merging.

## Commit & Pull Request Guidelines
Write commits with imperative subjects ≤72 characters, optionally prefixed with scope tags such as `Core:`. Ensure `swift build` and `swift test` pass before pushing. Pull requests should describe intent, outline behavioral changes, link relevant issues, and call out demo updates. Include before/after snippets or reproduction notes when altering spec behavior.

## Additional Notes
Avoid modifying generated files or demo UI when touching library logic. When introducing new specs, add a corresponding example under `Examples/` if it clarifies usage. Keep documentation aligned by updating `DOCS/markdown/` when public APIs change.
