codex
Added @AutoContext usage in the Demo app and verified it builds. Ready to procee
d with conformance support and more tests.

What I changed
- Demo usage: Introduced a simple auto-context spec and displayed it in the UI.
  - File: DemoApp/Sources/DecisionsDemoView.swift
  - Added:
    - @AutoContext struct PromoEnabledSpec: checks EvaluationContext flag "promo
".
    - Row showing result via property wrapper:
      - @Satisfies(provider: PromoEnabledSpec.contextProvider, using: PromoEnabl
edSpec())
      - Displays “@AutoContext PromoEnabledSpec: ON/OFF”.
- Build verified:
  - swift build (root) and DemoApp build both succeed.

Next steps I can take
- Implement conformance support:
  - Extend the macro to add AutoContextSpecification conformance (requires Confo
rmanceMacro support).
  - Enforce Provider.Context == T constraint at compile time.
- Add tests:
  - Positive: @Satisfies(using: SpecType) path works when spec has @AutoContext
and conformance.
  - Negative: Mismatched context types produce clear diagnostics.
