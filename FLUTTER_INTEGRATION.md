# AppsOnAir Flutter Push Notification — Integration Guide

This guide covers the core integration steps for the `appsonair_flutter_apppush` plugin: initialization, notification permission, tagging, and user login/logout.

## Prerequisites

Before calling any API, configure the native app ID:

- **Android**: add the `AppsonairAppId` meta-data entry to `AndroidManifest.xml`.
- **iOS**: add the `AppsonairAppId` entry to `Info.plist`.

The SDK reads the app ID from native configuration — the `appId` parameter on `initialize` is kept only for source compatibility and is ignored.

## 1. Initialization

Call `AppPushService.initialize()` once, as early as possible — typically in `main()` before `runApp()`.

```dart
import 'package:appsonair_flutter_apppush/appsonair_flutter_apppush.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppPushService.initialize();

  runApp(const MyApp());
}
```

### Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `appId` | `String` | `''` | Deprecated, ignored. App ID comes from native manifest/plist config. |
| `debug` | `bool` | `false` | Deprecated shortcut for `Debug.setLogLevel(LogLevel.debug)`. |
| `swizzle` | `bool` | `true` | iOS only — enables automatic method swizzling for push callbacks. |

### Optional: consent gating

If your app requires explicit user consent before any data collection, set this up **before** calling `initialize`:

```dart
await AppPushService.setConsentRequired(true);
await AppPushService.initialize();

// Later, once the user consents:
await AppPushService.setConsentGiven(true);
```

### Optional: logging

```dart
await AppPushService.Debug.setLogLevel(LogLevel.debug);
```

## 2. Notification Permission

Permission APIs live under `AppPushService.Notifications`.

### Check current permission state

```dart
final bool granted = await AppPushService.Notifications.permission;
```

### Check whether the permission dialog can be shown

Returns `false` if the user has permanently denied permission (e.g. Android 13+ after a denial), in which case requesting again will no-op.

```dart
final bool canRequest =
    await AppPushService.Notifications.canRequestPermission;
```

### Request permission

```dart
await AppPushService.Notifications.requestPermission();
```

If permission was previously denied, you can fall back to deep-linking into the app's system Settings page instead of showing a dialog that would no-op:

```dart
await AppPushService.Notifications.requestPermission(
  fallbackToSettings: true,
);
```

### iOS provisional authorization (optional)

Delivers notifications silently to Notification Center without a system prompt. No-op on Android.

```dart
await AppPushService.Notifications.registerForProvisionalAuthorization();
```

### Observe permission changes

```dart
void onPermissionChanged(bool granted) {
  debugPrint('Notification permission granted: $granted');
}

AppPushService.Notifications.addPermissionObserver(onPermissionChanged);

// When no longer needed:
AppPushService.Notifications.removePermissionObserver(onPermissionChanged);
```

## 3. Tags

Tags are used for audience segmentation. Tag APIs live under `AppPushService.User`.

### Add a single tag

```dart
await AppPushService.User.addTagWithKey('plan', 'premium');
```

### Add multiple tags

```dart
await AppPushService.User.addTags({
  'plan': 'premium',
  'signup_cohort': '2026-q1',
});
```

### Remove a single tag

```dart
await AppPushService.User.removeTag('plan');
```

### Remove multiple tags

```dart
await AppPushService.User.removeTags(['plan', 'signup_cohort']);
```

### Fetch current tags

```dart
final Map<String, String> tags = await AppPushService.User.getTags();
```

## 4. Login / Logout

Associate or clear the identity of the device's current user. Tags, aliases, and identity are cleared on logout — the device reverts to anonymous.

### Login

Call after a successful sign-in, passing your backend's external user identifier.

```dart
await AppPushService.login(userId);
```

### Logout

Call on sign-out.

```dart
await AppPushService.logout();
```

### Observe login/logout changes

```dart
void onUserChanged(UserChangedState state) {
  debugPrint('User changed: $state');
}

AppPushService.User.addObserver(onUserChanged);

// When no longer needed:
AppPushService.User.removeObserver(onUserChanged);
```

## Full Example

```dart
import 'package:appsonair_flutter_apppush/appsonair_flutter_apppush.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppPushService.initialize();

  // Ask for notification permission.
  final canRequest = await AppPushService.Notifications.canRequestPermission;
  if (canRequest) {
    await AppPushService.Notifications.requestPermission();
  }

  runApp(const MyApp());
}

class LoginController {
  Future<void> signIn(String userId) async {
    await AppPushService.login(userId);
    await AppPushService.User.addTags({'plan': 'free'});
  }

  Future<void> signOut() async {
    await AppPushService.logout();
  }
}
```

## Reference

| Area | API |
|---|---|
| Initialize | `AppPushService.initialize()` |
| Permission — check | `AppPushService.Notifications.permission` |
| Permission — can request | `AppPushService.Notifications.canRequestPermission` |
| Permission — request | `AppPushService.Notifications.requestPermission({fallbackToSettings})` |
| Permission — observe | `AppPushService.Notifications.addPermissionObserver()` / `removePermissionObserver()` |
| Add tag | `AppPushService.User.addTagWithKey(key, value)` |
| Add tags | `AppPushService.User.addTags(Map<String, String>)` |
| Remove tag | `AppPushService.User.removeTag(key)` |
| Remove tags | `AppPushService.User.removeTags(List<String>)` |
| Get tags | `AppPushService.User.getTags()` |
| Login | `AppPushService.login(externalId)` |
| Logout | `AppPushService.logout()` |
