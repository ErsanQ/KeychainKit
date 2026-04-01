// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "KeychainKit",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v14),
        .macOS(.v11),
        .tvOS(.v14),
        .watchOS(.v7),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "KeychainKit",
            targets: ["KeychainKit"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "KeychainKit",
            dependencies: [],
            path: "Sources/KeychainKit"),
        .testTarget(
            name: "KeychainKitTests",
            dependencies: ["KeychainKit"]),
    ]
)
