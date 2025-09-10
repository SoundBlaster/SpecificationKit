  .target(
      name: "SpecificationKitMacros",
      dependencies: [
          .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
          .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
      ]
  ),
  ```
- [x] Link Macro to Main Library: Expose the macro from `SpecificationKitMacros` and add it as a plugin dependency to the main `SpecificationKit` target in `Package.swift`.
  ```swift
  .target(name: "SpecificationKit", dependencies: [
      ...,
      "SpecificationKitMacros"
  ]),
  ```
- [x] Add Testing Dependency: Add swift-macro-testing to the `SpecificationKitTests` target dependencies for unit testing the macro expansion.

⸻

✅ 2. `@specs` Macro Implementation

- [x] Create Macro Definition File: Create a new file `SpecsMacro.swift` inside `Sources/SpecificationKitMacros/`.

- [x] Define `@specs` Macro Struct:
   - Define a public struct `SpecsMacro`.\
   - Have it conform to `MemberMacro` to add new members to the type it's attached to.

- [x] Implement Macro Expansion:
   - Implement the required `expansion(of:providingMembersOf:in:)` method.
   - Parse the arguments passed to the `@specs(...)` attribute.
   - Validate that all arguments are initializers for types conforming to `Specification`.

- [x] Generate composite Property:
   - Generate the private stored property: `private let composite: AnySpecification<EvaluationContext>`.

- [x] Generate `init()` Method:
   - Generate the `init()` method.
   - Inside the initializer, build the chain of specifications using `.and()`.
   - The first spec is the base, and subsequent specs are appended with `.and(...)`.
   - Assign the final composed specification to the composite property, wrapped in `AnySpecification`.

- [x] Generate `isSatisfiedBy(_:)` Method:
   - Generate the `isSatisfiedBy(_ context: EvaluationContext) -> Bool` method.
   - The implementation should simply delegate the call to the generated composite property: `composite.isSatisfiedBy(context)`.

⸻

✅ 3. Plugin Registration

- [x] Create Plugin Entry Point: Create a `Plugin.swift` file in `Sources/SpecificationKitMacros/`.

- [x] Register the Macro: Implement a struct conforming to `CompilerPlugin` and expose the `SpecsMacro` implementation.
  ```swift
  @main
  struct SpecificationKitPlugin: CompilerPlugin {
      let providingMacros: [Macro.Type] = [
          SpecsMacro.self,
      ]
  }
  ```

⸻

✅ 4. Unit Testing

- [x] Create Test File: Create `SpecsMacroTests.swift` in the `Tests/SpecificationKitTests/` directory.

- [x] Test Single Spec Expansion: Write a test to verify that `@specs(SomeSpec())` expands correctly to the full struct implementation.

- [x] Test Multiple Specs Expansion: Write a test to ensure that `@specs(SpecA(), SpecB(), SpecC())` correctly generates the `.and()` chain.

- [ ] Test Error Conditions: (Optional but recommended)
   - Write a test to ensure the macro produces a compile-time error if a non-Specification type is passed as an argument.
   - Verify that the diagnostic message is clear and helpful.

⸻

✅ 5. Documentation & Integration

- [x] Update `README.md`: Document the new @specs macro, including its purpose and a clear usage example.
- [x] Update `DemoApp/`: Modify an example in the demo application to use the new macro, showcasing its simplicity.
- [x] Update `00_SpecificationKit_TODO.md`: Mark the macro-related tasks as complete.
````
