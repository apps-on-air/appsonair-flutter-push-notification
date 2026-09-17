// This is a basic Flutter integration test.
//
// Since integration tests run in a full Flutter application, they can interact
// with the host side of a plugin implementation, unlike Dart unit tests.
//
// For more information about Flutter integration tests, please see
// https://flutter.dev/to/integration-testing

import 'package:appsonair_flutter_apppush/appsonair_flutter_apppush.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('getDeviceId returns a non-empty id after initialize', (
    WidgetTester tester,
  ) async {
    await AppPushService.initialize(
      appId: 'integration-test-app-id',
      debug: true,
    );
    final String? deviceId = await AppPushService.User.appsonairId;
    expect(deviceId?.isNotEmpty, true);
  });
}
