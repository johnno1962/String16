// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "String16",
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "String16",
            targets: ["String16"]),
    ],
    dependencies: [
        .package(url: "https://github.com/johnno1962/StringIndex",
                 .upToNextMinor(from: "2.2.3")),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "String16",
            dependencies: ["StringIndex"]),
        .testTarget(
            name: "String16Tests",
            dependencies: ["String16", "StringIndex"]
        ),
    ],
    swiftLanguageVersions: [.v5]
)
