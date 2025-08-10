// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftSqlcPractice",
    platforms: [.macOS(.v15)],
    dependencies: [
        .package(url: "https://github.com/vapor/sqlite-kit.git", from: "4.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "SwiftSqlcPractice",
            dependencies: [
                .product(name: "SQLiteKit", package: "sqlite-kit"),
            ],
            resources: [.process("chinook.db")],
        ),
    ]
)
