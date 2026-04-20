// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "flusbserial",
    platforms: [
        .macOS("10.15")
    ],
    products: [
        .library(name: "flusbserial", targets: ["flusbserial"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "flusbserial",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ],
            path: "Sources/flusbserial"
        )
    ]
)
