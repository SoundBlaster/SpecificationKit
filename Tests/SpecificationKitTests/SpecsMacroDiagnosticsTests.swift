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
}

