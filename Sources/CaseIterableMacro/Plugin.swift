import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct CaseIterablePlugin: CompilerPlugin {
	var providingMacros: [any Macro.Type] {
		[
			CaseIterableMacro.self,
		]
	}
}
