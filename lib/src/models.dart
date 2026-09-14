/// Data and event models shared by the AppsOnAir push Dart API.
library;

/// SDK error codes. Not every code is possible on every platform — see the
/// doc comment on each value.
enum PushErrorCode {
  /// [AppsOnAirPush.initialize] was not called before an API that requires it.
  notInitialized,

  /// The user denied (or the OS blocked) the notification permission request.
  permissionDenied,

  /// Android only — fetching the FCM token failed.
  tokenFetchFailed,

  /// Android only — fetching the Firebase Installation ID failed.
  installationIdFetchFailed,

  /// iOS only — APNs device-token registration failed.
  apnsRegistrationFailed,

  /// Any other/unrecognized native error code.
  unknown;

  /// Parses the wire-format string sent by the native side, falling back to
  /// [unknown] for anything unrecognized.
  static PushErrorCode fromWire(String? value) {
    switch (value) {
      case 'notInitialized':
        return PushErrorCode.notInitialized;
      case 'permissionDenied':
        return PushErrorCode.permissionDenied;
      case 'tokenFetchFailed':
        return PushErrorCode.tokenFetchFailed;
      case 'installationIdFetchFailed':
        return PushErrorCode.installationIdFetchFailed;
      case 'apnsRegistrationFailed':
        return PushErrorCode.apnsRegistrationFailed;
      default:
        return PushErrorCode.unknown;
    }
  }
}

/// An SDK error reported via `AppsOnAirPush.addErrorListener`.
class PushError {
  /// Creates a push error with the given [code] and [message].
  const PushError({required this.code, required this.message});

  /// The error's category — see [PushErrorCode].
  final PushErrorCode code;

  /// A human-readable description of the error.
  final String message;

  @override
  String toString() => 'PushError($code, $message)';
}

/// Logging verbosity for `AppsOnAirDebugManager.logLevel`.
enum LogLevel {
  /// No logging. The default, and recommended for production.
  none,

  /// Only fatal errors.
  fatal,

  /// Errors and above.
  error,

  /// Warnings and above.
  warn,

  /// Informational messages and above.
  info,

  /// Debug messages and above.
  debug,

  /// Every log message. Recommended during development only.
  verbose;

  /// The wire-format string sent to the native side.
  String get wireValue => name;

  /// Parses the wire-format string sent by the native side, falling back to
  /// [none] for anything unrecognized.
  static LogLevel fromWire(String? value) {
    return LogLevel.values.firstWhere(
      (l) => l.name == value,
      orElse: () => LogLevel.none,
    );
  }
}

/// Data carried by a received or tapped push notification.
///
/// [data] is the full payload map. On Android every value arrives as a
/// [String] (FCM data payloads are string-only); on iOS values keep their
/// original APNs payload types.
class PushNotification {
  /// Creates a push notification from its individual fields.
  const PushNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.data,
  });

  /// Parses a push notification from the raw map sent by the native side.
  factory PushNotification.fromMap(Map<Object?, Object?> map) {
    final rawData = map['data'];
    return PushNotification(
      id: map['id'] as String?,
      title: map['title'] as String?,
      body: map['body'] as String?,
      data: rawData is Map
          ? rawData.map((k, v) => MapEntry(k.toString(), v))
          : const <String, dynamic>{},
    );
  }

  /// Value of `notification_id` from the push payload. Null if not present.
  final String? id;

  /// Pre-translated notification title, if present.
  final String? title;

  /// Pre-translated notification body, if present.
  final String? body;

  /// The full payload map.
  final Map<String, dynamic> data;

  @override
  String toString() => 'PushNotification(id: $id, title: $title, body: $body)';
}

/// Fired for a notification that arrives while the app is in the foreground.
/// Call [preventDefault] synchronously inside your listener to suppress the
/// system notification display; otherwise it is shown automatically.
class NotificationWillDisplayEvent {
  /// Not for public use — constructed internally when bridging the native event.
  NotificationWillDisplayEvent.internal(
    this.notification,
    this._eventId,
    this._complete,
  );

  /// The notification about to be displayed.
  final PushNotification notification;
  final String _eventId;
  final void Function(String eventId, bool discard) _complete;
  bool _resolved = false;

  /// Suppress the system notification display for this event.
  void preventDefault() {
    if (_resolved) return;
    _resolved = true;
    _complete(_eventId, true);
  }
}

