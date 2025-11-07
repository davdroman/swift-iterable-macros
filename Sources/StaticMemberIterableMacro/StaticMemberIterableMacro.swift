import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

struct StaticMemberIterableMacro: MemberMacro {
	static func expansion(
		of node: AttributeSyntax,
		providingMembersOf declaration: some DeclGroupSyntax,
		conformingTo protocols: [TypeSyntax],
		in context: some MacroExpansionContext
	) throws -> [DeclSyntax] {
		let options = AttributeOptions(attribute: node)

		guard declaration.isSupportedType else {
			throw DiagnosticsError(
				diagnostics: [
					Diagnostic(node: Syntax(node), message: NotATypeError()),
				]
			)
		}

		let members = declaration.staticMembers

		guard !members.isEmpty else {
			context.diagnose(
				Diagnostic(node: Syntax(node), message: NoStaticMembersWarning())
			)
			return []
		}

		let emitter = StaticMemberEmitter(
			access: AccessSpecifier(keyword: options.accessModifier),
			members: members,
			valueType: options.memberType ?? declaration.memberValueType
		)

		let conflicts = StaticMemberEmitter.synthesizedMemberNames
			.filter { declaration.declaresMember(named: $0) }

		guard conflicts.isEmpty else {
			throw DiagnosticsError(
				diagnostics: conflicts.map {
					Diagnostic(node: Syntax(node), message: ConflictingMemberError(memberName: $0))
				}
			)
		}

		return emitter.makeDeclarations()
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
	let members: [StaticMember]
	let valueType: String

	static let synthesizedMemberNames = [
		"allStaticMembers",
		"allStaticMemberNames",
		"allNamedStaticMembers",
	]

	func makeDeclarations() -> [DeclSyntax] {
		let identifiers = members.map(\.reference).joined(separator: ", ")
		let names = members.map(\.literal).joined(separator: ", ")
		let tuples = members.map(\.tuple).joined(separator: ",\n")

		return [
			"\(raw: access.prefix)static let allStaticMembers = [\(raw: identifiers)]",
			"\(raw: access.prefix)static let allStaticMemberNames: [StaticMemberName] = [\(raw: names)]",
			"""
			\(raw: access.prefix)static let allNamedStaticMembers: [(name: StaticMemberName, value: \(raw: valueType))] = [
			\(raw: tuples)
			]
			""",
		]
	}
}

struct AccessSpecifier {
	let prefix: String

	init(keyword: String?) {
		self.prefix = keyword.map { "\($0) " } ?? ""
	}
}

struct StaticMember {
	let reference: String
	let literal: String
	let tuple: String

	init(identifier: TokenSyntax) {
		self.reference = identifier.text
		let plainName = reference.trimmingBackticks()
		self.literal = "\"\(plainName)\""
		self.tuple = "(name: \(literal), value: \(reference))"
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

	var staticMembers: [StaticMember] {
		memberBlock.members.flatMap(\.staticMembers)
	}

	func declaresMember(named name: String) -> Bool {
		memberBlock.members.contains { $0.declaresVariable(named: name) }
	}

	var memberValueType: String {
		if self.is(ClassDeclSyntax.self) {
			return classValueTypeName ?? "Self"
		}
		return "Self"
	}

	var classValueTypeName: String? {
		guard let classDecl = self.as(ClassDeclSyntax.self) else { return nil }

		var name = classDecl.name.text

		if let generics = classDecl.genericParameterClause {
			let parameters = generics.parameters
				.map(\.name.text)
				.joined(separator: ", ")
			name += "<\(parameters)>"
		}

		return name
	}
}

extension MemberBlockItemSyntax {
	var staticMembers: [StaticMember] {
		guard
			let variable = decl.as(VariableDeclSyntax.self),
			variable.isStaticLet
		else {
			return []
		}

		return variable.bindings.compactMap {
			$0.pattern.as(IdentifierPatternSyntax.self)?.identifier
		}
		.map(StaticMember.init(identifier:))
	}

	func declaresVariable(named name: String) -> Bool {
		guard let variable = decl.as(VariableDeclSyntax.self) else {
			return false
		}

		return variable.declaredNames.contains(name)
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
