//
//  AutoContextMacroComprehensiveTests.swift
//  SpecificationKitTests
//
//  Created by SpecificationKit on 2025.
//

import MacroTesting
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

@testable import SpecificationKit
@testable import SpecificationKitMacros

private let testMacros: [String: Macro.Type] = [
    "AutoContext": AutoContextMacro.self
]

final class AutoContextMacroComprehensiveTests: XCTestCase {

    override func invokeTest() {
        withMacroTesting(
            // isRecording: true,
            macros: testMacros
        ) {
            super.invokeTest()
        }
    }

    // MARK: - Basic Expansion Tests

    func testAutoContextMacro_BasicExpansion_Struct() {
        assertMacroExpansion(
            """
            @AutoContext
            struct TestSpec: Specification {
                typealias T = EvaluationContext

                func isSatisfiedBy(_ context: EvaluationContext) -> Bool {
                    true
                }
            }
            """,
            expandedSource: """
                struct TestSpec: Specification {
                    typealias T = EvaluationContext

                    func isSatisfiedBy(_ context: EvaluationContext) -> Bool {
                        true
                    }

                    public typealias Provider = DefaultContextProvider

                    public static var contextProvider: DefaultContextProvider {
                        DefaultContextProvider.shared
                    }
                }
                """,
            macros: testMacros
        )
    }

    func testAutoContextMacro_BasicExpansion_Class() {
        assertMacroExpansion(
            """
            @AutoContext
            class TestSpec: Specification {
                typealias T = EvaluationContext

                func isSatisfiedBy(_ context: EvaluationContext) -> Bool {
                    true
                }
            }
            """,
            expandedSource: """
                class TestSpec: Specification {
                    typealias T = EvaluationContext

                    func isSatisfiedBy(_ context: EvaluationContext) -> Bool {
                        true
                    }

                    public typealias Provider = DefaultContextProvider

                    public static var contextProvider: DefaultContextProvider {
                        DefaultContextProvider.shared
                    }
                }
                """,
            macros: testMacros
        )
    }

    func testAutoContextMacro_BasicExpansion_Enum() {
        assertMacroExpansion(
            """
            @AutoContext
            enum TestSpec: Specification {
                typealias T = EvaluationContext

                func isSatisfiedBy(_ context: EvaluationContext) -> Bool {
                    true
                }
            }
            """,
            expandedSource: """
                enum TestSpec: Specification {
                    typealias T = EvaluationContext

                    func isSatisfiedBy(_ context: EvaluationContext) -> Bool {
                        true
                    }

                    public typealias Provider = DefaultContextProvider

                    public static var contextProvider: DefaultContextProvider {
                        DefaultContextProvider.shared
                    }
                }
                """,
            macros: testMacros
        )
    }

    // MARK: - Integration Tests with Real Specifications

    func testAutoContextMacro_IntegrationWithFeatureFlagSpecification() {
        // Create a specification that uses @AutoContext
        @AutoContext
        struct FeatureFlagCheck: Specification {
            typealias T = EvaluationContext
            let flagKey: String

            func isSatisfiedBy(_ context: EvaluationContext) -> Bool {
                context.flag(for: flagKey)
            }
        }

        // Test that the injected members work correctly
        XCTAssertTrue(FeatureFlagCheck.Provider.self == DefaultContextProvider.self)
        XCTAssertNotNil(FeatureFlagCheck.contextProvider)
        XCTAssertTrue(type(of: FeatureFlagCheck.contextProvider) == DefaultContextProvider.self)

        // Test that it provides DefaultContextProvider.shared
        XCTAssertTrue(FeatureFlagCheck.contextProvider === DefaultContextProvider.shared)

        // Test that it works with @Satisfies
        let provider = DefaultContextProvider.shared
        provider.clearAll()
        provider.setFlag("testFlag", to: true)

        @Satisfies(
            provider: FeatureFlagCheck.contextProvider,
            using: FeatureFlagCheck(flagKey: "testFlag"))
        var isFeatureEnabled: Bool

        let initialEvaluation = isFeatureEnabled
        if !initialEvaluation {
            XCTFail("FeatureFlagCheck should evaluate to true for the initial flag state")
        }

        // Change flag and test again
        provider.setFlag("testFlag", to: false)
        let updatedEvaluation = isFeatureEnabled
        if updatedEvaluation {
            XCTFail("FeatureFlagCheck should evaluate to false after toggling the flag")
        }
    }

