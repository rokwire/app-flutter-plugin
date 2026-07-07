// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "rokwire_plugin",
    platforms: [
        .iOS("12.0"),
    ],
    products: [
        .library(name: "rokwire-plugin", targets: ["rokwire_plugin"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "rokwire_plugin",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ],
            resources: [
            ],
            cSettings: [
                // TODO: Update your plugin name.
                .headerSearchPath("include/rokwire_plugin")
            ]
        )
    ]
)
