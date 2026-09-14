import AppsOnAirPush
import Flutter
import UIKit

@MainActor
public class AppsonairFlutterPushNotificationPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {

  private var eventSink: FlutterEventSink?

  private var pendingWillDisplayEvents: [String: NotificationWillDisplayEvent] = [:]

  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = AppsonairFlutterPushNotificationPlugin()

    let channel = FlutterMethodChannel(
      name: "appsonair_flutter_push_notification/methods",
      binaryMessenger: registrar.messenger()
    )
    registrar.addMethodCallDelegate(instance, channel: channel)

    let eventChannel = FlutterEventChannel(
      name: "appsonair_flutter_push_notification/events",
      binaryMessenger: registrar.messenger()
    )
    eventChannel.setStreamHandler(instance)

    AppsOnAirPush.setListener(instance)
    AppsOnAirPush.Notifications.addForegroundLifecycleListener(instance)
    AppsOnAirPush.Notifications.addClickListener(instance)
    AppsOnAirPush.Notifications.addPermissionObserver(instance)
    AppsOnAirPush.User.pushSubscription.addObserver(instance)
    AppsOnAirPush.User.addObserver(instance)
  }

  // MARK: - FlutterStreamHandler

  public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    eventSink = events
    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    return nil
  }

  // MARK: - FlutterPlugin

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any]

    switch call.method {
    case "initialize":
      AppsOnAirPush.initialize(
        debug: args?["debug"] as? Bool ?? false,
        swizzle: args?["swizzle"] as? Bool ?? true
      )
      result(nil)
    case "login":
      AppsOnAirPush.login(args?["externalId"] as? String ?? "")
      result(nil)
    case "logout":
      AppsOnAirPush.logout()
      result(nil)
    case "getDeviceId":
      result(AppsOnAirPush.deviceId)
    case "setConsentRequired":
      AppsOnAirPush.consentRequired = args?["value"] as? Bool ?? false
      result(nil)
    case "setConsentGiven":
      AppsOnAirPush.consentGiven = args?["value"] as? Bool ?? false
      result(nil)
    case "isPermissionGranted":
      Task { @MainActor in
        result(await AppsOnAirPush.isPermissionGranted())
      }
    case "clearAllNotifications":
      AppsOnAirPush.clearAllNotifications()
      result(nil)

    // MARK: User namespace
    case "user#getExternalId":
      result(AppsOnAirPush.User.externalId)
    case "user#pushSubscription#isOptedIn":
      result(AppsOnAirPush.User.pushSubscription.optedIn)
    case "user#pushSubscription#getToken":
      result(AppsOnAirPush.User.pushSubscription.token)
    case "user#pushSubscription#optIn":
      AppsOnAirPush.User.pushSubscription.optIn()
      result(nil)
    case "user#pushSubscription#optOut":
      AppsOnAirPush.User.pushSubscription.optOut()
      result(nil)
    case "user#addTag":
      AppsOnAirPush.User.addTag(
        key: args?["key"] as? String ?? "",
        value: args?["value"] as? String ?? ""
      )
      result(nil)
    case "user#addTags":
      AppsOnAirPush.User.addTags(args?["tags"] as? [String: String] ?? [:])
      result(nil)
    case "user#removeTag":
      AppsOnAirPush.User.removeTag(args?["key"] as? String ?? "")
      result(nil)
    case "user#removeTags":
      AppsOnAirPush.User.removeTags(args?["keys"] as? [String] ?? [])
      result(nil)
    case "user#getTags":
      result(AppsOnAirPush.User.getTags())
    case "user#setLanguage":
      AppsOnAirPush.User.setLanguage(args?["code"] as? String ?? "")
      result(nil)
    case "user#getLanguage":
      result(AppsOnAirPush.User.language)
    case "user#addAlias":
      AppsOnAirPush.User.addAlias(
        label: args?["label"] as? String ?? "",
        id: args?["id"] as? String ?? ""
      )
      result(nil)
    case "user#addAliases":
      AppsOnAirPush.User.addAliases(args?["aliases"] as? [String: String] ?? [:])
      result(nil)
    case "user#removeAlias":
      AppsOnAirPush.User.removeAlias(args?["label"] as? String ?? "")
      result(nil)
    case "user#removeAliases":
      AppsOnAirPush.User.removeAliases(args?["labels"] as? [String] ?? [])
      result(nil)
    case "user#addEmail":
      AppsOnAirPush.User.addEmail(args?["address"] as? String ?? "")
      result(nil)
    case "user#removeEmail":
      AppsOnAirPush.User.removeEmail(args?["address"] as? String ?? "")
      result(nil)

    // MARK: Notifications namespace
    case "notifications#permission":
      result(AppsOnAirPush.Notifications.permission)
    case "notifications#canRequestPermission":
      result(AppsOnAirPush.Notifications.canRequestPermission)
    case "notifications#requestPermission":
      AppsOnAirPush.Notifications.requestPermission(
        fallbackToSettings: args?["fallbackToSettings"] as? Bool ?? false
      )
      result(nil)
    case "notifications#registerForProvisionalAuthorization":
      AppsOnAirPush.Notifications.registerForProvisionalAuthorization()
      result(nil)
    case "notifications#clearAll":
      AppsOnAirPush.Notifications.clearAllNotifications()
      result(nil)
    case "notifications#removeNotification":
      if let id = args?["id"] as? String {
        AppsOnAirPush.Notifications.removeNotification(withIdentifier: id)
      }
      result(nil)
    case "notifications#removeGroupedNotifications":
      result(nil) // Android-only
    case "notifications#completeDisplay":
      let eventId = args?["eventId"] as? String
      let discard = args?["discard"] as? Bool ?? false
      let event = eventId.flatMap { pendingWillDisplayEvents.removeValue(forKey: $0) }
      if discard {
        event?.preventDefault()
      }
      result(nil)

    // MARK: Debug namespace
    case "debug#setLogLevel":
      AppsOnAirPush.Debug.logLevel = LogLevel(wire: args?["level"] as? String)
      result(nil)
    case "debug#getLogLevel":
      result(AppsOnAirPush.Debug.logLevel.wireValue)

    default:
      result(FlutterMethodNotImplemented)
    }
  }
}

