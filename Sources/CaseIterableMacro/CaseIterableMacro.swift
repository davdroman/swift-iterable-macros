import Foundation
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

struct CaseIterableMacro: MemberMacro {
	static func expansion(
		of attribute: AttributeSyntax,
		providingMembersOf declaration: some DeclGroupSyntax,
		conformingTo protocols: [TypeSyntax],
		in context: some MacroExpansionContext,
	) throws -> [DeclSyntax] {
		let options = AttributeOptions(attribute: attribute)

		guard let enumDecl = declaration.as(EnumDeclSyntax.self) else {
			throw DiagnosticsError(
				diagnostics: [
					Diagnostic(node: Syntax(attribute), message: NotAnEnumError()),
				],
			)
		}

		let access = AccessSpecifier(keyword: options.accessModifier)

		let conflictingMembers = CaseEmitter.synthesizedMemberNames
			.filter { enumDecl.declaresMember(named: $0) }

		guard conflictingMembers.isEmpty else {
			throw DiagnosticsError(
				diagnostics: conflictingMembers.map {
					Diagnostic(
						node: Syntax(attribute),
						message: ConflictingMemberError(memberName: $0),
					)
				},
			)
		}

		let caseElements = enumDecl.caseElements
		let unsupportedCases = enumDecl.associatedValueCases

		if unsupportedCases.isEmpty == false {
			throw DiagnosticsError(
				diagnostics: unsupportedCases.map {
					Diagnostic(
						node: Syntax($0),
						message: AssociatedValueCaseError(caseName: $0.name.text.trimmingBackticks()),
					)
				},
			)
		}

		guard caseElements.isEmpty == false else {
			context.diagnose(
				Diagnostic(
					node: Syntax(attribute),
					message: NoEnumCasesWarning(),
				),
			)
			return []
		}

		let hasDynamicMemberLookup = enumDecl.hasDynamicMemberLookupAttribute

		let emitter = CaseEmitter(
			access: access,
			containerType: enumDecl.declaredTypeName,
			cases: caseElements.map(EnumCaseInfo.init),
			dynamicMemberAccess: hasDynamicMemberLookup ? enumDecl.propertiesStructAccessSpecifier : nil,
		)

		return emitter.makeDeclarations()
	}
}

// MARK: Diagnostics

struct NotAnEnumError: DiagnosticMessage {
	var message: String {
		"`@CaseIterable` only works on enums"
	}

	var diagnosticID: MessageID {
		.init(domain: "CaseIterableMacro", id: "NotAnEnumError")
	}

	var severity: DiagnosticSeverity { .error }
}

struct NoEnumCasesWarning: DiagnosticMessage {
	var message: String {
		"'@CaseIterable' does not generate members when there are no enum cases"
	}

	var diagnosticID: MessageID {
		.init(domain: "CaseIterableMacro", id: "NoEnumCasesWarning")
	}

	var severity: DiagnosticSeverity { .warning }
}

struct AssociatedValueCaseError: DiagnosticMessage {
	let caseName: String

	var message: String {
		"'@CaseIterable' does not support cases with associated values ('\(caseName)')"
	}

	var diagnosticID: MessageID {
		.init(domain: "CaseIterableMacro", id: "AssociatedValueCaseError")
	}

	var severity: DiagnosticSeverity { .error }
}

struct ConflictingMemberError: DiagnosticMessage {
	let memberName: String

	var message: String {
		"'@CaseIterable' cannot generate '\(memberName)' because it already exists"
	}

	var diagnosticID: MessageID {
		.init(domain: "CaseIterableMacro", id: "ConflictingMemberError")
	}

	var severity: DiagnosticSeverity { .error }
}

// MARK: Helpers

struct CaseEmitter {
	let access: AccessSpecifier
	let containerType: String
	let cases: [EnumCaseInfo]
	let dynamicMemberAccess: AccessSpecifier?

	static let synthesizedMemberNames = [
		"allCases",
	]

