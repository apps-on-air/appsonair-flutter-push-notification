# AppsOnAir Flutter Push Notification SDK

A Flutter plugin wrapping the native AppsOnAir Push Notification SDKs for Android and iOS.
Provides device registration, push notification delivery, foreground display control, notification
taps and action buttons, user identity, tags, aliases, email channels, opt-in/opt-out, GDPR
consent management, and debug logging — all through a single Dart API.

> [!WARNING]
> **Beta release — not yet recommended for production use.**
>
> `1.0.6-beta` is an early access release intended for evaluation, integration testing, and
> prototype builds. Do not ship this version in a production app or a build with a large user base.
>
> - The public API may change between releases without a deprecation period.
> - Breaking changes are not restricted to major versions while the SDK is in beta.
> - Behavior in production-scale environments has not been fully validated.

---

## Contents

**Getting started** — [Requirements](#requirements) · [Features](#features) · [Installation](#installation) · [Android Setup](#android-setup) · [iOS Setup](#ios-setup) · [AppDelegate](#3-appdelegate--required) · [NSE](#4-notification-service-extension-nse--optional-for-rich-push) · [NCE](#5-notification-content-extension-nce--optional-for-expanded-long-press-view) · [Usage](#usage)

**Guides** — [Debug Logging](#debug-logging) · [User Identity](#user-identity) · [Tags](#tags) · [Language](#language) · [Aliases](#aliases) · [Email](#email) · [Opt-in / Opt-out](#opt-in--opt-out) · [User Observers](#user-observers) · [Permission](#permission) · [Foreground Display](#foreground-display) · [Handling Taps](#handling-taps) · [Silent Push](#silent-push) · [Notification Management](#notification-management) · [Custom Sound (Android)](#custom-sound-android) · [Consent](#consent)

**Reference** — [API Reference](#api-reference) · [Data Models](#data-models) · [Troubleshooting](#troubleshooting) · [iOS silent push](#ios--silent-push-not-received) · [Android silent push](#android--silent-push-not-received)

---

## Requirements

| | Minimum |
|---|---|
| Android | API 24 (Android 7.0) |
| iOS | 15.0 |
| Flutter | 3.16.0 |
| Dart SDK | 3.2.0 |

---

## Features

| Feature | Description |
|---|---|
| Push Registration | Automatically registers the device for push delivery via FCM (Android) or APNs (iOS). |
| Notification Taps and Actions | Receive callbacks when the user taps a notification or one of its action buttons. |
| Foreground Display Control | Decide whether to show or suppress a notification that arrives while the app is open. |
| User Identity | Associate a device with a known user using `login` and `logout`. |
| Tags | Attach key/value metadata to a device for audience segmentation. |
| Aliases | Link external identifiers such as a CRM or analytics ID to a device. |
| Email Channels | Associate email addresses with a device for cross-channel messaging. |
| Opt-in / Opt-out | Pause or resume push delivery to a device without changing OS-level permission. |
| Consent Management | Gate all data collection on explicit user consent, for GDPR compliance. |
| Permission Handling | Check, request, and observe the notification permission state. |
| Notification Management | Remove individual delivered notifications, clear all, or remove a group (Android). |
| Silent Push | Receive data-only background pushes without showing a notification banner. |
| Custom Sound | Play a custom audio file for notifications. Drop a WAV/MP3/OGG file in `res/raw/` — the plugin creates the Android channel automatically. iOS uses the standard APNs sound key. |
| Debug Logging | Configure SDK log verbosity for local development and diagnostics. |

For complete documentation visit [documentation.appsonair.com](https://documentation.appsonair.com).

---

## Installation

Run in your project directory:

```sh
flutter pub add appsonair_flutter_apppush
```

Or add the dependency manually to your `pubspec.yaml`:

```yaml
dependencies:
  appsonair_flutter_apppush: ^1.0.6-beta
```

Then run:

```sh
flutter pub get
```

---

## Android Setup

### 1. App ID

Add your AppsOnAir App ID as a `<meta-data>` entry inside the `<application>` tag in
`android/app/src/main/AndroidManifest.xml`:

```xml
<application>
    ...
    <meta-data
        android:name="AppsonairAppId"
        android:value="XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX" />
</application>
```

Configure a custom notification icon and accent color. Without these, both the SDK and FCM fall
back to the app launcher icon (which Android renders as a white square):

```xml
<application>
    ...
    <!-- SDK-rendered (data-only) notifications — used by the AppsOnAir SDK directly -->
    <meta-data
        android:name="com.appsonair.apppush.default_notification_icon"
        android:resource="@drawable/ic_notification" />

    <!-- FCM notification-block messages — used by Firebase for system-rendered notifications -->
    <meta-data
        android:name="com.google.firebase.messaging.default_notification_icon"
        android:resource="@drawable/ic_notification" />
    <meta-data
        android:name="com.google.firebase.messaging.default_notification_color"
        android:resource="@color/notification_accent" />
</application>
```

> **Use a silhouette icon.** Android paints every non-transparent pixel of the small icon solid
> white, so a full-colour launcher icon renders as a white square. Point both icon keys to the
> same alpha-only silhouette drawable — `com.appsonair.apppush.default_notification_icon` covers
> data-only payloads built by the SDK; `com.google.firebase.messaging.default_notification_icon`
> covers notification-block payloads rendered by Firebase.

**Creating the icon asset**

Create a white silhouette PNG named `ic_notification.png` at each density and place the files in your app's `res/` folder:

| Folder | Size |
|---|---|
| `android/app/src/main/res/drawable-mdpi/` | 24 × 24 px |
| `android/app/src/main/res/drawable-hdpi/` | 36 × 36 px |
| `android/app/src/main/res/drawable-xhdpi/` | 48 × 48 px |
| `android/app/src/main/res/drawable-xxhdpi/` | 72 × 72 px |
| `android/app/src/main/res/drawable-xxxhdpi/` | 96 × 96 px |

You can also place a single `ic_notification.png` in `drawable/` as a fallback. Use [Android Asset Studio](https://romannurik.github.io/AndroidAssetStudio/icons-notification.html) to generate all densities from a single source image.

**Creating the accent color**

Add `notification_accent` to `android/app/src/main/res/values/colors.xml` (create the file if it does not exist):

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="notification_accent">#FF6200EE</color>
</resources>
```

Replace `#FF6200EE` with your app's brand color.

### 2. Firebase

Place `google-services.json` inside `android/app/`. The SDK uses Firebase Cloud Messaging for
push delivery on Android.

### 3. JitPack repository

The native Push SDK and its transitive dependency (AppsOnAir Core) are published on JitPack.
Add the JitPack repository so Gradle can resolve them.

**Option A — `dependencyResolutionManagement` (modern projects)**

In `android/settings.gradle.kts`:

```kotlin
dependencyResolutionManagement {
    repositories {
        google()
        mavenCentral()
        maven("https://jitpack.io")
    }
}
```

**Option B — `allprojects` (older project layout)**

In your root `android/build.gradle.kts`:

```kotlin
allprojects {
    repositories {
        google()
        mavenCentral()
        maven("https://jitpack.io")
    }
}
```

Use whichever block your project already declares repositories in — do not add both.

### 4. Google Services plugin

In your root `android/build.gradle.kts`:

```kotlin
plugins {
    id("com.google.gms.google-services") version "4.4.2" apply false
}
```

In your app-level `android/app/build.gradle.kts`:

```kotlin
plugins {
    id("com.google.gms.google-services")
}
```

---

## iOS Setup

### 1. App ID

Add your AppsOnAir App ID to `ios/Runner/Info.plist`:

```xml
<key>AppsonairAppId</key>
<string>XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX</string>
```

If `CFBundleDisplayName` is not already present in `Info.plist`, add it:

```xml
<key>CFBundleDisplayName</key>
<string>YourAppName</string>
```

### 2. Xcode capabilities

In Xcode, open the Runner target, go to **Signing & Capabilities**, click **+ Capability**,
and add:

- **Push Notifications** — required for push delivery.
- **Background Modes** → enable **Remote notifications** — required for background and data-only pushes.

> APNs device tokens are not issued on the iOS Simulator. Push registration must be tested on a
> physical device.

### 3. AppDelegate — no changes required

No changes to `AppDelegate.swift` are needed. The plugin handles everything automatically:

- Registers itself as `UNUserNotificationCenter` delegate before `didFinishLaunchingWithOptions` returns — captures kill-mode taps before Dart's `AppPushService.initialize()` runs.
- Forwards silent pushes internally — no `didReceiveRemoteNotification` override needed.
- APNs token and error callbacks are handled by SDK swizzling automatically.

The standard `AppDelegate.swift` generated by `flutter create` is all that's required:

```swift
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
```

### 4. Notification Service Extension (NSE) — optional, for rich push

The NSE enables rich push features: image attachments, delivery receipts, badge management, and
action button registration. It is required for images to appear in notifications.

**Step 1 — Add the target**

In Xcode: **File → New → Target → Notification Service Extension**. Name it
`AppsonairNotificationServiceExtension` (or any name you prefer).

**Step 2 — Link the SDK**

**CocoaPods** — add to your `Podfile` outside the Runner target:

```ruby
target 'AppsonairNotificationServiceExtension' do
  use_frameworks!
  pod 'AppsOnAir-AppPush-ServiceExt'
end
```

Then run `pod install`.

**SPM** — In Xcode: **File → Add Package Dependencies** → enter the repository URL:

```
https://github.com/apps-on-air/appsonair-ios-push-notification
```

Link **`AppsOnAir-AppPush-ServiceExt`** to the **AppsonairNotificationServiceExtension** target only. Never link it to the main app Runner target.

> **Use standalone pods — not subspecs.** Do not use `pod 'AppsOnAir-AppPush/ServiceExtension'` — that subspec compiles into the same `AppsOnAir_AppPush.framework` as the main pod and causes _"Multiple commands produce AppsOnAir_AppPush.framework"_ on archive.

**Step 3 — Subclass the base class**

Replace the generated `NotificationService.swift` content with:

```swift
#if canImport(AppsOnAir_AppPush_ServiceExt)
import AppsOnAir_AppPush_ServiceExt
#else
import AppsOnAir_AppPush
#endif

class NotificationService: AppsOnAirNotificationServiceExtension {
}
```

**Step 4 — Add an App Group (for delivery receipts and badge counting)**

In Xcode, add the **App Groups** capability to both the **Runner** target and the
**AppsonairNotificationServiceExtension** target. Use the same group identifier for both:

```
group.com.yourcompany.yourapp.appsonair
```

> **Important:** Xcode adds the group to `.entitlements` automatically — but **not** to
> `Info.plist`. You must add the `AppsOnAirAppGroup` key to `Info.plist` manually on both
> the main app target and the NSE target. Without this key the SDK cannot read shared
> storage and delivery receipts will not be sent.

Add to `ios/Runner/Info.plist`:

```xml
<key>AppsOnAirAppGroup</key>
<string>group.com.yourcompany.yourapp.appsonair</string>
```

Add the same key to the NSE target's `Info.plist`.

> **Note:** The App Group must be registered in **Apple Developer Portal → Identifiers**
> for both your main app App ID and your NSE App ID before regenerating provisioning
> profiles. Adding it only in Xcode Signing & Capabilities is not enough — the
> provisioning profile will not include the entitlement until you regenerate it in the portal.

If you name the group following the exact convention `group.<main-bundle-id>.appsonair`,
the SDK finds it automatically without the `AppsOnAirAppGroup` Info.plist key. If your
group name differs from that convention, the key is required.

If you omit the App Group entirely, image attachments still work; delivery receipts and
badge counting require it.

**Step 5 — Enable mutable-content**

The NSE only runs when **mutable-content** is enabled on the push. Enable this option when sending from the AppsOnAir dashboard — it is required for image attachments, delivery receipts, and badge management to work.

### 5. Notification Content Extension (NCE) — optional, for expanded long-press view

The NCE renders a full-width image with title and body when the user long-presses
(or 3D-touches) a notification banner.

**Step 1 — Add the target**

In Xcode: **File → New → Target → Notification Content Extension**. Name it
`AppsonairNotificationContentExtension`.

**Step 2 — Link the SDK**

**CocoaPods** — add to your `Podfile` outside the Runner target:

```ruby
target 'AppsonairNotificationContentExtension' do
  use_frameworks!
  pod 'AppsOnAir-AppPush-ContentExt'
end
```

Then run `pod install`.

**SPM** — In Xcode: **File → Add Package Dependencies** → enter the repository URL:

```
https://github.com/apps-on-air/appsonair-ios-push-notification
```

Link **`AppsOnAir-AppPush-ContentExt`** to the **AppsonairNotificationContentExtension** target only. Never link it to the main app Runner target.

> **Use standalone pods — not subspecs.** Do not use `pod 'AppsOnAir-AppPush/ContentExtension'` — that subspec compiles into the same `AppsOnAir_AppPush.framework` as the main pod and causes _"Multiple commands produce AppsOnAir_AppPush.framework"_ on archive.

There are two ways to implement the NCE — choose based on your preference:

---

**Option A — SDK built-in UI (recommended, no storyboard)**

The SDK renders the full-width image, title, and body automatically. No layout code needed.

**Step 3 — Delete `MainInterface.storyboard`**

Right-click `MainInterface.storyboard` in the Xcode project navigator → **Delete → Move to Trash**.
The SDK builds its UI entirely in code — the storyboard is not used and its default `label`
outlet will crash the extension at load time if left in place.

**Step 4 — Subclass the base class**

Replace the generated `NotificationViewController.swift` content with:

```swift
#if canImport(AppsOnAir_AppPush_ContentExt)
import AppsOnAir_AppPush_ContentExt
#else
import AppsOnAir_AppPush
#endif

class NotificationViewController: AppsOnAirContentViewController {
    // No code required — image, title, and body are rendered automatically.
}
```

**Step 5 — Update the NCE Info.plist**

Replace `NSExtensionMainStoryboard` with `NSExtensionPrincipalClass` in the NCE Info.plist.

---

**Option B — Custom storyboard UI**

Use this when you want full control over the layout or have an existing storyboard-based NCE.

Keep `MainInterface.storyboard` and `NSExtensionMainStoryboard` in the NCE Info.plist as Xcode generated them. Implement `UNNotificationContentExtension` directly in your view controller:

```swift
import UIKit
import UserNotifications
import UserNotificationsUI

class NotificationViewController: UIViewController, UNNotificationContentExtension {

    // Wire these outlets to views in MainInterface.storyboard
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var bodyLabel: UILabel!

    func didReceive(_ notification: UNNotification) {
        let content = notification.request.content
        titleLabel.text = content.title
        bodyLabel.text  = content.body
        if let attachment = content.attachments.first,
           attachment.url.startAccessingSecurityScopedResource() {
            defer { attachment.url.stopAccessingSecurityScopedResource() }
            if let data = try? Data(contentsOf: attachment.url) {
                imageView.image = UIImage(data: data)
            }
        }
    }
}
```

No SDK import is needed for Option B — you handle the layout entirely yourself.

---

**Option A — NCE Info.plist**

Open the NCE target's `Info.plist`. Replace `NSExtensionMainStoryboard` with
`NSExtensionPrincipalClass`, and set `UNNotificationExtensionCategory` to match the
`aps.category` value in your push payload:

```xml
<key>NSExtension</key>
<dict>
    <key>NSExtensionAttributes</key>
    <dict>
        <key>UNNotificationExtensionCategory</key>
        <string>aoa_rich</string>
        <key>UNNotificationExtensionInitialContentSizeRatio</key>
        <real>1</real>
    </dict>
    <key>NSExtensionPrincipalClass</key>
    <string>$(PRODUCT_MODULE_NAME).NotificationViewController</string>
    <key>NSExtensionPointIdentifier</key>
    <string>com.apple.usernotifications.content-extension</string>
</dict>
```

The `UNNotificationExtensionCategory` value set in the NCE `Info.plist` must exactly match the **category** value configured in the AppsOnAir dashboard when sending the push. Use `aoa_rich` (or any identifier you choose) — just ensure both the `Info.plist` and the dashboard use the same value.

**Step 5 — Enable mutable-content and set the category from the dashboard**

When sending a push from the AppsOnAir dashboard, enable **mutable-content** and set the **category** to the same value as `UNNotificationExtensionCategory` in the NCE `Info.plist` (e.g. `aoa_rich`). The NCE is only triggered when these match.

### 6. Dependency manager

This plugin supports both **CocoaPods** (default) and **Swift Package Manager**. SPM support
requires Flutter 3.24.0 or higher.

**CocoaPods (default)**

```sh
flutter pub get
cd ios && pod install
```

If you have NSE and/or NCE targets, add their standalone pods outside the Runner target block:

```ruby
target 'Runner' do
  use_frameworks!
  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
  # AppsOnAir-AppPush is installed automatically via the Flutter plugin.
end

target 'AppsonairNotificationServiceExtension' do
  use_frameworks!
  pod 'AppsOnAir-AppPush-ServiceExt'
end

target 'AppsonairNotificationContentExtension' do
  use_frameworks!
  pod 'AppsOnAir-AppPush-ContentExt'
end
```

> **Use standalone pods — not subspecs.** `AppsOnAir-AppPush-ServiceExt` and
> `AppsOnAir-AppPush-ContentExt` are separate pods with their own module names.
> Do **not** use `pod 'AppsOnAir-AppPush/ServiceExtension'` or
> `pod 'AppsOnAir-AppPush/ContentExtension'` — those are subspecs that compile into the same
> `AppsOnAir_AppPush.framework` and cause _"Multiple commands produce"_ archive failures.

**Swift Package Manager**

Flutter 3.24.0 and higher support SPM. To opt in, run:

```sh
flutter config --enable-swift-package-manager
```

Once enabled, `flutter pub get` resolves the native iOS SDK
(`appsonair-ios-push-notification 1.0.6-beta` from GitHub) automatically.
No Podfile or Xcode configuration is required.

To switch back to CocoaPods at any time:

```sh
flutter config --no-enable-swift-package-manager
```

| Setting | Flutter version | Resolver |
|---|---|---|
| SPM disabled (default) | any | CocoaPods — run `pod install` after `pub get` |
| SPM enabled | 3.24.0 or higher | Swift Package Manager — no extra step needed |

---

## Usage

Call `initialize` once, as early as possible. Call `runApp` before `initialize` to ensure the
Flutter widget tree is ready before the method channel is used:

```dart
import 'package:appsonair_flutter_apppush/appsonair_flutter_apppush.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
  await AppPushService.initialize();
}
```

> **iOS — call order matters for kill-mode taps.** `initialize()` must be called **before** adding any listeners (e.g. `addClickListener`). Internally, `initialize()` registers the native event bridge. If listeners are added first, a kill-mode tap buffered during startup is flushed before the bridge is ready and the click event is dropped.
>
> ```dart
> runApp(const MyApp());
> await AppPushService.initialize();  // ← FIRST
> AppPushService.Notifications.addClickListener(myListener);  // ← THEN listeners
> ```

The SDK reads `AppsonairAppId` from the native platform configuration automatically. No app ID
argument is required from Dart.

### initialize() parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `debug` | `bool` | `false` | Enables debug log output. Prefer `Debug.setLogLevel()` for finer control. |
| `swizzle` | `bool` | `true` | **iOS only.** When `true`, the SDK swizzles `AppDelegate` methods automatically. Flutter apps do not need to set this — the `FlutterImplicitEngineDelegate` pattern handles all delegate setup automatically. |

---

## Debug Logging

Set the log level **before** `initialize()` so startup output is captured.

```dart
await AppPushService.Debug.setLogLevel(LogLevel.verbose);
await AppPushService.initialize();

// Read the current log level
final LogLevel level = await AppPushService.Debug.logLevel;
```

| Level | Description |
|---|---|
| `LogLevel.none` | No log output. Default. Recommended for production builds. |
| `LogLevel.fatal` | Fatal errors only. |
| `LogLevel.error` | Errors and above. |
| `LogLevel.warn` | Warnings and above. |
| `LogLevel.info` | Informational messages and above. |
| `LogLevel.debug` | Debug messages and above. |
| `LogLevel.verbose` | All log output. Recommended during development only. |

---

## User Identity

Associate this device with a known user after sign-in. Tags, aliases, and language are
cleared on `logout`; the push token and device ID are preserved and the device continues
receiving pushes as an anonymous user until the next `login`.

```dart
await AppPushService.login('user_12345');
await AppPushService.logout();
```

---

## Tags

Key/value strings attached to a device for audience segmentation.

```dart
await AppPushService.User.addTagWithKey('plan', 'premium');
await AppPushService.User.addTags({'plan': 'premium', 'region': 'us'});
await AppPushService.User.removeTag('plan');
await AppPushService.User.removeTags(['plan', 'region']);

final Map<String, String> tags = await AppPushService.User.getTags();
```

---

## Language

Override the device language used for server-side notification translation. Use BCP-47 language
tags (`"en"`, `"fr"`, `"en-US"`).

```dart
await AppPushService.User.setLanguage('fr');
final String currentLanguage = await AppPushService.User.language;
```

---

## Aliases

Map this device to an identifier in an external system. The label identifies the system
(`"crm_id"`, `"hubspot_id"`); the id is the value from that system.

```dart
await AppPushService.User.addAlias('crm_id', 'CRM-9876');
await AppPushService.User.addAliases({'crm_id': 'CRM-9876', 'stripe_id': 'cus_abc'});
await AppPushService.User.removeAlias('crm_id');
await AppPushService.User.removeAliases(['crm_id', 'stripe_id']);
```

---

## Email

Associate an email address with this device for cross-channel messaging. The backend keeps
one email per subscription — calling `addEmail` again replaces the previous address.

```dart
await AppPushService.User.addEmail('user@example.com');
await AppPushService.User.removeEmail('user@example.com');
```

---

## Opt-in / Opt-out

Pause or resume push delivery to this device without revoking OS-level notification permission.
The push token is preserved — opting back in resumes delivery immediately.

```dart
await AppPushService.User.pushSubscription.optOut();
await AppPushService.User.pushSubscription.optIn();

final bool    isOptedIn = await AppPushService.User.pushSubscription.isOptedIn;
final String? token     = await AppPushService.User.pushSubscription.token;
```

---

## User Observers

Observe changes to the push subscription (token rotation, opt-in state) and user identity
(login/logout). Add observers before `initialize()` to receive the initial state on startup.

### Push subscription observer

```dart
AppPushService.User.pushSubscription.addObserver((PushSubscriptionChangedState state) {
  print('token: ${state.current.token}');
  print('isOptedIn: ${state.current.isOptedIn}');
});

AppPushService.User.pushSubscription.removeObserver(observer);
```

### User state observer

```dart
AppPushService.User.addObserver((UserChangedState state) {
  print('externalId: ${state.externalId}');
  print('appsonairId: ${state.appsonairId}');
});

AppPushService.User.removeObserver(observer);
```

---

## Permission

```dart
// Check current state
final bool permission = await AppPushService.Notifications.permission;
final bool canRequest = await AppPushService.Notifications.canRequestPermission;

// Request permission
await AppPushService.Notifications.requestPermission();

// If permanently denied, open the system Settings page instead
await AppPushService.Notifications.requestPermission(fallbackToSettings: true);

// iOS only — provisional (quiet) authorization, no system prompt
await AppPushService.Notifications.registerForProvisionalAuthorization();

// Observe permission state changes
AppPushService.Notifications.addPermissionObserver((bool granted) {
  print('Notification permission changed: $granted');
});

AppPushService.Notifications.removePermissionObserver(observer);
```

---

## Foreground Display

By default the SDK shows notification banners even when the app is in the foreground. Add a
listener to intercept delivery and call `event.preventDefault()` on any notification you want
to handle silently.

`preventDefault()` must be called **synchronously** inside the listener. Calling it after an
`await` has no effect because the display decision is resolved when the callback returns.

```dart
AppPushService.Notifications.addForegroundWillDisplayListener(
  (NotificationWillDisplayEvent event) {
    // Do nothing — the SDK shows the notification automatically.
    // Or call preventDefault() to suppress the banner and handle it yourself.
    event.preventDefault();
  },
);

AppPushService.Notifications.removeForegroundWillDisplayListener(listener);
```

---

## Handling Taps

Fired when the user taps a notification body or one of its action buttons. Use `actionId` to
identify which button was tapped; `null` indicates a body tap.

```dart
AppPushService.Notifications.addClickListener((NotificationClickEvent event) {
  final String  title    = event.notification.title ?? '';
  final String? actionId = event.actionId; // null = body tap
  print('Tapped "$title", action: $actionId');
});

AppPushService.Notifications.removeClickListener(listener);
```

---

## Silent Push

Silent pushes are data-only background notifications — no banner is shown to the user. They are
useful for triggering in-app data sync, live-activity updates, or VoIP-style signalling.

Register the listener **before** `initialize()` so pushes that wake the app in the background
are not missed. Only one listener is active at a time — each call replaces the previous one.
Pass `null` to unregister.

```dart
// Call BEFORE initialize() — background wakeup pushes arrive before Dart finishes starting up.
AppPushService.setSilentPushListener((Map<String, dynamic> data) {
  print('Silent push received: $data');
});

await AppPushService.initialize();
```

### Platform setup

**iOS** — enable the **Background Modes → Remote notifications** capability in Xcode (Runner
target → Signing & Capabilities). Without this entitlement iOS will not wake the app for silent
pushes. No `AppDelegate` changes are required — the plugin forwards silent pushes to the SDK
internally.

**Android** — no additional setup required. The SDK intercepts data-only FCM messages
automatically.

> For device and OS conditions that can prevent silent push delivery (Low Power Mode, kill mode,
> Doze, manufacturer battery savers, etc.) see
> [iOS — silent push not received](#ios--silent-push-not-received) and
> [Android — silent push not received](#android--silent-push-not-received) in Troubleshooting.

---

## Notification Management

```dart
// Remove all delivered notifications from the notification shade / Notification Center
await AppPushService.Notifications.clearAll();

// Remove a single delivered notification by its payload notification_id
await AppPushService.Notifications.removeNotification('notification-id');

// Android only — remove every notification belonging to a group key
await AppPushService.Notifications.removeGroupedNotifications('orders');
```

---

## Custom Sound (Android)

The plugin automatically creates a custom-sound notification channel on Android 8+ when a
`custom_sound` audio file is present in your app's `res/raw/` folder. No Kotlin or Dart
code is required.

**Step 1 — Add the sound file**

Place a WAV, MP3, or OGG file named `custom_sound` in:

```
android/app/src/main/res/raw/custom_sound.wav
```

That is all the setup needed. The plugin detects the file at startup and pre-creates the channel
with the ID `appsonair_push_channel_snd_custom_sound`.

**Step 2 — Set as the FCM default channel (optional)**

To make Firebase-rendered (notification-block) messages also use the custom sound, add to
`AndroidManifest.xml` inside `<application>`:

```xml
<meta-data
    android:name="com.google.firebase.messaging.default_notification_channel_id"
    android:value="appsonair_push_channel_snd_custom_sound" />
```

**Step 3 — Send a push with the sound key**

For data-only (SDK-rendered) notifications, set `"sound": "custom_sound"` in the push data map
from the AppsOnAir dashboard or API.

> **Using a different sound name?** Add a manifest meta-data key to override the auto-detected
> name — the plugin reads this instead of looking for `custom_sound`:
>
> ```xml
> <meta-data
>     android:name="com.appsonair.apppush.default_notification_sound"
>     android:value="my_alert" />
> ```
>
> Then place `android/app/src/main/res/raw/my_alert.wav` in your project.

> **Channel sound is immutable on Android 8+.** A notification channel's sound cannot be changed
> after it is created. To change the sound, uninstall the app (or clear app data) and reinstall,
> or use a different channel ID. This is an Android OS constraint — it applies to all apps, not
> just this SDK.

> **iOS custom sound** — place the sound file in the Xcode Runner target (e.g.
> `ios/Runner/custom_sound.wav`) and reference it in the push payload:
> `"aps": { "sound": "custom_sound.wav" }`. No additional SDK setup is needed on iOS.

---

## Consent

Gate all data collection on explicit user consent. Set `consentRequired` **before**
`initialize()` so it applies on the very first launch. Both values persist across restarts.

```dart
await AppPushService.setConsentRequired(true);
await AppPushService.initialize();

await AppPushService.setConsentGiven(true);   // user accepted consent
await AppPushService.setConsentGiven(false);  // user withdrew consent
```

---

## API Reference

### AppPushService

| Method | Description |
|---|---|
| `initialize()` | Initializes the SDK. Call once, before any other API. |
| `login(externalId)` | Associates this device with a signed-in user. |
| `logout()` | Removes the user association and reverts the device to anonymous. |
| `setConsentRequired(bool)` | Gates data collection on user consent. Call before `initialize()`. |
| `setConsentGiven(bool)` | Records whether the user has accepted (`true`) or withdrawn (`false`) consent. |
| `setSilentPushListener(listener)` | Registers a listener for silent (data-only) push notifications. Call before `initialize()`. Pass `null` to unregister. Only one listener is active at a time. |

### AppPushService.User

| Member | Description |
|---|---|
| `appsonairId` | The AppsOnAir-assigned device ID. `null` until registered. |
| `externalId` | The external ID set by `login`. `null` when anonymous. |
| `addTagWithKey(key, value)` | Adds or updates a single tag. |
| `addTags(map)` | Adds or updates multiple tags. |
| `removeTag(key)` | Removes a single tag by key. |
| `removeTags(keys)` | Removes multiple tags by key. |
| `getTags()` | Fetches the backend's copy of this device's tags. |
| `setLanguage(code)` | Overrides the language for server-side translation (BCP-47). |
| `language` | The current language override or the detected device language. |
| `addAlias(label, id)` | Associates an external identifier alias with this device. |
| `addAliases(map)` | Associates multiple aliases at once. |
| `removeAlias(label)` | Removes an alias by label. |
| `removeAliases(labels)` | Removes multiple aliases by label. |
| `addEmail(address)` | Adds an email channel for this device. |
| `removeEmail(address)` | Removes an email channel from this device. |
| `addObserver(observer)` | Observes login/logout user state changes. |
| `removeObserver(observer)` | Removes a user state observer. |

### AppPushService.User.pushSubscription

| Member | Description |
|---|---|
| `isOptedIn` | Whether the device is currently opted in to receive pushes. |
| `token` | FCM token (Android) or hex APNs token (iOS). `null` until registered. |
| `optIn()` | Resumes push delivery to this device. |
| `optOut()` | Pauses push delivery without changing OS-level permission. |
| `addObserver(observer)` | Observes token and opt-in state changes. |
| `removeObserver(observer)` | Removes a subscription observer. |

### AppPushService.Notifications

| Member | Description |
|---|---|
| `permission` | Current notification permission state. |
| `canRequestPermission` | Whether the OS dialog will appear if `requestPermission` is called. |
| `requestPermission(fallbackToSettings)` | Requests notification permission. Opens Settings if `fallbackToSettings` is `true` and permission was permanently denied. |
| `registerForProvisionalAuthorization()` | iOS only. Requests provisional (quiet) authorization without a system prompt. No-op on Android. |
| `addPermissionObserver(observer)` | Observes notification permission state changes. |
| `removePermissionObserver(observer)` | Removes a permission observer. |
| `addForegroundWillDisplayListener(listener)` | Controls foreground notification display. Call `event.preventDefault()` synchronously to suppress. |
| `removeForegroundWillDisplayListener(listener)` | Removes a foreground display listener. |
| `addNotificationReceivedListener(listener)` | Fires when a notification is received while the app is in the foreground, after the display decision. Does not fire for silent pushes. |
| `removeNotificationReceivedListener(listener)` | Removes a notification received listener. |
| `addClickListener(listener)` | Observes notification taps and action button taps. |
| `removeClickListener(listener)` | Removes a click listener. |
| `clearAll()` | Removes all delivered notifications from the notification shade / Notification Center. |
| `removeNotification(id)` | Removes a single delivered notification by its payload `notification_id`. |
| `removeGroupedNotifications(groupKey)` | Android only. Removes every notification in the group. No-op on iOS. |

### AppPushService.Debug

| Member | Description |
|---|---|
| `setLogLevel(LogLevel)` | Sets the SDK's logging verbosity. |
| `logLevel` | The SDK's current logging verbosity. |

---

## Data Models

### PushNotification

| Field | Type | Description |
|---|---|---|
| `id` | `String?` | The `notification_id` value from the push payload, if present. |
| `title` | `String?` | The pre-translated notification title. |
| `body` | `String?` | The pre-translated notification body. |
| `data` | `Map<String, dynamic>` | The full push payload. On Android all values are `String` (FCM limitation); on iOS values retain their original APNs types. |

### NotificationClickEvent

| Field | Type | Description |
|---|---|---|
| `notification` | `PushNotification` | The notification that was tapped. |
| `actionId` | `String?` | `null` when the notification body was tapped; the action button identifier otherwise. |

### PushSubscriptionState

| Field | Type | Description |
|---|---|---|
| `token` | `String?` | FCM registration token (Android) or hex-encoded APNs device token (iOS). `null` until registered. |
| `isOptedIn` | `bool` | Whether the device is currently opted in to receive push notifications. |

### PushSubscriptionChangedState

| Field | Type | Description |
|---|---|---|
| `previous` | `PushSubscriptionState` | The subscription state before the change. |
| `current` | `PushSubscriptionState` | The subscription state after the change. |

### UserChangedState

| Field | Type | Description |
|---|---|---|
| `externalId` | `String?` | The external identifier set by `login`. `null` when anonymous. |
| `appsonairId` | `String` | The AppsOnAir-assigned device identifier. |

---

## Troubleshooting

### Android — notifications not received

1. Verify `google-services.json` is present in `android/app/`.
2. Verify the Google Services plugin is applied in both `build.gradle.kts` files.
3. Verify JitPack is declared in both `settings.gradle.kts` and the root `build.gradle.kts`.
4. Verify `AppsonairAppId` is declared in `AndroidManifest.xml`.
5. Set `LogLevel.verbose` and inspect logcat output for SDK diagnostic messages.

### Android — silent push not received

The following device and OS conditions can prevent silent push delivery regardless of correct SDK integration.

| Condition | Behaviour |
|---|---|
| **Doze mode** | Android 6+ enters Doze when the device is stationary, unplugged, and the screen is off. All background network access is suspended. FCM high-priority messages can break through Doze; normal-priority messages are deferred until the next maintenance window. |
| **App Standby buckets** | Android 9+ places apps the user has not interacted with recently into standby buckets. Background processing for rarely-used apps is progressively restricted — silent pushes may be deferred or dropped. |
| **Battery optimization** | If battery optimization is enabled for the app (Settings → Apps → [Your App] → Battery → Optimized), Android may delay or skip background wake-ups. Users should set it to **Unrestricted** for reliable silent push delivery. |
| **Background data restricted** | If the user has disabled background data for the app (Settings → Apps → [Your App] → Mobile data → Background data), FCM cannot deliver messages while the app is in the background on mobile data. |
| **App force-stopped** | If the user force-stops the app via Settings, Android will not wake it for any push — including high-priority FCM — until the user relaunches it manually. This is an Android OS policy and cannot be worked around in code. |
| **Manufacturer battery savers** | Xiaomi/MIUI, Huawei/EMUI, Samsung/One UI, OnePlus/OxygenOS, and Oppo/ColorOS add proprietary battery management on top of stock Android. These layers can kill background processes and block push delivery even for high-priority messages. Users may need to add the app to an **Autostart** or **Protected apps** whitelist in the device's battery settings. |
| **No network / poor signal** | FCM holds messages offline until the device reconnects, up to the `time_to_live` window in the payload (default 4 weeks). |

### iOS — APNs token not received

1. Verify the **Push Notifications** capability is enabled in Xcode.
2. Run on a physical device — APNs tokens are not issued on the iOS Simulator.
3. Verify `AppsonairAppId` is present in `Info.plist`.
4. Verify `AppPushService.initialize()` is called early (before `runApp` or in `initState`).
5. Verify `AppDelegate.swift` has not removed `GeneratedPluginRegistrant.register(with: self)` — the plugin relies on this call to set up the APNs token forwarding swizzle.

### iOS — notification tap not handled (kill mode)

Tapping a notification that cold-launches the app fires `didReceive` before Dart runs and before `initialize()` is called. The plugin handles this automatically — it registers itself as `UNUserNotificationCenter` delegate in `register(with:)` before `didFinishLaunchingWithOptions` returns, and buffers the tap until Dart's `AppPushService.initialize()` runs. No AppDelegate changes are required. Verify `GeneratedPluginRegistrant.register(with: self)` is present in `AppDelegate.swift`.

### iOS — silent push not received

The following device and OS conditions can prevent silent push delivery regardless of correct SDK integration.

| Condition | Behaviour |
|---|---|
| **Low Power Mode** | iOS suspends background app refresh and silent push delivery entirely while Low Power Mode is active. Delivery resumes when Low Power Mode is turned off or the device is charging. |
| **Background App Refresh disabled** | If the user has turned off Background App Refresh for the app (Settings → General → Background App Refresh → [Your App]), iOS will not wake the app for silent pushes. |
| **App force-quit (kill mode)** | If the user swipes the app off the App Switcher, iOS will not deliver silent pushes to it until the user manually relaunches the app. This is an iOS OS policy and cannot be worked around in code. |
| **iOS rate limiting** | Apple allows only a limited number of silent pushes per hour per device. If too many are sent in a short window, excess pushes are deferred or dropped silently. |
| **Low battery** | As battery level drops (roughly below 20 %), iOS becomes more aggressive at deferring background work even without Low Power Mode enabled. |
| **No network / poor signal** | Silent pushes require network connectivity. APNs holds the push until the device reconnects, up to the `apns-expiration` window in the request. |

### iOS — CocoaPods and Swift Package Manager conflict

Only one dependency manager should be active at a time. To switch from CocoaPods to SPM, run
`pod deintegrate` in the `ios` directory first. To switch back, disable SPM in Flutter's
configuration before running `pod install`.

### Foreground notification not suppressed

`event.preventDefault()` must be called synchronously inside the
`addForegroundWillDisplayListener` callback. Calling it after an `await` expression has no
effect because the display decision is resolved when the callback returns.

### iOS — NSE not invoked (no image, no delivery receipt)

1. Verify `mutable-content: 1` is present in the APNs `aps` payload.
2. Verify the NSE target is embedded in the app bundle (Xcode → Runner target → Build Phases → Embed Foundation Extensions).
3. Verify both the Runner target and NSE target have the same App Group in Signing & Capabilities.
4. Verify `AppsOnAirAppGroup` is present in **both** `ios/Runner/Info.plist` and the NSE `Info.plist` (Xcode does not add it automatically — only the `.entitlements` file is updated).
5. Regenerate provisioning profiles in Apple Developer Portal after adding the App Group to each App ID.
6. **Verify the NSE deployment target is ≤ the device's iOS version.** In Xcode, select the NSE target → Build Settings → `iOS Deployment Target`. Set it to `15.0` (or your app's minimum). iOS silently refuses to launch extensions whose minimum OS version exceeds the device OS — no crash, no log, the extension is simply never invoked.
7. **Flutter only — verify `CODE_SIGN_ENTITLEMENTS` path in `project.pbxproj`.** The path is resolved relative to `Runner.xcodeproj` (which lives inside `ios/`). The correct value is `AppsonairNotificationServiceExtension/AppsonairNotificationServiceExtension.entitlements` — **not** `ios/AppsonairNotificationServiceExtension/...`. Adding an `ios/` prefix causes a double path (`ios/ios/...`) and a build error.

### iOS — NCE not shown on long-press (no expanded image)

1. Verify `UNNotificationExtensionCategory` in the NCE `Info.plist` exactly matches the `"category"` value in the payload's `aps` object.
2. Verify the NCE `Info.plist` uses `NSExtensionPrincipalClass` (not `NSExtensionMainStoryboard`).
3. Verify `MainInterface.storyboard` was deleted — its default `label` outlet crashes the extension at load time.
4. Verify the NSE is running first (the NCE shows the attachment downloaded by the NSE — if no NSE, no attachment, no image).

### iOS — Xcode archive fails with "Multiple commands produce AppsOnAir_AppPush.framework"

NSE or NCE targets are linked via CocoaPods **subspecs** (`pod 'AppsOnAir-AppPush/ServiceExtension'` or `pod 'AppsOnAir-AppPush/ContentExtension'`). All subspecs compile into the same `AppsOnAir_AppPush.framework` — adding them to multiple targets creates duplicate outputs.

**Fix:** Replace the subspec pods with the standalone pods in your Podfile:

```ruby
# ❌ Wrong — subspecs cause duplicate framework
pod 'AppsOnAir-AppPush/ServiceExtension'
pod 'AppsOnAir-AppPush/ContentExtension'

# ✅ Correct — standalone pods with separate module names
pod 'AppsOnAir-AppPush-ServiceExt'
pod 'AppsOnAir-AppPush-ContentExt'
```

### iOS — `CFPrefsPlistSource` warning on device

The App Group is not included in the provisioning profile. Regenerate the main app and NSE provisioning profiles in Apple Developer Portal after adding the App Group to each App ID.
