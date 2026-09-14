import '../appsonair_flutter_push_notification_platform_interface.dart';
import 'models.dart';

/// `AppsOnAirPush.Debug` — logging configuration.
class AppsOnAirDebugManager {
  AppsOnAirDebugManager(this._platform);

  final AppsonairFlutterPushNotificationPlatform _platform;

  /// Set the SDK's logging verbosity. Default is [LogLevel.none].
  Future<void> setLogLevel(LogLevel level) =>
      _platform.setLogLevel(level.wireValue);

  Future<LogLevel> get logLevel async =>
      LogLevel.fromWire(await _platform.getLogLevel());
}