    func testAutoContextMacro_IntegrationWithCustomSpecification() {
        @AutoContext
        struct CustomCounterSpec: Specification {
            typealias T = EvaluationContext
            let counterKey: String
            let threshold: Int

            func isSatisfiedBy(_ context: EvaluationContext) -> Bool {
                context.counter(for: counterKey) < threshold
            }
        }

        // Test the injected provider
        let provider = CustomCounterSpec.contextProvider
        provider.clearAll()
        provider.incrementCounter("test")
        provider.incrementCounter("test")

        let spec = CustomCounterSpec(counterKey: "test", threshold: 5)
        let context = provider.currentContext()

        XCTAssertTrue(spec.isSatisfiedBy(context))

        // Increment beyond threshold
        provider.incrementCounter("test")
        provider.incrementCounter("test")
        provider.incrementCounter("test")

        let newContext = provider.currentContext()
        XCTAssertFalse(spec.isSatisfiedBy(newContext))
    }

    // MARK: - Edge Cases

    func testAutoContextMacro_WithExistingMembers() {
        assertMacroExpansion(
            """
            @AutoContext
            struct TestSpecWithMembers: Specification {
                typealias T = EvaluationContext
                let existingProperty: String

                func isSatisfiedBy(_ context: EvaluationContext) -> Bool {
                    true
                }

                func existingMethod() -> String {
                    existingProperty
                }
            }
            """,
            expandedSource: """
                struct TestSpecWithMembers: Specification {
                    typealias T = EvaluationContext
                    let existingProperty: String

                    func isSatisfiedBy(_ context: EvaluationContext) -> Bool {
                        true
                    }

                    func existingMethod() -> String {
                        existingProperty
                    }

                    public typealias Provider = DefaultContextProvider

                    public static var contextProvider: DefaultContextProvider {
                        DefaultContextProvider.shared
                    }
                }
                """,
            macros: testMacros
        )
    }

    func testAutoContextMacro_WithGenericSpecification() {
        assertMacroExpansion(
            """
            @AutoContext
            struct GenericTestSpec<T>: Specification {
                typealias T = EvaluationContext

                func isSatisfiedBy(_ context: EvaluationContext) -> Bool {
                    true
                }
            }
            """,
            expandedSource: """
                struct GenericTestSpec<T>: Specification {
                    typealias T = EvaluationContext

                    func isSatisfiedBy(_ context: EvaluationContext) -> Bool {
                        true
                    }

                    public typealias Provider = DefaultContextProvider

                    public static var contextProvider: DefaultContextProvider {
                        DefaultContextProvider.shared
                    }
                }
                """,
            macros: testMacros
        )
    }

    func testAutoContextMacro_WithInheritanceClause() {
        assertMacroExpansion(
            """
            @AutoContext
            struct TestSpecWithProtocols: Specification, Equatable, Hashable {
                typealias T = EvaluationContext

                func isSatisfiedBy(_ context: EvaluationContext) -> Bool {
                    true
                }
            }
            """,
            expandedSource: """
                struct TestSpecWithProtocols: Specification, Equatable, Hashable {
                    typealias T = EvaluationContext

                    func isSatisfiedBy(_ context: EvaluationContext) -> Bool {
                        true
                    }

                    public typealias Provider = DefaultContextProvider

                    public static var contextProvider: DefaultContextProvider {
                        DefaultContextProvider.shared
                    }
                }
                """,
            macros: testMacros
        )
    }

    // MARK: - Provider Type Tests

    func testAutoContextMacro_ProviderTypeAlias() {
        @AutoContext
        struct TestProviderAlias: Specification {
            typealias T = EvaluationContext

            func isSatisfiedBy(_ context: EvaluationContext) -> Bool {
                true
            }
        }

        // Test that Provider typealias is correct
        XCTAssertTrue(TestProviderAlias.Provider.self == DefaultContextProvider.self)

        // Test that we can use Provider in type annotations
        let provider: TestProviderAlias.Provider = DefaultContextProvider.shared
        XCTAssertNotNil(provider)
        XCTAssertTrue(type(of: provider) == DefaultContextProvider.self)
    }

    func testAutoContextMacro_ContextProviderProperty() {
        @AutoContext
        struct TestContextProvider: Specification {
            typealias T = EvaluationContext

            func isSatisfiedBy(_ context: EvaluationContext) -> Bool {
                true
            }
        }

        // Test that contextProvider is static
        let provider1 = TestContextProvider.contextProvider
        let provider2 = TestContextProvider.contextProvider

        // Should be the same instance (DefaultContextProvider.shared)
        XCTAssertTrue(provider1 === provider2)
        XCTAssertTrue(provider1 === DefaultContextProvider.shared)

        // Test that it provides EvaluationContext
        let context: EvaluationContext = provider1.currentContext()
        XCTAssertNotNil(context)
    }

    // MARK: - Real Usage Scenarios

