import '../appsonair_flutter_push_notification_platform_interface.dart';
import 'models.dart';

/// `AppsOnAirUserManager.pushSubscription` — opt-in/opt-out and the device's
/// current push token.
class AppsOnAirPushSubscription {
  /// Not for public use — access via `AppPushService.User.pushSubscription`.
  AppsOnAirPushSubscription(this._platform);

  final AppsonairFlutterPushNotificationPlatform _platform;
  final List<PushSubscriptionListener> _observers = [];

  /// Whether the device is currently opted in to receive pushes.
  Future<bool> get isOptedIn => _platform.pushSubscriptionIsOptedIn();

  /// FCM token (Android) or hex APNs token (iOS). Null until registered.
  Future<String?> get token => _platform.pushSubscriptionGetToken();

  /// Resumes push delivery to this device.
  Future<void> optIn() => _platform.pushSubscriptionOptIn();

  /// Pauses push delivery to this device without touching OS-level permission.
  Future<void> optOut() => _platform.pushSubscriptionOptOut();

  /// Observe changes to the subscription's opt-in state or token.
  void addObserver(PushSubscriptionListener observer) =>
      _observers.add(observer);

  /// Removes an observer added with [addObserver].
  void removeObserver(PushSubscriptionListener observer) =>
      _observers.remove(observer);

  /// Not for public use — invoked internally to fan out a native
  /// subscription change to registered observers.
  void dispatch(PushSubscriptionChangedState state) {
    for (final observer in List.of(_observers)) {
      observer(state);
    }
  }
}

/// `AppPushService.User` — identity, tags, aliases, email, language.
class AppsOnAirUserManager {
  /// Not for public use — access via `AppPushService.User`.
  AppsOnAirUserManager(this._platform)
      : pushSubscription = AppsOnAirPushSubscription(_platform);

  final AppsonairFlutterPushNotificationPlatform _platform;
  final List<UserStateListener> _observers = [];

  /// Opt-in/opt-out and the device's current push token.
  final AppsOnAirPushSubscription pushSubscription;

  /// The AppsOnAir-assigned device ID.
  Future<String?> get appsonairId => _platform.getDeviceId();

  /// Set by `AppPushService.login`, `null` when anonymous.
  Future<String?> get externalId => _platform.userGetExternalId();

  /// Adds or updates a single key/value tag for audience segmentation.
  Future<void> addTagWithKey(String key, dynamic value) =>
      _platform.addTag(key, value.toString());

  /// Adds or updates multiple tags at once.
  Future<void> addTags(Map<String, String> tags) => _platform.addTags(tags);

  /// Removes a single tag by key.
  Future<void> removeTag(String key) => _platform.removeTag(key);

  /// Removes multiple tags by key.
  Future<void> removeTags(List<String> keys) => _platform.removeTags(keys);

  /// Fetches the backend's copy of this device's tags.
  Future<Map<String, String>> getTags() => _platform.getTags();

  /// Overrides the device language used for server-side notification
  /// translation (e.g. `"fr"`, `"en-US"`).
  Future<void> setLanguage(String code) => _platform.setLanguage(code);

  /// The current language override, or the detected device language.
  Future<String> get language => _platform.getLanguage();

  /// Associates an external identifier alias (e.g. a CRM ID) with this device.
  Future<void> addAlias(String label, String id) =>
      _platform.addAlias(label, id);

  /// Associates multiple external identifier aliases at once.
  Future<void> addAliases(Map<String, String> aliases) =>
      _platform.addAliases(aliases);

  /// Removes an alias by label.
  Future<void> removeAlias(String label) => _platform.removeAlias(label);

  /// Removes multiple aliases by label.
  Future<void> removeAliases(List<String> labels) =>
      _platform.removeAliases(labels);

  /// Adds an email channel for this device.
  Future<void> addEmail(String address) => _platform.addEmail(address);

  /// Removes an email channel from this device.
  Future<void> removeEmail(String address) => _platform.removeEmail(address);

  /// Observe `login`/`logout` changes.
  void addObserver(UserStateListener observer) => _observers.add(observer);

  /// Removes an observer added with [addObserver].
  void removeObserver(UserStateListener observer) =>
      _observers.remove(observer);

  /// Not for public use — invoked internally to fan out a native user-state
  /// change to registered observers.
  void dispatch(UserChangedState state) {
    for (final observer in List.of(_observers)) {
      observer(state);
    }
  }
}
