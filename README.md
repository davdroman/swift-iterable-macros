# IterableMacros

[![CI](https://github.com/davdroman/IterableMacros/actions/workflows/ci.yml/badge.svg)](https://github.com/davdroman/IterableMacros/actions/workflows/ci.yml)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fdavdroman%2FIterableMacros%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/davdroman/IterableMacros)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fdavdroman%2FIterableMacros%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/davdroman/IterableMacros)

IterableMacros hosts Swift macros that generate iterable collections for your types:

- `@StaticMemberIterable` synthesizes collections describing every `static let` defined in a struct, enum, class, or extension.
- `@CaseIterable` mirrors Swift’s `CaseIterable` but keeps a case’s name, value, and presentation metadata.

This is handy for building fixtures, demo data, menus, or anywhere you want a single source of truth for a handful of well-known static members.

## Installation

Add the dependency and product to your `Package.swift`:

```swift
.package(url: "https://github.com/davdroman/IterableMacros", from: "0.3.0"),
```

```swift
.product(name: "IterableMacros", package: "IterableMacros"),
```

`IterableMacros` re-exports both modules. If you only need one macro, depend on it explicitly instead:

```swift
.product(name: "StaticMemberIterable", package: "IterableMacros"),
.product(name: "CaseIterable", package: "IterableMacros"),
```

## Static members (`@StaticMemberIterable`)

```swift
import StaticMemberIterable
import SwiftUI

@StaticMemberIterable
enum ColorPalette {
    static let sunrise: Color = Color(red: 1.00, green: 0.58, blue: 0.22)
    static let moonlight: Color = Color(red: 0.30, green: 0.32, blue: 0.60)
    static let stardust: Color = Color(red: 0.68, green: 0.51, blue: 0.78)
}

ColorPalette.allStaticMembers.map(\.value)   // [Color(red: 1.00, ...), ...]
ColorPalette.allStaticMembers.map(\.title)   // ["Sunrise", "Moonlight", "Stardust"]
ColorPalette.allStaticMembers.map(\.keyPath) // [\ColorPalette.sunrise, ...] as [KeyPath<ColorPalette.Type, Color>]
```

The macro works the same for enums and classes (actors are intentionally unsupported so far).

Each synthesized entry is a `StaticMember<Container, Value>`: an `Identifiable` property wrapper that stores the friendly name, the `KeyPath` to the static property, and the concrete value. This makes it trivial to drive UI:

```swift
ForEach(ColorPalette.allStaticMembers) { $color in
    Text($color.title)
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 8).fill(color)
        }
}
```

`StaticMember` exposes four pieces of data:

- `name: String` – keeps the original identifier for the member.
- `title: String` – human-friendly representation derived from the identifier.
- `keyPath: KeyPath<Container.Type, Value>` – points back to the static property inside the declaring type.
- `value`/`wrappedValue: Value` – the actual static instance.

Because it is a property wrapper, you can also project (`$member`) when you use it on your own properties, and `Identifiable` conformance makes it slot neatly into `ForEach`.

## Enum cases (`@CaseIterable`)

```swift
import CaseIterable
import SwiftUI

@CaseIterable
@dynamicMemberLookup
enum CoffeeMenu {
    case espresso
    case cortado
    case flatWhite

    struct Properties {
        let emoji: String
        let price: Double
    }

    var properties: Properties {
        switch self {
        case .espresso:
            Properties(emoji: "☕️", price: 2.50)
        case .cortado:
            Properties(emoji: "🥛", price: 3.20)
        case .flatWhite:
            Properties(emoji: "🌿", price: 3.80)
        }
    }
}

List {
    ForEach(CoffeeMenu.allCases) { $coffee in
        HStack {
            Text("\(coffee.emoji) \($coffee.title)")
            Spacer()
            Text(coffee.price, format: .currency(code: "USD"))
        }
        .tag($coffee.id)
    }
}
```

`@CaseIterable` produces an explicit `allCases: [CaseOf<Enum>]`. Each entry remains a property wrapper (`CaseOf`) so you keep the friendly title, stable `id`, and the underlying case value for driving pickers or lists. When you combine the macro with `@dynamicMemberLookup` plus a nested `struct Properties`, the generated dynamic-member subscript forwards through `properties`, letting you ask every case for details such as `emoji` and `price` above.

### Access control

Need public-facing lists? Pass the desired access modifier:

```swift
@StaticMemberIterable(.public)
struct Coffee { ... }

@CaseIterable(.public)
enum MenuSection { ... }
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
