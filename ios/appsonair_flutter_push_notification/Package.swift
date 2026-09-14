
import PackageDescription

let package = Package(
    name: "appsonair_flutter_push_notification",
    platforms: [
        // Matches the native AppPushService (AppsOnAir-AppPush) SDK's floor.
        .iOS("15.0")
    ],
    products: [
        .library(name: "appsonair-flutter-push-notification", targets: ["appsonair_flutter_push_notification"])
    ],
    dependencies: [
        // Published native SDK, on GitHub now (was a private git.logicwind.co host
        // before 0.0.2-alpha), pinned to the current alpha tag.
        .package(
            url: "https://github.com/apps-on-air/appsonair-ios-push-notification.git",
            exact: "0.0.2-alpha"
        )
    ],
    targets: [
        .target(
            name: "appsonair_flutter_push_notification",
            dependencies: [
                // SPM's package identity is the repository name
                // (appsonair-ios-push-notification), and the product it vends is
                // "AppsOnAir-AppPush". SPM/Swift sanitizes the hyphen to an
                // underscore for the actual import — `import AppsOnAir_AppPush`.
                .product(name: "AppsOnAir-AppPush", package: "appsonair-ios-push-notification")
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
