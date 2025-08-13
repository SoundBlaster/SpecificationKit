//
//  MacroPlugin.swift
//  SpecificationKit
//
//  Registers macros for the SpecificationKit macro plugin target.
//
//  Created by AutoContext Macro Implementation.
//

import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport

@main
struct SpecificationKitMacroPlugin: MacroPlugin {
    static func registerMacros(registry: inout MacroRegistry) {
        registry.register(AutoContextMacro.self, for: "AutoContext")
        // Register other macros here as needed
    }
}
