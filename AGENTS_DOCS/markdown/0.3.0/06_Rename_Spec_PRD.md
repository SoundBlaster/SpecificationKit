# PRD: Rename Property Wrapper `@Spec` → `@Decides`

## 1. Scope & Intent

**Goal:**
Unify terminology and improve developer experience by renaming the decision-specification property wrapper from `@Spec` to `@Decides`.

**Rationale:**
- Current naming (`@Spec`) is ambiguous and collides conceptually with the macro `@spec`.
- Capitalized attribute name (`@Spec`) breaks Swift ecosystem conventions (`@Published`, `@State`, etc.).
- `@Decides` is semantically aligned with the domain (Decision Specifications) and clearly expresses intent: “this decides a value based on rules.”

**Deliverable:**
A backward-compatible migration where `@Decides` becomes the canonical name, and `@Spec` remains as a deprecated alias.

## 2. Functional Requirements

1. **Property Wrapper Definition**
   - Introduce `@Decides<Context, Result>` property wrapper, identical in functionality to the existing `@Spec`.
   - Provide constructors for:
     - `FirstMatchSpec`
     - Array of `(Specification, Result)` pairs
     - Builder pattern
     - Fallback support
     - Custom context providers

2. **Deprecation Layer**
   - Retain `@Spec` as a typealias to `@Decides`.
   - Mark `@Spec` with `@available(*, deprecated, message: "Use @Decides instead")`.

3. **Source Code Updates**
   - Update all internal references in codebase from `@Spec` to `@Decides`.
   - Update documentation comments, README, and DocC examples.

4. **Test Suite Updates**
   - Rename or duplicate test cases to cover `@Decides`.
   - Keep at least one legacy test using `@Spec` to ensure alias works.

5. **Examples & Samples**
   - Replace `@Spec` with `@Decides` in all sample code (e.g., `DiscountDecisionExample.swift`).
   - Provide explicit migration example in README.

## 3. Non-Functional Requirements

- **Backward Compatibility:** Existing user code with `@Spec` compiles but produces deprecation warnings.
- **Clarity:** Documentation consistently explains that `@Decides` is the recommended wrapper.
- **Consistency:** Align naming with `@Satisfies`, creating a natural pair:
  - `@Satisfies` → Boolean Specification
  - `@Decides` → Decision Specification

## 4. Migration Plan

1. **Implementation Phase**
   - Add `@Decides` wrapper.
   - Add `typealias Spec = Decides` with deprecation.
   - Update core code and tests.

2. **Documentation Phase**
   - Update DocC guides, README, and examples.
   - Add “Migration from @Spec to @Decides” section.

3. **Release Phase**
   - Ship in version `0.3.0`.
   - Mark `@Spec` as deprecated but functional.

4. **Future Removal**
   - Remove `@Spec` in `0.5.0` (major bump), after at least one deprecation cycle.

## 5. User Interaction Flow

**Before:**

```swift
@Spec(FirstMatchSpec([
    (isVipSpec, 50),
    (promoSpec, 20),
    (birthdaySpec, 10),
    (AlwaysTrueSpec(), 0)
]))
var discount: Int
```

**After:**

```swift
@Decides(FirstMatchSpec([
    (isVipSpec, 50),
    (promoSpec, 20),
    (birthdaySpec, 10),
    (AlwaysTrueSpec(), 0)
]))
var discount: Int
```

**Migration Note:**

If using `@Spec`, a deprecation warning appears:

`'Spec' is deprecated: Use @Decides instead`

## 6. Edge Cases & Risks

- Risk: Developers may confuse @Decides with a Boolean decision.
Mitigation: Documentation emphasizes that @Satisfies is for Boolean, @Decides is for typed outcomes.
- Risk: Large user codebases need time to migrate.
Mitigation: Provide deprecation alias for at least two minor releases.
- Risk: Autocomplete may still suggest @Spec.
Mitigation: Xcode shows deprecation message.

## 7. Acceptance Criteria

- ✅ @Decides works as a full replacement of @Spec.
- ✅ All docs/examples use @Decides.
- ✅ Tests for @Decides pass.
- ✅ @Spec issues deprecation warnings but compiles.
- ✅ Release notes clearly state migration path.

## 8. Summary

At the end of the work, please add a file with a feature summary in Markdown format to the folder `DOCS/markdown/0.3.0`.
