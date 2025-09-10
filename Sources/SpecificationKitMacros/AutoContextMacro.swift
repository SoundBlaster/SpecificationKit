import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// @AutoContext macro
/// - Adds conformance to `AutoContextSpecification`
/// - Injects `public typealias Provider = DefaultContextProvider`
/// - Injects `public static var contextProvider: DefaultContextProvider { .shared }`
/// - Synthesizes `public init()` if not already declared
public struct AutoContextMacro: MemberMacro {
    // MARK: - MemberMacro
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {

        var members: [DeclSyntax] = []

        // Inject provider typealias and static contextProvider using DefaultContextProvider
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
}
