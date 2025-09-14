//
//  MacroPlugin.swift
//  SpecificationKit
//
//  Registers macros for the SpecificationKit macro plugin target.
//
//  Created by AutoContext Macro Implementation.
//

import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct SpecificationKitPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        SpecsMacro.self,
        AutoContextMacro.self,
        SatisfiesMacro.self,
    ]
}
