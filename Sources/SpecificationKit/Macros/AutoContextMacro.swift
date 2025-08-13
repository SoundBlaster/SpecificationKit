//
//  AutoContextMacro.swift
//  SpecificationKit
//
//  Implements the @AutoContext attached macro for specification structs.
//
//  Created by AutoContext Macro Implementation.
//

import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics

/// An attached macro that injects a static contextProvider and init() for Specification structs.
public struct AutoContextMacro: MemberMacro, PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // Only apply to structs conforming to Specification
        guard let structDecl = declaration.as(StructDeclSyntax.self),
              structDecl.inheritanceClause?.inheritedTypes.contains(where: { $0.type.description.contains("Specification") }) == true else {
            throw CustomDiagnosticError(message: "@AutoContext can only be applied to structs conforming to Specification.")
        }

        // Inject the default contextProvider property
        let contextProviderDecl = """
        public static let contextProvider: DefaultContextProvider = .shared
        """

        // Inject a default init() if not explicitly defined
        let hasInit = structDecl.memberBlock.members.contains { member in
            member.decl.is(InitializerDeclSyntax.self)
        }
        let initDecl = hasInit ? "" : "public init() {}\n"

        // Conform to AutoContextSpecification
        let autoContextConformance = ": AutoContextSpecification"
        
        // Can't actually modify inheritance list in a macro; user must add conformance manually if needed.
        // So, we just inject members here.

        let decls: [DeclSyntax] = [
            DeclSyntax(stringLiteral: contextProviderDecl),
        ]
        + (initDecl.isEmpty ? [] : [DeclSyntax(stringLiteral: initDecl)])

        return decls
    }

    // Peer macro not needed for this use case
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        return []
    }
}

// Macro registration (add to MacroPlugin.swift as needed)
