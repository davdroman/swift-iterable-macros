// swift-tools-version: 6.1

import CompilerPluginSupport
import PackageDescription

let package = Package(
	name: "StaticMemberIterable",
	platforms: [
		.iOS(.v13),
		.macOS(.v10_15),
		.tvOS(.v13),
		.visionOS(.v1),
		.watchOS(.v6),
	],
	products: [
		.library(name: "StaticMemberIterable", targets: ["StaticMemberIterable"]),
	],
	targets: [
		.target(name: "StaticMemberIterable", dependencies: ["StaticMemberIterableMacro"]),

		.macro(
			name: "StaticMemberIterableMacro",
			dependencies: [
				.product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
				.product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
			]
		),

		.testTarget(
			name: "StaticMemberIterableTests",
			dependencies: [
				"StaticMemberIterable",
				"StaticMemberIterableMacro",
				.product(name: "MacroTesting", package: "swift-macro-testing"),
				// For some reason, with Swift Syntax prebuilts enabled, we need to depend on SwiftCompilerPlugin here to work around error:
				// Compilation search paths unable to resolve module dependency: 'SwiftCompilerPlugin'
				.product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
			]
		),
	]
)

package.dependencies += [
	.package(url: "https://github.com/pointfreeco/swift-macro-testing", from: "0.6.0"),
	.package(url: "https://github.com/swiftlang/swift-syntax", "600.0.0"..<"603.0.0"),
]

for target in package.targets {
	target.swiftSettings = target.swiftSettings ?? []
	target.swiftSettings? += [
		.enableUpcomingFeature("ExistentialAny"),
		.enableUpcomingFeature("InternalImportsByDefault"),
	]
}
