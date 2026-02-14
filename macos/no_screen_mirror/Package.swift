// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "no_screen_mirror",
    platforms: [
        .macOS("10.14")
    ],
    products: [
        .library(name: "no-screen-mirror", targets: ["no_screen_mirror"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "no_screen_mirror",
            dependencies: [],
            resources: [
                .process("PrivacyInfo.xcprivacy"),
            ]
        )
    ]
)
