# StaticMemberIterable

StaticMemberIterable is a Swift macro that synthesizes collections describing every `static let` defined in a struct, enum, or class.

This is handy for building fixtures, demo data, menus, or anywhere you want a single source of truth for a handful of well-known static members.

## Installation

Add the dependency and product to your `Package.swift`:

```swift
.package(url: "https://github.com/davdroman/StaticMemberIterable", from: "0.1.0"),
```

```swift
.product(name: "StaticMemberIterable", package: "StaticMemberIterable"),
```

## Usage

```swift
import StaticMemberIterable

@StaticMemberIterable
struct Coffee {
    let name: String
    let roastLevel: Int

    static let sunrise = Coffee(name: "sunrise", roastLevel: 2)
    static let moonlight = Coffee(name: "moonlight", roastLevel: 3)
    static let stardust = Coffee(name: "stardust", roastLevel: 4)
}

Coffee.allStaticMembers       // [sunrise, moonlight, stardust]
Coffee.allStaticMemberNames   // ["sunrise", "moonlight", "stardust"] as [StaticMemberName]
Coffee.allNamedStaticMembers  // [(name: "sunrise", value: sunrise), ...] as [(name: StaticMemberName, value: Coffee)]

Coffee.allStaticMemberNames.map(\.title) // ["Sunrise", "Moonlight", "Stardust"]
```

The macro works the same for enums and classes (actors are intentionally unsupported so far).

### Access control

Need public-facing lists? Pass the desired access modifier:

```swift
@StaticMemberIterable(.public)
struct Coffee { ... }
```

Supported modifiers:

- `.public`
- `.internal` (or omit the argument)
- `.package`
- `.fileprivate`
- `.private`

### Overriding the member type

If your namespace stores values of a different type (e.g. an enum that only vends `Beverage` instances), supply `ofType:`:

```swift
@StaticMemberIterable(ofType: Beverage.self)
enum BeverageFixtures {
    static let sparkling = Beverage(name: "Sparkling")
    static let still = Beverage(name: "Still")
}
```
