// NOTE: The following imports and macro implementation code are required only when compiled
// as part of a macro plugin target using the Swift toolchain that supports macros.
// They should NOT be included in the main library target to avoid build errors.
//
// import SwiftSyntax
// import SwiftSyntaxMacros
// import SwiftDiagnostics

/// A macro that adds a computed property `hello` returning "Hello, Macro!" to a struct.
///
/// Usage:
/// ```swift
/// @AddHelloMacro
/// struct MyStruct {}
///
/// print(MyStruct().hello) // Prints "Hello, Macro!"
/// ```
///
/// This macro implementation must be provided in a macro plugin target using SwiftSyntax macros.
//public struct AddHelloMacro: SwiftSyntaxMacro {
    // Macro implementation should be in the macro plugin target.
//}

// Macro implementation example (to be placed in macro plugin target):
/*
import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics

public struct AddHelloMacro: MemberMacro {
    public static func expansion(
        of node: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        let helloProperty = """
        var hello: String {
            "Hello, Macro!"
        }
        """
        return [DeclSyntax(stringLiteral: helloProperty)]
    }
}
*/
