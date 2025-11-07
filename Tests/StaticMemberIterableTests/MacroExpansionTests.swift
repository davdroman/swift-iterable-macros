#if canImport(StaticMemberIterableMacro)
import MacroTesting
import Testing

@testable import StaticMemberIterableMacro

@Suite(
	.macros(
		[StaticMemberIterableMacro.self],
		indentationWidth: .tab,
		record: .missing
	)
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
			"""
			struct Coffee {
				let name: String
				let roastLevel: Int

				static let sunrise = Coffee(name: "sunrise", roastLevel: 2)
				static let moonlight = Coffee(name: "moonlight", roastLevel: 3)
				static let stardust = Coffee(name: "stardust", roastLevel: 4)

				static let allStaticMembers = [sunrise, moonlight, stardust]

				static let allStaticMemberNames: [StaticMemberName] = ["sunrise", "moonlight", "stardust"]

				static let allNamedStaticMembers: [(name: StaticMemberName, value: Self)] = [
					(name: "sunrise", value: sunrise),
					(name: "moonlight", value: moonlight),
					(name: "stardust", value: stardust)
				]
			}
			"""
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
			"""
			struct Blend {
				static let sunrise = Blend(), moonlight = Blend()
				static let stardust = Blend()

				static let allStaticMembers = [sunrise, moonlight, stardust]

				static let allStaticMemberNames: [StaticMemberName] = ["sunrise", "moonlight", "stardust"]

				static let allNamedStaticMembers: [(name: StaticMemberName, value: Self)] = [
					(name: "sunrise", value: sunrise),
					(name: "moonlight", value: moonlight),
					(name: "stardust", value: stardust)
				]
			}
			"""
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
			"""
			class Laboratory {
				static let alpha = Laboratory()
				static var placeholder = Laboratory()
				static let beta = Laboratory()

				static let allStaticMembers = [alpha, beta]

				static let allStaticMemberNames: [StaticMemberName] = ["alpha", "beta"]

				static let allNamedStaticMembers: [(name: StaticMemberName, value: Laboratory)] = [
					(name: "alpha", value: alpha),
					(name: "beta", value: beta)
				]
			}
			"""
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
			"""
			enum ReservedNames {
				static let `class` = ReservedNames()
				static let `struct` = ReservedNames()
				static let plain = ReservedNames()

				static let allStaticMembers = [`class`, `struct`, plain]

				static let allStaticMemberNames: [StaticMemberName] = ["class", "struct", "plain"]

				static let allNamedStaticMembers: [(name: StaticMemberName, value: Self)] = [
					(name: "class", value: `class`),
					(name: "struct", value: `struct`),
					(name: "plain", value: plain)
				]
			}
			"""
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
			"""
			struct MyRecord {
				enum Fixtures {
					static let a = MyRecord()
					static let b = MyRecord()
					static let c = MyRecord()

					fileprivate static let allStaticMembers = [a, b, c]

					fileprivate static let allStaticMemberNames: [StaticMemberName] = ["a", "b", "c"]

					fileprivate static let allNamedStaticMembers: [(name: StaticMemberName, value: Self)] = [
						(name: "a", value: a),
						(name: "b", value: b),
						(name: "c", value: c)
					]
				}
			}
			"""
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
			"""
			class Drink {}
			class MockDrink: Drink {
				static let water = MockDrink()
				static let soda = MockDrink()

				static let allStaticMembers = [water, soda]

				static let allStaticMemberNames: [StaticMemberName] = ["water", "soda"]

				static let allNamedStaticMembers: [(name: StaticMemberName, value: MockDrink)] = [
					(name: "water", value: water),
					(name: "soda", value: soda)
				]
			}
			"""
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
			"""
			struct Drink {}
			enum DrinkFixtures {
				static let water = Drink()
				static let soda = Drink()

				static let allStaticMembers = [water, soda]

				static let allStaticMemberNames: [StaticMemberName] = ["water", "soda"]

				static let allNamedStaticMembers: [(name: StaticMemberName, value: Drink)] = [
					(name: "water", value: water),
					(name: "soda", value: soda)
				]
			}
			"""
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
			"""
			protocol Beverage {}
			struct Coffee: Beverage {}
			enum BeverageFixtures {
				static let espresso = Coffee()
				static let latte = Coffee()

				static let allStaticMembers = [espresso, latte]

				static let allStaticMemberNames: [StaticMemberName] = ["espresso", "latte"]

				static let allNamedStaticMembers: [(name: StaticMemberName, value: (any Beverage))] = [
					(name: "espresso", value: espresso),
					(name: "latte", value: latte)
				]
			}
			"""
		}
	}

	// MARK: Access control

	@Test func publicAccess() {
		assertMacro {
			"""
			struct Beverage {}

			@StaticMemberIterable(.public, ofType: Beverage.self)
			enum Menu {
				static let espresso = Beverage()
				static let latte = Beverage()
			}
			"""
		} expansion: {
			"""
			struct Beverage {}
			enum Menu {
				static let espresso = Beverage()
				static let latte = Beverage()

				public static let allStaticMembers = [espresso, latte]

				public static let allStaticMemberNames: [StaticMemberName] = ["espresso", "latte"]

				public static let allNamedStaticMembers: [(name: StaticMemberName, value: Beverage)] = [
					(name: "espresso", value: espresso),
					(name: "latte", value: latte)
				]
			}
			"""
		}
	}

	@Test func packageAccess() {
		assertMacro {
			"""
			@StaticMemberIterable(.package)
			struct Roast {
				static let light = Roast()
				static let dark = Roast()
			}
			"""
		} expansion: {
			"""
			struct Roast {
				static let light = Roast()
				static let dark = Roast()

				package static let allStaticMembers = [light, dark]

				package static let allStaticMemberNames: [StaticMemberName] = ["light", "dark"]

				package static let allNamedStaticMembers: [(name: StaticMemberName, value: Self)] = [
					(name: "light", value: light),
					(name: "dark", value: dark)
				]
			}
			"""
		}
	}

	@Test func privateAccess() {
		assertMacro {
			"""
			@StaticMemberIterable(.private)
			enum MenuItem {
				static let breakfast = MenuItem()
				static let dinner = MenuItem()
			}
			"""
		} expansion: {
			"""
			enum MenuItem {
				static let breakfast = MenuItem()
				static let dinner = MenuItem()

				private static let allStaticMembers = [breakfast, dinner]

				private static let allStaticMemberNames: [StaticMemberName] = ["breakfast", "dinner"]

				private static let allNamedStaticMembers: [(name: StaticMemberName, value: Self)] = [
					(name: "breakfast", value: breakfast),
					(name: "dinner", value: dinner)
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
				static let allStaticMembers: [Fixtures] = []
				static let sunrise = Fixtures()
			}
			"""
		} diagnostics: {
			"""
			@StaticMemberIterable
			┬────────────────────
			╰─ 🛑 '@StaticMemberIterable' cannot generate 'allStaticMembers' because it already exists
			struct Fixtures {
				static let allStaticMembers: [Fixtures] = []
				static let sunrise = Fixtures()
			}
			"""
		}
	}
}
#endif