/// Fired when the user taps a notification or one of its action buttons.
class NotificationClickEvent {
  /// Creates a click event from its individual fields.
  const NotificationClickEvent({
    required this.notification,
    required this.actionId,
  });

  /// Parses a click event from the raw map sent by the native side.
  factory NotificationClickEvent.fromMap(Map<Object?, Object?> map) {
    return NotificationClickEvent(
      notification: PushNotification.fromMap(
        (map['notification'] as Map?)?.cast<Object?, Object?>() ?? const {},
      ),
      actionId: map['actionId'] as String?,
    );
  }

  /// The notification that was tapped.
  final PushNotification notification;

  /// Null when the notification body was tapped; non-null for a specific
  /// action button identifier.
  final String? actionId;
}

/// Snapshot of the device's push subscription state.
class PushSubscriptionState {
  /// Creates a subscription state snapshot from its individual fields.
  const PushSubscriptionState({required this.token, required this.isOptedIn});

  /// Parses a subscription state snapshot from the raw map sent by the native side.
  factory PushSubscriptionState.fromMap(Map<Object?, Object?> map) {
    return PushSubscriptionState(
      token: map['token'] as String?,
      isOptedIn: map['isOptedIn'] as bool? ?? false,
    );
  }

  /// FCM token (Android) or hex APNs token (iOS). Null until registered.
  final String? token;

  /// Whether the device is currently opted in to receive pushes.
  final bool isOptedIn;
}

/// Before/after pair delivered to push-subscription observers.
class PushSubscriptionChangedState {
  /// Creates a before/after pair from its individual fields.
  const PushSubscriptionChangedState({
    required this.previous,
    required this.current,
  });

  /// Parses a before/after pair from the raw map sent by the native side.
  factory PushSubscriptionChangedState.fromMap(Map<Object?, Object?> map) {
    return PushSubscriptionChangedState(
      previous: PushSubscriptionState.fromMap(
        (map['previous'] as Map?)?.cast<Object?, Object?>() ?? const {},
      ),
      current: PushSubscriptionState.fromMap(
        (map['current'] as Map?)?.cast<Object?, Object?>() ?? const {},
      ),
    );
  }

  /// The subscription state before the change.
  final PushSubscriptionState previous;

  /// The subscription state after the change.
  final PushSubscriptionState current;
}

/// Delivered to user-state observers after [AppsOnAirPush.login]/`.logout()`.
class UserChangedState {
  /// Creates a user-state change from its individual fields.
  const UserChangedState({required this.externalId, required this.appsonairId});

  /// Parses a user-state change from the raw map sent by the native side.
  factory UserChangedState.fromMap(Map<Object?, Object?> map) {
    return UserChangedState(
      externalId: map['externalId'] as String?,
      appsonairId: map['appsonairId'] as String? ?? '',
    );
  }

  /// The external identifier set by `AppsOnAirPush.login`, `null` when anonymous.
  final String? externalId;

  /// The AppsOnAir-assigned device ID.
  final String appsonairId;
}

/// Signature for `AppsOnAirPush.addTokenListener`.
typedef PushTokenListener =
    void Function(String token, String? apnsEnvironment);

/// Signature for `AppsOnAirPush.addNotificationReceivedListener` and
/// `AppsOnAirPush.addNotificationOpenedListener`.
typedef PushNotificationListener = void Function(PushNotification notification);

/// Signature for `AppsOnAirNotificationsManager.addForegroundWillDisplayListener`.
typedef NotificationWillDisplayListener =
    void Function(NotificationWillDisplayEvent event);

/// Signature for `AppsOnAirNotificationsManager.addClickListener`.
typedef NotificationClickListener = void Function(NotificationClickEvent event);

/// Signature for `AppsOnAirNotificationsManager.addPermissionObserver`.
typedef NotificationPermissionListener = void Function(bool granted);

/// Signature for `AppsOnAirPushSubscription.addObserver`.
typedef PushSubscriptionListener =
    void Function(PushSubscriptionChangedState state);

/// Signature for `AppsOnAirUserManager.addObserver`.
typedef UserStateListener = void Function(UserChangedState state);

/// Signature for `AppsOnAirPush.addErrorListener`.
typedef PushErrorListener = void Function(PushError error);
