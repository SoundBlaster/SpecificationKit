// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SpecificationKitDemo",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
    ],
    products: [
        .executable(
            name: "SpecificationKitDemo",
            targets: ["SpecificationKitDemo"]
        )
    ],
    dependencies: [
        .package(name: "SpecificationKit", path: "../")
    ],
    targets: [
        .executableTarget(
            name: "SpecificationKitDemo",
            dependencies: [
                .product(name: "SpecificationKit", package: "SpecificationKit")
            ],
            path: "Sources"
        )
    ]
)
