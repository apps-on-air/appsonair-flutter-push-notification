import 'package:appsonair_flutter_push_notification/appsonair_flutter_push_notification_method_channel.dart';
import 'package:appsonair_flutter_push_notification/appsonair_flutter_push_notification_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final AppsonairFlutterPushNotificationPlatform initialPlatform =
      AppsonairFlutterPushNotificationPlatform.instance;

  test(
    '$MethodChannelAppsonairFlutterPushNotification is the default instance',
    () {
      expect(
        initialPlatform,
        isInstanceOf<MethodChannelAppsonairFlutterPushNotification>(),
      );
    },
  );
}
