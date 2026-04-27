//
//  SwiftMapperPlugin.swift
//  SwiftMapper
//
//  Created by apostivoy on 27.04.2026.
//


import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct SwiftMapperPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        MappableMacro.self,
        MapIgnoreMacro.self,
        MapKeyMacro.self
    ]
}
