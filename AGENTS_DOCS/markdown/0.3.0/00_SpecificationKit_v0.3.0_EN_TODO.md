# SpecificationKit v0.3.0 – Definition of Done

> This document defines a set of deliverables for the next major release of SpecificationKit.
 
**Each item below should be implemented in a modular way, accompanied by unit tests and documentation.  Use clear commit messages and follow the existing folder structure described in the architecture documents.**

## 1. Implement the Macro System

### 1.1. @specs attached macro

	•	Create a new SwiftPM target named SpecificationKitMacros to host the code generation logic.  This target should compile separately from the main library.
	•	Implement an attached macro named @specs that accepts a comma‑separated list of types conforming to Specification.  The macro must:
	•	Generate a struct with a private composite: AnySpecification property.
	•	Generate an initializer that composes the listed specifications using .and() or .or() calls.
	•	Add an isSatisfiedBy(_:) method that delegates to composite.
	•	Add compile‑time validation:
	•	All arguments must conform to Specification and share the same Context type.
	•	If validation fails, the macro must emit a helpful diagnostic message.
	•	Provide unit tests using MacroTesting (or a similar package) that verify correct generation and error diagnostics.

### 1.2. @AutoContext attached macro

	•	Implement an attached macro @AutoContext that converts a plain specification into an auto‑context specification.  When applied to a struct conforming to Specification:
	•	Inject a static contextProvider property using a default provider (e.g. DefaultContextProvider).
	•	Synthesize a default initializer if none exists.
	•	Ensure that the provider’s Context type matches the specification’s Context.
	•	The macro must accept an optional type argument to override the default provider (e.g. @AutoContext(MyProvider.self)).
	•	Support future extensions such as environment or infer flags, as outlined in the AutoContext design document.
	•	Provide tests showing that an @AutoContext specification can be used with the existing @Satisfies wrapper without passing a context manually.  Include negative tests for type mismatches.

### 1.3. Prototype additional macros

	•	Design and prototype at least one of the following experimental macros:
	•	@specsIf(condition:) – generates a composite only when a compile‑time condition is true.
	•	#composed(...) – allows inline composition in expressions.
	•	@deriveSpec(from:) – derives a specification from annotated model properties.
	•	Provide a basic implementation and a brief usage example for the chosen macro.

## 2. Expand the Set of Built‑in Specifications

The first version includes TimeSinceEventSpec, MaxCountSpec, CooldownIntervalSpec and PredicateSpec.  In v2.0.0 add the following reusable specifications:

	•	DateRangeSpec: verifies that the current date/time (EvaluationContext.currentDate) falls within a specified range.
	•	FeatureFlagSpec: checks a boolean flag in EvaluationContext.flags and returns true only if the flag matches an expected value.
	•	UserSegmentSpec: matches the user against one or more logical segments (e.g. “new”, “subscriber”, “beta tester”).  Define an enum UserSegment and extend EvaluationContext with a segments property.
	•	SubscriptionStatusSpec: validates subscription state (active, expired, trial) retrieved from EvaluationContext.userData.
	•	DateComparisonSpec: generalises time‑based comparisons against a date stored in EvaluationContext.events with operators such as .before/.after.

For each new spec:

	•	Create a struct conforming to Specification with an explicit Context type.
	•	Add convenience factory methods and optional description strings.
	•	Add unit tests covering typical and edge cases.

## 3. Asynchronous and Reactive Support

	•	Extend ContextProviding with an asynchronous API: func currentContext() async throws -> Context.  Provide default synchronous and asynchronous implementations.
	•	Define a new protocol AsyncSpecification with associatedtype Context and func isSatisfiedBy(_ context: Context) async throws -> Bool.  Create a type‑erased wrapper AnyAsyncSpecification.
	•	Implement an asynchronous variant of the property wrapper (@AsyncSatisfies or by adding an async API to Satisfies) that awaits the context and evaluation.
	•	Write tests to verify correct behaviour of asynchronous specifications, including scenarios with delays and thrown errors.

## 4. Enhance Context Providers

	•	Implement EnvironmentContextProvider, which reads values from SwiftUI @Environment or @AppStorage to populate an EvaluationContext.  Provide an example integration within a SwiftUI view.
	•	Support dependency‑injection (DI) by allowing clients to set a global provider or pass providers through initializer injection.  Document the pattern.
	•	Provide the ability to observe changes in context (using Combine or AsyncSequence) and re‑evaluate bound specifications when the context updates.

## 5. Improve Property Wrappers

	•	Add a version of @Satisfies that publishes changes when the underlying specification result changes, enabling SwiftUI views to update automatically.  This can be done by integrating with ObservableObject or @Published.
	•	Support passing parameters directly into a specification via the wrapper, e.g. @Satisfies(using: CooldownIntervalSpec.self, interval: 10).  The wrapper should construct the specification with the given arguments.
	•	Ensure @Satisfies can work with any type conforming to ContextProviding, as demonstrated in the example with a generic ContextProviding protocol.

## 6. Documentation and Examples

	•	Update README.md to include sections on the macro system (@specs and @AutoContext), new built‑in specs and asynchronous features.
	•	Generate DocC documentation for all public APIs in the library, including macro descriptions and example code snippets.
	•	Create a new demo application (or extend DemoApp) to showcase macro usage, AutoContext integration and asynchronous context retrieval in a SwiftUI environment.

## 7. Infrastructure and Continuous Integration

	•	Add GitHub Actions workflows to build all targets (library, macros and tests) and run tests across the supported platforms (macOS, iOS, tvOS, watchOS).
	•	Prepare the package for publishing on the Swift Package Index: supply metadata, license and a clean semantic‑versioned tag (e.g. 2.0.0).
	•	Maintain a CHANGELOG.md with entries describing the new features and breaking changes introduced in version 2.0.0.

## 8. Testing and Quality Assurance

	•	Cover all new macros with unit tests that verify code generation and failure cases.
	•	Write comprehensive tests for every new specification introduced in section 2.
	•	Add performance benchmarks to measure overhead of specification composition and macro‑generated code.  Optimise as necessary.
	•	Ensure code follows the Swift API Design Guidelines and the existing naming conventions in the project.

## 9. Performance and Refactoring

	•	Investigate potential bottlenecks in AnySpecification and reduce overhead, possibly by adding @inlinable attributes where appropriate.
	•	Measure the compilation impact of macros and optimise macro code to minimise build times.
	•	Review and refactor existing code for clarity and maintainability, ensuring consistent use of generics and extensions.

⸻

**Following this roadmap will deliver a comprehensive SpecificationKit 2.0 release with macro‑driven declarative composition, auto‑context support, a richer suite of specifications, asynchronous features and improved developer ergonomics.  Each task should be addressed with proper unit tests and documentation so that a downstream agent can confidently build, test and maintain the library.**