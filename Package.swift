// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "KeychainKit",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
        .tvOS(.v16),
        .watchOS(.v9),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "KeychainKit",
            targets: ["KeychainKit"]
        ),
    ],
    targets: [
        .target(
            name: "KeychainKit",
            path: "Sources/KeychainKit",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "KeychainKitTests",
            dependencies: ["KeychainKit"],
            path: "Tests/KeychainKitTests"
        ),
    ],
    swiftLanguageVersions: [.v5]
)
