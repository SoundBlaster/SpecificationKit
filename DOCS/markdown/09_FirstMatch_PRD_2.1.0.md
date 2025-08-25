# PRD: DecisionSpec and FirstMatchSpec Support in SpecificationKit

## 1. Overview

### Goal

Extend SpecificationKit beyond purely boolean specifications (`Specification<T> → Bool`) by introducing **decision-oriented specifications** that can return **payload results** in addition to `true/false`.

### Rationale

- Current specifications (e.g., `AndSpec`, `OrSpec`) answer only "does this rule hold?"  
- Many business rules require **categorization** or **prioritized outcomes** (e.g., discount tiers, experiment buckets, routing decisions).  
- By introducing `DecisionSpec`, SpecificationKit can evolve toward a **general-purpose rule engine** without breaking existing API contracts.

## 2. Feature Description

### Core Concept

- Introduce a new protocol:  
  ```swift
  protocol DecisionSpec {
      associatedtype Context
      associatedtype Result

      func decide(_ context: Context) -> Result?
  }
  ```

- Ordinary `Specification<T>` can be seen as a special case where `Result == Bool`.

### FirstMatchSpec

- New composite specification that evaluates children in order and returns the result of the first match.
- Example use case: determine the discount a user should receive.
```swift
let spec = FirstMatchSpec<UserContext, Int>([
    (isVipSpec, 50),
    (promoSpec, 20),
    (birthdaySpec, 10),
    (AlwaysTrueSpec(), 0) // fallback
])

let discount = spec.decide(userContext) // e.g. 50 if VIP
```

## 3. Property Wrapper Support

### Current

```swift
@Satisfies(MySpec()) var isAllowed: Bool
```

### New

Introduce `@Spec` wrapper that supports both boolean and decision-oriented specs:

```swift
@Spec(FirstMatchSpec([
    (isVipSpec, 50),
    (promoSpec, 20),
    (birthdaySpec, 10),
    (AlwaysTrueSpec(), 0)
]))
var discount: Int
```

- The wrapper infers `Result` type from the spec.
- Accessing the wrapped property evaluates the spec against a provided context.

## 4. Deliverables

### New Protocol

```swift
DecisionSpec<Context, Result> with decide(_:) -> Result?.
```

### New Spec

- `FirstMatchSpec<Context, Result>` implementing `DecisionSpec`.
- Minimal variant: returns first successful `Result`.
- Extended variant: also exposes index or identifier of matched spec.

### New Property Wrapper

- `@Spec` that works with both `Specification<T>` and `DecisionSpec<T, R>`.
- Evaluates automatically with injected `EvaluationContext` provider.

### Compatibility
	
- Existing `Specification` and `@Satisfies` remain untouched.
- `@Spec` is additive, not breaking.

## 5. Acceptance Criteria

1. API Stability: Existing users of @Satisfies and boolean-only specifications are unaffected.
2. Expressiveness: Developers can model prioritization and categorization logic using FirstMatchSpec.
3. Type-Safety: The Result type is inferred by the compiler (e.g., Int for discount).
4. Extensibility: DecisionSpec is generic and can be adopted for future DSL use.
5. Testing: XCTest suite covers:
	•	Single match, multiple matches, no match.
	•	Payload propagation correctness.
	•	Integration via @Spec wrapper.
  ```swift
  // Tests/FirstMatchSpecTests.swift
import XCTest
@testable import SpecificationKit

final class FirstMatchSpecTests: XCTestCase {

    // MARK: - Single match
    func test_FirstMatch_returnsPayload_whenSingleSpecMatches() {}
    func test_FirstMatch_shortCircuits_onSingleEarlyMatch() {}

    // MARK: - Multiple matches
    func test_FirstMatch_returnsFirstPayload_whenMultipleSpecsMatch() {}
    func test_FirstMatch_respectsPriorityOrder_withMultipleMatches() {}

    // MARK: - No match
    func test_FirstMatch_returnsNil_whenNoSpecsMatch() {}
    func test_FirstMatch_withFallbackAlwaysTrue_returnsFallbackPayload() {}

    // MARK: - Payload propagation correctness
    func test_Payload_isPropagatedExactly_asConfigured() {}
    func test_Payload_genericResultType_isCorrectlyInferred() {}

    // MARK: - Integration via @Spec wrapper
    func test_SpecWrapper_evaluatesDecisionSpec_andExposesResult() {}
    func test_SpecWrapper_updatesExposedResult_whenContextChanges() {}
}
  ```
  
## 6. Non-Functional Requirements

- Performance: Evaluation must short-circuit at the first satisfied child.
- Memory: No additional allocations compared to existing composite specs.
- Documentation: README and DocC pages updated with examples for FirstMatchSpec and @Spec.
- Clarity: Property wrapper API should mirror existing @Satisfies to avoid confusion.

## 7. Example Usage

```swift
struct UserContext {
    let isVip: Bool
    let isInPromo: Bool
    let isBirthday: Bool
}

// Define specs
let isVipSpec = PredicateSpec<UserContext> { $0.isVip }
let promoSpec = PredicateSpec<UserContext> { $0.isInPromo }
let birthdaySpec = PredicateSpec<UserContext> { $0.isBirthday }

// Combine
let discountSpec = FirstMatchSpec<UserContext, Int>([
    (isVipSpec, 50),
    (promoSpec, 20),
    (birthdaySpec, 10),
    (AlwaysTrueSpec(), 0)
])

// Evaluate
let user = UserContext(isVip: true, isInPromo: false, isBirthday: false)
let discount = discountSpec.decide(user) // → 50
```

With @Spec:

```swift
struct DiscountEngine {
    let context: UserContext

    @Spec(FirstMatchSpec([
        (isVipSpec, 50),
        (promoSpec, 20),
        (birthdaySpec, 10),
        (AlwaysTrueSpec(), 0)
    ]))
    var discount: Int
}
```

## 8. Future Iteration (Cliffhanger)

### 🚀 DSL Builder (Optional Future Work)

Introduce a @SpecBuilder DSL for more declarative rule definitions:

```Swift
@SpecBuilder(userContext)
var discount: Int {
    FirstMatch {
        isVipSpec => 50
        promoSpec => 20
        birthdaySpec => 10
        AlwaysTrueSpec() => 0
    }
}
```

This would leverage Swift’s @resultBuilder for more natural configuration syntax.

## 9. Open Questions

- Should FirstMatchSpec expose both Result and index of matched spec?
- Should @Spec wrapper accept external context provider injection, like @Satisfies does today?
- Should DecisionSpec inherit from Specification (wrapping Bool) or remain parallel?