import CaseIterable
import Testing

@MainActor
@Suite
struct CaseIterableRuntimeTests {
	@CaseIterable
	enum CoffeeKind: Equatable {
		case espresso
		case latte
		case pourOver
	}

	@CaseIterable(.public)
	enum MenuSection {
		case breakfast, lunch, dinner
	}

	@CaseIterable
	@dynamicMemberLookup
	enum Palette {
		case sunrise
		case midnight

		struct Properties {
			let description: String
		}

		var properties: Properties {
			switch self {
			case .sunrise:
				Properties(description: "Sunrise")
			case .midnight:
				Properties(description: "Midnight")
			}
		}
	}

	@Test func caseIterableMembers() {
		let cases = CoffeeKind.allCases

		#expect(cases.count == 3)
		#expect(cases.map(\.name) == ["espresso", "latte", "pourOver"])
		#expect(cases.map(\.title) == ["Espresso", "Latte", "Pour Over"])
		#expect(cases.map(\.value) == [.espresso, .latte, .pourOver])
		#expect(cases.map(\.id) == ["espresso", "latte", "pourOver"])
	}

	@Test func dynamicMemberLookupForwardsToProperties() {
		#expect(Palette.sunrise.description == "Sunrise")
		#expect(Palette.midnight.description == "Midnight")
	}
}
