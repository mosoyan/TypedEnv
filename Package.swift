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
    ],

    targets: [
        // Core
        .target(
            name: "TypedEnv",
            dependencies: []
        ),
        .testTarget(
            name: "TypedEnvTests",
            dependencies: ["TypedEnv"]
        ),
    ]
)
