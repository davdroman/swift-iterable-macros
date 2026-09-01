#if canImport(CaseIterableMacro)
@testable import CaseIterableMacro
import MacroTesting
import SnapshotTesting
import SwiftSyntax
import Testing

@Suite(
	.macros(
		[CaseIterableMacro.self],
		indentationWidth: .tab,
		record: .missing,
	),
)
struct CaseIterableMacroTests {
	@Test func `default access is internal`() {
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
			"""
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
			"""
		}
	}

	@Test func `multiple case declarations`() {
		assertMacro {
			"""
			@CaseIterable
			enum Meal {
				case breakfast, lunch
				case dinner
			}
			"""
		} expansion: {
			"""
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
			"""
		}
	}

	@Test func `raw value cases`() {
		assertMacro {
			"""
			@CaseIterable
			enum Flavor: String {
				case vanilla = "vanilla"
				case chocolate = "chocolate"
			}
			"""
		} expansion: {
			"""
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
			"""
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
	func `macro access level applies to allCases`(macroModifier: String, membersModifier: String) {
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

	@Test func `not an enum error`() {
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

	@Test func `no enum cases warning`() {
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

	@Test func `associated value case error`() {
		assertMacro {
			"""
			@CaseIterable
			enum CoffeeOrder {
				case espresso
				case latte(size: Int)
			}
			"""
		} diagnostics: {
			"""
			@CaseIterable
			enum CoffeeOrder {
				case espresso
				case latte(size: Int)
			      ┬───────────────
			      ╰─ 🛑 '@CaseIterable' does not support cases with associated values ('latte')
			}
			"""
		}
	}

	// MARK: Dynamic member lookup

	@Test func `dynamic member lookup synthesizes subscript`() {
		assertMacro {
			"""
			@dynamicMemberLookup
			@CaseIterable
			enum Palette {
				case sunrise

				struct Properties {}

				var properties: Properties { Properties() }
			}
			"""
		} expansion: {
			"""
			@dynamicMemberLookup
			enum Palette {
				case sunrise

				struct Properties {}

				var properties: Properties { Properties() }

				static let allCases: [CaseOf<Palette>] = [
					CaseOf(
						name: "sunrise",
						value: .sunrise
					)
				]

				subscript <T>(dynamicMember keyPath: KeyPath<Properties, T>) -> T {
					properties[keyPath: keyPath]
				}
			}
			"""
		}
	}

	@Test(arguments: ["public ", "internal ", "", "package ", "fileprivate ", "private "])
	func `dynamic member subscript matches access level of Properties`(accessLevel: String) {
		assertMacro {
			"""
			@dynamicMemberLookup
			@CaseIterable
			enum Palette {
				case sunrise

				\(accessLevel)struct Properties {}

				var properties: Properties { Properties() }
			}
			"""
		} expansion: {
			"""
			@dynamicMemberLookup
			enum Palette {
				case sunrise

				\(accessLevel)struct Properties {}

				var properties: Properties { Properties() }

				static let allCases: [CaseOf<Palette>] = [
					CaseOf(
						name: "sunrise",
						value: .sunrise
					)
				]

				\(accessLevel)subscript <T>(dynamicMember keyPath: KeyPath<Properties, T>) -> T {
					properties[keyPath: keyPath]
				}
			}
			"""
		}
	}

	@Test func `dynamic member lookup without properties skips subscript`() {
		assertMacro {
			"""
			@dynamicMemberLookup
			@CaseIterable
			enum Palette {
				case sunrise

				var properties: Int { 0 }
			}
			"""
		} expansion: {
			"""
			@dynamicMemberLookup
			enum Palette {
				case sunrise

				var properties: Int { 0 }

				static let allCases: [CaseOf<Palette>] = [
					CaseOf(
						name: "sunrise",
						value: .sunrise
					)
				]
			}
			"""
		}
	}
}
#endif
