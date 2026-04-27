import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics

public struct MappableMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        
        let targetTypeNames = getTargetTypeNames(from: node)
        let members = declaration.memberBlock.members
        let properties = members.compactMap { extractPropertyInfo(from: $0) }

        return targetTypeNames.map { targetName in
            let body = properties.compactMap { prop in
                generateAssignment(for: prop, targetName: targetName)
            }.joined(separator: "\n        ")

            let isClass = declaration.is(ClassDeclSyntax.self)
            let initKeyword = isClass ? "convenience public init" : "public init"
            let callSelfInit = isClass ? "self.init()\n        " : ""

            return """
            \(raw: initKeyword)(from source: \(raw: targetName)) {
                \(raw: callSelfInit)\(raw: body)
            }
            """
        }
    }

    private static func generateAssignment(for prop: PropertyInfo, targetName: String) -> String? {
        if prop.isIgnored {
            if prop.ignoredFor.isEmpty || prop.ignoredFor.contains(targetName) {
                return nil
            }
        }
        
        let sourceField = prop.customKey ?? prop.name
        let baseType = getBaseType(prop.type)
        let isBasePrimitive = isPrimitive(baseType)

        if prop.isArray {
            if isBasePrimitive {
                let fallback = prop.isOptional ? "" : " ?? []"
                return "self.\(prop.name) = source.\(sourceField)\(fallback)"
            } else {
                let optionalChaining = "?.map { \(baseType)(from: $0) }"
                let fallback = prop.isOptional ? "" : " ?? []"
                return "self.\(prop.name) = source.\(sourceField)\(optionalChaining)\(fallback)"
            }
        }
        
        if !isBasePrimitive {
            if prop.isOptional {
                return "self.\(prop.name) = source.\(sourceField).map { \(baseType)(from: $0) }"
            } else {
                return "self.\(prop.name) = \(baseType)(from: source.\(sourceField))"
            }
        }

        // 3. Primitive (String, Int, Bool...)
        if !prop.isOptional {
            let defaultVal = defaultValue(for: baseType)
            return "self.\(prop.name) = source.\(sourceField) ?? \(defaultVal)"
        } else {
            return "self.\(prop.name) = source.\(sourceField)"
        }
    }

    private static func defaultValue(for type: String) -> String {
        switch type {
        case "String": return "\"\""
        case "Int", "Double", "Float": return "0"
        case "Bool": return "false"
        case "UUID": return "UUID()"
        case "Date": return "Date()"
        case "Data": return "Data()"
        default: return "nil"
        }
    }

    private static func isPrimitive(_ type: String) -> Bool {
        let primitives = ["String", "Int", "Double", "Float", "Bool", "UUID", "Date", "Data"]
        return primitives.contains(type)
    }

    private static func getBaseType(_ type: String) -> String {
        return type
            .replacingOccurrences(of: "[", with: "")
            .replacingOccurrences(of: "]", with: "")
            .replacingOccurrences(of: "?", with: "")
            .trimmingCharacters(in: .whitespaces)
    }

    private static func getTargetTypeNames(from node: AttributeSyntax) -> [String] {
        guard let args = node.arguments?.as(LabeledExprListSyntax.self),
              let array = args.first?.expression.as(ArrayExprSyntax.self) else { return [] }
        return array.elements.map { $0.expression.description.replacingOccurrences(of: ".self", with: "").trimmingCharacters(in: .whitespaces) }
    }

    private static func extractPropertyInfo(from member: MemberBlockItemSyntax) -> PropertyInfo? {
        guard let varDecl = member.decl.as(VariableDeclSyntax.self),
              let binding = varDecl.bindings.first,
              let name = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text,
              let type = binding.typeAnnotation?.type.description.trimmingCharacters(in: .whitespaces) else { return nil }

        var customKey: String?
        var isIgnored = false
        var ignoredFor: [String] = []

        for attr in varDecl.attributes {
            if let attrSyntax = attr.as(AttributeSyntax.self) {
                let attrName = attrSyntax.attributeName.description.trimmingCharacters(in: .whitespaces)
                
                if attrName == "MapKey", let arg = attrSyntax.arguments?.as(LabeledExprListSyntax.self)?.first {
                    customKey = arg.expression.description.replacingOccurrences(of: "\"", with: "")
                }
                
                if attrName == "MapIgnore" {
                    isIgnored = true
                    if let args = attrSyntax.arguments?.as(LabeledExprListSyntax.self),
                       let array = args.first?.expression.as(ArrayExprSyntax.self) {
                        ignoredFor = array.elements.map {
                            $0.expression.description
                                .replacingOccurrences(of: ".self", with: "")
                                .trimmingCharacters(in: .whitespaces)
                        }
                    }
                }
            }
        }

        return PropertyInfo(
            name: name, type: type, isOptional: type.hasSuffix("?"),
            isArray: type.hasPrefix("["), customKey: customKey,
            isIgnored: isIgnored, ignoredFor: ignoredFor
        )
    }
}

public struct MapIgnoreMacro: PeerMacro { public static func expansion(of node: AttributeSyntax, providingPeersOf declaration: some DeclSyntaxProtocol, in context: some MacroExpansionContext) throws -> [DeclSyntax] { [] } }
public struct MapKeyMacro: PeerMacro { public static func expansion(of node: AttributeSyntax, providingPeersOf declaration: some DeclSyntaxProtocol, in context: some MacroExpansionContext) throws -> [DeclSyntax] { [] } }

struct PropertyInfo {
    let name: String
    let type: String
    let isOptional: Bool
    let isArray: Bool
    let customKey: String?
    let isIgnored: Bool
    let ignoredFor: [String]
}
