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
import SwiftUI

@StaticMemberIterable
enum ColorPalette {
    static let sunrise: Color = Color(red: 1.00, green: 0.58, blue: 0.22)
    static let moonlight: Color = Color(red: 0.30, green: 0.32, blue: 0.60)
    static let stardust: Color = Color(red: 0.68, green: 0.51, blue: 0.78)
}

ColorPalette.allStaticMembers.map(\.value)   // [.orange, .indigo, .purple] as [Color]
ColorPalette.allStaticMembers.map(\.title)   // ["Sunrise", "Moonlight", "Stardust"]
ColorPalette.allStaticMembers.map(\.keyPath) // [\ColorPalette.sunrise, ...] as [KeyPath<ColorPalette.Type, Color>]
```

The macro works the same for enums and classes (actors are intentionally unsupported so far).

Each synthesized entry is a `StaticMember<Container, Value>`: an `Identifiable` property wrapper that stores the friendly name, the `KeyPath` to the static property, and the concrete value. This makes it trivial to drive UI:

```swift
ForEach(ColorPalette.allStaticMembers) { $color in
    RoundedRectangle(cornerRadius: 12)
        .fill(color)
        .overlay(Text($color.title))
        .tag($color.id)
}
```

`StaticMember` exposes four pieces of data:

- `name: String` – keeps the original identifier for the member.
- `title: String` – human-friendly representation derived from the identifier.
- `keyPath: KeyPath<Container.Type, Value>` – points back to the static property inside the declaring type.
- `value`/`wrappedValue: Value` – the actual static instance.

Because it is a property wrapper, you can also project (`$member`) when you use it on your own properties, and `Identifiable` conformance makes it slot neatly into `ForEach`.

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
