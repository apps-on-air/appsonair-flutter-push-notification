# AppsOnAir Flutter Push Notification SDK

A Flutter plugin wrapping the native AppsOnAir Push Notification SDKs for Android and iOS.
Provides device registration, push notification delivery, foreground display control, notification
taps and action buttons, user identity, tags, aliases, email channels, opt-in/opt-out, GDPR
consent management, and debug logging — all through a single Dart API.

> [!WARNING]
> **Beta release — not yet recommended for production use.**
>
> `1.0.4-beta` is an early access release intended for evaluation, integration testing, and
> prototype builds. Do not ship this version in a production app or a build with a large user base.
>
> - The public API may change between releases without a deprecation period.
> - Breaking changes are not restricted to major versions while the SDK is in beta.
> - Behavior in production-scale environments has not been fully validated.

---

## Contents

**Getting started** — [Requirements](#requirements) · [Features](#features) · [Installation](#installation) · [Android Setup](#android-setup) · [iOS Setup](#ios-setup) · [AppDelegate](#3-appdelegate--required) · [NSE](#4-notification-service-extension-nse--optional-for-rich-push) · [NCE](#5-notification-content-extension-nce--optional-for-expanded-long-press-view) · [Usage](#usage)

**Guides** — [Debug Logging](#debug-logging) · [User Identity](#user-identity) · [Tags](#tags) · [Language](#language) · [Aliases](#aliases) · [Email](#email) · [Opt-in / Opt-out](#opt-in--opt-out) · [User Observers](#user-observers) · [Permission](#permission) · [Foreground Display](#foreground-display) · [Handling Taps](#handling-taps) · [Notification Management](#notification-management) · [Consent](#consent)

**Reference** — [API Reference](#api-reference) · [Data Models](#data-models) · [Troubleshooting](#troubleshooting)

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
| Debug Logging | Configure SDK log verbosity for local development and diagnostics. |

For complete documentation visit [documentation.appsonair.com](https://documentation.appsonair.com).

---

## Installation

Add the plugin to your app's `pubspec.yaml`:

```yaml
dependencies:
  appsonair_flutter_apppush: '>=1.0.4-beta'
```

Run:

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

### 3. AppDelegate — required

Open `ios/Runner/AppDelegate.swift` and add the four overrides below.

Flutter starts the SDK from Dart — which runs after the iOS app has already launched. This means iOS can deliver an APNs token or a notification tap before the SDK is ready. These overrides make sure the SDK never misses those events.

> **Important:** Call `AppPushService.initialize(swizzle: false)` **natively** in `didFinishLaunchingWithOptions`, before `GeneratedPluginRegistrant.register()`. This ensures the SDK is ready when iOS delivers a kill-mode notification tap — which fires `handleDidReceive` before Dart has started. Without this, kill-mode analytics (opened/clicked events) are lost.
>
> Because the SDK guards against double-initialization, the Dart-side `AppPushService.initialize()` call is safely ignored when called later.
>
> Pass `swizzle: false` here — Flutter's engine intercepts `AppDelegate` methods, so manual overrides below are required instead of swizzling.

```swift
import UIKit
import Flutter
import UserNotifications
import AppsOnAir_AppPush

@main
@objc class AppDelegate: FlutterAppDelegate {

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Initialize the SDK here (native, before Flutter engine starts) so that
        // kill-mode notification taps can enqueue analytics before Dart runs.
        // swizzle: false — Flutter intercepts AppDelegate methods; use the manual
        // overrides below instead. The SDK ignores a second initialize() call from Dart.
        AppPushService.initialize(swizzle: false)
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    // Gives the SDK the APNs device token as soon as iOS provides it.
    override func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        AppPushService.handleAPNsToken(deviceToken)
        super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
    }

    // Lets the SDK handle APNs registration errors.
    override func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        AppPushService.handleAPNsRegistrationError(error)
        super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
    }

    // Handles notification taps — including when the app is launched from a killed state.
    override func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        AppPushService.handleDidReceive(response: response)
        super.userNotificationCenter(center, didReceive: response, withCompletionHandler: completionHandler)
    }

    // Shows the notification banner while the app is open in the foreground.
    override func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let options = AppPushService.handleWillPresent(notification: notification)
        completionHandler(options)
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

In Xcode: **File → Add Package Dependencies** → enter the repository URL:

```
https://github.com/apps-on-air/appsonair-ios-push-notification
```

Link **`AppsOnAir-AppPush-ServiceExt`** to the **AppsonairNotificationServiceExtension** target only. Never link it to the main app Runner target.

> **NSE must always use SPM — even if your main app uses CocoaPods.** All CocoaPods subspecs
> compile into the same `AppsOnAir_AppPush.framework`. Adding a `ServiceExtension` subspec
> via CocoaPods causes Xcode archive to fail with _"Multiple commands produce
> AppsOnAir_AppPush.framework"_. Use SPM for NSE regardless of which manager the main app uses.

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

**Step 5 — Enable mutable-content in your payloads**

The NSE only runs when `mutable-content: 1` is present in the APNs payload:

```json
{
  "aps": {
    "alert": { "title": "Hello", "body": "World" },
    "mutable-content": 1,
    "sound": "default"
  },
  "notification_id": "your-notification-id",
  "big_picture": "https://example.com/image.png"
}
```

### 5. Notification Content Extension (NCE) — optional, for expanded long-press view

The NCE renders a full-width image with title and body when the user long-presses
(or 3D-touches) a notification banner.

**Step 1 — Add the target**

In Xcode: **File → New → Target → Notification Content Extension**. Name it
`AppsonairNotificationContentExtension`.

**Step 2 — Link the SDK**

In Xcode: **File → Add Package Dependencies** → enter the repository URL:

```
https://github.com/apps-on-air/appsonair-ios-push-notification
```

Link **`AppsOnAir-AppPush-ContentExt`** to the **AppsonairNotificationContentExtension** target only. Never link it to the main app Runner target.

> **NCE must always use SPM — same rule as NSE.** All CocoaPods subspecs compile into the
> same `AppsOnAir_AppPush.framework`, causing an archive failure if added via CocoaPods.
> Use SPM for NCE regardless of which manager the main app uses.

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

The `UNNotificationExtensionCategory` value (`aoa_rich` above) must exactly match the
`"category"` field in your APNs payload's `aps` object.

**Step 5 — Include `category` in your payloads**

```json
{
  "aps": {
    "alert": { "title": "NCE with Image", "body": "Long-press to see the full image." },
    "mutable-content": 1,
    "sound": "default",
    "category": "aoa_rich"
  },
  "notification_id": "your-notification-id",
  "big_picture": "https://example.com/image.png"
}
```

### 6. Dependency manager

This plugin supports both **CocoaPods** (default) and **Swift Package Manager**. SPM support
requires Flutter 3.24.0 or higher.

**CocoaPods (default)**

```sh
flutter pub get
cd ios && pod install
```

If you have NSE and/or NCE targets, keep their Podfile blocks with `inherit! :search_paths` only — **do not add subspecs**. Link NSE and NCE via SPM instead (see [NSE Step 2](#4-notification-service-extension-nse--optional-for-rich-push) and [NCE Step 2](#5-notification-content-extension-nce--optional-for-expanded-long-press-view)):

```ruby
target 'Runner' do
  # AppsOnAir-AppPush is installed automatically via the Flutter plugin.

  target 'AppsonairNotificationServiceExtension' do
    inherit! :search_paths
    # No pod here — NSE is linked via SPM in Xcode.
  end

  target 'AppsonairNotificationContentExtension' do
    inherit! :search_paths
    # No pod here — NCE is linked via SPM in Xcode.
  end
end
```

**Swift Package Manager**

Flutter 3.24.0 and higher support SPM. To opt in, run:

```sh
flutter config --enable-swift-package-manager
```

Once enabled, `flutter pub get` resolves the native iOS SDK
(`appsonair-ios-push-notification 1.0.4-beta` from GitHub) automatically.
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
| `swizzle` | `bool` | `true` | **iOS only.** When `true`, the SDK swizzles `AppDelegate` methods automatically. Set to `false` for Flutter apps — Flutter's engine intercepts `AppDelegate` methods, so the manual overrides in `AppDelegate.swift` are required instead. |

> **Flutter apps should always pass `swizzle: false`** (both in the native `AppDelegate.swift` call and the Dart `initialize()` call) since the manual `AppDelegate` overrides are already in place.

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

Associate an email address with this device for cross-channel messaging. Multiple addresses
can be added and removed independently.

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

### iOS — APNs token not received

1. Verify the **Push Notifications** capability is enabled in Xcode.
2. Run on a physical device — APNs tokens are not issued on the iOS Simulator.
3. Verify `AppsonairAppId` is present in `Info.plist`.
4. Verify `AppPushService.initialize()` is called early (before `runApp` or in `initState`).
5. Verify `AppDelegate.swift` includes the `didRegisterForRemoteNotificationsWithDeviceToken` and `didFailToRegisterForRemoteNotificationsWithError` overrides (see [AppDelegate](#3-appdelegate)). `initialize()` is called from Dart after the Flutter engine starts — an APNs token can arrive before the swizzle is installed, and without these overrides the token is silently lost.

### iOS — notification tap not handled (kill mode)

Tapping a notification that cold-launches the app fires `didReceive` before Dart runs and before `initialize()` is called. Without the `userNotificationCenter(_:didReceive:withCompletionHandler:)` override in `AppDelegate.swift`, the tap event is lost. Add the override as shown in [AppDelegate](#3-appdelegate).

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

NSE or NCE targets are linked via CocoaPods subspecs (`pod 'AppsOnAir-AppPush/ServiceExtension'`). All subspecs compile into the same `AppsOnAir_AppPush.framework` — adding them to multiple targets via CocoaPods creates duplicate outputs.

**Fix:** Remove subspec pod lines from NSE and NCE Podfile target blocks. Link `AppsOnAir-AppPush-ServiceExt` and `AppsOnAir-AppPush-ContentExt` via **File → Add Package Dependencies** in Xcode instead. NSE and NCE must always use SPM, even when the main app uses CocoaPods.

### iOS — `CFPrefsPlistSource` warning on device

The App Group is not included in the provisioning profile. Regenerate the main app and NSE provisioning profiles in Apple Developer Portal after adding the App Group to each App ID.
