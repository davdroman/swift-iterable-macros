public protocol StaticMemberIterable {
	associatedtype StaticMemberValue
}

@attached(
	member,
	names: named(StaticMemberValue), named(allStaticMembers)
)
@attached(
	extension,
	conformances: StaticMemberIterable
)
public macro StaticMemberIterable(
	_ access: StaticMemberIterableAccess? = nil,
	ofType memberType: Any.Type? = nil,
) = #externalMacro(
	module: "StaticMemberIterableMacro",
	type: "StaticMemberIterableMacro",
)

public enum StaticMemberIterableAccess {
	case `public`
	case `internal`
	case `package`
	case `fileprivate`
	case `private`
}
