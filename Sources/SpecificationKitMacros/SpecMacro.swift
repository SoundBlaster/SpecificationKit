import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

struct MissingTypealiasTMessage: DiagnosticMessage {
    var message: String {
        "Specification type appears to be missing typealias T (e.g. 'typealias T = EvaluationContext')."
    }
    var severity: DiagnosticSeverity { .warning }
    var diagnosticID: MessageID { .init(domain: "SpecificationKitMacros", id: "missingTypealiasT") }
}

struct NonInstanceArgumentMessage: DiagnosticMessage {
    let index: Int
    var message: String { "Argument #\(index + 1) to @specs does not appear to be a specification instance." }
    var severity: DiagnosticSeverity { .error }
    var diagnosticID: MessageID { .init(domain: "SpecificationKitMacros", id: "nonInstanceArg") }
}

struct TypeArgumentWarning: DiagnosticMessage {
    let index: Int
    var message: String { "Argument #\(index + 1) to @specs looks like a type reference. Did you mean to pass an instance?" }
    var severity: DiagnosticSeverity { .warning }
    var diagnosticID: MessageID { .init(domain: "SpecificationKitMacros", id: "typeArgWarning") }
}

struct MixedContextsWarning: DiagnosticMessage {
    let contexts: [String]
    var message: String {
        let list = contexts.joined(separator: ", ")
        return "@specs arguments appear to use mixed Context types (\(list)). Ensure all specs share the same Context."
    }
    var severity: DiagnosticSeverity { .warning }
    var diagnosticID: MessageID { .init(domain: "SpecificationKitMacros", id: "mixedContextsWarning") }
}

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

        // Suggest adding `typealias T = ...` if missing.
        let hasTypealiasT: Bool = declaration.memberBlock.members.contains { member in
            guard let typealiasDecl = member.decl.as(TypeAliasDeclSyntax.self) else { return false }
            return typealiasDecl.name.text == "T"
        }
        if !hasTypealiasT {
            context.diagnose(Diagnostic(node: Syntax(node), message: MissingTypealiasTMessage()))
        }

        // The first spec is the base of our chain.
        let firstSpec = arguments.first!.expression
        let otherSpecs = arguments.dropFirst()

        // Best-effort validations on arguments
        var inferredContexts = [String]()
        let knownEvaluationContextSpecs = [
            "MaxCountSpec",
            "TimeSinceEventSpec",
            "CooldownIntervalSpec",
            "FeatureFlagSpec",
            "DateRangeSpec",
            "DateComparisonSpec",
            "UserSegmentSpec",
            "SubscriptionStatusSpec",
        ]

        func extractContext(from text: String) -> String? {
            if let lt = text.firstIndex(of: "<"), let gt = text[lt...].firstIndex(of: ">") {
                let inside = text[text.index(after: lt)..<gt]
                if let first = inside.split(separator: ",").first {
                    let trimmed = first.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty { return trimmed }
                }
            }
            if let name = text.split(separator: "(").first?.split(separator: ".").last,
               knownEvaluationContextSpecs.contains(String(name)) {
                return "EvaluationContext"
            }
            return nil
        }

        func isLiteral(_ expr: ExprSyntax) -> Bool {
            expr.is(StringLiteralExprSyntax.self)
            || expr.is(BooleanLiteralExprSyntax.self)
            || expr.is(IntegerLiteralExprSyntax.self)
            || expr.is(FloatLiteralExprSyntax.self)
        }

        for (idx, arg) in arguments.enumerated() {
            let expr = arg.expression
            let text = expr.trimmedDescription
            if isLiteral(expr) {
                context.diagnose(Diagnostic(node: Syntax(node), message: NonInstanceArgumentMessage(index: idx)))
            } else if text.hasSuffix(".self") {
                context.diagnose(Diagnostic(node: Syntax(node), message: TypeArgumentWarning(index: idx)))
            }

            if let ctx = extractContext(from: text) {
                inferredContexts.append(ctx)
            }
        }

        let uniqueContexts = Set(inferredContexts)
        if uniqueContexts.count > 1 {
            context.diagnose(Diagnostic(node: Syntax(node), message: MixedContextsWarning(contexts: Array(uniqueContexts).sorted())))
        }

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
