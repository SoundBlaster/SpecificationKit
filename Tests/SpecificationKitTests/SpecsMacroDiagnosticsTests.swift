import XCTest
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
@testable import SpecificationKitMacros

private let testMacros: [String: Macro.Type] = [
    "specs": SpecsMacro.self,
]

final class SpecsMacroDiagnosticsTests: XCTestCase {
    func test_specs_emptyArgs_emitsErrorDiagnostic() {
        assertMacroExpansion(
            """
            @specs()
            struct Empty: Specification { typealias T = EvaluationContext }
            """,
            expandedSource: """
            struct Empty: Specification { typealias T = EvaluationContext }
            """,
            diagnostics: [
                .init(
                    message: "@specs macro requires at least one specification argument.",
                    line: 1,
                    column: 1
                )
            ],
            macros: testMacros
        )
    }

    func test_specs_mustBeAppliedToSpecificationType() {
        assertMacroExpansion(
            """
            @specs(MaxCountSpec(counterKey: "c", limit: 1))
            struct NotSpec {}
            """,
            expandedSource: """
            struct NotSpec {}
            """,
            diagnostics: [
                .init(
                    message: "@specs macro must be used on a type conforming to `Specification`.",
                    line: 1,
                    column: 1
                )
            ],
            macros: testMacros
        )
    }

    func test_specs_warnsWhenMissingTypealiasT() {
        assertMacroExpansion(
            """
            @specs(MaxCountSpec(counterKey: "c", limit: 1))
            struct MissingT: Specification {}
            """,
            expandedSource: """
            struct MissingT: Specification {
            
                private let composite: AnySpecification<T>

                public init() {
                    let specChain = MaxCountSpec(counterKey: "c", limit: 1)
                    self.composite = AnySpecification(specChain)
                }

                public func isSatisfiedBy(_ candidate: T) -> Bool {
                    composite.isSatisfiedBy(candidate)
                }

                public func isSatisfiedByAsync(_ candidate: T) async throws -> Bool {
                    composite.isSatisfiedBy(candidate)
                }}
            """,
            diagnostics: [
                .init(
                    message: "Specification type appears to be missing typealias T (e.g. 'typealias T = EvaluationContext').",
                    line: 1,
                    column: 1,
                    severity: .warning
                )
            ],
            macros: testMacros
        )
    }

    func test_specs_argumentLiteral_emitsError() {
        assertMacroExpansion(
            """
            @specs("oops")
            struct BadArg: Specification { typealias T = EvaluationContext }
            """,
            expandedSource: """
            struct BadArg: Specification { typealias T = EvaluationContext 

                private let composite: AnySpecification<T>

                public init() {
                    let specChain = "oops"
                    self.composite = AnySpecification(specChain)
                }

                public func isSatisfiedBy(_ candidate: T) -> Bool {
                    composite.isSatisfiedBy(candidate)
                }

                public func isSatisfiedByAsync(_ candidate: T) async throws -> Bool {
                    composite.isSatisfiedBy(candidate)
                }}
            """,
            diagnostics: [
                .init(
                    message: "Argument #1 to @specs does not appear to be a specification instance.",
                    line: 1,
                    column: 1
                )
            ],
            macros: testMacros
        )
    }

    func test_specs_mixedContexts_errorsWhenConfident() {
        assertMacroExpansion(
            """
            @specs(PredicateSpec<CustomContext> { _ in true }, MaxCountSpec(counterKey: "c", limit: 1))
            struct MixedCtx: Specification { typealias T = EvaluationContext }
            """,
            expandedSource: """
            struct MixedCtx: Specification { typealias T = EvaluationContext 
            
                private let composite: AnySpecification<T>

                public init() {
                    let specChain = PredicateSpec<CustomContext> { _ in
                        true
                    } .and(MaxCountSpec(counterKey: "c", limit: 1))
                    self.composite = AnySpecification(specChain)
                }

                public func isSatisfiedBy(_ candidate: T) -> Bool {
                    composite.isSatisfiedBy(candidate)
                }

                public func isSatisfiedByAsync(_ candidate: T) async throws -> Bool {
                    composite.isSatisfiedBy(candidate)
                }}
            """,
            diagnostics: [
                .init(
                    message: "@specs arguments use mixed Context types (CustomContext, EvaluationContext). All specs must share the same Context.",
                    line: 1,
                    column: 1,
                    severity: .error
                )
            ],
            macros: testMacros
        )
    }

    func test_specs_asyncArgument_emitsError() {
        assertMacroExpansion(
            """
            @specs(AnyAsyncSpecification<EvaluationContext> { _ in true })
            struct AsyncArg: Specification { typealias T = EvaluationContext }
            """,
            expandedSource: """
            struct AsyncArg: Specification { typealias T = EvaluationContext 

                private let composite: AnySpecification<T>

                public init() {
                    let specChain = AnyAsyncSpecification<EvaluationContext> { _ in
                        true
                    }
                    self.composite = AnySpecification(specChain)
                }

                public func isSatisfiedBy(_ candidate: T) -> Bool {
                    composite.isSatisfiedBy(candidate)
                }

                public func isSatisfiedByAsync(_ candidate: T) async throws -> Bool {
                    composite.isSatisfiedBy(candidate)
                }}
            """,
            diagnostics: [
                .init(
                    message: "Argument #1 to @specs appears to be an async specification. Use a synchronous Specification instead.",
                    line: 1,
                    column: 1
                )
            ],
            macros: testMacros
        )
    }

    func test_specs_mixedContexts_warnsWhenNotConfident() {
        assertMacroExpansion(
            """
            @specs(PredicateSpec<CustomContext> { _ in true }, MaxCountSpec(counterKey: "c", limit: 1), UnknownSpec())
            struct MixedCtxWarn: Specification { typealias T = EvaluationContext }
            """,
            expandedSource: """
            struct MixedCtxWarn: Specification { typealias T = EvaluationContext 
            
                private let composite: AnySpecification<T>

                public init() {
                    let specChain = PredicateSpec<CustomContext> { _ in
                        true
                    } .and(MaxCountSpec(counterKey: "c", limit: 1)).and(UnknownSpec())
                    self.composite = AnySpecification(specChain)
                }

                public func isSatisfiedBy(_ candidate: T) -> Bool {
                    composite.isSatisfiedBy(candidate)
                }

                public func isSatisfiedByAsync(_ candidate: T) async throws -> Bool {
                    composite.isSatisfiedBy(candidate)
                }}
            """,
            diagnostics: [
                .init(
                    message: "@specs arguments appear to use mixed Context types (CustomContext, EvaluationContext). Ensure all specs share the same Context.",
                    line: 1,
                    column: 1,
                    severity: .warning
                )
            ],
            macros: testMacros
        )
    }
}
