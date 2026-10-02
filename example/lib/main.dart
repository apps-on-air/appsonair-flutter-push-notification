import 'package:appsonair_flutter_apppush/appsonair_flutter_apppush.dart';
import 'package:flutter/material.dart';

// Declare your AppsOnAir app ID in the platform manifests, not in code:
// - Android: AppsonairAppId meta-data in AndroidManifest.xml
// - iOS: AppsonairAppId entry in Info.plist

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
    // Set log level before initialize() so early SDK messages are captured.
    await AppPushService.Debug.setLogLevel(LogLevel.verbose);

    // Register the silent push listener BEFORE initialize() so pushes that
    // wake the app in the background are not missed.
    AppPushService.setSilentPushListener((data) {
      _appendLog('Silent push received: $data');
    });

    // swizzle: false is required for Flutter — the manual AppDelegate overrides
    // in ios/Runner/AppDelegate.swift handle APNs callbacks instead.
    await AppPushService.initialize(swizzle: false);

    // Observe push-subscription state changes (token, opt-in).
    AppPushService.User.pushSubscription.addObserver((state) {
      _appendLog('Subscription changed — token: ${state.current.token}');
    });

    // Observe user identity changes (login / logout).
    AppPushService.User.addObserver((state) {
      _appendLog(
        'User changed — externalId: ${state.externalId ?? '(anonymous)'}',
      );
    });

    // Control foreground display: call event.preventDefault() to suppress.
    AppPushService.Notifications.addForegroundWillDisplayListener((event) {
      _appendLog('Will display: ${event.notification.title}');
      // event.preventDefault(); // uncomment to suppress the system banner
    });

    // Observe notification taps and action button taps.
    AppPushService.Notifications.addClickListener((event) {
      _appendLog(
        'Tapped: ${event.notification.title} (action: ${event.actionId ?? 'body'})',
      );
    });

    // Observe runtime permission changes.
    AppPushService.Notifications.addPermissionObserver((granted) {
      _appendLog('Permission: $granted');
    });

    final deviceId = await AppPushService.User.appsonairId;
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
              const SizedBox(height: 4),
              Text('Tags: $_tags'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
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
                      _appendLog('Tag added: favorite_color=blue');
                    },
                    child: const Text('Add tag'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      await AppPushService.User.removeTag('favorite_color');
                      final tags = await AppPushService.User.getTags();
                      setState(() => _tags = tags);
                      _appendLog('Tag removed: favorite_color');
                    },
                    child: const Text('Remove tag'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      AppPushService.login('demo-user-123');
                      _appendLog('login(demo-user-123)');
                    },
                    child: const Text('Login'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      AppPushService.logout();
                      _appendLog('logout()');
                    },
                    child: const Text('Logout'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      AppPushService.User.addAlias('crm_id', 'CRM-9876');
                      _appendLog('addAlias(crm_id, CRM-9876)');
                    },
                    child: const Text('Add alias'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      AppPushService.User.addEmail('user@example.com');
                      _appendLog('addEmail(user@example.com)');
                    },
                    child: const Text('Add email'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      AppPushService.User.removeEmail('user@example.com');
                      _appendLog('removeEmail(user@example.com)');
                    },
                    child: const Text('Remove email'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      AppPushService.User.pushSubscription.optOut();
                      _appendLog('optOut()');
                    },
                    child: const Text('Opt out'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      AppPushService.User.pushSubscription.optIn();
                      _appendLog('optIn()');
                    },
                    child: const Text('Opt in'),
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
