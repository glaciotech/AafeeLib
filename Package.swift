// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AafeeLib",
    platforms: [
        .macOS("13.3")
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "AafeeLib",
            targets: ["AafeeLib"]),
        .executable(
            name: "AafeeDemo",
            targets: ["AafeeDemo"])
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
//        .package(url: "https://github.com/ptliddle/swifty-prompts.git", branch: "main"),
        .package(path: "../../Libraries/SwiftyPrompts"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.3"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.5.3"),
//        .package(url: "https://github.com/ptliddle/swifty-json-schema.git", branch: "main"), // Adjust URL and version as needed
        .package(path: "../../Libraries/SwiftyFirecrawl"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "AafeeLib",
            dependencies: [
                .product(name: "Logging", package: "swift-log"),
                .product(name: "SwiftyPrompts", package: "SwiftyPrompts"),
                .product(name: "SwiftyPrompts.OpenAI", package: "SwiftyPrompts"),
                .product(name: "SwiftyPrompts.Tools", package: "SwiftyPrompts"),
//                .product(name: "SwiftyJsonSchema", package: "swifty-json-schema"),
                .product(name: "SwiftFirecrawl", package: "SwiftyFirecrawl")
            ]),
        .executableTarget(
            name: "AafeeDemo",
            dependencies: [
                "AafeeLib",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Logging", package: "swift-log")
            ]),
        .testTarget(
            name: "AafeeLibTests",
            dependencies: ["AafeeLib"])
    ]
)
