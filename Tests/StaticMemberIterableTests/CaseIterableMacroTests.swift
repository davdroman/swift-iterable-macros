#if canImport(CaseIterableMacro)
import MacroTesting
import Testing

@testable import CaseIterableMacro

@Suite(
	.macros(
		[CaseIterableMacro.self],
		indentationWidth: .tab,
		record: .missing
	)
)
struct CaseIterableMacroTests {
	@Test func defaultAccessInternal() {
		assertMacro {
			"""
			@CaseIterable
			enum Beverage {
				case still
				case sparkling
				case sparklingWater
			}
			"""
		} expansion: {
			#"""
			enum Beverage {
				case still
				case sparkling
				case sparklingWater

				static let allCases: [CaseOf<Beverage>] = [
					CaseOf(
						name: "still",
						value: .still
					),
					CaseOf(
						name: "sparkling",
						value: .sparkling
					),
					CaseOf(
						name: "sparklingWater",
						value: .sparklingWater
					)
				]
			}
			"""#
		}
	}

	@Test func multiCaseDeclarations() {
		assertMacro {
			"""
			@CaseIterable
			enum Meal {
				case breakfast, lunch
				case dinner
			}
			"""
		} expansion: {
			#"""
			enum Meal {
				case breakfast, lunch
				case dinner

				static let allCases: [CaseOf<Meal>] = [
					CaseOf(
						name: "breakfast",
						value: .breakfast
					),
					CaseOf(
						name: "lunch",
						value: .lunch
					),
					CaseOf(
						name: "dinner",
						value: .dinner
					)
				]
			}
			"""#
		}
	}

	@Test func rawValueCases() {
		assertMacro {
			"""
			@CaseIterable
			enum Flavor: String {
				case vanilla = "vanilla"
				case chocolate = "chocolate"
			}
			"""
		} expansion: {
			#"""
			enum Flavor: String {
				case vanilla = "vanilla"
				case chocolate = "chocolate"

				static let allCases: [CaseOf<Flavor>] = [
					CaseOf(
						name: "vanilla",
						value: .vanilla
					),
					CaseOf(
						name: "chocolate",
						value: .chocolate
					)
				]
			}
			"""#
		}
	}

	// MARK: Access control

	@Test(arguments: [
		("(.public)", "public "),
		("(.internal)", "internal "),
		("", ""),
		("(.package)", "package "),
		("(.fileprivate)", "fileprivate "),
		("(.private)", "private "),
	])
	func macroAccessSetsAllCases(macroModifier: String, membersModifier: String) {
		assertMacro {
			"""
			@CaseIterable\(macroModifier)
			enum AccessControlled {
				case sample
			}
			"""
		} expansion: {
			"""
			enum AccessControlled {
				case sample

				\(membersModifier)static let allCases: [CaseOf<AccessControlled>] = [
					CaseOf(
						name: "sample",
						value: .sample
					)
				]
			}
			"""
		}
	}

	// MARK: Diagnostics

	@Test func notAnEnumError() {
		assertMacro {
			"""
			@CaseIterable
			struct NotAnEnum {}
			"""
		} diagnostics: {
			"""
			@CaseIterable
			┬────────────
			╰─ 🛑 `@CaseIterable` only works on enums
			struct NotAnEnum {}
			"""
		}
	}

	@Test func noEnumCasesWarning() {
		assertMacro {
			"""
			@CaseIterable
			enum Empty {}
			"""
		} diagnostics: {
			"""
			@CaseIterable
			┬────────────
			╰─ ⚠️ '@CaseIterable' does not generate members when there are no enum cases
			enum Empty {}
			"""
		} expansion: {
			"""
			enum Empty {}
			"""
		}
	}

	@Test func associatedValueCaseError() {
		assertMacro {
			"""
			@CaseIterable
			enum CoffeeOrder {
				case espresso
				case latte(size: Int)
			}
			"""
		} diagnostics: {
#"""
@CaseIterable
enum CoffeeOrder {
	case espresso
	case latte(size: Int)
      ┬───────────────
      ╰─ 🛑 '@CaseIterable' does not support cases with associated values ('latte')
}
"""#
		}
	}
}
#endif
