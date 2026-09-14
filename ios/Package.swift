// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "appsonair_flutter_push_notification",
    platforms: [
        .iOS("15.0")
    ],
    products: [
        .library(name: "appsonair-flutter-push-notification", targets: ["appsonair_flutter_push_notification"])
    ],
    dependencies: [
        .package(
            url: "https://github.com/apps-on-air/appsonair-ios-push-notification.git",
            exact: "0.0.2-alpha"
        )
    ],
    targets: [
        .target(
            name: "appsonair_flutter_push_notification",
            dependencies: [
                .product(name: "AppsOnAir-AppPush", package: "appsonair-ios-push-notification")
            ],
            path: "appsonair_flutter_push_notification/Sources/appsonair_flutter_push_notification",
            resources: [
                // .process("PrivacyInfo.xcprivacy"),
            ]
        )
    ]
)
