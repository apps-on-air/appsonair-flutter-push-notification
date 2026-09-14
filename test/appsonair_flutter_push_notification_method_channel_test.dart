import 'package:appsonair_flutter_push_notification/appsonair_flutter_push_notification_method_channel.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final platform = MethodChannelAppsonairFlutterPushNotification();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(platform.methodChannel, (
          MethodCall methodCall,
        ) async {
          switch (methodCall.method) {
            case 'getDeviceId':
              return 'test-device-id';
            case 'isPermissionGranted':
              return true;
            default:
              return null;
          }
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(platform.methodChannel, null);
  });

  test('getDeviceId', () async {
    expect(await platform.getDeviceId(), 'test-device-id');
  });

  test('isPermissionGranted', () async {
    expect(await platform.isPermissionGranted(), true);
  });
}