    func testAutoContextMacro_ComplexSpecificationScenario() {
        @AutoContext
        struct ComplexBusinessRule: Specification {
            typealias T = EvaluationContext
            let userTier: String
            let actionType: String

            func isSatisfiedBy(_ context: EvaluationContext) -> Bool {
                let hasFeature = context.flag(for: "premium_features")
                let actionCount = context.counter(for: "daily_actions")
                let lastAction = Date()  // Simplified for test purposes

                // Complex business logic
                if userTier == "premium" && hasFeature {
                    return actionCount < 100
                } else if userTier == "basic" {
                    let timeSinceLastAction = Date().timeIntervalSince(lastAction)
                    return actionCount < 10 && timeSinceLastAction > 300  // 5 minutes
                }
                return false
            }
        }

        let provider = ComplexBusinessRule.contextProvider
        provider.clearAll()

        // Set up scenario
        provider.setFlag("premium_features", to: true)
        provider.setCounter("daily_actions", to: 5)
        provider.recordEvent("user_action")

        let spec = ComplexBusinessRule(userTier: "premium", actionType: "send_message")
        let context = provider.currentContext()

        XCTAssertTrue(spec.isSatisfiedBy(context))

        // Test with different scenario
        provider.setCounter("daily_actions", to: 105)
        let newContext = provider.currentContext()
        XCTAssertFalse(spec.isSatisfiedBy(newContext))
    }

    // MARK: - Compilation Tests

    func testAutoContextMacro_CompilesWithoutErrors() {
        // This test ensures that the macro generates valid Swift code
        @AutoContext
        struct CompilationTestSpec: Specification {
            typealias T = EvaluationContext

            func isSatisfiedBy(_ context: EvaluationContext) -> Bool {
                return context.flag(for: "test")
            }
        }

        // If this compiles and runs, the macro generated valid code
        XCTAssertNotNil(CompilationTestSpec.contextProvider)
        XCTAssertTrue(CompilationTestSpec.Provider.self == DefaultContextProvider.self)
    }

    // MARK: - Thread Safety Tests

    func testAutoContextMacro_ThreadSafety() {
        @AutoContext
        struct ThreadSafeSpec: Specification {
            typealias T = EvaluationContext

            func isSatisfiedBy(_ context: EvaluationContext) -> Bool {
                context.flag(for: "thread_test")
            }
        }

        let expectation = self.expectation(description: "Thread safety test")
        expectation.expectedFulfillmentCount = 10

        // Test concurrent access to the static contextProvider
        for i in 0..<10 {
            DispatchQueue.global().async {
                let provider = ThreadSafeSpec.contextProvider
                provider.setFlag("thread_test_\(i)", to: true)
                let context = provider.currentContext()
                XCTAssertNotNil(context)
                expectation.fulfill()
            }
        }

        waitForExpectations(timeout: 5.0)
    }

    // MARK: - Performance Tests

    func testAutoContextMacro_Performance() {
        @AutoContext
        struct PerformanceTestSpec: Specification {
            typealias T = EvaluationContext

            func isSatisfiedBy(_ context: EvaluationContext) -> Bool {
                context.flag(for: "perf_test")
            }
        }

        measure {
            for _ in 0..<1000 {
                let provider = PerformanceTestSpec.contextProvider
                let context = provider.currentContext()
                let spec = PerformanceTestSpec()
                _ = spec.isSatisfiedBy(context)
            }
        }
    }

    // MARK: - Error Scenarios

    func testAutoContextMacro_WithoutSpecificationConformance() {
        // This would be caught at compile time, but we can test that the macro
        // still generates the expected code structure
        assertMacroExpansion(
            """
            @AutoContext
            struct NonSpecification {
                let value: String
            }
            """,
            expandedSource: """
                struct NonSpecification {
                    let value: String

                    public typealias Provider = DefaultContextProvider

                    public static var contextProvider: DefaultContextProvider {
                        DefaultContextProvider.shared
                    }
                }
                """,
            macros: testMacros
        )
    }

    // MARK: - Documentation Examples

    func testAutoContextMacro_DocumentationExample() {
        // Example from documentation showing how @AutoContext simplifies usage
        @AutoContext
        struct UserPermissionCheck: Specification {
            typealias T = EvaluationContext
            let requiredPermission: String

            func isSatisfiedBy(_ context: EvaluationContext) -> Bool {
                context.flag(for: "has_\(requiredPermission)_permission")
            }
        }

        // Before @AutoContext, you would need to manually implement:
        // - typealias Provider = DefaultContextProvider
        // - static var contextProvider: DefaultContextProvider { .shared }

        // With @AutoContext, these are automatically generated
        XCTAssertTrue(UserPermissionCheck.Provider.self == DefaultContextProvider.self)
        XCTAssertTrue(UserPermissionCheck.contextProvider === DefaultContextProvider.shared)

        // Can be used directly with @Satisfies
        UserPermissionCheck.contextProvider.setFlag("has_read_permission", to: true)

        @Satisfies(
            provider: UserPermissionCheck.contextProvider,
            using: UserPermissionCheck(requiredPermission: "read"))
        var canReadPermission: Bool

        XCTAssertTrue(canReadPermission)
    }
}
