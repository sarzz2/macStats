// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MacStats",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "MacStats",
            targets: ["MacStats"]),
    ],
    targets: [
        .executableTarget(
            name: "MacStats",
            dependencies: []),
        .testTarget(
            name: "MacStatsTests",
            dependencies: ["MacStats"]),
    ]
)
