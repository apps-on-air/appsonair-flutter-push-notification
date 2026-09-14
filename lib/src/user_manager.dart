import '../appsonair_flutter_push_notification_platform_interface.dart';
import 'models.dart';

class AppsOnAirPushSubscription {
  AppsOnAirPushSubscription(this._platform);

  final AppsonairFlutterPushNotificationPlatform _platform;
  final List<PushSubscriptionListener> _observers = [];

  Future<bool> get isOptedIn => _platform.pushSubscriptionIsOptedIn();

  Future<String?> get token => _platform.pushSubscriptionGetToken();

  Future<void> optIn() => _platform.pushSubscriptionOptIn();

  Future<void> optOut() => _platform.pushSubscriptionOptOut();

  void addObserver(PushSubscriptionListener observer) =>
      _observers.add(observer);

  void removeObserver(PushSubscriptionListener observer) =>
      _observers.remove(observer);

  void dispatch(PushSubscriptionChangedState state) {
    for (final observer in List.of(_observers)) {
      observer(state);
    }
  }
}

/// `AppsOnAirPush.User` — identity, tags, aliases, email, language.
class AppsOnAirUserManager {
  AppsOnAirUserManager(this._platform)
    : pushSubscription = AppsOnAirPushSubscription(_platform);

  final AppsonairFlutterPushNotificationPlatform _platform;
  final List<UserStateListener> _observers = [];

  final AppsOnAirPushSubscription pushSubscription;

  /// The AppsOnAir-assigned device ID.
  Future<String?> get appsonairId => _platform.getDeviceId();

  Future<String?> get externalId => _platform.userGetExternalId();

  Future<void> addTagWithKey(String key, dynamic value) =>
      _platform.addTag(key, value.toString());

  Future<void> addTags(Map<String, String> tags) => _platform.addTags(tags);

  Future<void> removeTag(String key) => _platform.removeTag(key);

  Future<void> removeTags(List<String> keys) => _platform.removeTags(keys);

  Future<Map<String, String>> getTags() => _platform.getTags();

  Future<void> setLanguage(String code) => _platform.setLanguage(code);

  Future<String> get language => _platform.getLanguage();

  Future<void> addAlias(String label, String id) =>
      _platform.addAlias(label, id);

  Future<void> addAliases(Map<String, String> aliases) =>
      _platform.addAliases(aliases);

  Future<void> removeAlias(String label) => _platform.removeAlias(label);

  Future<void> removeAliases(List<String> labels) =>
      _platform.removeAliases(labels);

  Future<void> addEmail(String address) => _platform.addEmail(address);

  Future<void> removeEmail(String address) => _platform.removeEmail(address);

  void addObserver(UserStateListener observer) => _observers.add(observer);

  void removeObserver(UserStateListener observer) =>
      _observers.remove(observer);

  void dispatch(UserChangedState state) {
    for (final observer in List.of(_observers)) {
      observer(state);
    }
  }
}
