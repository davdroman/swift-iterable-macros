@propertyWrapper
public struct StaticMember<Container, Value>: Identifiable {
	public typealias ID = KeyPath<Container.Type, Value>

	public let keyPath: KeyPath<Container.Type, Value>
	public let name: StaticMemberName

	private let storage: Value

	public var wrappedValue: Value { storage }
	public var projectedValue: StaticMember { self }
	public var value: Value { storage }
	public var id: ID { keyPath }

	public init(keyPath: KeyPath<Container.Type, Value>, name: StaticMemberName, value: Value) {
		self.keyPath = keyPath
		self.name = name
		self.storage = value
	}

	public init(projectedValue: Self) {
		self.init(keyPath: projectedValue.keyPath, name: projectedValue.name, value: projectedValue.value)
	}
}

extension StaticMember: @unchecked Sendable where Value: Sendable {}
