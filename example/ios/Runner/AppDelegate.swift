import AppsOnAir_AppPush
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
        // The plugin registers itself as UNUserNotificationCenter delegate here,
        // capturing kill-mode taps before Dart's AppPushService.initialize() runs.
        GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    }

    // Gives the SDK the APNs device token as soon as iOS provides it.
    override func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        AppPushService.handleAPNsToken(deviceToken)
        super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
    }

    // Lets the SDK handle APNs registration errors.
    override func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        AppPushService.handleAPNsRegistrationError(error)
        super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
    }
}
