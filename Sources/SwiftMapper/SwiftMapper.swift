import Foundation

@attached(member, names: named(init))
public macro Mappable(targets: [Any]) = #externalMacro(module: "SwiftMapperMacros", type: "MappableMacro")

@attached(peer)
public macro MapIgnore() = #externalMacro(module: "SwiftMapperMacros", type: "MapIgnoreMacro")

@attached(peer)
public macro MapKey(_ name: String) = #externalMacro(module: "SwiftMapperMacros", type: "MapKeyMacro")
