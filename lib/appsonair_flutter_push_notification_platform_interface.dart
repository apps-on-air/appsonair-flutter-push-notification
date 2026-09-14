import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'appsonair_flutter_push_notification_method_channel.dart';

/// The interface that platform-specific implementations of this plugin must
/// implement.
///
/// App developers should use the public `AppsOnAirPush` API instead of this
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
  /// permission changes, etc.), bridged into the public `AppsOnAirPush` API.
  Stream<Map<Object?, Object?>> get eventStream {
    throw UnimplementedError('eventStream has not been implemented.');
  }

  /// See `AppsOnAirPush.initialize`.
  Future<void> initialize({
    String appId = '',
    bool debug = false,
    bool swizzle = true,
  }) {
    throw UnimplementedError('initialize() has not been implemented.');
  }

  /// See `AppsOnAirPush.login`.
  Future<void> login(String externalId) {
    throw UnimplementedError('login() has not been implemented.');
  }

  /// See `AppsOnAirPush.logout`.
  Future<void> logout() {
    throw UnimplementedError('logout() has not been implemented.');
  }

  /// See `AppsOnAirPush.deviceId`.
  Future<String?> getDeviceId() {
    throw UnimplementedError('getDeviceId() has not been implemented.');
  }

  /// See `AppsOnAirPush.setConsentRequired`.
  Future<void> setConsentRequired(bool value) {
    throw UnimplementedError('setConsentRequired() has not been implemented.');
  }

  /// See `AppsOnAirPush.setConsentGiven`.
  Future<void> setConsentGiven(bool value) {
    throw UnimplementedError('setConsentGiven() has not been implemented.');
  }

  /// See `AppsOnAirPush.isPermissionGranted`.
  Future<bool> isPermissionGranted() {
    throw UnimplementedError('isPermissionGranted() has not been implemented.');
  }

  /// See `AppsOnAirPush.clearAllNotifications`.
  Future<void> clearAllNotifications() {
    throw UnimplementedError(
      'clearAllNotifications() has not been implemented.',
    );
  }

  /// See `AppsOnAirUserManager.externalId`.
  Future<String?> userGetExternalId() {
    throw UnimplementedError('userGetExternalId() has not been implemented.');
  }

  /// See `AppsOnAirPushSubscription.isOptedIn`.
  Future<bool> pushSubscriptionIsOptedIn() {
    throw UnimplementedError(
      'pushSubscriptionIsOptedIn() has not been implemented.',
    );
  }

  /// See `AppsOnAirPushSubscription.token`.
  Future<String?> pushSubscriptionGetToken() {
    throw UnimplementedError(
      'pushSubscriptionGetToken() has not been implemented.',
    );
  }

  /// See `AppsOnAirPushSubscription.optIn`.
  Future<void> pushSubscriptionOptIn() {
    throw UnimplementedError(
      'pushSubscriptionOptIn() has not been implemented.',
    );
  }

  /// See `AppsOnAirPushSubscription.optOut`.
  Future<void> pushSubscriptionOptOut() {
    throw UnimplementedError(
      'pushSubscriptionOptOut() has not been implemented.',
    );
  }

  /// See `AppsOnAirUserManager.addTagWithKey`.
  Future<void> addTag(String key, String value) {
    throw UnimplementedError('addTag() has not been implemented.');
  }

  /// See `AppsOnAirUserManager.addTags`.
  Future<void> addTags(Map<String, String> tags) {
    throw UnimplementedError('addTags() has not been implemented.');
  }

  /// See `AppsOnAirUserManager.removeTag`.
  Future<void> removeTag(String key) {
    throw UnimplementedError('removeTag() has not been implemented.');
  }

  /// See `AppsOnAirUserManager.removeTags`.
  Future<void> removeTags(List<String> keys) {
    throw UnimplementedError('removeTags() has not been implemented.');
  }

  /// See `AppsOnAirUserManager.getTags`.
  Future<Map<String, String>> getTags() {
    throw UnimplementedError('getTags() has not been implemented.');
  }

  /// See `AppsOnAirUserManager.setLanguage`.
  Future<void> setLanguage(String code) {
    throw UnimplementedError('setLanguage() has not been implemented.');
  }

  /// See `AppsOnAirUserManager.language`.
  Future<String> getLanguage() {
    throw UnimplementedError('getLanguage() has not been implemented.');
  }

  /// See `AppsOnAirUserManager.addAlias`.
  Future<void> addAlias(String label, String id) {
    throw UnimplementedError('addAlias() has not been implemented.');
  }

  /// See `AppsOnAirUserManager.addAliases`.
  Future<void> addAliases(Map<String, String> aliases) {
    throw UnimplementedError('addAliases() has not been implemented.');
  }

  /// See `AppsOnAirUserManager.removeAlias`.
  Future<void> removeAlias(String label) {
    throw UnimplementedError('removeAlias() has not been implemented.');
  }

  /// See `AppsOnAirUserManager.removeAliases`.
  Future<void> removeAliases(List<String> labels) {
    throw UnimplementedError('removeAliases() has not been implemented.');
  }

  /// See `AppsOnAirUserManager.addEmail`.
  Future<void> addEmail(String address) {
    throw UnimplementedError('addEmail() has not been implemented.');
  }

  /// See `AppsOnAirUserManager.removeEmail`.
  Future<void> removeEmail(String address) {
    throw UnimplementedError('removeEmail() has not been implemented.');
  }

  // ── Notifications namespace ─────────────────────────────────────────

  /// See `AppsOnAirNotificationsManager.permission`.
  Future<bool> notificationsPermission() {
    throw UnimplementedError(
      'notificationsPermission() has not been implemented.',
    );
  }

  /// See `AppsOnAirNotificationsManager.canRequestPermission`.
  Future<bool> notificationsCanRequestPermission() {
    throw UnimplementedError(
      'notificationsCanRequestPermission() has not been implemented.',
    );
  }

  /// See `AppsOnAirNotificationsManager.requestPermission`.
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

  /// See `AppsOnAirNotificationsManager.clearAll`.
  Future<void> notificationsClearAll() {
    throw UnimplementedError(
      'notificationsClearAll() has not been implemented.',
    );
  }

  /// See `AppsOnAirNotificationsManager.removeNotification`.
  Future<void> removeNotification(String id) {
    throw UnimplementedError('removeNotification() has not been implemented.');
  }

  /// See `AppsOnAirNotificationsManager.removeGroupedNotifications`.
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

  /// See `AppsOnAirDebugManager.setLogLevel`.
  Future<void> setLogLevel(String level) {
    throw UnimplementedError('setLogLevel() has not been implemented.');
  }

  /// See `AppsOnAirDebugManager.logLevel`.
  Future<String> getLogLevel() {
    throw UnimplementedError('getLogLevel() has not been implemented.');
  }
}
