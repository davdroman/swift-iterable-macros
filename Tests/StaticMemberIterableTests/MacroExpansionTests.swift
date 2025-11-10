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

	@Test func publicTypePropagatesAliasAccess() {
		assertMacro {
			"""
			@StaticMemberIterable
			public struct Showcase {
				public static let demo = Showcase()
			}
			"""
		} expansion: {
			#"""
			public struct Showcase {
				public static let demo = Showcase()

				public typealias StaticMemberValue = Showcase

				static let allStaticMembers: [StaticMember<Showcase, Showcase>] = [
					StaticMember(
						keyPath: \Showcase.Type .demo,
						name: "demo",
						value: demo
					)
				]
			}
			"""#
		}
	}

	@Test func implicitInternalTypePropagatesAliasAccess() {
		assertMacro {
			"""
			@StaticMemberIterable
			struct InternalMenu {
				static let breakfast = InternalMenu()
			}
			"""
		} expansion: {
			#"""
			struct InternalMenu {
				static let breakfast = InternalMenu()

				typealias StaticMemberValue = InternalMenu

				static let allStaticMembers: [StaticMember<InternalMenu, InternalMenu>] = [
					StaticMember(
						keyPath: \InternalMenu.Type .breakfast,
						name: "breakfast",
						value: breakfast
					)
				]
			}
			"""#
		}
	}

	@Test func explicitInternalTypePropagatesAliasAccess() {
		assertMacro {
			"""
			@StaticMemberIterable
			internal struct ExplicitInternalMenu {
				static let dinner = ExplicitInternalMenu()
			}
			"""
		} expansion: {
			#"""
			internal struct ExplicitInternalMenu {
				static let dinner = ExplicitInternalMenu()

				internal typealias StaticMemberValue = ExplicitInternalMenu

				static let allStaticMembers: [StaticMember<ExplicitInternalMenu, ExplicitInternalMenu>] = [
					StaticMember(
						keyPath: \ExplicitInternalMenu.Type .dinner,
						name: "dinner",
						value: dinner
					)
				]
			}
			"""#
		}
	}

	@Test func packageTypePropagatesAliasAccess() {
		assertMacro {
			"""
			@StaticMemberIterable
			package struct PackageMenu {
				static let special = PackageMenu()
			}
			"""
		} expansion: {
			#"""
			package struct PackageMenu {
				static let special = PackageMenu()

				package typealias StaticMemberValue = PackageMenu

				static let allStaticMembers: [StaticMember<PackageMenu, PackageMenu>] = [
					StaticMember(
						keyPath: \PackageMenu.Type .special,
						name: "special",
						value: special
					)
				]
			}
			"""#
		}
	}

	@Test func fileprivateTypePropagatesAliasAccess() {
		assertMacro {
			"""
			@StaticMemberIterable
			fileprivate enum FileprivateMenu {
				static let hidden = FileprivateMenu()
			}
			"""
		} expansion: {
			#"""
			fileprivate enum FileprivateMenu {
				static let hidden = FileprivateMenu()

				fileprivate typealias StaticMemberValue = FileprivateMenu

				static let allStaticMembers: [StaticMember<FileprivateMenu, FileprivateMenu>] = [
					StaticMember(
						keyPath: \FileprivateMenu.Type .hidden,
						name: "hidden",
						value: hidden
					)
				]
			}
			"""#
		}
	}

	@Test func privateTypePropagatesAliasAccess() {
		assertMacro {
			"""
			@StaticMemberIterable
			private enum SecretMenu {
				static let chef = SecretMenu()
			}
			"""
		} expansion: {
			#"""
			private enum SecretMenu {
				static let chef = SecretMenu()

				private typealias StaticMemberValue = SecretMenu

				static let allStaticMembers: [StaticMember<SecretMenu, SecretMenu>] = [
					StaticMember(
						keyPath: \SecretMenu.Type .chef,
						name: "chef",
						value: chef
					)
				]
			}
			"""#
		}
	}

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
			#"""
			struct Beverage {}
			enum Menu {
				static let espresso = Beverage()
				static let latte = Beverage()

				typealias StaticMemberValue = Beverage

				public static let allStaticMembers: [StaticMember<Menu, Beverage>] = [
					StaticMember(
						keyPath: \Menu.Type .espresso,
						name: "espresso",
						value: espresso
					),
					StaticMember(
						keyPath: \Menu.Type .latte,
						name: "latte",
						value: latte
					)
				]
			}
			"""#
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
			#"""
			struct Roast {
				static let light = Roast()
				static let dark = Roast()

				typealias StaticMemberValue = Roast

				package static let allStaticMembers: [StaticMember<Roast, Roast>] = [
					StaticMember(
						keyPath: \Roast.Type .light,
						name: "light",
						value: light
					),
					StaticMember(
						keyPath: \Roast.Type .dark,
						name: "dark",
						value: dark
					)
				]
			}
			"""#
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
			#"""
			enum MenuItem {
				static let breakfast = MenuItem()
				static let dinner = MenuItem()

				typealias StaticMemberValue = MenuItem

				private static let allStaticMembers: [StaticMember<MenuItem, MenuItem>] = [
					StaticMember(
						keyPath: \MenuItem.Type .breakfast,
						name: "breakfast",
						value: breakfast
					),
					StaticMember(
						keyPath: \MenuItem.Type .dinner,
						name: "dinner",
						value: dinner
					)
				]
			}
			"""#
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
