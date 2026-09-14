import '../appsonair_flutter_push_notification_platform_interface.dart';
import 'models.dart';

/// `AppPushService.Notifications` — permission, foreground display, taps, and
/// delivered-notification management.
class AppsOnAirNotificationsManager {
  /// Not for public use — access via `AppPushService.Notifications`.
  AppsOnAirNotificationsManager(this._platform);

  final AppsonairFlutterPushNotificationPlatform _platform;

  final List<NotificationPermissionListener> _permissionObservers = [];
  final List<NotificationWillDisplayListener> _foregroundListeners = [];
  final List<NotificationClickListener> _clickListeners = [];

  Future<bool> get permission => _platform.notificationsPermission();

  /// Whether the system will show the permission dialog if
  /// [requestPermission] is called (false if permanently denied — Android 13+).
  Future<bool> get canRequestPermission =>
      _platform.notificationsCanRequestPermission();

  /// Request notification permission.
  /// If [fallbackToSettings] is true and permission was denied, opens the
  /// app's system Settings page instead of showing a dialog that would no-op.
  Future<void> requestPermission({bool fallbackToSettings = false}) {
    return _platform.notificationsRequestPermission(
      fallbackToSettings: fallbackToSettings,
    );
  }

  /// iOS only. Requests provisional (quiet) authorization — notifications are
  /// delivered silently to Notification Center without a system prompt.
  /// No-op on Android.
  Future<void> registerForProvisionalAuthorization() {
    return _platform.registerForProvisionalAuthorization();
  }

  /// Observe changes to the notification permission.
  void addPermissionObserver(NotificationPermissionListener observer) {
    _permissionObservers.add(observer);
  }

  /// Removes an observer added with [addPermissionObserver].
  void removePermissionObserver(NotificationPermissionListener observer) {
    _permissionObservers.remove(observer);
  }

  /// Add a listener to control notification display while the app is in the
  /// foreground. Call `event.preventDefault()` inside the listener to
  /// suppress the system banner; otherwise it is shown automatically.
  void addForegroundWillDisplayListener(
    NotificationWillDisplayListener listener,
  ) {
    _foregroundListeners.add(listener);
  }

  /// Removes a listener added with [addForegroundWillDisplayListener].
  void removeForegroundWillDisplayListener(
    NotificationWillDisplayListener listener,
  ) {
    _foregroundListeners.remove(listener);
  }

  /// Add a listener that fires when the user taps a notification or an
  /// action button.
  void addClickListener(NotificationClickListener listener) {
    _clickListeners.add(listener);
  }

  /// Removes a listener added with [addClickListener].
  void removeClickListener(NotificationClickListener listener) {
    _clickListeners.remove(listener);
  }

  /// Remove all delivered notifications from the notification shade /
  /// Notification Center.
  Future<void> clearAll() => _platform.notificationsClearAll();

  /// Remove a single delivered notification.
  /// On Android [id] is the integer system notification ID (as a string);
  /// on iOS it's the `UNNotificationRequest` identifier string.
  Future<void> removeNotification(String id) =>
      _platform.removeNotification(id);

  /// Android only. Removes every notification belonging to [groupKey].
  /// No-op on iOS (no grouped-notification concept).
  Future<void> removeGroupedNotifications(String groupKey) {
    return _platform.removeGroupedNotifications(groupKey);
  }

  /// Not for public use — invoked internally to fan out a native permission
  /// change to registered observers.
  void dispatchPermissionChange(bool granted) {
    for (final observer in List.of(_permissionObservers)) {
      observer(granted);
    }
  }

  /// Not for public use — invoked internally to fan out a native click event
  /// to registered listeners.
  void dispatchClick(NotificationClickEvent event) {
    for (final listener in List.of(_clickListeners)) {
      listener(event);
    }
  }

  /// Not for public use — invoked internally to fan out a native
  /// will-display event to registered listeners.
  void dispatchWillDisplay(NotificationWillDisplayEvent event) {
    for (final listener in List.of(_foregroundListeners)) {
      listener(event);
    }
  }
}
