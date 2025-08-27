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
            }
            """,
            diagnostics: [
                .init(
                    message: "Specification type appears to be missing typealias T (e.g. 'typealias T = EvaluationContext').",
                    line: 1,
                    column: 1
                )
            ],
            macros: testMacros
        )
    }
}
