// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TypedEnv",

    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],

    products: [
        .library(name: "TypedEnv", targets: ["TypedEnv"]),
        .library(name: "TypedEnvNIO", targets: ["TypedEnvNIO"]),
        .library(name: "TypedEnvRouting", targets: ["TypedEnvRouting"])
    ],

    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.0.0"),
        .package(url: "https://github.com/vapor/routing-kit.git", from: "4.0.0")
    ],

    targets: [
        // Core
        .target(
            name: "TypedEnv",
            dependencies: []
        ),

        // NIO extension
        .target(
            name: "TypedEnvNIO",
            dependencies: [
                "TypedEnv",
                .product(name: "NIOCore", package: "swift-nio")
            ]
        ),

        // RoutingKit extension
        .target(
            name: "TypedEnvRouting",
            dependencies: [
                "TypedEnv",
                .product(name: "RoutingKit", package: "routing-kit")
            ]
        ),

        .testTarget(
            name: "TypedEnvTests",
            dependencies: ["TypedEnv"]
        ),
    ]
)
