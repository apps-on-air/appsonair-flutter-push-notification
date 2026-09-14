import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'appsonair_flutter_push_notification_method_channel.dart';

abstract class AppsonairFlutterPushNotificationPlatform
    extends PlatformInterface {
  AppsonairFlutterPushNotificationPlatform() : super(token: _token);

  static final Object _token = Object();

  static AppsonairFlutterPushNotificationPlatform _instance =
      MethodChannelAppsonairFlutterPushNotification();

  static AppsonairFlutterPushNotificationPlatform get instance => _instance;

  static set instance(AppsonairFlutterPushNotificationPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Stream<Map<Object?, Object?>> get eventStream {
    throw UnimplementedError('eventStream has not been implemented.');
  }

  Future<void> initialize({
    String appId = '',
    bool debug = false,
    bool swizzle = true,
  }) {
    throw UnimplementedError('initialize() has not been implemented.');
  }

  Future<void> login(String externalId) {
    throw UnimplementedError('login() has not been implemented.');
  }

  Future<void> logout() {
    throw UnimplementedError('logout() has not been implemented.');
  }

  Future<String?> getDeviceId() {
    throw UnimplementedError('getDeviceId() has not been implemented.');
  }

  Future<void> setConsentRequired(bool value) {
    throw UnimplementedError('setConsentRequired() has not been implemented.');
  }

  Future<void> setConsentGiven(bool value) {
    throw UnimplementedError('setConsentGiven() has not been implemented.');
  }

  Future<bool> isPermissionGranted() {
    throw UnimplementedError('isPermissionGranted() has not been implemented.');
  }

  Future<void> clearAllNotifications() {
    throw UnimplementedError(
      'clearAllNotifications() has not been implemented.',
    );
  }

  Future<String?> userGetExternalId() {
    throw UnimplementedError('userGetExternalId() has not been implemented.');
  }

  Future<bool> pushSubscriptionIsOptedIn() {
    throw UnimplementedError(
      'pushSubscriptionIsOptedIn() has not been implemented.',
    );
  }

  Future<String?> pushSubscriptionGetToken() {
    throw UnimplementedError(
      'pushSubscriptionGetToken() has not been implemented.',
    );
  }

  Future<void> pushSubscriptionOptIn() {
    throw UnimplementedError(
      'pushSubscriptionOptIn() has not been implemented.',
    );
  }

  Future<void> pushSubscriptionOptOut() {
    throw UnimplementedError(
      'pushSubscriptionOptOut() has not been implemented.',
    );
  }

  Future<void> addTag(String key, String value) {
    throw UnimplementedError('addTag() has not been implemented.');
  }

  Future<void> addTags(Map<String, String> tags) {
    throw UnimplementedError('addTags() has not been implemented.');
  }

  Future<void> removeTag(String key) {
    throw UnimplementedError('removeTag() has not been implemented.');
  }

  Future<void> removeTags(List<String> keys) {
    throw UnimplementedError('removeTags() has not been implemented.');
  }

  Future<Map<String, String>> getTags() {
    throw UnimplementedError('getTags() has not been implemented.');
  }

  Future<void> setLanguage(String code) {
    throw UnimplementedError('setLanguage() has not been implemented.');
  }

  Future<String> getLanguage() {
    throw UnimplementedError('getLanguage() has not been implemented.');
  }

  Future<void> addAlias(String label, String id) {
    throw UnimplementedError('addAlias() has not been implemented.');
  }

  Future<void> addAliases(Map<String, String> aliases) {
    throw UnimplementedError('addAliases() has not been implemented.');
  }

  Future<void> removeAlias(String label) {
    throw UnimplementedError('removeAlias() has not been implemented.');
  }

  Future<void> removeAliases(List<String> labels) {
    throw UnimplementedError('removeAliases() has not been implemented.');
  }

  Future<void> addEmail(String address) {
    throw UnimplementedError('addEmail() has not been implemented.');
  }

  Future<void> removeEmail(String address) {
    throw UnimplementedError('removeEmail() has not been implemented.');
  }

  // ── Notifications namespace ─────────────────────────────────────────

  Future<bool> notificationsPermission() {
    throw UnimplementedError(
      'notificationsPermission() has not been implemented.',
    );
  }

  Future<bool> notificationsCanRequestPermission() {
    throw UnimplementedError(
      'notificationsCanRequestPermission() has not been implemented.',
    );
  }

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

  Future<void> notificationsClearAll() {
    throw UnimplementedError(
      'notificationsClearAll() has not been implemented.',
    );
  }

  Future<void> removeNotification(String id) {
    throw UnimplementedError('removeNotification() has not been implemented.');
  }

  Future<void> removeGroupedNotifications(String groupKey) {
    throw UnimplementedError(
      'removeGroupedNotifications() has not been implemented.',
    );
  }

  Future<void> completeNotificationDisplay(String eventId, bool discard) {
    throw UnimplementedError(
      'completeNotificationDisplay() has not been implemented.',
    );
  }

  Future<void> setLogLevel(String level) {
    throw UnimplementedError('setLogLevel() has not been implemented.');
  }

  Future<String> getLogLevel() {
    throw UnimplementedError('getLogLevel() has not been implemented.');
  }
}
