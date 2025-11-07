import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct StaticMemberIterablePlugin: CompilerPlugin {
	let providingMacros: [any Macro.Type] = [
		StaticMemberIterableMacro.self,
	]
}
