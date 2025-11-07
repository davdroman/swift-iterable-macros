import StaticMemberIterable
import Testing

@MainActor
@Suite
struct StaticMemberIterableTests {
	// Fixtures

	@StaticMemberIterable
	struct Coffee {
		let name: String
		let roastLevel: Int

		static let sunrise = Coffee(name: "sunrise", roastLevel: 2)
		static let moonlight = Coffee(name: "moonlight", roastLevel: 3)
		static let stardust = Coffee(name: "stardust", roastLevel: 4)
	}

	@StaticMemberIterable(.public)
	struct Menu: Equatable {
		static let sunrise = Menu(), sunset = Menu()
	}

	struct Beverage: Equatable {
		let name: String
	}

	protocol BeverageProtocol: Sendable {
		var name: String { get }
	}

	struct ExistentialBeverage: BeverageProtocol, Equatable {
		let name: String
	}

	@StaticMemberIterable(ofType: Beverage.self)
	enum BeverageFixtures {
		static let sparkling = Beverage(name: "sparkling")
		static let still = Beverage(name: "still")
	}

	@StaticMemberIterable(ofType: (any BeverageProtocol).self)
	enum ExistentialBeverageFixtures {
		static let espresso = ExistentialBeverage(name: "espresso")
		static let latte = ExistentialBeverage(name: "latte")
	}

	@StaticMemberIterable
	struct ReservedNames: Equatable {
		static let `class` = ReservedNames()
		static let plain = ReservedNames()
	}

	@StaticMemberIterable
	class Laboratory: Equatable, @unchecked Sendable {
		static let alpha = Laboratory()
		nonisolated(unsafe) static var placeholder = Laboratory()
		static let beta = Laboratory()

		static func == (lhs: Laboratory, rhs: Laboratory) -> Bool {
			lhs === rhs
		}
	}

	class Drink {}

	@StaticMemberIterable
	class MockDrink: Drink, Equatable, @unchecked Sendable {
		static let water = MockDrink()
		static let soda = MockDrink()

		static func == (lhs: MockDrink, rhs: MockDrink) -> Bool {
			lhs === rhs
		}
	}

	// Tests

	@Test func coffeeMembers() {
		#expect(Coffee.allStaticMembers.count == 3)
		#expect(Coffee.allStaticMembers.map(\.name) == ["sunrise", "moonlight", "stardust"])
		#expect(Coffee.allStaticMembers.map(\.roastLevel) == [2, 3, 4])

		#expect(Coffee.allStaticMemberNames == ["sunrise", "moonlight", "stardust"])
		#expect(Coffee.allStaticMemberNames.map(\.title) == ["Sunrise", "Moonlight", "Stardust"])

		#expect(Coffee.allNamedStaticMembers.count == 3)
		#expect(Coffee.allNamedStaticMembers.map(\.name) == ["sunrise", "moonlight", "stardust"])
		#expect(Coffee.allNamedStaticMembers.map(\.name.title) == ["Sunrise", "Moonlight", "Stardust"])
		#expect(Coffee.allNamedStaticMembers.map(\.value.name) == ["sunrise", "moonlight", "stardust"])
		#expect(Coffee.allNamedStaticMembers.map(\.value.roastLevel) == [2, 3, 4])
	}

	@Test func multiBindingRuntime() {
		#expect(Menu.allStaticMembers.count == 2)
		#expect(Menu.allStaticMembers == [Menu.sunrise, Menu.sunset])

		#expect(Menu.allStaticMemberNames == ["sunrise", "sunset"])
		#expect(Menu.allStaticMemberNames.map(\.title) == ["Sunrise", "Sunset"])

		#expect(Menu.allNamedStaticMembers.count == 2)
		#expect(Menu.allNamedStaticMembers.map(\.name) == ["sunrise", "sunset"])
		#expect(Menu.allNamedStaticMembers.map(\.value) == [Menu.sunrise, Menu.sunset])
	}

	@Test func customMemberTypeRuntime() {
		#expect(BeverageFixtures.allStaticMembers == [Beverage(name: "sparkling"), Beverage(name: "still")])

		#expect(BeverageFixtures.allStaticMemberNames == ["sparkling", "still"])
		#expect(BeverageFixtures.allNamedStaticMembers.map(\.name) == ["sparkling", "still"])
		#expect(BeverageFixtures.allNamedStaticMembers.map(\.value) == BeverageFixtures.allStaticMembers)
	}

	@Test func existentialMemberTypeRuntime() {
		#expect(ExistentialBeverageFixtures.allStaticMembers.count == 2)
		#expect(
			ExistentialBeverageFixtures.allStaticMembers
				== [
					ExistentialBeverage(name: "espresso"),
					ExistentialBeverage(name: "latte"),
				]
		)

		#expect(ExistentialBeverageFixtures.allStaticMemberNames == ["espresso", "latte"])
		#expect(ExistentialBeverageFixtures.allStaticMemberNames.map(\.title) == ["Espresso", "Latte"])

		#expect(ExistentialBeverageFixtures.allNamedStaticMembers.map(\.name) == ["espresso", "latte"])
		#expect(
			ExistentialBeverageFixtures.allNamedStaticMembers.map(\.value.name)
				== ExistentialBeverageFixtures.allStaticMembers.map(\.name)
		)
	}

	@Test func reservedIdentifiers() {
		#expect(ReservedNames.allStaticMembers.count == 2)
		#expect(ReservedNames.allStaticMembers == [ReservedNames.`class`, ReservedNames.plain])

		#expect(ReservedNames.allStaticMemberNames == ["class", "plain"])
		#expect(ReservedNames.allStaticMemberNames.map(\.title) == ["Class", "Plain"])

		#expect(ReservedNames.allNamedStaticMembers.count == 2)
		#expect(ReservedNames.allNamedStaticMembers.map(\.name) == ["class", "plain"])
		#expect(ReservedNames.allNamedStaticMembers.map(\.value) == [ReservedNames.`class`, ReservedNames.plain])
	}

	@Test func ignoresNonLetMembers() {
		#expect(Laboratory.allStaticMembers.count == 2)
		#expect(Laboratory.allStaticMembers == [Laboratory.alpha, Laboratory.beta])

		#expect(Laboratory.allStaticMemberNames == ["alpha", "beta"])
		#expect(Laboratory.allStaticMemberNames.map(\.title) == ["Alpha", "Beta"])

		#expect(Laboratory.allNamedStaticMembers.count == 2)
		#expect(Laboratory.allNamedStaticMembers.map(\.name) == ["alpha", "beta"])
		#expect(Laboratory.allNamedStaticMembers.map(\.value) == [Laboratory.alpha, Laboratory.beta])
	}

	@Test func classInheritanceRuntime() {
		#expect(MockDrink.allStaticMembers.count == 2)
		#expect(MockDrink.allStaticMembers == [MockDrink.water, MockDrink.soda])

		#expect(MockDrink.allStaticMemberNames == ["water", "soda"])
		#expect(MockDrink.allStaticMemberNames.map(\.title) == ["Water", "Soda"])

		#expect(MockDrink.allNamedStaticMembers.count == 2)
		#expect(MockDrink.allNamedStaticMembers.map(\.name) == ["water", "soda"])
		#expect(MockDrink.allNamedStaticMembers.map(\.value) == [MockDrink.water, MockDrink.soda])
	}
}
