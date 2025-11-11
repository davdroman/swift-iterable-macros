#if canImport(StaticMemberIterableMacro)
import MacroTesting
import Testing

@testable import StaticMemberIterableMacro

@Suite(
	.macros(
		[StaticMemberIterableMacro.self],
		indentationWidth: .tab,
		record: .missing,
	),
)
struct StaticMemberIterableMacroTests {
	// MARK: Successful expansions

	@Test func defaultAccessInternal() {
		assertMacro {
			"""
			@StaticMemberIterable
			struct Coffee {
				let name: String
				let roastLevel: Int

				static let sunrise = Coffee(name: "sunrise", roastLevel: 2)
				static let moonlight = Coffee(name: "moonlight", roastLevel: 3)
				static let stardust = Coffee(name: "stardust", roastLevel: 4)
			}
			"""
		} expansion: {
			#"""
			struct Coffee {
				let name: String
				let roastLevel: Int

				static let sunrise = Coffee(name: "sunrise", roastLevel: 2)
				static let moonlight = Coffee(name: "moonlight", roastLevel: 3)
				static let stardust = Coffee(name: "stardust", roastLevel: 4)

				typealias StaticMemberValue = Coffee

				static let allStaticMembers: [StaticMember<Coffee, Coffee>] = [
					StaticMember(
						keyPath: \Coffee.Type .sunrise,
						name: "sunrise",
						value: sunrise
					),
					StaticMember(
						keyPath: \Coffee.Type .moonlight,
						name: "moonlight",
						value: moonlight
					),
					StaticMember(
						keyPath: \Coffee.Type .stardust,
						name: "stardust",
						value: stardust
					)
				]
			}
			"""#
		}
	}

	@Test func multiBindingStaticLets() {
		assertMacro {
			"""
			@StaticMemberIterable
			struct Blend {
				static let sunrise = Blend(), moonlight = Blend()
				static let stardust = Blend()
			}
			"""
		} expansion: {
			#"""
			struct Blend {
				static let sunrise = Blend(), moonlight = Blend()
				static let stardust = Blend()

				typealias StaticMemberValue = Blend

				static let allStaticMembers: [StaticMember<Blend, Blend>] = [
					StaticMember(
						keyPath: \Blend.Type .sunrise,
						name: "sunrise",
						value: sunrise
					),
					StaticMember(
						keyPath: \Blend.Type .moonlight,
						name: "moonlight",
						value: moonlight
					),
					StaticMember(
						keyPath: \Blend.Type .stardust,
						name: "stardust",
						value: stardust
					)
				]
			}
			"""#
		}
	}

	@Test func staticVarIgnored() {
		assertMacro {
			"""
			@StaticMemberIterable
			class Laboratory {
				static let alpha = Laboratory()
				static var placeholder = Laboratory()
				static let beta = Laboratory()
			}
			"""
		} expansion: {
			#"""
			class Laboratory {
				static let alpha = Laboratory()
				static var placeholder = Laboratory()
				static let beta = Laboratory()

				typealias StaticMemberValue = Laboratory

				static let allStaticMembers: [StaticMember<Laboratory, Laboratory>] = [
					StaticMember(
						keyPath: \Laboratory.Type .alpha,
						name: "alpha",
						value: alpha
					),
					StaticMember(
						keyPath: \Laboratory.Type .beta,
						name: "beta",
						value: beta
					)
				]
			}
			"""#
		}
	}

	@Test func escapedIdentifiers() {
		assertMacro {
			"""
			@StaticMemberIterable
			enum ReservedNames {
				static let `class` = ReservedNames()
				static let `struct` = ReservedNames()
				static let plain = ReservedNames()
			}
			"""
		} expansion: {
			#"""
			enum ReservedNames {
				static let `class` = ReservedNames()
				static let `struct` = ReservedNames()
				static let plain = ReservedNames()

				typealias StaticMemberValue = ReservedNames

				static let allStaticMembers: [StaticMember<ReservedNames, ReservedNames>] = [
					StaticMember(
						keyPath: \ReservedNames.Type .`class`,
						name: "class",
						value: `class`
					),
					StaticMember(
						keyPath: \ReservedNames.Type .`struct`,
						name: "struct",
						value: `struct`
					),
					StaticMember(
						keyPath: \ReservedNames.Type .plain,
						name: "plain",
						value: plain
					)
				]
			}
			"""#
		}
	}

	@Test func nestedTypes() {
		assertMacro {
			"""
			struct MyRecord {
				@StaticMemberIterable(.fileprivate)
				enum Fixtures {
					static let a = MyRecord()
					static let b = MyRecord()
					static let c = MyRecord()
				}
			}
			"""
		} expansion: {
			#"""
			struct MyRecord {
				enum Fixtures {
					static let a = MyRecord()
					static let b = MyRecord()
					static let c = MyRecord()

					typealias StaticMemberValue = Fixtures

					fileprivate static let allStaticMembers: [StaticMember<Fixtures, Fixtures>] = [
						StaticMember(
							keyPath: \Fixtures.Type .a,
							name: "a",
							value: a
						),
						StaticMember(
							keyPath: \Fixtures.Type .b,
							name: "b",
							value: b
						),
						StaticMember(
							keyPath: \Fixtures.Type .c,
							name: "c",
							value: c
						)
					]
				}
			}
			"""#
		}
	}

	@Test func classInheritance() {
		assertMacro {
			"""
			class Drink {}

			@StaticMemberIterable
			class MockDrink: Drink {
				static let water = MockDrink()
				static let soda = MockDrink()
			}
			"""
		} expansion: {
			#"""
			class Drink {}
			class MockDrink: Drink {
				static let water = MockDrink()
				static let soda = MockDrink()

				typealias StaticMemberValue = MockDrink

				static let allStaticMembers: [StaticMember<MockDrink, MockDrink>] = [
					StaticMember(
						keyPath: \MockDrink.Type .water,
						name: "water",
						value: water
					),
					StaticMember(
						keyPath: \MockDrink.Type .soda,
						name: "soda",
						value: soda
					)
				]
			}
			"""#
		}
	}

	@Test func customMemberType() {
		assertMacro {
			"""
			struct Drink {}

			@StaticMemberIterable(ofType: Drink.self)
			enum DrinkFixtures {
				static let water = Drink()
				static let soda = Drink()
			}
			"""
		} expansion: {
			#"""
			struct Drink {}
			enum DrinkFixtures {
				static let water = Drink()
				static let soda = Drink()

				typealias StaticMemberValue = Drink

				static let allStaticMembers: [StaticMember<DrinkFixtures, Drink>] = [
					StaticMember(
						keyPath: \DrinkFixtures.Type .water,
						name: "water",
						value: water
					),
					StaticMember(
						keyPath: \DrinkFixtures.Type .soda,
						name: "soda",
						value: soda
					)
				]
			}
			"""#
		}
	}

	@Test func existentialMemberType() {
		assertMacro {
			"""
			protocol Beverage {}
			struct Coffee: Beverage {}

			@StaticMemberIterable(ofType: (any Beverage).self)
			enum BeverageFixtures {
				static let espresso = Coffee()
				static let latte = Coffee()
			}
			"""
		} expansion: {
			#"""
			protocol Beverage {}
			struct Coffee: Beverage {}
			enum BeverageFixtures {
				static let espresso = Coffee()
				static let latte = Coffee()

				typealias StaticMemberValue = (any Beverage)

				static let allStaticMembers: [StaticMember<BeverageFixtures, (any Beverage)>] = [
					StaticMember(
						keyPath: \BeverageFixtures.Type .espresso,
						name: "espresso",
						value: espresso
					),
					StaticMember(
						keyPath: \BeverageFixtures.Type .latte,
						name: "latte",
						value: latte
					)
				]
			}
			"""#
		}
	}

	// MARK: Access control

	@Test(arguments: [
		("public ", "public "),
		("internal ", "internal "),
		("", ""),
		("package ", "package "),
		("fileprivate ", "fileprivate "),
		("private ", "private "),
	])
	func typealiasPropagatesTypeAccess(typeModifier: String, aliasModifier: String) {
		assertMacro {
			"""
			@StaticMemberIterable
			\(typeModifier)struct AccessAliasFixture {
				static let sample = AccessAliasFixture()
			}
			"""
		} expansion: {
			"""
			\(typeModifier)struct AccessAliasFixture {
				static let sample = AccessAliasFixture()

				\(aliasModifier)typealias StaticMemberValue = AccessAliasFixture

				static let allStaticMembers: [StaticMember<AccessAliasFixture, AccessAliasFixture>] = [
					StaticMember(
						keyPath: \\AccessAliasFixture.Type .sample,
						name: "sample",
						value: sample
					)
				]
			}
			"""
		}
	}

	@Test(arguments: [
		("(.public)", "public "),
		("(.internal)", "internal "),
		("", ""),
		("(.package)", "package "),
		("(.fileprivate)", "fileprivate "),
		("(.private)", "private "),
	])
	func macroAccessSetsAllStaticMembers(macroModifier: String, membersModifier: String) {
		assertMacro {
			"""
			@StaticMemberIterable\(macroModifier)
			struct AccessMacroFixture {
				static let sample = AccessMacroFixture()
			}
			"""
		} expansion: {
			"""
			struct AccessMacroFixture {
				static let sample = AccessMacroFixture()

				typealias StaticMemberValue = AccessMacroFixture

				\(membersModifier)static let allStaticMembers: [StaticMember<AccessMacroFixture, AccessMacroFixture>] = [
					StaticMember(
						keyPath: \\AccessMacroFixture.Type .sample,
						name: "sample",
						value: sample
					)
				]
			}
			"""
		}
	}

	// MARK: Diagnostics

	@Test func noStaticMembersWarning() {
		assertMacro {
			"""
			@StaticMemberIterable
			struct Fruit {
				let name: String
			}
			"""
		} diagnostics: {
			"""
			@StaticMemberIterable
			┬────────────────────
			╰─ ⚠️ '@StaticMemberIterable' does not generate members when there are no static `let` properties
			struct Fruit {
				let name: String
			}
			"""
		} expansion: {
			"""
			struct Fruit {
				let name: String
			}
			"""
		}
	}

	@Test func notATypeError() {
		assertMacro {
			"""
			@StaticMemberIterable
			actor RoastLogger {}
			"""
		} diagnostics: {
			"""
			@StaticMemberIterable
			┬────────────────────
			╰─ 🛑 `StaticMemberIterable` works on a `class`, `enum`, or `struct`
			actor RoastLogger {}
			"""
		}
	}

	@Test func conflictingMembersError() {
		assertMacro {
			"""
			@StaticMemberIterable
			struct Fixtures {
				static let allStaticMembers = []
				static let sunrise = Fixtures()
			}
			"""
		} diagnostics: {
			"""
			@StaticMemberIterable
			┬────────────────────
			╰─ 🛑 '@StaticMemberIterable' cannot generate 'allStaticMembers' because it already exists
			struct Fixtures {
				static let allStaticMembers = []
				static let sunrise = Fixtures()
			}
			"""
		}
	}
}
#endif
