// swift-tools-version: 5.8

// WARNING:
// This file is automatically generated.
// Do not edit it by hand because the contents will be replaced.

import PackageDescription
import AppleProductTypes

let package = Package(
    name: "Route of Data",
    platforms: [
        .iOS("16.0")
    ],
    products: [
        .iOSApplication(
            name: "Route of Data",
            targets: ["AppModule"],
            bundleIdentifier: "Canglong.HelmOfData",
            teamIdentifier: "45Z6V4YD5U",
            displayVersion: "1.0",
            bundleVersion: "1",
            appIcon: .placeholder(icon: .barChart),
            accentColor: .presetColor(.orange),
            supportedDeviceFamilies: [
                .pad,
                .phone
            ],
            supportedInterfaceOrientations: [
                .portrait,
                .landscapeRight,
                .landscapeLeft,
                .portraitUpsideDown(.when(deviceFamilies: [.pad]))
            ],
            capabilities: [
                .fileAccess(.userSelectedFiles, mode: .readWrite)
            ],
            appCategory: .utilities
        )
    ],
    targets: [
        .executableTarget(
            name: "AppModule",
            path: ".",
            resources: [
                .process("Resources")
            ]
        )
    ]
)