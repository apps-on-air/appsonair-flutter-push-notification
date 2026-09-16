import 'package:appsonair_flutter_apppush/appsonair_flutter_apppush_method_channel.dart';
import 'package:appsonair_flutter_apppush/appsonair_flutter_apppush_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final AppsonairFlutterAppPushPlatform initialPlatform =
      AppsonairFlutterAppPushPlatform.instance;

  test(
    '$MethodChannelAppsonairFlutterAppPush is the default instance',
    () {
      expect(
        initialPlatform,
        isInstanceOf<MethodChannelAppsonairFlutterAppPush>(),
      );
    },
  );
}
