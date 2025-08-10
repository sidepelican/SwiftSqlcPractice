// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftSqlcPractice",
    platforms: [.macOS(.v15)],
    dependencies: [
        .package(url: "https://github.com/vapor/sqlite-nio.git", from: "1.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "SwiftSqlcPractice",
            dependencies: [
                .product(name: "SQLiteNIO", package: "sqlite-nio"),
            ],
            resources: [.process("chinook.db")],
        ),
    ]
)
