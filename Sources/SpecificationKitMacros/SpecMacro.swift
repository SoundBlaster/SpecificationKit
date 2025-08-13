import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// An error that can be thrown by the SpecsMacro.
public enum SpecsMacroError: CustomStringConvertible, Error {
    /// Thrown when the `@specs` macro is used without any arguments.
    case requiresAtLeastOneArgument

    public var description: String {
        switch self {
        case .requiresAtLeastOneArgument:
            return "@specs macro requires at least one specification argument."
        }
    }
}

/// Implementation of the `@specs` macro, which generates a composite specification
/// from a list of individual specification instances.
///
/// For example:
/// `@specs(SpecA(), SpecB())`
/// will expand to a struct that conforms to `Specification` and combines `SpecA`
/// and `SpecB` with `.and()` logic.
public struct SpecsMacro: MemberMacro, AttachedMacro {

    // MARK: - MemberMacro

    /// This expansion adds the necessary members to the type to conform to `Specification`.
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // Ensure there's at least one specification provided.
        guard let arguments = node.arguments?.as(LabeledExprListSyntax.self), !arguments.isEmpty else {
            throw SpecsMacroError.requiresAtLeastOneArgument
        }

        // The first spec is the base of our chain.
        let firstSpec = arguments.first!.expression
        let otherSpecs = arguments.dropFirst()

        // Build the chain of .and() calls from the arguments.
        // e.g., spec1.and(spec2).and(spec3)
        let andChain = otherSpecs.reduce(into: firstSpec) { result, currentSpec in
            result = ExprSyntax(
                FunctionCallExprSyntax(
                    calledExpression: MemberAccessExprSyntax(
                        base: result,
                        name: .identifier("and")
                    ),
                    leftParen: .leftParenToken(),
                    arguments: LabeledExprListSyntax {
                        LabeledExprSyntax(expression: currentSpec.expression)
                    },
                    rightParen: .rightParenToken()
                )
            )
        }
        
        // Generate the required code as string literals and parse them into syntax nodes.
        let compositeProperty: DeclSyntax =
            "private let composite: AnySpecification<EvaluationContext>"

        let initializer: DeclSyntax =
            """
            public init() {
                let specChain = \(andChain)
                self.composite = AnySpecification(specChain)
            }
            """

        let isSatisfiedByMethod: DeclSyntax =
            """
            public func isSatisfiedBy(_ candidate: EvaluationContext) -> Bool {
                composite.isSatisfiedBy(candidate)
            }
            """

        let typeAlias: DeclSyntax =
            "public typealias T = EvaluationContext"

        return [
            typeAlias,
            compositeProperty,
            initializer,
            isSatisfiedByMethod
        ]
    }

    // MARK: - AttachedMacro

    /// This expansion adds the `Specification` protocol conformance to the type.
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingConformancesOf type: some TypeSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [(TypeSyntax, GenericWhereClauseSyntax?)] {
        // The type that this macro is attached to will conform to `Specification`.
        return [(TypeSyntax("Specification"), nil)]
    }
}
