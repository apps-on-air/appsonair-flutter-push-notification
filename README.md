# AppsOnAir-Flutter-PushNotification

A Flutter plugin wrapping the native AppsOnAir Push Notification SDKs (Android/iOS) — device
registration, rich notifications, taps/actions, tags, aliases, opt-in/opt-out, and more, behind
one Dart API.

## Features Overview

- Push Token 📮
> Get notified whenever the FCM token (Android) or APNs device token (iOS) is issued or refreshed.

- Notification Received & Opened 📬
> Listen for notifications as they arrive and when the user taps them, including any tapped
  action button.

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

Use this if you want to always use CocoaPods regardless of any global Flutter setting:

```yaml
# pubspec.yaml
flutter:
  config:
    # false → always uses CocoaPods (default)
    enable-swift-package-manager: false
```

No other steps needed. Run:

```sh
flutter pub get
cd ios && pod install
```

#### Option 2 — Swift Package Manager

> Requires **Flutter ≥ 3.24.0**. SPM support on iOS is available starting from this version.

Use this to opt into SPM and use `AppsOnAirPush` via Swift Package Manager:

```yaml
# pubspec.yaml
flutter:
  config:
    # true → uses Swift Package Manager
    enable-swift-package-manager: true
```

Then run:

```sh
flutter pub get
```

Flutter will automatically resolve `AppsOnAirPush` via SPM. No additional Xcode configuration is
required.

> **Note:** You can also enable SPM globally for all your Flutter projects (instead of
> per-project) by running:
> ```sh
> flutter config --enable-swift-package-manager
> ```
> In that case, you can remove the `config` block from `pubspec.yaml` entirely and Flutter will
> use SPM automatically.

#### Summary

| `enable-swift-package-manager` | Flutter version | Result |
|:---:|:---:|:---|
| `false` | any | **CocoaPods** — uses `AppsOnAirPush` |
| `true` | ≥ 3.24.0 | **SPM** — uses `AppsOnAirPush` |
| not set | any (global off) | **CocoaPods** — default behaviour |
| not set | ≥ 3.24.0 (global on) | **SPM** — Flutter global setting applies |

> 💡 **Recommendation:** We recommend migrating to **Swift Package Manager** — it is Apple's
> official, actively maintained dependency manager and receives updates first.

---

## Example

Initialize the SDK once, as early as possible (`main()` or your root widget's `initState`):

```dart
import 'package:appsonair_flutter_push_notification/appsonair_flutter_push_notification.dart';

@override
void initState() {
  super.initState();
  AppsOnAirPush.initialize();
}
```

`initialize()` reads the app ID from the `AppsonairAppId` manifest meta-data (Android) /
Info.plist entry (iOS) declared above — no need to pass it from Dart.

### Listening for events

```dart
AppsOnAirPush.addTokenListener((token, apnsEnvironment) {
  // Android: FCM token, apnsEnvironment is always null.
  // iOS: hex APNs token, apnsEnvironment is "sandbox" or "production".
  print('Token: $token');
});

AppsOnAirPush.addNotificationReceivedListener((notification) {
  print('Received: ${notification.title}');
});

AppsOnAirPush.addNotificationOpenedListener((notification) {
  print('Opened: ${notification.title}');
});

AppsOnAirPush.addErrorListener((error) {
  print('[${error.code}] ${error.message}');
});
```

### Requesting notification permission

```dart
final granted = await AppsOnAirPush.isPermissionGranted();
if (!granted) {
  await AppsOnAirPush.Notifications.requestPermission();
}

// Permanently denied? Send the user to Settings instead:
await AppsOnAirPush.Notifications.requestPermission(fallbackToSettings: true);
```

### Controlling foreground display

```dart
AppsOnAirPush.Notifications.addForegroundWillDisplayListener((event) {
  // Do nothing → the SDK shows it.
  // Call preventDefault() → suppressed entirely, handle it yourself.
  event.preventDefault();
});
```

### Handling taps and action buttons

```dart
AppsOnAirPush.Notifications.addClickListener((event) {
  final actionId = event.actionId; // null = body tap, else the tapped action's ID
  print('Tapped ${event.notification.title}, action: $actionId');
});
```

### Identity, tags, aliases, and email

```dart
await AppsOnAirPush.login('user_12345');
await AppsOnAirPush.logout();

await AppsOnAirPush.User.addTagWithKey('plan', 'premium');
await AppsOnAirPush.User.addTags({'plan': 'premium', 'region': 'us'});
await AppsOnAirPush.User.removeTag('plan');
final tags = await AppsOnAirPush.User.getTags();

await AppsOnAirPush.User.addAlias('crm_id', 'CRM-9876');
await AppsOnAirPush.User.addEmail('user@example.com');

await AppsOnAirPush.User.setLanguage('fr');
```

### Opt-in / opt-out

```dart
await AppsOnAirPush.User.pushSubscription.optOut();
await AppsOnAirPush.User.pushSubscription.optIn();
final optedIn = await AppsOnAirPush.User.pushSubscription.isOptedIn;
```

### Consent (GDPR)

```dart
await AppsOnAirPush.setConsentRequired(true);
await AppsOnAirPush.initialize();

await AppsOnAirPush.setConsentGiven(true);  // user accepted
await AppsOnAirPush.setConsentGiven(false); // user withdrew
```

### Managing delivered notifications

```dart
await AppsOnAirPush.clearAllNotifications();
await AppsOnAirPush.Notifications.removeNotification('order-4821');
await AppsOnAirPush.Notifications.removeGroupedNotifications('orders'); // Android only
```

### Debug logging

```dart
await AppsOnAirPush.Debug.setLogLevel(LogLevel.verbose);
await AppsOnAirPush.initialize();
```
