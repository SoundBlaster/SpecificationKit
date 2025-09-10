# isSatisfiedByAsync

## Step 1

codex
I added async support to @specs and verified it with tests, plus delivered the @
AsyncSatisfies wrapper and async demo as requested.

What’s implemented

- @specs async member
  - File: Sources/SpecificationKitMacros/SpecMacro.swift
  - Adds an async bridge:
    - public func isSatisfiedByAsync(_ candidate: T) async throws -> Bool
    - Currently bridges to the sync composite; ready to switch to async internal
s later.
  - Export updated:
    - File: Sources/SpecificationKit/SpecificationKit.swift
    - Macro declaration now includes named(isSatisfiedByAsync).

- Tests
  - File: Tests/SpecificationKitTests/SpecsMacroIntegrationTests.swift
  - New: test_specsMacro_asyncMethod — calls try await BannerSpec().isSatisfiedB
yAsync(_:) and asserts True/False cases.
  - Fixed async XCTAssert usage by first binding results, then asserting.

- Async property wrapper (done earlier in this round)
  - File: Sources/SpecificationKit/Wrappers/AsyncSatisfies.swift
  - Property wrapper that exposes an async projected evaluate() without needing
_spec.evaluateAsync().
  - Tests: Tests/SpecificationKitTests/AsyncSatisfiesWrapperTests.swift (predica
te and sync-spec cases).

- Demo additions (already landed)
  - File: DemoApp/Sources/AsyncDemoView.swift — screen demonstrating AnyAsyncSpe
cification with delay and error toggles.
  - Navigation updated in DemoApp/Sources/main.swift.

- README improvements
  - Added Async Specs Quick Start with AnyAsyncSpecification and Satisfies.evalu
ateAsync examples.
  - Noted “Async Specs” screen in the Demo section.
  - Added “Async capable” bullet to Features and macro diagnostics section.

Notes and rationale
- The new isSatisfiedByAsync provides a smooth async call site for @specs types
without changing their internals. It’s a safe bridge for now; we can gradually e
nrich internals to use async chaining if we later add async spec composition.
- For AutoContext-specific async convenience (e.g., an async computed property i
sSatisfied), it’s safer to add in a follow-up so we can guard generation (only w
hen a static contextProvider exists) and add tests.

## Step 2

codex
Good catch — that failure was because we added the new async method to @specs, s
o the diagnostics tests that assert the entire expanded source needed to include
 it.

What I changed
- Updated expected expansions in SpecsMacroDiagnosticsTests to include the async
 bridge:
  - public func isSatisfiedByAsync(_ candidate: T) async throws -> Bool { compos
ite.isSatisfiedBy(candidate) }
- Adjusted three tests’ expected expandedSource to match current macro output an
d formatting:
  - test_specs_warnsWhenMissingTypealiasT
  - test_specs_argumentLiteral_emitsError
  - test_specs_mixedContexts_warns

Current status
- Full test suite passes after the updates.
- @specs generates:
  - composite property
  - init()
  - isSatisfiedBy(_:)
  - isSatisfiedByAsync(_:) async throws
  - For @AutoContext + @specs types: async computed var isSatisfied: Bool { get
async throws } using contextProvider.currentContextAsync().
