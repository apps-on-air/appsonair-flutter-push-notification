// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.
// Deliberately kept at 5.9 (Swift 5 language mode) rather than matching the native
// SDK's 6.2 — Swift 6's strict concurrency mode flags this plugin's @MainActor class
// conforming to Flutter's (non-isolated) FlutterPlugin/FlutterStreamHandler protocols
// as a hard error. Each package in the dependency graph builds under its own
// language mode, so this doesn't affect the native SDK's own build.

import PackageDescription

let package = Package(
    name: "appsonair_flutter_push_notification",
    platforms: [
        // Matches the native AppsOnAir-iOS-Push SDK's floor.
        .iOS("15.0")
    ],
    products: [
        .library(name: "appsonair-flutter-push-notification", targets: ["appsonair_flutter_push_notification"])
    ],
    dependencies: [
        // Published native SDK, pinned to the current alpha tag.
        .package(
            url: "git@git.logicwind.co:logicwind/appsonair/appsonair-push-notification-ios.git",
            exact: "0.0.1-alpha"
        )
    ],
    targets: [
        .target(
            name: "appsonair_flutter_push_notification",
            dependencies: [
                // SPM's package identity is the repository name
                // (appsonair-push-notification-ios), not the `name:` declared inside
                // that package's own Package.swift ("AppsOnAir-iOS-Push").
                .product(name: "AppsOnAirPush", package: "appsonair-push-notification-ios")
            ],
            resources: [
                // If your plugin requires a privacy manifest, for example if it uses any required
                // reason APIs, update the PrivacyInfo.xcprivacy file to describe your plugin's
                // privacy impact, and then uncomment these lines. For more information, see
                // https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
                // .process("PrivacyInfo.xcprivacy"),

                // If you have other resources that need to be bundled with your plugin, refer to
                // the following instructions to add them:
                // https://developer.apple.com/documentation/xcode/bundling-resources-with-a-swift-package
            ]
        )
    ]
)
