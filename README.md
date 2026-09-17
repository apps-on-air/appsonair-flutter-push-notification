# AppsOnAir-Flutter-AppPush

A Flutter plugin wrapping the native AppsOnAir Push Notification SDKs (Android/iOS) — device
registration, rich notifications, taps/actions, tags, aliases, opt-in/opt-out, and more, behind
one Dart API.

> [!WARNING]
> **Alpha release — not for production use.**
>
> `0.0.3-alpha` is an early preview, intended for evaluation, prototypes, and internal test
> builds. Do **not** ship it in a production app or one with a large user base.
>
> - The public API may change without notice and may not stay source-compatible — expect to
>   update your integration between releases.
> - Breaking changes are not limited to major versions while the SDK is pre-1.0.
> - Not yet proven at scale; some behaviour is still unverified in real-world use.
>
> Pin this exact version rather than a version range, and re-test on every upgrade.

## Features Overview

- Notification Taps & Actions 📬
> Listen for when the user taps a notification, including any tapped action button.

- Foreground Display Control 🖥️
> Decide whether a notification received while the app is in the foreground is shown by the
  system, or suppressed so you can handle it yourself.

- Identity & Tags 🏷️
> Associate the device with a signed-in user (`login`/`logout`), and segment your audience with
  key/value tags, aliases, and email addresses.

- Opt-in / Opt-out 🔕
> Pause or resume delivery to a device without touching OS-level notification permission.

- Consent (GDPR) ✅
> Gate all data collection on explicit user consent.

- Permission Handling 🔔
> Check and request the notification permission, including a fallback to the system Settings
  page when it has been permanently denied.

- Notification Management 🗑️
> Clear all delivered notifications, remove a single one by ID, or (Android) remove a group.

- Debug Logging 🐞
> Configure the SDK's logging verbosity for local development.

#### To learn more about AppsOnAir Push, please visit the [AppsOnAir](https://documentation.appsonair.com) website

## Android Setup

### Minimum Requirements

- Android: API 24 (7.0) or higher
- Kotlin: Version 2.2.20 or higher
- Gradle: Version 8.0 or higher
- Firebase: `google-services.json` (the SDK uses Firebase Cloud Messaging)

Add meta-data to the app's `AndroidManifest.xml` file under the `application` tag.

>Make sure meta-data name is “AppsonairAppId”.

>Provide your application id in meta-data value.

```xml
<application>
    ...
    <meta-data
        android:name="AppsonairAppId"
        android:value="********-****-****-****-************" />
</application>
```

