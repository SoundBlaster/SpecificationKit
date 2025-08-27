import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// An error that can be thrown by the SpecsMacro.
public enum SpecsMacroError: CustomStringConvertible, Error {
    /// Thrown when the `@specs` macro is used without any arguments.
    case requiresAtLeastOneArgument
    /// Thrown when the `@specs` macro is attached to a type not conforming to `Specification`.
    case mustBeAppliedToSpecificationType

    public var description: String {
        switch self {
        case .requiresAtLeastOneArgument:
            return "@specs macro requires at least one specification argument."
        case .mustBeAppliedToSpecificationType:
            return "@specs macro must be used on a type conforming to `Specification`."
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
public struct SpecsMacro: MemberMacro {

    // MARK: - MemberMacro

    /// This expansion adds the necessary members to the type to conform to `Specification`.
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // Ensure there's at least one specification provided.
        guard let arguments = node.arguments?.as(LabeledExprListSyntax.self), !arguments.isEmpty
        else {
            throw SpecsMacroError.requiresAtLeastOneArgument
        }

        // Ensure the macro is applied to a type that conforms to `Specification`.
        let conformsToSpecification: Bool = {
            if let s = declaration.as(StructDeclSyntax.self) {
                return s.inheritanceClause?.inheritedTypes.contains(where: { $0.type.trimmedDescription == "Specification" }) ?? false
            }
            if let c = declaration.as(ClassDeclSyntax.self) {
                return c.inheritanceClause?.inheritedTypes.contains(where: { $0.type.trimmedDescription == "Specification" }) ?? false
            }
            if let a = declaration.as(ActorDeclSyntax.self) {
                return a.inheritanceClause?.inheritedTypes.contains(where: { $0.type.trimmedDescription == "Specification" }) ?? false
            }
            if let e = declaration.as(EnumDeclSyntax.self) {
                return e.inheritanceClause?.inheritedTypes.contains(where: { $0.type.trimmedDescription == "Specification" }) ?? false
            }
            return false
        }()

        guard conformsToSpecification else {
            throw SpecsMacroError.mustBeAppliedToSpecificationType
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
                        period: .periodToken(),
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
            "private let composite: AnySpecification<T>"

        let initializer: DeclSyntax =
            """
            public init() {
                let specChain = \(andChain)
                self.composite = AnySpecification(specChain)
            }
            """

        let isSatisfiedByMethod: DeclSyntax =
            """
            public func isSatisfiedBy(_ candidate: T) -> Bool {
                composite.isSatisfiedBy(candidate)
            }
            """

        return [
            compositeProperty,
            initializer,
            isSatisfiedByMethod,
        ]
    }

}
