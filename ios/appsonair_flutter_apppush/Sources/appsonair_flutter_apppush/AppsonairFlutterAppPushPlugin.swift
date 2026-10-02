import AppsOnAir_AppPush
import Flutter
import UIKit
import UserNotifications

@MainActor
public class AppsonairFlutterAppPushPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {

  private var eventSink: FlutterEventSink?

  // Generic event buffer: any event that fires before the Dart event stream
  // connects (onListen) is queued here and flushed the moment onListen() is
  // called. This mirrors Android's pendingEvents and is critical for silent
  // pushes that arrive while the Flutter engine is still starting up.
  private var pendingEvents: [[String: Any]] = []

  private var pendingWillDisplayEvents: [String: NotificationWillDisplayEvent] = [:]

  // Kill-mode UNNotificationResponse buffer: when the plugin is the early
  // UNUserNotificationCenterDelegate (set in register(with:) before
  // didFinishLaunchingWithOptions returns), a tap can arrive before Dart calls
  // initialize(). We hold it here and forward it in case "initialize".
  private var pendingLaunchResponse: UNNotificationResponse? = nil
  // Tracks whether AppPushService.initialize() has been called from Dart.
  // Used by the UNUserNotificationCenterDelegate extension to decide whether
  // to forward or buffer a notification response.
  private var sdkInitialized = false

  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = AppsonairFlutterAppPushPlugin()

    let channel = FlutterMethodChannel(
      name: "appsonair_flutter_apppush/methods",
      binaryMessenger: registrar.messenger()
    )
    registrar.addMethodCallDelegate(instance, channel: channel)

    let eventChannel = FlutterEventChannel(
      name: "appsonair_flutter_apppush/events",
      binaryMessenger: registrar.messenger()
    )
    eventChannel.setStreamHandler(instance)

    AppPushService.setListener(instance)
    AppPushService.Notifications.addForegroundLifecycleListener(instance)
    AppPushService.Notifications.addClickListener(instance)
    AppPushService.Notifications.addPermissionObserver(instance)
    AppPushService.User.pushSubscription.addObserver(instance)
    AppPushService.User.addObserver(instance)

    // Register for UIApplicationDelegate callbacks so the plugin can forward
    // silent pushes to the SDK without requiring any AppDelegate changes.
    registrar.addApplicationDelegate(instance)

    // Silent push (content-available: 1). The completion handler is called
    // immediately with .newData so iOS does not penalise the app for a missing
    // call — Dart has no mechanism to signal completion back to the OS within
    // the ~30 s background window.
    AppPushService.onSilentPushReceived = { [weak instance] userInfo, completion in
      // Cast [AnyHashable: Any] → [String: Any] — Flutter event channel codec
      // cannot encode AnyHashable keys and silently drops the event without this.
      let data = userInfo.reduce(into: [String: Any]()) { result, pair in
        if let key = pair.key.base as? String { result[key] = pair.value }
      }
      instance?.sendEvent(["type": "silentPushReceived", "data": data])
      completion(.newData)
    }

