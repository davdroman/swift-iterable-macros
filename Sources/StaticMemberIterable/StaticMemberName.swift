import Foundation

public struct StaticMemberName: RawRepresentable, Hashable, Sendable, Codable, ExpressibleByStringLiteral, CustomStringConvertible {
	public let rawValue: String

	public init(rawValue: String) {
		self.rawValue = rawValue
	}

	public init(stringLiteral value: StringLiteralType) {
		self.init(rawValue: value)
	}

	public var description: String { rawValue }

	/// Human-friendly representation of the identifier. Converts `camelCase`, `PascalCase`, `snake_case`, and `UPPERCase`
	/// styles into words separated by spaces (e.g. `icedLatte` -> `"Iced Latte"`).
	public var title: String {
		let words = rawValue.memberIdentifierWords()
		guard !words.isEmpty else { return rawValue }
		return words
			.map { word in
				// Preserve fully-uppercase words (acronyms) while sentence-casing the rest.
				if word == word.uppercased() {
					return word
				}

				guard let first = word.first else { return word }
				let remainder = word.dropFirst().lowercased()
				return String(first).uppercased() + remainder
			}
			.joined(separator: " ")
	}
}

extension String {
	fileprivate func memberIdentifierWords() -> [String] {
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
				if shouldInsertBreak(
					before: character,
					previous: previous,
					next: next
				) {
					flush()
				}
			}

			current.append(character)
		}

		flush()

		return words
	}

	private func shouldInsertBreak(
		before character: Character,
		previous: Character,
		next: Character?
	) -> Bool {
		switch true {
		case previous.isLowercaseLetter && character.isUppercaseLetter:
			true
		case previous.isLowercaseLetter && character.isNumber:
			true
		case previous.isNumber && character.isLetter:
			true
		case previous.isUppercaseLetter && character.isUppercaseLetter && (next?.isLowercaseLetter ?? false):
			// Handle transitions like "URLSession" -> "URL Session"
			true
		default:
			false
		}
	}
}

extension Character {
	fileprivate var isLetter: Bool {
		unicodeScalars.allSatisfy(CharacterSet.letters.contains)
	}

	fileprivate var isUppercaseLetter: Bool {
		unicodeScalars.allSatisfy(CharacterSet.uppercaseLetters.contains)
	}

	fileprivate var isLowercaseLetter: Bool {
		unicodeScalars.allSatisfy(CharacterSet.lowercaseLetters.contains)
	}

	fileprivate var isNumber: Bool {
		unicodeScalars.allSatisfy(CharacterSet.decimalDigits.contains)
	}

	fileprivate var isWordSeparator: Bool {
		self == "_" || self == "-" || self == " "
	}
}
