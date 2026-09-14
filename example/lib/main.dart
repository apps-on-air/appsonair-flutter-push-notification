import 'package:appsonair_flutter_push_notification/appsonair_flutter_push_notification.dart';
import 'package:flutter/material.dart';

// - Android: AppsonairAppId meta-data in AndroidManifest.xml
// - iOS: AppsonairAppId entry in Info.plist

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String? _deviceId;
  Map<String, String> _tags = {};
  final List<String> _log = [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await AppPushService.Debug.setLogLevel(LogLevel.verbose);
    await AppPushService.initialize(debug: true);

    AppPushService.addTokenListener((token, environment) {
      _appendLog(
        'Token updated: $token${environment != null ? ' ($environment)' : ''}',
      );
    });
    AppPushService.addErrorListener((error) {
      _appendLog('Error: ${error.code} — ${error.message}');
    });
    AppPushService.Notifications.addForegroundWillDisplayListener((event) {
      _appendLog('Notification will display: ${event.notification.title}');
    });
    AppPushService.Notifications.addClickListener((event) {
      _appendLog(
        'Notification clicked: ${event.notification.title} (action: ${event.actionId})',
      );
    });

    final deviceId = await AppPushService.deviceId;
    final tags = await AppPushService.User.getTags();
    if (!mounted) return;
    setState(() {
      _deviceId = deviceId;
      _tags = tags;
    });
  }

  void _appendLog(String message) {
    if (!mounted) return;
    setState(() => _log.insert(0, message));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('AppsOnAir Push example')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Device ID: ${_deviceId ?? '(loading…)'}'),
              const SizedBox(height: 8),
              Text('Tags: $_tags'),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: [
                  ElevatedButton(
                    onPressed: () =>
                        AppPushService.Notifications.requestPermission(),
                    child: const Text('Request permission'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      await AppPushService.User.addTagWithKey(
                        'favorite_color',
                        'blue',
                      );
                      final tags = await AppPushService.User.getTags();
                      setState(() => _tags = tags);
                    },
                    child: const Text('Add tag'),
                  ),
                  ElevatedButton(
                    onPressed: () => AppPushService.login('demo-user-123'),
                    child: const Text('Login'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Event log:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Expanded(child: ListView(children: _log.map(Text.new).toList())),
            ],
          ),
        ),
      ),
    );
  }
}