    // Install this instance as the UNUserNotificationCenterDelegate NOW, while
    // we are still inside didFinishLaunchingWithOptions. iOS delivers the
    // kill-mode didReceive(_:withCompletionHandler:) on the very first run-loop
    // turn AFTER that function returns — before Dart's async initialize() ever
    // runs. If no delegate is set by then, the tap is silently dropped and
    // analytics are never recorded.
    // We only install when nothing else has claimed the delegate slot.
    // AppPushService.initialize(swizzle:true) will see center.delegate != nil
    // and skip installing its own PushNotificationDelegate — this plugin takes
    // over both willPresent and didReceive for the lifetime of the process.
    let center = UNUserNotificationCenter.current()
    if center.delegate == nil {
      center.delegate = instance
    }
  }

  /// Sends an event to the Dart event stream. If the stream is not yet
  /// connected (eventSink is nil), the event is buffered and flushed the
  /// moment onListen() is called — matching Android's pendingEvents behaviour.
  private func sendEvent(_ event: [String: Any]) {
    if let sink = eventSink {
      sink(event)
    } else {
      pendingEvents.append(event)
    }
  }

  public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    eventSink = events
    // Flush all events buffered before the Dart stream was ready
    // (e.g. silent pushes or click events that arrived before initialize() ran).
    let buffered = pendingEvents
    pendingEvents.removeAll()
    buffered.forEach { events($0) }
    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    return nil
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any]

    switch call.method {
    case "initialize":
      AppPushService.initialize(
        debug: args?["debug"] as? Bool ?? false,
        swizzle: args?["swizzle"] as? Bool ?? true
      )
      sdkInitialized = true
      // Replay any kill-mode tap that arrived before initialize() was called.
      if let pending = pendingLaunchResponse {
        pendingLaunchResponse = nil
        AppPushService.handleDidReceive(response: pending)
      }
      result(nil)
    case "login":
      AppPushService.login(args?["externalId"] as? String ?? "")
      result(nil)
    case "logout":
      AppPushService.logout()
      result(nil)
    case "getDeviceId":
      result(AppPushService.deviceId)
    case "setConsentRequired":
      AppPushService.consentRequired = args?["value"] as? Bool ?? false
      result(nil)
    case "setConsentGiven":
      AppPushService.consentGiven = args?["value"] as? Bool ?? false
      result(nil)
    case "isPermissionGranted":
      Task { @MainActor in
        result(await AppPushService.isPermissionGranted())
      }
    case "clearAllNotifications":
      AppPushService.clearAllNotifications()
      result(nil)

    case "user#getExternalId":
      result(AppPushService.User.externalId)
    case "user#pushSubscription#isOptedIn":
      result(AppPushService.User.pushSubscription.optedIn)
    case "user#pushSubscription#getToken":
      result(AppPushService.User.pushSubscription.token)
    case "user#pushSubscription#optIn":
      AppPushService.User.pushSubscription.optIn()
      result(nil)
    case "user#pushSubscription#optOut":
      AppPushService.User.pushSubscription.optOut()
      result(nil)
    case "user#addTag":
      AppPushService.User.addTag(
        key: args?["key"] as? String ?? "",
        value: args?["value"] as? String ?? ""
      )
      result(nil)
    case "user#addTags":
      AppPushService.User.addTags(args?["tags"] as? [String: String] ?? [:])
      result(nil)
    case "user#removeTag":
      AppPushService.User.removeTag(args?["key"] as? String ?? "")
      result(nil)
    case "user#removeTags":
      AppPushService.User.removeTags(args?["keys"] as? [String] ?? [])
      result(nil)
    case "user#getTags":
      result(AppPushService.User.getTags())
    case "user#setLanguage":
      AppPushService.User.setLanguage(args?["code"] as? String ?? "")
      result(nil)
    case "user#getLanguage":
      result(AppPushService.User.language)
    case "user#addAlias":
      AppPushService.User.addAlias(
        label: args?["label"] as? String ?? "",
        id: args?["id"] as? String ?? ""
      )
      result(nil)
    case "user#addAliases":
      AppPushService.User.addAliases(args?["aliases"] as? [String: String] ?? [:])
      result(nil)
    case "user#removeAlias":
      AppPushService.User.removeAlias(args?["label"] as? String ?? "")
      result(nil)
    case "user#removeAliases":
      AppPushService.User.removeAliases(args?["labels"] as? [String] ?? [])
      result(nil)
    case "user#addEmail":
      AppPushService.User.addEmail(args?["address"] as? String ?? "")
      result(nil)
    case "user#removeEmail":
      AppPushService.User.removeEmail(args?["address"] as? String ?? "")
      result(nil)

    case "notifications#permission":
      result(AppPushService.Notifications.permission)
    case "notifications#canRequestPermission":
      result(AppPushService.Notifications.canRequestPermission)
    case "notifications#requestPermission":
      AppPushService.Notifications.requestPermission(
        fallbackToSettings: args?["fallbackToSettings"] as? Bool ?? false
      )
      result(nil)
    case "notifications#registerForProvisionalAuthorization":
      AppPushService.Notifications.registerForProvisionalAuthorization()
      result(nil)
    case "notifications#clearAll":
      AppPushService.Notifications.clearAllNotifications()
      result(nil)
    case "notifications#removeNotification":
      if let id = args?["id"] as? String {
        AppPushService.Notifications.removeNotification(withIdentifier: id)
      }
      result(nil)
    case "notifications#removeGroupedNotifications":
      result(nil)
    case "notifications#completeDisplay":
      let eventId = args?["eventId"] as? String
      let discard = args?["discard"] as? Bool ?? false
      let event = eventId.flatMap { pendingWillDisplayEvents.removeValue(forKey: $0) }
      if discard {
        event?.preventDefault()
      }
      result(nil)

    case "debug#setLogLevel":
      AppPushService.Debug.logLevel = LogLevel(wire: args?["level"] as? String)
      result(nil)
    case "debug#getLogLevel":
      result(AppPushService.Debug.logLevel.wireValue)

    default:
      result(FlutterMethodNotImplemented)
    }
  }
}

