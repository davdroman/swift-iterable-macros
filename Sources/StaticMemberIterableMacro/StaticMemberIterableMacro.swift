import Foundation
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

struct StaticMemberIterableMacro: MemberMacro {
	static func expansion(
		of node: AttributeSyntax,
		providingMembersOf declaration: some DeclGroupSyntax,
		conformingTo protocols: [TypeSyntax],
		in context: some MacroExpansionContext,
	) throws -> [DeclSyntax] {
		let options = AttributeOptions(attribute: node)

		guard declaration.isSupportedType else {
			throw DiagnosticsError(
				diagnostics: [
					Diagnostic(node: Syntax(node), message: NotATypeError()),
				],
			)
		}

		let members = declaration.staticMembers

		guard !members.isEmpty else {
			context.diagnose(
				Diagnostic(node: Syntax(node), message: NoStaticMembersWarning()),
			)
			return []
		}

		let emitter = StaticMemberEmitter(
			access: AccessSpecifier(keyword: options.accessModifier),
			typeAccess: AccessSpecifier(keyword: declaration.explicitAccessModifier),
			members: members,
			containerType: declaration.memberContainerType,
			valueType: options.memberType ?? declaration.memberValueType,
		)

		let conflicts = StaticMemberEmitter.synthesizedMemberNames
			.filter { declaration.declaresMember(named: $0) }

		guard conflicts.isEmpty else {
			throw DiagnosticsError(
				diagnostics: conflicts.map {
					Diagnostic(node: Syntax(node), message: ConflictingMemberError(memberName: $0))
				},
			)
		}

		return emitter.makeDeclarations()
	}
}

extension StaticMemberIterableMacro: ExtensionMacro {
	static func expansion(
		of node: AttributeSyntax,
		attachedTo declaration: some DeclGroupSyntax,
		providingExtensionsOf type: some TypeSyntaxProtocol,
		conformingTo protocols: [TypeSyntax],
		in context: some MacroExpansionContext,
	) throws -> [ExtensionDeclSyntax] {
		if protocols.isEmpty {
			return []
		}

		guard declaration.isSupportedType else {
			throw DiagnosticsError(
				diagnostics: [
					Diagnostic(node: Syntax(node), message: NotATypeError()),
				],
			)
		}

		let wantsStaticMemberIterable = protocols.contains {
			$0.trimmedDescription == "StaticMemberIterable"
		}

		guard wantsStaticMemberIterable else {
			return []
		}

		let extendedType = type.trimmedDescription.trimmingCharacters(in: .whitespacesAndNewlines)
		let extensionDecl: DeclSyntax =
			"""
			extension \(raw: extendedType): StaticMemberIterable {}
			"""

		return [
			extensionDecl.cast(ExtensionDeclSyntax.self),
		]
	}
}

// MARK: Diagnostics

struct NotATypeError: DiagnosticMessage {
	var message: String {
		"`StaticMemberIterable` works on a `class`, `enum`, or `struct`"
	}

	var diagnosticID: MessageID {
		.init(domain: "StaticMemberIterableMacro", id: "NotATypeError")
	}

	var severity: DiagnosticSeverity { .error }
}

struct NoStaticMembersWarning: DiagnosticMessage {
	var message: String {
		"'@StaticMemberIterable' does not generate members when there are no static `let` properties"
	}

	var diagnosticID: MessageID {
		.init(domain: "StaticMemberIterableMacro", id: "NoStaticMembersWarning")
	}

	var severity: DiagnosticSeverity { .warning }
}

struct ConflictingMemberError: DiagnosticMessage {
	let memberName: String

	var message: String {
		"'@StaticMemberIterable' cannot generate '\(memberName)' because it already exists"
	}

	var diagnosticID: MessageID {
		.init(domain: "StaticMemberIterableMacro", id: "ConflictingMemberError")
	}

	var severity: DiagnosticSeverity { .error }
}

// MARK: Helpers

struct StaticMemberEmitter {
	let access: AccessSpecifier
	let typeAccess: AccessSpecifier
	let members: [StaticMemberInfo]
	let containerType: String
	let valueType: String

	static let synthesizedMemberNames = [
		"StaticMemberValue",
		"allStaticMembers",
	]

	func makeDeclarations() -> [DeclSyntax] {
		let sanitizedContainerType = containerType.trimmingCharacters(in: .whitespacesAndNewlines)
		let entries = members
			.map { $0.initializer(containerType: sanitizedContainerType) }
			.joined(separator: ",\n")

		let typealiasDecl: DeclSyntax =
			"""
			\(raw: typeAccess.prefix)typealias StaticMemberValue = \(raw: valueType)
			"""

		let membersDecl: DeclSyntax =
			"""
			\(raw: access.prefix)static let allStaticMembers: [StaticMember<\(raw: containerType), \(raw: valueType)>] = [
			\(raw: entries)
			]
			"""

		return [
			typealiasDecl,
			membersDecl,
		]
	}
}

struct AccessSpecifier {
	let prefix: String

	init(keyword: String?) {
		self.prefix = keyword.map { "\($0) " } ?? ""
	}
}

struct StaticMemberInfo {
	let reference: String
	let literal: String

	init(identifier: TokenSyntax) {
		let identifierText = identifier.text
			.trimmingCharacters(in: .whitespacesAndNewlines)
		self.reference = identifierText
		let plainName = identifierText.trimmingBackticks()
		self.literal = "\"\(plainName)\""
	}

