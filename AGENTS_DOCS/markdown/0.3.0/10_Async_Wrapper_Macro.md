codex
Yes. You have two good paths depending on how “hands‑off” you want it to feel:

- Property wrapper: add an async-aware wrapper to hide evaluateAsync.
- Macro: generate async members so call sites don’t mention evaluate at all.

Here’s what works well in today’s Swift.

Option A — @AsyncSatisfies wrapper
- Goal: Avoid calling _spec.evaluateAsync() directly; wrap async evaluation and
expose a clean API.
- Constraints: wrappedValue cannot be async. So expose:
  - wrappedValue: Bool? (last known value or nil before first evaluation)
  - projected API: async evaluate(), refresh(), task, and a publisher/AsyncSeque
nce for SwiftUI.
- Sketch:

  - Wrapper
    - @MainActor public struct AsyncSatisfies<Context> {
      - Stores provider.currentContextAsync, AnyAsyncSpecification<Context> or a
 sync predicate bridged to async
      - Keeps lastValue: Bool? and an internal Task to drive refresh
      - wrappedValue: Bool? (lastValue)
      - projectedValue: exposes async evaluate() and optionally an AsyncStream<B
ool>
    - Usage
      - @AsyncSatisfies(provider: DefaultContextProvider.shared,
                       predicate: { $0.flag(for: "feature_async") })
        var isEnabled: Bool?
      - await $isEnabled.evaluate()  // updates wrappedValue; SwiftUI can observ
e via onChange

- SwiftUI ergonomic add-ons:
  - projectedValue.publisher (Combine) or stream (AsyncSequence) so Views can bi
nd without manual Task.
  - projectedValue.refreshOnAppear() convenience to kick evaluation in .task or
.onAppear.

Option B — Async macro on the spec type
- Goal: no invocations at call sites; use async members the macro generates.
- Works by generating async members alongside @specs or as a sibling macro:

  - @asyncSpecs(…) or @specs(…) + async expansion
    - Adds an async method:
      - public func isSatisfiedByAsync(_ candidate: T) async throws -> Bool
    - If the spec knows its provider (AutoContext case), also add an async compu
ted property:
      - public var isSatisfied: Bool { get async throws }
    - Usage
      - if try await BannerSpec().isSatisfiedByAsync(ctx) { … }
      - If AutoContext: if try await BannerSpec().isSatisfied { … }

- Notes:
  - Swift supports effectful accessors (async/throws getters), so a macro can em
it:
    - public var isSatisfied: Bool { get async throws { … } }
  - For general @specs you can always emit isSatisfiedByAsync(_:) and only emit
isSatisfied for AutoContext specs that provide a static provider.

Recommended path
- Short term: implement @AsyncSatisfies — it gives a smooth, explicit API and wo
rks great in SwiftUI (publish results, auto-refresh).
- In parallel: extend @specs with async members (isSatisfiedByAsync, and isSatis
fied for AutoContext) so types feel first‑class in async code.

Concrete API suggestions

- @AsyncSatisfies wrapper

  - API
    - init(provider: ContextProviding, using: AnyAsyncSpecification or predicate
:)
    - wrappedValue: Bool?
    - projectedValue:
      - func evaluate() async throws -> Bool      // updates wrappedValue
      - var stream: AsyncStream<Bool>             // optional; emits updates
      - func refreshOnAppear() -> some View       // optional SwiftUI sugar

- @specs async expansion (macro)
  - Members to add
    - public func isSatisfiedByAsync(_ candidate: T) async throws -> Bool
    - If AutoContext (type has static contextProvider):
      - public var isSatisfied: Bool { get async throws }

Example usage

- Wrapper (no explicit evaluateAsync at call site)
  - @AsyncSatisfies(provider: DefaultContextProvider.shared,
                   predicate: { $0.flag(for: "feature_async") })
    var isFeatureOn: Bool?
  - .task { try? await $isFeatureOn.evaluate() }
  - SwiftUI can render isFeatureOn ?? false

- Macro (async accessor)
  - @specs(MaxCountSpec(counterKey: "tries", limit: 3))
    struct TryGate: Specification { typealias T = EvaluationContext }
  - if try await TryGate().isSatisfiedByAsync(ctx) { … }
  - If AutoContext:
    - @AutoContext @specs(FeatureFlagSpec(flagKey: "feature_async"))
      struct AsyncFlag: Specification { typealias T = EvaluationContext }
    - if try await AsyncFlag().isSatisfied { … }

Feasibility and effort
- Wrapper: straightforward; we already added Satisfies.evaluateAsync(). I can fa
ctor that into a new @AsyncSatisfies with lastValue + async evaluate and optiona
l publisher/stream in 1–2 passes.
- Macro: also feasible with current toolchain; add async codegen to SpecMacro (a
nd a sibling macro if you want to keep async separate). We’ll add tests to asser
t the async members and some diagnostics for AutoContext-only property generatio
n.

Want me to:
- Implement @AsyncSatisfies now (with lastValue and evaluate() + optional AsyncS
tream), or
- Extend @specs to emit isSatisfiedByAsync and (for AutoContext) an async isSati
sfied accessor?
