# Async Spec

## Step 1

codex
Great — started the async features via TDD and got the first slice green.

What I added (tests first)
- Async tests
  - File: Tests/SpecificationKitTests/AsyncFeaturesTests.swift
  - Cases:
    - test_ContextProviding_asyncDefault_returnsContext: Awaits async context fr
om provider.
    - test_AnyAsyncSpecification_predicate: Verifies AnyAsyncSpecification with
an async predicate.
    - test_Satisfies_evaluateAsync_usesProvider: Demonstrates awaiting context a
nd evaluating a predicate through provider (bridged in test helper).

What I implemented to pass tests
- AsyncSpecification + type erasure
  - File: Sources/SpecificationKit/Core/AsyncSpecification.swift
  - Protocol: AsyncSpecification { associatedtype T; func isSatisfiedBy(_:) asyn
c throws -> Bool }
  - Type-erased: AnyAsyncSpecification<T> with:
    - init<S: AsyncSpecification>(_:)
    - init((_:) async throws -> Bool)
    - Bridge from sync Specification: init<S: Specification>(_:)

- Async context convenience
  - File: Sources/SpecificationKit/Core/ContextProviding.swift
  - Added extension method:
    - public func currentContextAsync() async throws -> Context
    - Default bridges to sync currentContext()

Notes
- I used currentContextAsync() rather than overloading currentContext() to avoid
 ambiguity/recursion in Swift overload resolution inside async contexts.
- The wrapper-level async API is not yet added. If wanted, I can add Satisfies.e
valuateAsync() that:
  - Awaits provider.currentContextAsync()
  - Evaluates the stored specification
  - Returns Bool

## Step 2

codex
Progress: async features — first two tasks done via TDD, third implemented and t
ested.

What I did
- Tests added: Tests/SpecificationKitTests/AsyncFeaturesTests.swift
  - ContextProviding async default returns context.
  - AnyAsyncSpecification predicate evaluates asynchronously.
  - Satisfies.evaluateAsync uses provider’s async context.

- Implemented core async types
  - AsyncSpecification + AnyAsyncSpecification
    - File: Sources/SpecificationKit/Core/AsyncSpecification.swift
    - Protocol and type-erased wrapper with sync-bridge initializer.
  - Async context convenience
    - File: Sources/SpecificationKit/Core/ContextProviding.swift
    - Added currentContextAsync() defaulting to sync bridge.

- Wrapper async API
  - Satisfies.evaluateAsync()
    - File: Sources/SpecificationKit/Wrappers/Satisfies.swift
    - Stores optional async context factory; initializers capture provider.curre
ntContextAsync.
    - Added projectedValue for accessing helper methods where needed.

Status
- All tests pass, including the new async tests.
- Changes kept minimal and localized.

## Step 3

codex
Async features extended and demo added — implemented and verified via TDD.

What I added
- Async tests
  - File: Tests/SpecificationKitTests/AsyncFeaturesTests.swift
  - New cases:
    - Throws + delay: AnyAsyncSpecification that throws on a flag and awaits a s
hort delay.
    - Already present: async context bridge, async predicate, and Satisfies.eval
uateAsync usage.
- Async core APIs
  - File: Sources/SpecificationKit/Core/AsyncSpecification.swift
    - AsyncSpecification protocol.
    - AnyAsyncSpecification<T> with:
      - init((_:) async throws -> Bool)
      - init<S: AsyncSpecification>(_:)
      - Sync Specification bridge init.
  - File: Sources/SpecificationKit/Core/ContextProviding.swift
    - currentContextAsync() default implementation bridging to sync.
- Property wrapper async eval
  - File: Sources/SpecificationKit/Wrappers/Satisfies.swift
    - Stores optional async context factory.
    - Added evaluateAsync() returning Bool using async context if present.
    - Initializers now capture provider.currentContextAsync.
- DemoApp: Async Specs screen
  - File: DemoApp/Sources/AsyncDemoView.swift
    - Toggles: feature flag, simulate error, add delay.
    - Button evaluates an AnyAsyncSpecification with optional delay and error, t
hen reports result.
  - App nav updated:
    - File: DemoApp/Sources/main.swift
    - Adds “Async Specs” navigation link.
  - Build verified for both root and DemoApp.

Notes
- I used currentContextAsync() instead of overloading currentContext() to avoid
ambiguity.
- Satisfies.evaluateAsync evaluates the stored sync spec with an async context;
async spec composition remains explicit via AnyAsyncSpecification in the demo/te
sts.
- Tests cover both thrown errors and delays without adding significant runtime (
10ms delay).
