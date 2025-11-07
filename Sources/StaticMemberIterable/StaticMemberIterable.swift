@attached(
	member,
	names: named(allStaticMembers), named(allStaticMemberNames), named(allNamedStaticMembers)
)
public macro StaticMemberIterable(
	_ access: StaticMemberIterableAccess? = nil,
	ofType memberType: Any.Type? = nil
) = #externalMacro(
	module: "StaticMemberIterableMacro",
	type: "StaticMemberIterableMacro"
)

public enum StaticMemberIterableAccess {
	case `public`
	case `internal`
	case `package`
	case `fileprivate`
	case `private`
}
