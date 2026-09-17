// ignore_for_file: non_constant_identifier_names
library;

import 'dart:async';

import 'appsonair_flutter_apppush_platform_interface.dart';
import 'src/debug_manager.dart';
import 'src/models.dart';
import 'src/notifications_manager.dart';
import 'src/user_manager.dart';

export 'src/debug_manager.dart';
export 'src/models.dart';
export 'src/notifications_manager.dart';
export 'src/user_manager.dart'
    show AppsOnAirPushSubscription, AppsOnAirUserManager;

/// Entry point for the AppsOnAir push notification SDK.
///
/// Call [initialize] once, as early as possible, then use [User],
/// [Notifications], and [Debug] for the rest of the API.
class AppPushService {
  AppPushService._();

  static AppsonairFlutterAppPushPlatform get _platform =>
      AppsonairFlutterAppPushPlatform.instance;

  /// Identity, tags, aliases, email, language, and push-subscription state.
  static final AppsOnAirUserManager User = AppsOnAirUserManager(_platform);

  /// Permission, foreground display, taps, and delivered-notification management.
  static final AppsOnAirNotificationsManager Notifications =
      AppsOnAirNotificationsManager(_platform);

  /// Logging configuration.
  static final AppsOnAirDebugManager Debug = AppsOnAirDebugManager(_platform);

  static StreamSubscription<Map<Object?, Object?>>? _subscription;

  static void _ensureEventBridge() {
    if (_subscription != null) return;
    _subscription = _platform.eventStream.listen(_onEvent);
  }

  static void _onEvent(Map<Object?, Object?> raw) {
    final type = raw['type'] as String?;
    switch (type) {
      case 'notificationWillDisplay':
        final notification = PushNotification.fromMap(
          (raw['notification'] as Map?)?.cast<Object?, Object?>() ?? const {},
        );
        final eventId = raw['eventId'] as String? ?? '';
        final event = NotificationWillDisplayEvent.internal(
          notification,
          eventId,
          (id, discard) => _platform.completeNotificationDisplay(id, discard),
        );
        Notifications.dispatchWillDisplay(event);
        break;
      case 'notificationClicked':
        Notifications.dispatchClick(NotificationClickEvent.fromMap(raw));
        break;
      case 'permissionChanged':
        Notifications.dispatchPermissionChange(
          raw['granted'] as bool? ?? false,
        );
        break;
      case 'subscriptionChanged':
        User.pushSubscription.dispatch(
          PushSubscriptionChangedState.fromMap(raw),
        );
        break;
      case 'userChanged':
        User.dispatch(UserChangedState.fromMap(raw));
        break;
    }
  }

  /// Initializes the SDK. Call once, before any other API, typically in
  /// `main()` or your root widget's `initState`.
  ///
  /// [appId] is optional and kept only for source compatibility — the app ID
  /// is read from the `AppsonairAppId` manifest meta-data (Android) or
  /// Info.plist entry (iOS). [debug] is a deprecated shortcut for
  /// `Debug.setLogLevel(LogLevel.debug)`. [swizzle] is iOS-only.
  static Future<void> initialize({
    String appId = '',
    bool debug = false,
    bool swizzle = true,
  }) {
    _ensureEventBridge();
    return _platform.initialize(appId: appId, debug: debug, swizzle: swizzle);
  }

  /// Associates the device with a known user after sign-in.
  static Future<void> login(String externalId) => _platform.login(externalId);

  /// Clears the current user identity, tags, and aliases — the device
  /// reverts to anonymous.
  static Future<void> logout() => _platform.logout();

  /// Gates all data collection on explicit consent. Set before [initialize]
  /// so it applies on the very first launch.
  static Future<void> setConsentRequired(bool value) =>
      _platform.setConsentRequired(value);

  /// Records whether the user has given (`true`) or withdrawn (`false`) consent.
  static Future<void> setConsentGiven(bool value) =>
      _platform.setConsentGiven(value);
}
