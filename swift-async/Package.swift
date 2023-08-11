// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "EasyRacer",
    platforms: [
        .macOS(.v10_15)
    ],
    dependencies: [
        .package(url: "file:///Users/jleow/Development/3rdParty/BigInt", branch: "unsafe-array-access"),
        .package(url: "https://github.com/alexsteinerde/docker-client-swift.git", from: "0.1.2"),
    ],
    targets: [
        .executableTarget(
            name: "EasyRacer",
            dependencies: []),
        .executableTarget(
            name: "Fibonacci",
            dependencies: [
                .product(name: "BigInt", package: "BigInt")
            ]),
        .testTarget(
            name: "EasyRacerTests",
            dependencies: [
                "EasyRacer",
                .product(name: "DockerClientSwift", package: "docker-client-swift")
            ]),
    ]
)
