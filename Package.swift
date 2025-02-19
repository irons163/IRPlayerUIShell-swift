// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "IRPlayerUIShell",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "IRPlayerUIShell",
            targets: ["IRPlayerUIShell"]),
    ],
    dependencies: [
//        .package(url: "https://github.com/irons163/IRPlayer-swift", from: "0.1.0"),
        .package(path: "/Users/irons/IRPlayer-swift")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "IRPlayerUIShell",
            dependencies: [.product(name: "IRPlayer", package: "IRPlayer-swift")]),
        .testTarget(
            name: "IRPlayerUIShellTests",
            dependencies: ["IRPlayerUIShell"]
        ),
    ]
)
