import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

/// @specsIf macro
/// - Wraps a specification to conditionally enable/disable based on a closure
/// - Syntax: `@specsIf(condition: { context in context.isSubscribed })`
/// - Generates a conditional wrapper that evaluates the condition before checking the spec
///
/// ## Usage
/// ```swift
/// @specsIf(condition: { ctx in ctx.flag(for: "premium") })
/// struct PremiumFeatureSpec: Specification {
///     typealias T = EvaluationContext
///     func isSatisfiedBy(_ context: T) -> Bool {
///         // Premium feature logic
///     }
/// }
/// ```
///
/// The macro generates a conditional wrapper that:
/// 1. Evaluates the condition closure first
/// 2. If condition is false, returns false immediately (short-circuits)
/// 3. If condition is true, evaluates the wrapped specification
public struct SpecsIfMacro: MemberMacro {

    /// Argument types for @specsIf
    private enum SpecsIfArgument {
        case condition(ExprSyntax)
        case missing
        case invalid
    }

    // MARK: - MemberMacro

    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {

        // Parse the condition argument
        let argument = parseArguments(from: node, context: context)

        // Emit diagnostics for errors
        emitDiagnosticsIfNeeded(for: argument, at: node, in: context)

        // For error cases, don't generate any members
        switch argument {
        case .missing, .invalid:
            return []
        case .condition(let conditionExpr):
            return generateConditionalMembers(conditionExpr: conditionExpr, declaration: declaration)
        }
    }

    // MARK: - Argument Parsing

    /// Parse arguments from the @specsIf attribute
    private static func parseArguments(
        from node: AttributeSyntax,
        context: some MacroExpansionContext
    ) -> SpecsIfArgument {
        // Get the argument list from the attribute
        guard let arguments = node.arguments,
              case let .argumentList(argList) = arguments else {
            return .missing
        }

        let args = Array(argList)

        // Should have exactly one argument labeled "condition"
        guard args.count == 1 else {
            return .invalid
        }

        guard let firstArg = args.first else {
            return .missing
        }

        // Check for condition: label
        guard let label = firstArg.label?.text, label == "condition" else {
            return .invalid
        }

        // Extract the closure expression
        let expression = firstArg.expression

        // Validate it's a closure expression
        guard expression.is(ClosureExprSyntax.self) else {
            return .invalid
        }

        return .condition(expression)
    }

    // MARK: - Member Generation

    /// Generate conditional wrapper members
    private static func generateConditionalMembers(
        conditionExpr: ExprSyntax,
        declaration: some DeclGroupSyntax
    ) -> [DeclSyntax] {
        var members: [DeclSyntax] = []

        // Store the condition closure
        let conditionProperty: DeclSyntax =
            """
            private let _specsIfCondition: (T) -> Bool = \(conditionExpr)
            """
        members.append(conditionProperty)

        // Add a helper property that wraps the base specification
        // Users must define _baseSpecification that returns their core spec
        let wrappedSpecProperty: DeclSyntax =
            """
            private var _conditionalWrapper: ConditionalSpecification<T> {
                ConditionalSpecification(condition: _specsIfCondition, wrapping: _baseSpecification)
            }
            """
        members.append(wrappedSpecProperty)

        // Provide default isSatisfiedBy implementation that uses the wrapper
        let isSatisfiedByMethod: DeclSyntax =
            """
            public func isSatisfiedBy(_ candidate: T) -> Bool {
                _conditionalWrapper.isSatisfiedBy(candidate)
            }
            """
        members.append(isSatisfiedByMethod)

        // Add documentation for the required _baseSpecification property
        let baseSpecDocumentation: DeclSyntax =
            """
            // IMPLEMENTATION REQUIRED: Define _baseSpecification to return your core specification
            // Example:
            // private var _baseSpecification: some Specification<T> {
            //     PredicateSpec { candidate in
            //         // Your specification logic here
            //     }
            // }
            """
        members.append(baseSpecDocumentation)

        return members
    }

    // MARK: - Diagnostics

    /// Emit appropriate diagnostics for invalid usage
    private static func emitDiagnosticsIfNeeded(
        for argument: SpecsIfArgument,
        at node: AttributeSyntax,
        in context: some MacroExpansionContext
    ) {
        switch argument {
        case .condition:
            // Valid - emit warning about macro limitations
            let limitationDiagnostic = Diagnostic(
                node: Syntax(node),
                message: SpecsIfDiagnostic.macroLimitations
            )
            context.diagnose(limitationDiagnostic)

            // Also emit informational note about alternative approach
            let alternativeDiagnostic = Diagnostic(
                node: Syntax(node),
                message: SpecsIfDiagnostic.considerWrapperAlternative
            )
            context.diagnose(alternativeDiagnostic)

        case .missing:
            let diagnostic = Diagnostic(
                node: Syntax(node),
                message: SpecsIfDiagnostic.missingCondition
            )
            context.diagnose(diagnostic)

        case .invalid:
            let diagnostic = Diagnostic(
                node: Syntax(node),
                message: SpecsIfDiagnostic.invalidCondition
            )
            context.diagnose(diagnostic)
        }
    }
}

// MARK: - Diagnostic Messages

/// Diagnostic messages for @specsIf macro
private enum SpecsIfDiagnostic: String, DiagnosticMessage {
    case missingCondition
    case invalidCondition
    case macroLimitations
    case considerWrapperAlternative

    var message: String {
        switch self {
        case .missingCondition:
            return "@specsIf requires a 'condition:' argument with a closure that takes the context and returns Bool."
        case .invalidCondition:
            return "@specsIf condition must be a closure expression of type (T) -> Bool."
        case .macroLimitations:
            return "@specsIf macro cannot generate complete Specification conformance due to Swift macro system limitations. You must still implement isSatisfiedBy yourself."
        case .considerWrapperAlternative:
            return "Recommended: Use ConditionalSpecification wrapper directly instead: ConditionalSpecification(condition: { ... }, wrapping: YourSpec()) or YourSpec().when { ... }"
        }
    }

    var diagnosticID: MessageID {
        MessageID(domain: "SpecificationKitMacros", id: rawValue)
    }

    var severity: DiagnosticSeverity {
        switch self {
        case .missingCondition, .invalidCondition:
            return .error
        case .macroLimitations:
            return .warning
        case .considerWrapperAlternative:
            return .note
        }
    }
}
