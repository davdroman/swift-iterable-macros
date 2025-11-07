import StaticMemberIterable
import Testing

@Suite
struct StaticMemberNameTests {
	@Test func camelCaseToTitle() {
		let name = StaticMemberName(rawValue: "moonlightLatte")
		#expect(name.rawValue == "moonlightLatte")
		#expect(name.title == "Moonlight Latte")
	}

	@Test func preservesAcronyms() {
		let name = StaticMemberName(rawValue: "URLSessionLogger")
		#expect(name.title == "URL Session Logger")
	}

	@Test func handlesSeparatorsAndNumbers() {
		let name: StaticMemberName = "iced_latteV2"
		#expect(name.rawValue == "iced_latteV2")
		#expect(name.title == "Iced Latte V2")
	}

	@Test func acronymsAndSeparators() {
		let name = StaticMemberName(rawValue: "httpURLParser")
		#expect(name.title == "Http URL Parser")
	}

	@Test func mixedSeparators() {
		let name = StaticMemberName(rawValue: "iced_latteV2-pro")
		#expect(name.title == "Iced Latte V2 Pro")
	}

	@Test func lowercaseAndUppercaseWords() {
		#expect(StaticMemberName(rawValue: "sunrise").title == "Sunrise")
		#expect(StaticMemberName(rawValue: "API").title == "API")
	}

	@Test func unicodeLetters() {
		let name = StaticMemberName(rawValue: "mañanaBlend")
		#expect(name.title == "Mañana Blend")
	}

	@Test func emptyString() {
		let name = StaticMemberName(rawValue: "")
		#expect(name.title == "")
	}

	@Test func expressibleByStringLiteral() {
		let names: [StaticMemberName] = ["sunrise", "stardust"]
		#expect(names == ["sunrise", "stardust"])
	}
}
