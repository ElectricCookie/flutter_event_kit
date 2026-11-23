// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "flutter_event_kit",
    platforms: [
        .iOS("13.0"),
    ],
    products: [
        .library(name: "flutter-event-kit", targets: ["flutter_event_kit"]),
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework"),
    ],
    targets: [
        .target(
            name: "flutter_event_kit",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework"),
            ],
            resources: [
                .process("PrivacyInfo.xcprivacy"),
            ],
            linkerSettings: [
                .linkedFramework("EventKit"),
                .linkedFramework("EventKitUI"),
                .linkedFramework("CoreLocation"),
            ],
        ),
    ],
)