	func makeDeclarations() -> [DeclSyntax] {
		let entries = cases
			.map(\.initializer)
			.joined(separator: ",\n")

		let allCasesDecl: DeclSyntax =
			"""
			\(raw: access.prefix)static let allCases: [CaseOf<\(raw: containerType)>] = [
			\(raw: entries)
			]
			"""

		var declarations: [DeclSyntax] = [allCasesDecl]

		if let dynamicMemberAccess {
			let subscriptDecl: DeclSyntax =
				"""
				\(raw: dynamicMemberAccess.prefix)subscript<T>(dynamicMember keyPath: KeyPath<Properties, T>) -> T {
					properties[keyPath: keyPath]
				}
				"""
			declarations.append(subscriptDecl)
		}

		return declarations
	}
}

struct EnumCaseInfo {
	let reference: String
	let literal: String

	init(element: EnumCaseElementSyntax) {
		let identifierText = element.name.text.trimmingCharacters(in: .whitespacesAndNewlines)
		self.reference = identifierText
		self.literal = "\"\(identifierText.trimmingBackticks())\""
	}

	var initializer: String {
		"""
		CaseOf(
			name: \(literal),
			value: .\(reference)
		)
		"""
	}
}

struct AccessSpecifier {
	let prefix: String

	init(keyword: String?) {
		self.prefix = keyword.map { "\($0) " } ?? ""
	}
}

struct AttributeOptions {
	let accessModifier: String?

	init(attribute: AttributeSyntax) {
		var access: String?

		if case let .argumentList(arguments)? = attribute.arguments {
			for argument in arguments {
				if access == nil {
					access = accessKeyword(from: argument.expression)
				}
			}
		}

		self.accessModifier = access
	}
}

// MARK: Syntax helpers

extension EnumDeclSyntax {
	var caseElements: [EnumCaseElementSyntax] {
		memberBlock.members.flatMap(\.simpleEnumCaseElements)
	}

	var associatedValueCases: [EnumCaseElementSyntax] {
		memberBlock.members.flatMap(\.associatedValueEnumCaseElements)
	}

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

	func declaresMember(named name: String) -> Bool {
		memberBlock.members.contains { $0.declaresVariable(named: name) }
	}

	var propertiesStructAccessSpecifier: AccessSpecifier? {
		guard let properties = propertiesStruct else {
			return nil
		}
		return AccessSpecifier(keyword: properties.modifiers.accessModifierKeyword)
	}

	var hasDynamicMemberLookupAttribute: Bool {
		attributes.containsAttribute(named: "dynamicMemberLookup")
	}

	private var propertiesStruct: StructDeclSyntax? {
		for member in memberBlock.members {
			if let structDecl = member.decl.as(StructDeclSyntax.self),
			   structDecl.name.text.trimmingBackticks() == "Properties"
			{
				return structDecl
			}
		}
		return nil
	}
}

extension MemberBlockItemSyntax {
	var simpleEnumCaseElements: [EnumCaseElementSyntax] {
		guard
			let enumCase = decl.as(EnumCaseDeclSyntax.self)
		else {
			return []
		}

		return enumCase.elements.compactMap { element in
			element.parameterClause == nil ? element : nil
		}
	}

	var associatedValueEnumCaseElements: [EnumCaseElementSyntax] {
		guard
			let enumCase = decl.as(EnumCaseDeclSyntax.self)
		else {
			return []
		}

		return enumCase.elements.compactMap { element in
			element.parameterClause == nil ? nil : element
		}
	}

	func declaresVariable(named name: String) -> Bool {
		guard let variable = decl.as(VariableDeclSyntax.self) else {
			return false
		}

		return variable.declaredNames.contains(name)
	}
}

extension VariableDeclSyntax {
	var declaredNames: [String] {
		bindings.compactMap {
			$0.pattern.as(IdentifierPatternSyntax.self)?.identifier.text.trimmingBackticks()
		}
	}
}

func accessKeyword(from expr: ExprSyntax) -> String? {
	if let member = expr.as(MemberAccessExprSyntax.self) {
		return member.declName.baseName.text
	}
	return nil
}

extension String {
	func trimmingBackticks() -> String {
		guard hasPrefix("`"), hasSuffix("`"), count >= 2 else {
			return self
		}
		return String(dropFirst().dropLast())
	}
}

extension SyntaxProtocol {
	var trimmedDescription: String {
		self.trimmed.description
	}
}

extension AttributeListSyntax {
	func containsAttribute(named name: String) -> Bool {
		for attribute in self {
			guard let attribute = attribute.as(AttributeSyntax.self) else {
				continue
			}

			if attribute.attributeName.trimmedDescription == name {
				return true
			}
		}
		return false
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