// MARK: - UIApplicationDelegate (silent push)

// Registered via registrar.addApplicationDelegate() so the Flutter engine
// forwards application:didReceiveRemoteNotification:fetchCompletionHandler:
// to this plugin — no AppDelegate changes required from the developer.
extension AppsonairFlutterAppPushPlugin {
  public func application(
    _ application: UIApplication,
    didReceiveRemoteNotification userInfo: [AnyHashable: Any],
    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
  ) -> Bool {
    AppPushService.handleSilentPush(userInfo, fetchCompletionHandler: completionHandler)
    return true
  }
}

// MARK: - UNUserNotificationCenterDelegate

// The plugin sets itself as UNUserNotificationCenter.current().delegate in
// register(with:) so the delegate is in place before didFinishLaunchingWithOptions
// returns — capturing kill-mode taps that iOS delivers on the very next run-loop turn.
//
// willPresent: forward directly to AppPushService (foreground display control).
// didReceive:  if initialize() has already run, forward immediately; otherwise
//              buffer until the "initialize" method channel call replays it.
//
// When AppPushService.initialize(swizzle: true) runs later, its swizzler sees
// center.delegate != nil and skips installing PushNotificationDelegate — this
// extension takes over both callbacks for the process lifetime.
extension AppsonairFlutterAppPushPlugin: @preconcurrency UNUserNotificationCenterDelegate {

  public func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification
  ) async -> UNNotificationPresentationOptions {
    return AppPushService.handleWillPresent(notification: notification)
  }

  public func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    if sdkInitialized {
      AppPushService.handleDidReceive(response: response)
    } else {
      // SDK not yet initialized (kill-mode tap before Dart's initialize() ran).
      // Buffer it — replayed in case "initialize" above.
      if pendingLaunchResponse == nil {
        pendingLaunchResponse = response
      }
    }
    completionHandler()
  }
}

// MARK: - PushListener

extension AppsonairFlutterAppPushPlugin: PushListener {
  public func onAPNsTokenUpdated(token: String, environment: APNsEnvironment) {
    sendEvent(["type": "tokenUpdated", "token": token, "environment": environment.rawValue])
  }

  public func onNotificationReceived(notification: PushNotification) {
    sendEvent(["type": "notificationReceived", "notification": notification.toMap()])
  }

  public func onNotificationOpened(notification: PushNotification) {
    sendEvent(["type": "notificationOpened", "notification": notification.toMap()])
  }

  public func onError(_ error: PushError) {
    sendEvent(["type": "error", "code": error.code.rawValue, "message": error.message])
  }
}

extension AppsonairFlutterAppPushPlugin: NotificationLifecycleListener {
  public func onWillDisplay(event: NotificationWillDisplayEvent) {
    let eventId = UUID().uuidString
    pendingWillDisplayEvents[eventId] = event
    sendEvent([
      "type": "notificationWillDisplay",
      "eventId": eventId,
      "notification": event.notification.toMap(),
    ])
  }
}

extension AppsonairFlutterAppPushPlugin: NotificationClickListener {
  public func onClick(event: NotificationClickEvent) {
    let payload: [String: Any] = [
      "type": "notificationClicked",
      "notification": event.notification.toMap(),
      "actionId": event.result.actionId as Any,
    ]
    sendEvent(payload)
  }
}

extension AppsonairFlutterAppPushPlugin: NotificationPermissionObserver {
  public func onNotificationPermissionDidChange(_ permission: Bool) {
    sendEvent(["type": "permissionChanged", "granted": permission])
  }
}

extension AppsonairFlutterAppPushPlugin: PushSubscriptionObserver {
  public func onPushSubscriptionDidChange(state: PushSubscriptionChangedState) {
    sendEvent([
      "type": "subscriptionChanged",
      "previous": ["token": state.previous.token as Any, "isOptedIn": state.previous.optedIn],
      "current": ["token": state.current.token as Any, "isOptedIn": state.current.optedIn],
    ])
  }
}

extension AppsonairFlutterAppPushPlugin: UserStateObserver {
  public func onUserStateDidChange(state: UserChangedState) {
    sendEvent([
      "type": "userChanged",
      "externalId": state.current.externalId as Any,
      "appsonairId": state.current.appsOnAirId,
    ])
  }
}

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
