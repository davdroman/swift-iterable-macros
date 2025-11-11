import CaseIterable
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
		static let espresso: any BeverageProtocol = ExistentialBeverage(name: "espresso")
		static let latte: any BeverageProtocol = ExistentialBeverage(name: "latte")
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

	@CaseIterable
	enum CoffeeKind: Equatable {
		case espresso
		case latte
		case pourOver
	}

	@CaseIterable(.public)
	enum MenuSection {
		case breakfast
		case lunch
		case dinner
	}

	// Tests

	@Test func coffeeMembers() throws {
		let members = Coffee.allStaticMembers

		#expect(members.count == 3)
		#expect(members.map(\.name) == ["sunrise", "moonlight", "stardust"])
		#expect(members.map(\.title) == ["Sunrise", "Moonlight", "Stardust"])
		#expect(members.map(\.value.name) == ["sunrise", "moonlight", "stardust"])
		#expect(members.map(\.value.roastLevel) == [2, 3, 4])

		let sunrise = try #require(members.first)
		#expect(Coffee.self[keyPath: sunrise.keyPath].name == sunrise.value.name)
	}

	@Test func multiBindingRuntime() {
		let members = Menu.allStaticMembers

		#expect(members.count == 2)
		#expect(members.map(\.name) == ["sunrise", "sunset"])
		#expect(members.map(\.title) == ["Sunrise", "Sunset"])
		#expect(members.map(\.value) == [Menu.sunrise, Menu.sunset])
	}

	@Test func customMemberTypeRuntime() {
		let members = BeverageFixtures.allStaticMembers

		#expect(members.map(\.name) == ["sparkling", "still"])
		#expect(members.map(\.value) == [Beverage(name: "sparkling"), Beverage(name: "still")])
	}

	@Test func existentialMemberTypeRuntime() {
		let members = ExistentialBeverageFixtures.allStaticMembers

		#expect(members.count == 2)
		#expect(members.map(\.name) == ["espresso", "latte"])
		#expect(members.map(\.title) == ["Espresso", "Latte"])
		#expect(members.map(\.value.name) == members.map(\.name))
	}

	@Test func reservedIdentifiers() {
		let members = ReservedNames.allStaticMembers

		#expect(members.count == 2)
		#expect(members.map(\.name) == ["class", "plain"])
		#expect(members.map(\.title) == ["Class", "Plain"])
		#expect(members.map(\.value) == [ReservedNames.`class`, ReservedNames.plain])
	}

	@Test func ignoresNonLetMembers() {
		let members = Laboratory.allStaticMembers

		#expect(members.count == 2)
		#expect(members.map(\.name) == ["alpha", "beta"])
		#expect(members.map(\.title) == ["Alpha", "Beta"])
		#expect(members.map(\.value) == [Laboratory.alpha, Laboratory.beta])
	}

	@Test func classInheritanceRuntime() {
		let members = MockDrink.allStaticMembers

		#expect(members.count == 2)
		#expect(members.map(\.name) == ["water", "soda"])
		#expect(members.map(\.title) == ["Water", "Soda"])
		#expect(members.map(\.value) == [MockDrink.water, MockDrink.soda])
	}

	@Test func staticMemberIterableConformance() {
		let coffeeMembers: [StaticMemberOf<Coffee>] = Coffee.allStaticMembers
		let beverageMembers: [StaticMemberOf<BeverageFixtures>] = BeverageFixtures.allStaticMembers

		#expect(coffeeMembers.count == 3)
		#expect(beverageMembers.map(\.value.name) == ["sparkling", "still"])
	}

	@Test func caseIterableMembers() {
		let cases = CoffeeKind.allCases

		#expect(cases.count == 3)
		#expect(cases.map(\.name) == ["espresso", "latte", "pourOver"])
		#expect(cases.map(\.title) == ["Espresso", "Latte", "Pour Over"])
		#expect(cases.map(\.value) == [.espresso, .latte, .pourOver])
		#expect(cases.map(\.id) == ["espresso", "latte", "pourOver"])
	}
}
