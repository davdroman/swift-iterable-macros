import StaticMemberIterable
import Testing

@Suite
struct StaticMemberTitleTests {
	private struct Fixture {
		static let reference = Fixture()
	}

	private func makeMember(name: String) -> StaticMember<Fixture, Fixture> {
		StaticMember(
			keyPath: \Fixture.Type.reference,
			name: name,
			value: Fixture.reference,
		)
	}

	@Test func `camel case to title`() {
		let member = makeMember(name: "moonlightLatte")
		#expect(member.name == "moonlightLatte")
		#expect(member.title == "Moonlight Latte")
	}

	@Test func `preserves acronyms`() {
		let member = makeMember(name: "URLSessionLogger")
		#expect(member.title == "URL Session Logger")
	}

	@Test func `handles separators and numbers`() {
		let member = makeMember(name: "iced_latteV2")
		#expect(member.name == "iced_latteV2")
		#expect(member.title == "Iced Latte V2")
	}

	@Test func `acronyms and separators`() {
		let member = makeMember(name: "httpURLParser")
		#expect(member.title == "Http URL Parser")
	}

	@Test func `mixed separators`() {
		let member = makeMember(name: "iced_latteV2-pro")
		#expect(member.title == "Iced Latte V2 Pro")
	}

	@Test func `lowercase and uppercase words`() {
		#expect(makeMember(name: "sunrise").title == "Sunrise")
		#expect(makeMember(name: "API").title == "API")
	}

	@Test func `unicode letters`() {
		let member = makeMember(name: "mañanaBlend")
		#expect(member.title == "Mañana Blend")
	}

	@Test func `empty string`() {
		let member = makeMember(name: "")
		#expect(member.title == "")
	}
}
