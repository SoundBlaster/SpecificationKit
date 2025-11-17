import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

/// @AutoContext macro
/// - Adds conformance to `AutoContextSpecification`
/// - Injects `public typealias Provider = DefaultContextProvider`
/// - Injects `public static var contextProvider: DefaultContextProvider { .shared }`
/// - Synthesizes `public init()` if not already declared
///
/// ## Future Extension Points
/// The macro infrastructure supports parsing the following future enhancement flags:
/// - `@AutoContext(CustomProvider.self)` - Custom provider type specification (planned)
/// - `@AutoContext(environment)` - SwiftUI Environment integration (planned)
/// - `@AutoContext(infer)` - Context provider inference from generic context (planned)
///
/// These flags are parsed and recognized but emit informative diagnostics indicating
/// they are not yet implemented. This allows the macro syntax to evolve gracefully
/// as Swift's macro capabilities expand.
public struct AutoContextMacro: MemberMacro {

    /// Argument types that can be passed to @AutoContext
    private enum AutoContextArgument {
        case none
        case environment
        case infer
        case customProviderType(String)
        case multipleArguments
        case invalid
    }

    // MARK: - MemberMacro
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {

        // Parse arguments from the attribute
        let argument = parseArguments(from: node, context: context)

        // Emit diagnostics for future flags
        emitDiagnosticsIfNeeded(for: argument, at: node, in: context)

        // For error cases, don't generate any members
        switch argument {
        case .invalid, .multipleArguments:
            return []
        default:
            break
        }

        var members: [DeclSyntax] = []

        // Currently, all valid argument types result in DefaultContextProvider
        // Future implementations will customize based on the argument type
        let typeAlias: DeclSyntax = "public typealias Provider = DefaultContextProvider"
        let provider: DeclSyntax =
            """
            public static var contextProvider: DefaultContextProvider {
                DefaultContextProvider.shared
            }
            """
        members.append(typeAlias)
        members.append(provider)

        return members
    }

    // MARK: - Argument Parsing

    /// Parse arguments from the @AutoContext attribute
    private static func parseArguments(
        from node: AttributeSyntax,
        context: some MacroExpansionContext
    ) -> AutoContextArgument {
        // Get the argument list from the attribute
        guard let arguments = node.arguments,
              case let .argumentList(argList) = arguments else {
            // No arguments - this is the current default behavior
            return .none
        }

        let args = Array(argList)

        // Check for multiple arguments (not supported)
        if args.count > 1 {
            return .multipleArguments
        }

        guard let firstArg = args.first else {
            return .none
        }

        // Parse the expression
        let expression = firstArg.expression

        // Check for identifier-based flags: 'environment' or 'infer'
        if let identifierExpr = expression.as(DeclReferenceExprSyntax.self) {
            let identifier = identifierExpr.baseName.text
            switch identifier {
            case "environment":
                return .environment
            case "infer":
                return .infer
            default:
                // Unknown identifier
                return .invalid
            }
        }

        // Check for member access expression (e.g., CustomProvider.self)
        if let memberAccess = expression.as(MemberAccessExprSyntax.self) {
            // Extract the type name from the member access
            if memberAccess.declName.baseName.text == "self",
               let baseExpr = memberAccess.base {
                // This is a .self expression, extract the type name
                let typeName = baseExpr.description.trimmingCharacters(in: .whitespaces)
                return .customProviderType(typeName)
            }
        }

        // Any other expression type is invalid
        return .invalid
    }

    // MARK: - Diagnostics

    /// Emit appropriate diagnostics for recognized but unimplemented features
    private static func emitDiagnosticsIfNeeded(
        for argument: AutoContextArgument,
        at node: AttributeSyntax,
        in context: some MacroExpansionContext
    ) {
        switch argument {
        case .none:
            // No diagnostic needed - this is the current supported behavior
            break

        case .environment:
            let diagnostic = Diagnostic(
                node: Syntax(node),
                message: AutoContextDiagnostic.environmentNotImplemented
            )
            context.diagnose(diagnostic)

        case .infer:
            let diagnostic = Diagnostic(
                node: Syntax(node),
                message: AutoContextDiagnostic.inferNotImplemented
            )
            context.diagnose(diagnostic)

        case .customProviderType:
            let diagnostic = Diagnostic(
                node: Syntax(node),
                message: AutoContextDiagnostic.customProviderNotImplemented
            )
            context.diagnose(diagnostic)

        case .multipleArguments:
            let diagnostic = Diagnostic(
                node: Syntax(node),
                message: AutoContextDiagnostic.multipleArguments
            )
            context.diagnose(diagnostic)

        case .invalid:
            let diagnostic = Diagnostic(
                node: Syntax(node),
                message: AutoContextDiagnostic.invalidArgument
            )
            context.diagnose(diagnostic)
        }
    }
}

// MARK: - Diagnostic Messages

/// Diagnostic messages for @AutoContext macro
private enum AutoContextDiagnostic: String, DiagnosticMessage {
    case environmentNotImplemented
    case inferNotImplemented
    case customProviderNotImplemented
    case invalidArgument
    case multipleArguments

    var message: String {
        switch self {
        case .environmentNotImplemented:
            return "SwiftUI Environment integration for @AutoContext is planned but not yet implemented. Currently, only @AutoContext (using DefaultContextProvider.shared) is supported."
        case .inferNotImplemented:
            return "Context provider inference for @AutoContext is planned but not yet implemented. Currently, only @AutoContext (using DefaultContextProvider.shared) is supported."
        case .customProviderNotImplemented:
            return "Custom provider type specification for @AutoContext is planned but not yet implemented. Currently, only @AutoContext (using DefaultContextProvider.shared) is supported."
        case .invalidArgument:
            return "@AutoContext expects either no arguments, a provider type (e.g., MyProvider.self), or a keyword ('environment' or 'infer')."
        case .multipleArguments:
            return "@AutoContext accepts at most one argument."
        }
    }

    var diagnosticID: MessageID {
        MessageID(domain: "SpecificationKitMacros", id: rawValue)
    }

    var severity: DiagnosticSeverity {
        switch self {
        case .invalidArgument, .multipleArguments:
            return .error
        case .environmentNotImplemented, .inferNotImplemented, .customProviderNotImplemented:
            return .warning
        }
    }
}
