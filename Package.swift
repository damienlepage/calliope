// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Calliope",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "Calliope",
            targets: ["Calliope"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "Calliope",
            dependencies: [],
            path: "Sources"
        ),
        .testTarget(
            name: "CalliopeTests",
            dependencies: ["Calliope"],
            path: "Tests",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
