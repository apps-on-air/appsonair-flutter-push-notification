import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'appsonair_flutter_apppush_platform_interface.dart';

/// Method-channel implementation of [AppsonairFlutterAppPushPlatform].
class MethodChannelAppsonairFlutterAppPush
    extends AppsonairFlutterAppPushPlatform {
  /// The method channel used to invoke request/response calls on the native side.
  @visibleForTesting
  final methodChannel = const MethodChannel(
    'appsonair_flutter_apppush/methods',
  );

  /// The event channel used to receive the [eventStream] broadcast from the native side.
  @visibleForTesting
  final eventChannel = const EventChannel(
    'appsonair_flutter_apppush/events',
  );

  Stream<Map<Object?, Object?>>? _eventStream;

  @override
  Stream<Map<Object?, Object?>> get eventStream {
    return _eventStream ??= eventChannel.receiveBroadcastStream().map(
          (event) => (event as Map).cast<Object?, Object?>(),
        );
  }

  Future<T> _invoke<T>(String method, [Map<String, dynamic>? args]) async {
    final result = await methodChannel.invokeMethod<T>(method, args);
    return result as T;
  }

  Future<T?> _invokeOrNull<T>(String method, [Map<String, dynamic>? args]) {
    return methodChannel.invokeMethod<T>(method, args);
  }

  // ── Core ──────────────────────────────────────────────────────────────

  @override
  Future<void> initialize({
    String appId = '',
    bool debug = false,
    bool swizzle = true,
  }) {
    return methodChannel.invokeMethod('initialize', {
      'debug': debug,
      'swizzle': swizzle,
    });
  }

  @override
  Future<void> login(String externalId) {
    return methodChannel.invokeMethod('login', {'externalId': externalId});
  }

  @override
  Future<void> logout() => methodChannel.invokeMethod('logout');

  @override
  Future<String?> getDeviceId() => _invokeOrNull<String>('getDeviceId');

  @override
  Future<void> setConsentRequired(bool value) {
    return methodChannel.invokeMethod('setConsentRequired', {'value': value});
  }

  @override
  Future<void> setConsentGiven(bool value) {
    return methodChannel.invokeMethod('setConsentGiven', {'value': value});
  }

  @override
  Future<bool> isPermissionGranted() => _invoke<bool>('isPermissionGranted');

  @override
  Future<void> clearAllNotifications() =>
      methodChannel.invokeMethod('clearAllNotifications');

  @override
  Future<String?> userGetExternalId() =>
      _invokeOrNull<String>('user#getExternalId');

  @override
  Future<bool> pushSubscriptionIsOptedIn() =>
      _invoke<bool>('user#pushSubscription#isOptedIn');

  @override
  Future<String?> pushSubscriptionGetToken() =>
      _invokeOrNull<String>('user#pushSubscription#getToken');

  @override
  Future<void> pushSubscriptionOptIn() =>
      methodChannel.invokeMethod('user#pushSubscription#optIn');

  @override
  Future<void> pushSubscriptionOptOut() =>
      methodChannel.invokeMethod('user#pushSubscription#optOut');

  @override
  Future<void> addTag(String key, String value) {
    return methodChannel.invokeMethod('user#addTag', {
      'key': key,
      'value': value,
    });
  }

  @override
  Future<void> addTags(Map<String, String> tags) {
    return methodChannel.invokeMethod('user#addTags', {'tags': tags});
  }

  @override
  Future<void> removeTag(String key) {
    return methodChannel.invokeMethod('user#removeTag', {'key': key});
  }

  @override
  Future<void> removeTags(List<String> keys) {
    return methodChannel.invokeMethod('user#removeTags', {'keys': keys});
  }

  @override
  Future<Map<String, String>> getTags() async {
    final result = await methodChannel.invokeMethod<Map<Object?, Object?>>(
      'user#getTags',
    );
    return (result ?? const {}).map(
      (k, v) => MapEntry(k.toString(), v.toString()),
    );
  }

  @override
  Future<void> setLanguage(String code) {
    return methodChannel.invokeMethod('user#setLanguage', {'code': code});
  }

  @override
  Future<String> getLanguage() => _invoke<String>('user#getLanguage');

  @override
  Future<void> addAlias(String label, String id) {
    return methodChannel.invokeMethod('user#addAlias', {
      'label': label,
      'id': id,
    });
  }

  @override
  Future<void> addAliases(Map<String, String> aliases) {
    return methodChannel.invokeMethod('user#addAliases', {'aliases': aliases});
  }

  @override
  Future<void> removeAlias(String label) {
    return methodChannel.invokeMethod('user#removeAlias', {'label': label});
  }

  @override
  Future<void> removeAliases(List<String> labels) {
    return methodChannel.invokeMethod('user#removeAliases', {'labels': labels});
  }

  @override
  Future<void> addEmail(String address) {
    return methodChannel.invokeMethod('user#addEmail', {'address': address});
  }

  @override
  Future<void> removeEmail(String address) {
    return methodChannel.invokeMethod('user#removeEmail', {'address': address});
  }

  // ── Notifications namespace ─────────────────────────────────────────

  @override
  Future<bool> notificationsPermission() =>
      _invoke<bool>('notifications#permission');

  @override
  Future<bool> notificationsCanRequestPermission() =>
      _invoke<bool>('notifications#canRequestPermission');

  @override
  Future<void> notificationsRequestPermission({
    bool fallbackToSettings = false,
  }) {
    return methodChannel.invokeMethod('notifications#requestPermission', {
      'fallbackToSettings': fallbackToSettings,
    });
  }

  @override
  Future<void> registerForProvisionalAuthorization() {
    return methodChannel.invokeMethod(
      'notifications#registerForProvisionalAuthorization',
    );
  }

  @override
  Future<void> notificationsClearAll() =>
      methodChannel.invokeMethod('notifications#clearAll');

  @override
  Future<void> removeNotification(String id) {
    return methodChannel.invokeMethod('notifications#removeNotification', {
      'id': id,
    });
  }

  @override
  Future<void> removeGroupedNotifications(String groupKey) {
    return methodChannel.invokeMethod(
      'notifications#removeGroupedNotifications',
      {'groupKey': groupKey},
    );
  }

  @override
  Future<void> completeNotificationDisplay(String eventId, bool discard) {
    return methodChannel.invokeMethod('notifications#completeDisplay', {
      'eventId': eventId,
      'discard': discard,
    });
  }

  // ── Debug namespace ──────────────────────────────────────────────────

  @override
  Future<void> setLogLevel(String level) {
    return methodChannel.invokeMethod('debug#setLogLevel', {'level': level});
  }

  @override
  Future<String> getLogLevel() => _invoke<String>('debug#getLogLevel');
}
