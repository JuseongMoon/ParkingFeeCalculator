// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ParkingPackages",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "ParkingFeeCore",
            targets: ["ParkingFeeCore"]),
        .library(
            name: "ParkingShared",
            targets: ["ParkingShared"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "ParkingFeeCore",
            dependencies: [],
            path: "Sources/ParkingFeeCore"),
        .target(
            name: "ParkingShared",
            dependencies: [],
            path: "Sources/ParkingShared"),
        .testTarget(
            name: "ParkingFeeCoreTests",
            dependencies: ["ParkingFeeCore"]),
    ]
)