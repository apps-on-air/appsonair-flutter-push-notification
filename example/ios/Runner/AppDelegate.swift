import AppsOnAir_AppPush
import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Initialize the SDK here — before Flutter starts — so kill-mode notification
        // taps are captured before Dart's async initialize() runs.
        // swizzle: false is required for Flutter apps (Flutter intercepts AppDelegate methods).
        AppPushService.initialize(swizzle: false)
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
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

    // Handles notification taps — including when the app is launched from a killed state.
    override func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        AppPushService.handleDidReceive(response: response)
        super.userNotificationCenter(center, didReceive: response, withCompletionHandler: completionHandler)
    }

    // Shows the notification banner while the app is open in the foreground.
    override func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        return AppPushService.handleWillPresent(notification: notification)
    }
}
