// ignore_for_file: non_constant_identifier_names
library;

import 'dart:async';

import 'appsonair_flutter_push_notification_platform_interface.dart';
import 'src/debug_manager.dart';
import 'src/models.dart';
import 'src/notifications_manager.dart';
import 'src/user_manager.dart';

export 'src/debug_manager.dart';
export 'src/models.dart';
export 'src/notifications_manager.dart';
export 'src/user_manager.dart'
    show AppsOnAirPushSubscription, AppsOnAirUserManager;

class AppsOnAirPush {
  AppsOnAirPush._();

  static AppsonairFlutterPushNotificationPlatform get _platform =>
      AppsonairFlutterPushNotificationPlatform.instance;

  static final AppsOnAirUserManager User = AppsOnAirUserManager(_platform);
  static final AppsOnAirNotificationsManager Notifications =
      AppsOnAirNotificationsManager(_platform);
  static final AppsOnAirDebugManager Debug = AppsOnAirDebugManager(_platform);

  static final List<PushTokenListener> _tokenListeners = [];
  static final List<PushNotificationListener> _receivedListeners = [];
  static final List<PushNotificationListener> _openedListeners = [];
  static final List<PushErrorListener> _errorListeners = [];

  static StreamSubscription<Map<Object?, Object?>>? _subscription;

  static void _ensureEventBridge() {
    if (_subscription != null) return;
    _subscription = _platform.eventStream.listen(_onEvent);
  }

  static void _onEvent(Map<Object?, Object?> raw) {
    final type = raw['type'] as String?;
    switch (type) {
      case 'tokenUpdated':
        final token = raw['token'] as String? ?? '';
        final environment = raw['environment'] as String?;
        for (final l in List.of(_tokenListeners)) {
          l(token, environment);
        }
        break;
      case 'notificationReceived':
        final notification = PushNotification.fromMap(
          (raw['notification'] as Map?)?.cast<Object?, Object?>() ?? const {},
        );
        for (final l in List.of(_receivedListeners)) {
          l(notification);
        }
        break;
      case 'notificationOpened':
        final notification = PushNotification.fromMap(
          (raw['notification'] as Map?)?.cast<Object?, Object?>() ?? const {},
        );
        for (final l in List.of(_openedListeners)) {
          l(notification);
        }
        break;
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
      case 'error':
        final error = PushError(
          code: PushErrorCode.fromWire(raw['code'] as String?),
          message: raw['message'] as String? ?? '',
        );
        for (final l in List.of(_errorListeners)) {
          l(error);
        }
        break;
    }
  }

  static Future<void> initialize({
    String appId = '',
    bool debug = false,
    bool swizzle = true,
  }) {
    _ensureEventBridge();
    return _platform.initialize(appId: appId, debug: debug, swizzle: swizzle);
  }

  static Future<void> login(String externalId) => _platform.login(externalId);

  static Future<void> logout() => _platform.logout();

  static Future<String?> get deviceId => _platform.getDeviceId();

  static Future<void> setConsentRequired(bool value) =>
      _platform.setConsentRequired(value);

  static Future<void> setConsentGiven(bool value) =>
      _platform.setConsentGiven(value);

  static Future<bool> isPermissionGranted() => _platform.isPermissionGranted();

  static Future<void> clearAllNotifications() =>
      _platform.clearAllNotifications();

  // ── Listeners ─────────────────────────────────────────────────────────

  /// Fires when the push token is issued/refreshed.
  /// Android: `token` is the FCM token, `apnsEnvironment` is always null.
  /// iOS: `token` is the hex APNs token, `apnsEnvironment` is `"sandbox"`/`"production"`.
  static void addTokenListener(PushTokenListener listener) {
    _ensureEventBridge();
    _tokenListeners.add(listener);
  }

  static void removeTokenListener(PushTokenListener listener) =>
      _tokenListeners.remove(listener);

  static void addNotificationReceivedListener(
    PushNotificationListener listener,
  ) {
    _ensureEventBridge();
    _receivedListeners.add(listener);
  }

  static void removeNotificationReceivedListener(
    PushNotificationListener listener,
  ) => _receivedListeners.remove(listener);

  static void addNotificationOpenedListener(PushNotificationListener listener) {
    _ensureEventBridge();
    _openedListeners.add(listener);
  }

  static void removeNotificationOpenedListener(
    PushNotificationListener listener,
  ) => _openedListeners.remove(listener);

  static void addErrorListener(PushErrorListener listener) {
    _ensureEventBridge();
    _errorListeners.add(listener);
  }

  static void removeErrorListener(PushErrorListener listener) =>
      _errorListeners.remove(listener);
}
