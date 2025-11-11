import IterableSupport

@propertyWrapper
public struct CaseOf<Enum> {
	public let name: String

	private let storage: Enum

	public var wrappedValue: Enum { storage }
	public var projectedValue: CaseOf<Enum> { self }
	public var value: Enum { storage }
	public var title: String { name.memberIdentifierTitle() }

	public init(name: String, value: Enum) {
		self.name = name
		self.storage = value
	}

	public init(projectedValue: CaseOf<Enum>) {
		self.init(name: projectedValue.name, value: projectedValue.value)
	}
}

extension CaseOf: Identifiable {
	public var id: String { name }
}

extension CaseOf: @unchecked Sendable where Enum: Sendable {}
