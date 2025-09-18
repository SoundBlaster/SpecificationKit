# MockSpecificationBuilder

Configurable test doubles for specification-based logic.

## Overview

`MockSpecificationBuilder` lets you construct deterministic `Specification` implementations for unit tests without re-implementing production logic. The builder surfaces multiple behaviors—fixed responses, contextual predicates, probabilistic outcomes, and timed delays—while the generated `MockSpecification` captures every evaluation for later inspection.

Use the builder when you need:

- Stable responses while validating orchestration and composition
- Synthetic latency to benchmark caching or async flows
- Randomized outcomes with reproducible probability control
- Rich telemetry about evaluation order, call counts, or recorded contexts

## Quick Start

```swift
import SpecificationKit
import XCTest

final class LoginSpecTests: XCTestCase {
    func testLoginRequiresFeatureFlag() {
        // Given a deterministic specification that always fails
        let featureGate = MockSpecificationBuilder<EvaluationContext>()
            .alwaysReturns(false)
            .build()

        let gate = featureGate.not()
        let context = EvaluationContext()

        // When
        let allowed = gate.isSatisfiedBy(context)

        // Then
        XCTAssertFalse(allowed)
        XCTAssertEqual(featureGate.callCount, 1)
    }
}
```

## Behavior Modes

Configure the mock using fluent helpers:

- `alwaysReturns(_:)` for fixed `true`/`false` responses
- `returns(_:)` to evaluate an arbitrary closure
- `withDelay(_:returning:)` for deterministic latency
- `withRandomResult(probability:)` for Bernoulli-style success rates
- `withSequence(_:)` to iterate through a repeating result list
- `withContextBoolean(_:)` to read Boolean values directly from the evaluation context
- `willThrow(_:)` to simulate fatal error scenarios during testing

Every configuration can be combined with `withExecutionTime(_:)` to add baseline evaluation overhead.

## Call Recording & Inspection

`MockSpecification` automatically tracks each invocation:

```swift
let mock = MockSpecificationBuilder<Int>()
    .withSequence([true, false])
    .build()

_ = mock.isSatisfiedBy(1)
_ = mock.isSatisfiedBy(2)

XCTAssertEqual(mock.callCount, 2)
XCTAssertEqual(mock.allResults, [true, false])
XCTAssertEqual(mock.recordedCalls.last?.context, 2)
```

Reset the mock between tests with `reset()` to clear history and sequence position.

## Convenience Factories

Common scenarios are available as static helpers:

```swift
let alwaysPassing = MockSpecificationBuilder<String>.alwaysTrue()
let flaky = MockSpecificationBuilder<String>.flaky(successRate: 0.2)
let slow = MockSpecificationBuilder<String>.slow(delay: 0.05)
```

These helpers return fully configured `MockSpecification` instances backed by separate builders.

## Thread Safety

`MockSpecification` uses a concurrent queue with barrier writers to guard state, allowing you to exercise concurrent evaluation paths safely:

```swift
let mock = MockSpecificationBuilder<Void>()
    .returns { _ in true }
    .build()

await withTaskGroup(of: Void.self) { group in
    for _ in 0..<10 {
        group.addTask { _ = mock.isSatisfiedBy(()) }
    }
}

XCTAssertEqual(mock.callCount, 10)
```

This makes the builder suitable for stress-testing actors, queues, and composite specifications under load.