// MARK: - PushListener

extension AppsonairFlutterPushNotificationPlugin: PushListener {
  public func onAPNsTokenUpdated(token: String, environment: APNsEnvironment) {
    eventSink?(["type": "tokenUpdated", "token": token, "environment": environment.rawValue])
  }

  public func onNotificationReceived(notification: PushNotification) {
    eventSink?(["type": "notificationReceived", "notification": notification.toMap()])
  }

  public func onNotificationOpened(notification: PushNotification) {
    eventSink?(["type": "notificationOpened", "notification": notification.toMap()])
  }

  public func onError(_ error: PushError) {
    eventSink?(["type": "error", "code": error.code.rawValue, "message": error.message])
  }
}

// MARK: - NotificationLifecycleListener

extension AppsonairFlutterPushNotificationPlugin: NotificationLifecycleListener {
  public func onWillDisplay(event: NotificationWillDisplayEvent) {
    let eventId = UUID().uuidString
    pendingWillDisplayEvents[eventId] = event
    eventSink?([
      "type": "notificationWillDisplay",
      "eventId": eventId,
      "notification": event.notification.toMap(),
    ])
  }
}

// MARK: - NotificationClickListener

extension AppsonairFlutterPushNotificationPlugin: NotificationClickListener {
  public func onClick(event: NotificationClickEvent) {
    eventSink?([
      "type": "notificationClicked",
      "notification": event.notification.toMap(),
      "actionId": event.result.actionId as Any,
    ])
  }
}

// MARK: - NotificationPermissionObserver

extension AppsonairFlutterPushNotificationPlugin: NotificationPermissionObserver {
  public func onNotificationPermissionDidChange(_ permission: Bool) {
    eventSink?(["type": "permissionChanged", "granted": permission])
  }
}

// MARK: - PushSubscriptionObserver

extension AppsonairFlutterPushNotificationPlugin: PushSubscriptionObserver {
  public func onPushSubscriptionDidChange(state: PushSubscriptionChangedState) {
    eventSink?([
      "type": "subscriptionChanged",
      "previous": ["token": state.previous.token as Any, "isOptedIn": state.previous.optedIn],
      "current": ["token": state.current.token as Any, "isOptedIn": state.current.optedIn],
    ])
  }
}

// MARK: - UserStateObserver

extension AppsonairFlutterPushNotificationPlugin: UserStateObserver {
  public func onUserStateDidChange(state: UserChangedState) {
    eventSink?([
      "type": "userChanged",
      "externalId": state.current.externalId as Any,
      "appsonairId": state.current.appsOnAirId,
    ])
  }
}

// MARK: - Helpers

extension PushNotification {
  fileprivate func toMap() -> [String: Any] {
    [
      "id": id as Any,
      "title": title as Any,
      "body": body as Any,
      "data": userInfo,
    ]
  }
}

extension LogLevel {
  fileprivate init(wire: String?) {
    switch wire {
    case "fatal": self = .fatal
    case "error": self = .error
    case "warn": self = .warn
    case "info": self = .info
    case "debug": self = .debug
    case "verbose": self = .verbose
    default: self = .none
    }
  }

  fileprivate var wireValue: String {
    switch self {
    case .none: return "none"
    case .fatal: return "fatal"
    case .error: return "error"
    case .warn: return "warn"
    case .info: return "info"
    case .debug: return "debug"
    case .verbose: return "verbose"
    }
  }
}
