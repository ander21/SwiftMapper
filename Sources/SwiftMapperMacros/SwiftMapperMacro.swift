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
                generateAssignment(for: prop)
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

    private static func generateAssignment(for prop: PropertyInfo) -> String? {
        if prop.isIgnored { return nil }
        
        let sourceField = prop.customKey ?? prop.name
        let baseType = getBaseType(prop.type)
        let isBasePrimitive = isPrimitive(baseType)

        // 1. ОБРОБКА МАСИВІВ
        if prop.isArray {
            if isBasePrimitive {
                // Якщо ціль [String], а джерело [String]?, додаємо ?? []
                let fallback = prop.isOptional ? "" : " ?? []"
                return "self.\(prop.name) = source.\(sourceField)\(fallback)"
            } else {
                // Складні масиви: [Type].map { ... }
                let optionalChaining = "?.map { \(baseType)(from: $0) }"
                let fallback = prop.isOptional ? "" : " ?? []"
                return "self.\(prop.name) = source.\(sourceField)\(optionalChaining)\(fallback)"
            }
        }
        
        // 2. СКЛАДНІ ОБ'ЄКТИ (Nested)
        if !isBasePrimitive {
            if prop.isOptional {
                // Ціль: Test?, Джерело: Test? -> map
                return "self.\(prop.name) = source.\(sourceField).map { \(baseType)(from: $0) }"
            } else {
                // Ціль: Test (Non-Optional). Тут макрос НЕ додає ??,
                // тому якщо в Source це Optional, виникне помилка компіляції (як ти і просив).
                return "self.\(prop.name) = \(baseType)(from: source.\(sourceField))"
            }
        }

        // 3. ПРИМІТИВИ (String, Int, Bool...)
        if !prop.isOptional {
            // Якщо ціль Non-Optional, додаємо розумний дефолт
            let defaultVal = defaultValue(for: baseType)
            return "self.\(prop.name) = source.\(sourceField) ?? \(defaultVal)"
        } else {
            // Якщо ціль Optional, просто копіюємо
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
        default: return "nil" // Це призведе до помилки компіляції, якщо тип не примітив
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

        for attr in varDecl.attributes {
            if let attrSyntax = attr.as(AttributeSyntax.self) {
                let attrName = attrSyntax.attributeName.description.trimmingCharacters(in: .whitespaces)
                if attrName == "MapIgnore" { isIgnored = true }
                if attrName == "MapKey", let arg = attrSyntax.arguments?.as(LabeledExprListSyntax.self)?.first {
                    customKey = arg.expression.description.replacingOccurrences(of: "\"", with: "")
                }
            }
        }

        return PropertyInfo(
            name: name,
            type: type,
            isOptional: type.hasSuffix("?"),
            isArray: type.hasPrefix("["),
            customKey: customKey,
            isIgnored: isIgnored
        )
    }
}

// Потрібні публічні структури для MapIgnore та MapKey (як у попередніх кроках)
public struct MapIgnoreMacro: PeerMacro { public static func expansion(of node: AttributeSyntax, providingPeersOf declaration: some DeclSyntaxProtocol, in context: some MacroExpansionContext) throws -> [DeclSyntax] { [] } }
public struct MapKeyMacro: PeerMacro { public static func expansion(of node: AttributeSyntax, providingPeersOf declaration: some DeclSyntaxProtocol, in context: some MacroExpansionContext) throws -> [DeclSyntax] { [] } }

struct PropertyInfo {
    let name, type: String
    let isOptional, isArray: Bool
    let customKey: String?
    let isIgnored: Bool
}
