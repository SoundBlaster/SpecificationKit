// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "SpecificationKit",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .tvOS(.v13),
        .watchOS(.v6),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        // A library product should only contain library targets. Test targets should not be included.
        .library(
            name: "SpecificationKit",
            targets: ["SpecificationKit"]
        ),
    ],
    dependencies: [
        // Depend on the latest Swift Syntax package for macro support.
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "510.0.0"),
        // Add swift-macro-testing for a simplified macro testing experience.
        .package(url: "https://github.com/pointfreeco/swift-macro-testing", from: "0.4.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        
        // This is the macro implementation target. It can import SwiftSyntax.
        .macro(
            name: "SpecificationKitMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ]
        ),
        
        // This is your main library target.
        // It depends on the macro target to use the macros.
        .target(
            name: "SpecificationKit",
            dependencies: ["SpecificationKitMacros"]
        ),
        
        // This is your test target.
        // We've streamlined the dependencies for a cleaner testing setup.
        .testTarget(
            name: "SpecificationKitTests",
            dependencies: [
                "SpecificationKit",
                // This product provides a convenient API for testing macro expansion.
                .product(name: "MacroTesting", package: "swift-macro-testing"),
                // Access macro types for MacroTesting
                "SpecificationKitMacros",
                // Apple macro test support for diagnostics and expansions
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ]
        ),
    ]
)
