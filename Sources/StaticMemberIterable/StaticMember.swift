import Foundation

public typealias StaticMemberOf<Container: StaticMemberIterable> = StaticMember<Container, Container.StaticMemberValue>

@propertyWrapper
public struct StaticMember<Container, Value>: Identifiable {
	public typealias ID = KeyPath<Container.Type, Value>

	public let keyPath: KeyPath<Container.Type, Value>
	public let name: String

	private let storage: Value

	public var wrappedValue: Value { storage }
	public var projectedValue: StaticMember<Container, Value> { self }
	public var value: Value { storage }
	public var title: String { name.memberIdentifierTitle() }
	public var id: ID { keyPath }

	public init(keyPath: KeyPath<Container.Type, Value>, name: String, value: Value) {
		self.keyPath = keyPath
		self.name = name
		self.storage = value
	}

	public init(projectedValue: StaticMember<Container, Value>) {
		self.init(keyPath: projectedValue.keyPath, name: projectedValue.name, value: projectedValue.value)
	}

	public static func ~= (
		keyPath: ID,
		staticMember: StaticMember<Container, Value>
	) -> Bool {
		staticMember.keyPath == keyPath
	}
}

extension StaticMember: @unchecked Sendable where Value: Sendable {}

private extension String {
	func memberIdentifierTitle() -> String {
		let words = memberIdentifierWords()
		guard !words.isEmpty else { return self }
		return words
			.map { word in
				if word == word.uppercased() {
					return word
				}

				guard let first = word.first else { return word }
				let remainder = word.dropFirst().lowercased()
				return String(first).uppercased() + remainder
			}
			.joined(separator: " ")
	}

	func memberIdentifierWords() -> [String] {
		guard !isEmpty else { return [] }

		var words: [String] = []
		var current = ""
		let characters = Array(self)

		func flush() {
			if !current.isEmpty {
				words.append(current)
				current.removeAll(keepingCapacity: true)
			}
		}

		for index in characters.indices {
			let character = characters[index]

			if character.isWordSeparator {
				flush()
				continue
			}

			if index > 0 {
				let previous = characters[index - 1]
				let next = index + 1 < characters.count ? characters[index + 1] : nil
				if character.shouldInsertBreak(before: previous, next: next) {
					flush()
				}
			}

			current.append(character)
		}

		flush()

		return words
	}
}

private extension Character {
	var isLetter: Bool {
		unicodeScalars.allSatisfy(CharacterSet.letters.contains)
	}

	var isUppercaseLetter: Bool {
		unicodeScalars.allSatisfy(CharacterSet.uppercaseLetters.contains)
	}

	var isLowercaseLetter: Bool {
		unicodeScalars.allSatisfy(CharacterSet.lowercaseLetters.contains)
	}

	var isNumber: Bool {
		unicodeScalars.allSatisfy(CharacterSet.decimalDigits.contains)
	}

	var isWordSeparator: Bool {
		self == "_" || self == "-" || self == " "
	}

	func shouldInsertBreak(before previous: Character, next: Character?) -> Bool {
		switch true {
		case previous.isLowercaseLetter && isUppercaseLetter:
			true
		case previous.isLowercaseLetter && isNumber:
			true
		case previous.isNumber && isLetter:
			true
		case previous.isUppercaseLetter && isUppercaseLetter && (next?.isLowercaseLetter ?? false):
			true
		default:
			false
		}
	}
}
