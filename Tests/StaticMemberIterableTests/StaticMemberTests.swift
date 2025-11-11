import StaticMemberIterable
import Testing

@Suite
struct StaticMemberPatternMatchingTests {
	private struct Fixture {
		static let alpha = Fixture()
		static let beta = Fixture()
	}

	private let alphaMember = StaticMember(
		keyPath: \Fixture.Type.alpha,
		name: "alpha",
		value: Fixture.alpha,
	)

	private let betaMember = StaticMember(
		keyPath: \Fixture.Type.beta,
		name: "beta",
		value: Fixture.beta,
	)

	@Test func keyPathPatternMatchesMember() {
		let members = [alphaMember, betaMember]
		var matched: [KeyPath<Fixture.Type, Fixture>] = []

		for member in members {
			switch member {
			case \Fixture.Type.alpha:
				matched.append(\Fixture.Type.alpha)
			case \Fixture.Type.beta:
				matched.append(\Fixture.Type.beta)
			default:
				break
			}
		}

		#expect(matched == [\Fixture.Type.alpha, \Fixture.Type.beta])
	}
}