	func initializer(containerType: String) -> String {
		let keyPath = "\\\(containerType).Type.\(reference)"
		return
			"""
			StaticMember(
				keyPath: \(keyPath),
				name: \(literal),
				value: \(reference)
			)
			"""
	}
}

// MARK: Attribute parsing

struct AttributeOptions {
	let accessModifier: String?
	let memberType: String?

	init(attribute: AttributeSyntax) {
		var access: String?
		var memberType: String?

		if case let .argumentList(arguments)? = attribute.arguments {
			for argument in arguments {
				if let label = argument.label?.text {
					switch label {
					case "ofType":
						memberType = memberTypeDescription(from: argument.expression)
					default:
						break
					}
				} else if access == nil {
					access = accessKeyword(from: argument.expression)
				}
			}
		}

		self.accessModifier = access
		self.memberType = memberType
	}
}

func accessKeyword(from expr: ExprSyntax) -> String? {
	if let member = expr.as(MemberAccessExprSyntax.self) {
		return member.declName.baseName.text
	}
	return nil
}

func memberTypeDescription(from expr: ExprSyntax) -> String? {
	let description = expr.trimmedDescription
	guard !description.isEmpty else { return nil }
	if description.hasSuffix(".self") {
		return String(description.dropLast(5))
	}
	return description
}

extension ExprSyntax {
	var trimmedDescription: String {
		self.trimmed.description
	}
}

extension DeclGroupSyntax {
	var isSupportedType: Bool {
		self.is(StructDeclSyntax.self) || self.is(EnumDeclSyntax.self) || self.is(ClassDeclSyntax.self)
	}

	var staticMembers: [StaticMemberInfo] {
		memberBlock.members.flatMap(\.staticMembers)
	}

	func declaresMember(named name: String) -> Bool {
		memberBlock.members.contains { $0.declaresVariable(named: name) }
	}

	var explicitAccessModifier: String? {
		if let structDecl = self.as(StructDeclSyntax.self) {
			return structDecl.modifiers.accessModifierKeyword
		}
		if let enumDecl = self.as(EnumDeclSyntax.self) {
			return enumDecl.modifiers.accessModifierKeyword
		}
		if let classDecl = self.as(ClassDeclSyntax.self) {
			return classDecl.modifiers.accessModifierKeyword
		}
		return nil
	}

	var memberValueType: String {
		declaredTypeName
	}

	var memberContainerType: String {
		declaredTypeName
	}

	var declaredTypeName: String {
		if let structDecl = self.as(StructDeclSyntax.self) {
			return structDecl.declaredTypeName
		}
		if let enumDecl = self.as(EnumDeclSyntax.self) {
			return enumDecl.declaredTypeName
		}
		if let classDecl = self.as(ClassDeclSyntax.self) {
			return classDecl.declaredTypeName
		}
		return "Self"
	}
}

extension StructDeclSyntax {
	var declaredTypeName: String {
		var name = self.name.text

		if let generics = genericParameterClause, !generics.parameters.isEmpty {
			let parameters = generics.parameters
				.map(\.name.text)
				.joined(separator: ", ")
			name += "<\(parameters)>"
		}

		return name
	}
}

extension EnumDeclSyntax {
	var declaredTypeName: String {
		var name = self.name.text

		if let generics = genericParameterClause, !generics.parameters.isEmpty {
			let parameters = generics.parameters
				.map(\.name.text)
				.joined(separator: ", ")
			name += "<\(parameters)>"
		}

		return name
	}
}

extension ClassDeclSyntax {
	var declaredTypeName: String {
		var name = self.name.text

		if let generics = genericParameterClause, !generics.parameters.isEmpty {
			let parameters = generics.parameters
				.map(\.name.text)
				.joined(separator: ", ")
			name += "<\(parameters)>"
		}

		return name
	}
}

extension MemberBlockItemSyntax {
	var staticMembers: [StaticMemberInfo] {
		guard
			let variable = decl.as(VariableDeclSyntax.self),
			variable.isStaticLet
		else {
			return []
		}

		return variable.bindings.compactMap {
			$0.pattern.as(IdentifierPatternSyntax.self)?.identifier
		}
		.map(StaticMemberInfo.init(identifier:))
	}

	func declaresVariable(named name: String) -> Bool {
		guard let variable = decl.as(VariableDeclSyntax.self) else {
			return false
		}

		return variable.declaredNames.contains(name)
	}
}

extension DeclModifierListSyntax {
	var accessModifierKeyword: String? {
		for modifier in self {
			if let keyword = modifier.accessKeywordText {
				return keyword
			}
		}
		return nil
	}
}

extension DeclModifierSyntax {
	var accessKeywordText: String? {
		if case let .keyword(keyword) = name.tokenKind {
			switch keyword {
			case .public:
				return "public"
			case .package:
				return "package"
			case .internal:
				return "internal"
			case .fileprivate:
				return "fileprivate"
			case .private:
				return "private"
			case .open:
				return "public"
			default:
				return nil
			}
		}
		return nil
	}
}

extension VariableDeclSyntax {
	var isStaticLet: Bool {
		modifiers.contains { $0.name.tokenKind == .keyword(.static) }
			&& bindingSpecifier.tokenKind == .keyword(.let)
	}

	var declaredNames: [String] {
		bindings.compactMap {
			$0.pattern.as(IdentifierPatternSyntax.self)?.identifier.text.trimmingBackticks()
		}
	}
}

extension String {
	func trimmingBackticks() -> String {
		guard hasPrefix("`"), hasSuffix("`"), count >= 2 else {
			return self
		}
		return String(dropFirst().dropLast())
	}
}
