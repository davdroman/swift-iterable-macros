@attached(
	member,
	names: named(allCases), named(subscript(dynamicMember:))
)
public macro CaseIterable(
	_ access: CaseIterableAccess? = nil,
) = #externalMacro(
	module: "CaseIterableMacro",
	type: "CaseIterableMacro",
)

public enum CaseIterableAccess {
	case `public`
	case `internal`
	case `package`
	case `fileprivate`
	case `private`
}
