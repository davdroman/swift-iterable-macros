import Foundation

extension String {
	package func memberIdentifierTitle() -> String {
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

	package func memberIdentifierWords() -> [String] {
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

extension Character {
	package var isLetter: Bool {
		unicodeScalars.allSatisfy(CharacterSet.letters.contains)
	}

	package var isUppercaseLetter: Bool {
		unicodeScalars.allSatisfy(CharacterSet.uppercaseLetters.contains)
	}

	package var isLowercaseLetter: Bool {
		unicodeScalars.allSatisfy(CharacterSet.lowercaseLetters.contains)
	}

	package var isNumber: Bool {
		unicodeScalars.allSatisfy(CharacterSet.decimalDigits.contains)
	}

	package var isWordSeparator: Bool {
		self == "_" || self == "-" || self == " "
	}

	package func shouldInsertBreak(before previous: Character, next: Character?) -> Bool {
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
