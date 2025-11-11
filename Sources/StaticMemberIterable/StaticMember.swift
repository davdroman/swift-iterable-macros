import Foundation
import IterableSupport

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
