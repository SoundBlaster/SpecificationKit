# Planning Notes — Parameterized @Satisfies Initializers (2025-11-19)

## Goals
- Provide wrapper initializers that accept a specification type and labeled arguments while preserving compatibility with existing auto-context and manual-context overloads.

## Research Checklist
- [ ] Review `Satisfies.swift` overload resolution rules and identify safe entry points for a type + argument initializer.
- [ ] Confirm macro-generated calls from `SatisfiesMacro.swift` can target the new initializer without additional codegen changes.
- [ ] Evaluate type inference behavior for specs requiring multiple labeled parameters or defaulted arguments.

## Open Questions
- How should we surface errors when forwarded parameters do not match the spec initializer signature (e.g., rely on compiler diagnostics vs. custom messaging)?
- Do we need distinct overloads for context-providing specs versus manual context injection to avoid ambiguous matches?

## Next Update
- Populate findings from the initializer prototype and outline required test fixtures.

