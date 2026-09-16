import '../appsonair_flutter_apppush_platform_interface.dart';
import 'models.dart';

/// `AppPushService.Debug` — logging configuration.
class AppsOnAirDebugManager {
  /// Not for public use — access via `AppPushService.Debug`.
  AppsOnAirDebugManager(this._platform);

  final AppsonairFlutterAppPushPlatform _platform;

  /// Set the SDK's logging verbosity. Default is [LogLevel.none].
  Future<void> setLogLevel(LogLevel level) =>
      _platform.setLogLevel(level.wireValue);

  /// The SDK's current logging verbosity.
  Future<LogLevel> get logLevel async =>
      LogLevel.fromWire(await _platform.getLogLevel());
}
