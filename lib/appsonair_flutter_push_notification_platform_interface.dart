import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'appsonair_flutter_push_notification_method_channel.dart';

/// The interface that platform-specific implementations of this plugin must
/// implement.
///
/// App developers should use the public `AppPushService` API instead of this
/// class directly; it exists so the plugin can be backed by a method-channel
/// implementation (the default, [MethodChannelAppsonairFlutterPushNotification])
/// or a different implementation for testing.
abstract class AppsonairFlutterPushNotificationPlatform
    extends PlatformInterface {
  /// Constructs a platform interface instance, verified via [PlatformInterface.verifyToken].
  AppsonairFlutterPushNotificationPlatform() : super(token: _token);

  static final Object _token = Object();

  static AppsonairFlutterPushNotificationPlatform _instance =
      MethodChannelAppsonairFlutterPushNotification();

  /// The default instance of [AppsonairFlutterPushNotificationPlatform] used
  /// by the plugin. Defaults to [MethodChannelAppsonairFlutterPushNotification].
  static AppsonairFlutterPushNotificationPlatform get instance => _instance;

  /// Overrides the default instance, for platform-specific or test
  /// implementations. Verified against [_token] so only genuine
  /// [AppsonairFlutterPushNotificationPlatform] subclasses may be installed.
  static set instance(AppsonairFlutterPushNotificationPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Broadcast stream of raw native events (token updates, notifications,
  /// permission changes, etc.), bridged into the public `AppPushService` API.
  Stream<Map<Object?, Object?>> get eventStream {
    throw UnimplementedError('eventStream has not been implemented.');
  }

  /// Initializes the native SDK. [appId] is kept only for source
  /// compatibility — the app ID is read from native platform configuration.
  /// [debug] is a deprecated shortcut for verbose logging. [swizzle] is iOS-only.
  Future<void> initialize({
    String appId = '',
    bool debug = false,
    bool swizzle = true,
  }) {
    throw UnimplementedError('initialize() has not been implemented.');
  }

  /// Associates the device with a known user after sign-in.
  Future<void> login(String externalId) {
    throw UnimplementedError('login() has not been implemented.');
  }

  /// Clears the current user identity, tags, and aliases — the device
  /// reverts to anonymous.
  Future<void> logout() {
    throw UnimplementedError('logout() has not been implemented.');
  }

  /// Fetches the AppsOnAir-assigned device ID.
  Future<String?> getDeviceId() {
    throw UnimplementedError('getDeviceId() has not been implemented.');
  }

  /// Gates all data collection on explicit consent. Set before [initialize]
  /// so it applies on the very first launch.
  Future<void> setConsentRequired(bool value) {
    throw UnimplementedError('setConsentRequired() has not been implemented.');
  }

  /// Records whether the user has given (`true`) or withdrawn (`false`) consent.
  Future<void> setConsentGiven(bool value) {
    throw UnimplementedError('setConsentGiven() has not been implemented.');
  }

  /// Whether the notification permission is currently granted.
  Future<bool> isPermissionGranted() {
    throw UnimplementedError('isPermissionGranted() has not been implemented.');
  }

  /// Removes every notification this app has posted.
  Future<void> clearAllNotifications() {
    throw UnimplementedError(
      'clearAllNotifications() has not been implemented.',
    );
  }

  /// Fetches the external identifier set by [login], `null` when anonymous.
  Future<String?> userGetExternalId() {
    throw UnimplementedError('userGetExternalId() has not been implemented.');
  }

  /// Whether the device is currently opted in to receive pushes.
  Future<bool> pushSubscriptionIsOptedIn() {
    throw UnimplementedError(
      'pushSubscriptionIsOptedIn() has not been implemented.',
    );
  }

  /// Fetches the device's current push token — FCM token (Android) or hex
  /// APNs token (iOS). Null until registered.
  Future<String?> pushSubscriptionGetToken() {
    throw UnimplementedError(
      'pushSubscriptionGetToken() has not been implemented.',
    );
  }

  /// Resumes push delivery to this device.
  Future<void> pushSubscriptionOptIn() {
    throw UnimplementedError(
      'pushSubscriptionOptIn() has not been implemented.',
    );
  }

  /// Pauses push delivery to this device without touching OS-level permission.
  Future<void> pushSubscriptionOptOut() {
    throw UnimplementedError(
      'pushSubscriptionOptOut() has not been implemented.',
    );
  }

  /// Adds or updates a single key/value tag for audience segmentation.
  Future<void> addTag(String key, String value) {
    throw UnimplementedError('addTag() has not been implemented.');
  }

  /// Adds or updates multiple tags at once.
  Future<void> addTags(Map<String, String> tags) {
    throw UnimplementedError('addTags() has not been implemented.');
  }

  /// Removes a single tag by key.
  Future<void> removeTag(String key) {
    throw UnimplementedError('removeTag() has not been implemented.');
  }

  /// Removes multiple tags by key.
  Future<void> removeTags(List<String> keys) {
    throw UnimplementedError('removeTags() has not been implemented.');
  }

  /// Fetches the backend's copy of this device's tags.
  Future<Map<String, String>> getTags() {
    throw UnimplementedError('getTags() has not been implemented.');
  }

  /// Overrides the device language used for server-side notification
  /// translation (e.g. `"fr"`, `"en-US"`).
  Future<void> setLanguage(String code) {
    throw UnimplementedError('setLanguage() has not been implemented.');
  }

  /// Fetches the current language override, or the detected device language.
  Future<String> getLanguage() {
    throw UnimplementedError('getLanguage() has not been implemented.');
  }

  /// Associates an external identifier alias (e.g. a CRM ID) with this device.
  Future<void> addAlias(String label, String id) {
    throw UnimplementedError('addAlias() has not been implemented.');
  }

  /// Associates multiple external identifier aliases at once.
  Future<void> addAliases(Map<String, String> aliases) {
    throw UnimplementedError('addAliases() has not been implemented.');
  }

  /// Removes an alias by label.
  Future<void> removeAlias(String label) {
    throw UnimplementedError('removeAlias() has not been implemented.');
  }

  /// Removes multiple aliases by label.
  Future<void> removeAliases(List<String> labels) {
    throw UnimplementedError('removeAliases() has not been implemented.');
  }

  /// Adds an email channel for this device.
  Future<void> addEmail(String address) {
    throw UnimplementedError('addEmail() has not been implemented.');
  }

  /// Removes an email channel from this device.
  Future<void> removeEmail(String address) {
    throw UnimplementedError('removeEmail() has not been implemented.');
  }

  // ── Notifications namespace ─────────────────────────────────────────

  /// Current notification permission state.
  Future<bool> notificationsPermission() {
    throw UnimplementedError(
      'notificationsPermission() has not been implemented.',
    );
  }

  /// Whether the system will show the permission dialog if
  /// [notificationsRequestPermission] is called (false if permanently denied
  /// — Android 13+).
  Future<bool> notificationsCanRequestPermission() {
    throw UnimplementedError(
      'notificationsCanRequestPermission() has not been implemented.',
    );
  }

  /// Requests notification permission. If [fallbackToSettings] is true and
  /// permission was denied, opens the app's system Settings page instead of
  /// showing a dialog that would no-op.
  Future<void> notificationsRequestPermission({
    bool fallbackToSettings = false,
  }) {
    throw UnimplementedError(
      'notificationsRequestPermission() has not been implemented.',
    );
  }

  /// iOS only. No-op on Android.
  Future<void> registerForProvisionalAuthorization() {
    throw UnimplementedError(
      'registerForProvisionalAuthorization() has not been implemented.',
    );
  }

  /// Removes all delivered notifications from the notification shade /
  /// Notification Center.
  Future<void> notificationsClearAll() {
    throw UnimplementedError(
      'notificationsClearAll() has not been implemented.',
    );
  }

  /// Removes a single delivered notification by its payload `notification_id`.
  Future<void> removeNotification(String id) {
    throw UnimplementedError('removeNotification() has not been implemented.');
  }

  /// Android only. Removes every notification belonging to [groupKey].
  /// No-op on iOS (no grouped-notification concept).
  Future<void> removeGroupedNotifications(String groupKey) {
    throw UnimplementedError(
      'removeGroupedNotifications() has not been implemented.',
    );
  }

  /// Resolves a pending `notificationWillDisplay` event, telling the native
  /// side whether to show ([discard] `false`) or suppress ([discard] `true`)
  /// the system notification.
  Future<void> completeNotificationDisplay(String eventId, bool discard) {
    throw UnimplementedError(
      'completeNotificationDisplay() has not been implemented.',
    );
  }

  /// Sets the SDK's logging verbosity. Default is `LogLevel.none`.
  Future<void> setLogLevel(String level) {
    throw UnimplementedError('setLogLevel() has not been implemented.');
  }

  /// Fetches the SDK's current logging verbosity.
  Future<String> getLogLevel() {
    throw UnimplementedError('getLogLevel() has not been implemented.');
  }
}