Add the notification icon/color used by Firebase Cloud Messaging (optional, but recommended so
notifications don't fall back to your launcher icon):

```xml
<application>
    ...
    <meta-data
        android:name="com.google.firebase.messaging.default_notification_icon"
        android:resource="@drawable/ic_notification" />
    <meta-data
        android:name="com.google.firebase.messaging.default_notification_color"
        android:resource="@color/notification_accent" />
</application>
```

Add below code to `settings.gradle.kts` (needed to resolve the native Push SDK, and its own
dependency AppsOnAir Core, from JitPack):

```kotlin
pluginManagement {
    ……
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
        maven("https://jitpack.io")
    }
}
```

Add below code to your root level `build.gradle.kts`:

```kotlin
allprojects {
    repositories {
        google()
        mavenCentral()
        maven("https://jitpack.io")
    }
}
```

Apply the Google Services plugin (required by Firebase Cloud Messaging), in your root
`build.gradle.kts`:

```kotlin
plugins {
    id("com.google.gms.google-services") version "4.4.2" apply false
}
```

and your app-level `build.gradle.kts`:

```kotlin
plugins {
    id("com.google.gms.google-services")
}
```

## iOS Setup

### Minimum Requirements

iOS deployment target: 15.0

Provide your application id in your app `Info.plist` file.

```xml
<key>AppsonairAppId</key>
<string>XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX</string>
```

If `CFBundleDisplayName` is not added in your app then add it in your app `Info.plist` file.

```xml
<key>CFBundleDisplayName</key>
<string>YourAppName</string>
```

In Xcode, enable the **Push Notifications** capability
(Target → **Signing & Capabilities → + Capability → Push Notifications**) and, if you want
background delivery of data-only pushes, **Background Modes → Background fetch**.

> APNs tokens are not available on the iOS Simulator — test push registration on a real device.

---

### iOS Dependency Manager

This plugin supports **both CocoaPods and Swift Package Manager (SPM)**. SPM support requires
**Flutter 3.24.0 or higher**.

By default, CocoaPods is used. You can control which dependency manager your project uses by
adding the following to your app's `pubspec.yaml`:

#### Option 1 — CocoaPods (default)

No extra steps needed. Run:

```sh
flutter pub get
cd ios && pod install
```

#### Option 2 — Swift Package Manager

> Requires **Flutter ≥ 3.24.0**.

SPM support is opt-in and configured through Flutter's `flutter config` toggle for Swift Package
Manager (see the [Flutter SPM documentation](https://docs.flutter.dev/packages-and-plugins/swift-package-manager/for-plugin-authors)
for how to enable/disable it). Once enabled, `flutter pub get` resolves `AppsOnAir-AppPush` via
SPM from GitHub automatically — no Podfile or additional Xcode configuration required.

#### Summary

| Flutter SPM config | Flutter version | Result |
|:---:|:---:|:---|
| disabled (default) | any | **CocoaPods** |
| enabled | ≥ 3.24.0 | **Swift Package Manager** |

> 💡 **Recommendation:** We recommend migrating to **Swift Package Manager** — it is Apple's
> official, actively maintained dependency manager and receives updates first.

---

## Example

Initialize the SDK once, as early as possible. Call `runApp` **before** `initialize` to avoid
a white screen if the channel is not ready yet:

```dart
import 'package:appsonair_flutter_apppush/appsonair_flutter_apppush.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
  await AppPushService.initialize();
}
```

Alternatively, initialize inside your root widget's `initState`:

```dart
@override
void initState() {
  super.initState();
  AppPushService.initialize();
}
```

`initialize()` reads the app ID from the `AppsonairAppId` manifest meta-data (Android) /
Info.plist entry (iOS) declared above — no need to pass it from Dart.

### Listening for events

```dart
AppPushService.User.pushSubscription.addObserver((state) {
  // FCM token (Android) or hex APNs token (iOS), and opt-in state.
  print('Token: ${state.current.token}, optedIn: ${state.current.isOptedIn}');
});

AppPushService.Notifications.addClickListener((event) {
  print('Opened: ${event.notification.title}');
});
```

### Requesting notification permission

```dart
final granted = await AppPushService.Notifications.permission;
if (!granted) {
  await AppPushService.Notifications.requestPermission();
}

// Permanently denied? Send the user to Settings instead:
await AppPushService.Notifications.requestPermission(fallbackToSettings: true);
```

### Controlling foreground display

```dart
AppPushService.Notifications.addForegroundWillDisplayListener((event) {
  // Do nothing → the SDK shows it.
  // Call preventDefault() → suppressed entirely, handle it yourself.
  event.preventDefault();
});
```

### Handling taps and action buttons

```dart
AppPushService.Notifications.addClickListener((event) {
  final actionId = event.actionId; // null = body tap, else the tapped action's ID
  print('Tapped ${event.notification.title}, action: $actionId');
});
```

### Identity, tags, aliases, and email

```dart
await AppPushService.login('user_12345');
await AppPushService.logout();

await AppPushService.User.addTagWithKey('plan', 'premium');
await AppPushService.User.addTags({'plan': 'premium', 'region': 'us'});
await AppPushService.User.removeTag('plan');
final tags = await AppPushService.User.getTags();

await AppPushService.User.addAlias('crm_id', 'CRM-9876');
await AppPushService.User.addEmail('user@example.com');

await AppPushService.User.setLanguage('fr');
```

### Opt-in / opt-out

```dart
await AppPushService.User.pushSubscription.optOut();
await AppPushService.User.pushSubscription.optIn();
final optedIn = await AppPushService.User.pushSubscription.isOptedIn;
```

### Consent (GDPR)

```dart
await AppPushService.setConsentRequired(true);
await AppPushService.initialize();

await AppPushService.setConsentGiven(true);  // user accepted
await AppPushService.setConsentGiven(false); // user withdrew
```

### Managing delivered notifications

```dart
await AppPushService.Notifications.clearAll();
await AppPushService.Notifications.removeNotification('order-4821');
await AppPushService.Notifications.removeGroupedNotifications('orders'); // Android only
```

### Debug logging

```dart
await AppPushService.Debug.setLogLevel(LogLevel.verbose);
await AppPushService.initialize();
```
