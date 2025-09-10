# Repository Guidelines

## Project Structure & Module Organization
- Sources: `Sources/SpecificationKit/` with submodules:
  - `Core/` (protocols, operators, base types)
  - `Specs/` (built-in specifications like `MaxCountSpec`, `TimeSinceEventSpec`)
  - `Providers/` (context providers, mocks)
  - `Wrappers/` (property wrappers `@Satisfies`, `@Spec`)
  - `Definitions/`, `Examples/` (reference composites and samples)
- Tests: `Tests/SpecificationKitTests/` (`…Tests.swift` files using XCTest)
- Docs: `DOCS/markdown/` (design notes, PRDs)
- Demo: `DemoApp/` Swift package showcasing usage.

## Build, Test, and Development Commands
- Build library: `swift build` (from repo root)
- Run tests: `swift test` (add `--filter NameOfTest` to scope)
- Open in Xcode: `open Package.swift` (or open the folder in Xcode)
- Demo app: `cd DemoApp && swift run SpecificationKitDemo`
- Resolve deps: `swift package resolve` (should be minimal/none).

## Coding Style & Naming Conventions
- Follow Swift API Design Guidelines; 4-space indentation; spaces, no tabs.
- Types: `UpperCamelCase`; functions/vars: `lowerCamelCase`.
- Specs: suffix with `Spec` (e.g., `CooldownIntervalSpec`); place in `Specs/`.
- Tests mirror types (e.g., `FirstMatchSpecTests.swift`).
- Prefer small, composable specs; add `///` doc comments for public APIs.

## Testing Guidelines
- Framework: XCTest.
- File naming: `*Tests.swift`; test methods start with `test…`.
- Use `MockContextProvider` for deterministic contexts; follow Given/When/Then comments.
- Run: `swift test` (optional coverage: `swift test --enable-code-coverage`).

## Commit & Pull Request Guidelines
- Commits: short, imperative subject (≤72 chars). Examples: `Fix warnings in documentation comments`, `Add FirstMatch PRD`.
- Scope prefix optional: `Core:`, `Specs:`, `Providers:` when helpful.
- Include rationale in body when changing behavior or APIs.
- PRs: clear description, linked issues, before/after notes or minimal example; ensure `swift build` and `swift test` pass.
- Branch naming: `feature/…`, `fix/…`, or `docs/…` (e.g., `feature/first-match-builder`).

## Architecture Tips
- New specs: put logic in `Specs/`, reuse operators from `Core/`.
- Decision flows: prefer `DecisionSpec` or `FirstMatchSpec` over nested conditionals.
- Keep demo changes in `DemoApp/`; library code remains UI-agnostic.
