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
        // Clean Architecture Products - 계층별 분리
        .library(
            name: "ParkingDomain",
            targets: ["ParkingDomain"]),
        .library(
            name: "ParkingData",
            targets: ["ParkingData"]),
        .library(
            name: "ParkingUI",
            targets: ["ParkingUI"]),
        .library(
            name: "ParkingShared",
            targets: ["ParkingShared"]),

        // Legacy Support - 점진적 마이그레이션을 위한 호환성 제공
        .library(
            name: "ParkingFeeCore",
            targets: ["ParkingDomain", "ParkingData", "ParkingUI"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
    ],
    targets: [
        // MARK: - Domain Layer (가장 안쪽 레이어 - 다른 것에 의존하지 않음)
        .target(
            name: "ParkingDomain",
            dependencies: [],
            path: "Sources/ParkingDomain"),

        // MARK: - Data Layer (Domain과 Shared에 의존)
        .target(
            name: "ParkingData",
            dependencies: ["ParkingDomain", "ParkingShared"],
            path: "Sources/ParkingData"),

        // MARK: - UI Layer (Domain, Data, Shared에 의존)
        .target(
            name: "ParkingUI",
            dependencies: ["ParkingDomain", "ParkingData", "ParkingShared"],
            path: "Sources/ParkingUI"),

        // MARK: - Shared Layer (공통 유틸리티)
        .target(
            name: "ParkingShared",
            dependencies: [],
            path: "Sources/ParkingShared"),

        // MARK: - Tests
        .testTarget(
            name: "ParkingDomainTests",
            dependencies: ["ParkingDomain"]),
        .testTarget(
            name: "ParkingDataTests",
            dependencies: ["ParkingData", "ParkingDomain"]),
        .testTarget(
            name: "ParkingUITests",
            dependencies: ["ParkingUI", "ParkingDomain"]),
    ]
)