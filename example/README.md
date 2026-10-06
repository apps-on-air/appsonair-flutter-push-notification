# AppsOnAir Push — Flutter example

A minimal working example that demonstrates the
[appsonair_flutter_apppush](https://pub.dev/packages/appsonair_flutter_apppush) plugin.

## What it demonstrates

- SDK initialisation with verbose logging
- Requesting notification permission
- Adding and removing tags
- Login and logout (user identity)
- Adding aliases
- Adding and removing email
- Opt-in / opt-out
- Observing foreground notifications, notification taps, subscription state, and user state
- Silent push (data-only background notifications) via `setSilentPushListener`
- Custom notification sound (Android) via `res/raw/custom_sound.wav`

---

## Prerequisites

- Flutter SDK >= 3.16.0
- An AppsOnAir account — get your **App ID** from the [AppsOnAir dashboard](https://appsonair.com)
- **Android:** A Firebase project with `google-services.json`
- **iOS:** An Apple Developer account with push notifications entitlement and a physical device (APNs does not work on the simulator)

---

## Android setup

### 1. Firebase

1. Open [console.firebase.google.com](https://console.firebase.google.com) → create or select a project.
2. Add an Android app → enter the package name `com.example.appsonair_flutter_apppush_example` (or your own).
3. Download `google-services.json` and place it at `example/android/app/google-services.json`.

### 2. Apply the Google Services Gradle plugin

`example/android/settings.gradle.kts` — add the plugin to the `plugins {}` block:

```kotlin
plugins {
    id("com.google.gms.google-services") version "4.4.2" apply false
}
```

`example/android/app/build.gradle.kts` — apply the plugin:

```kotlin
plugins {
    id("com.google.gms.google-services")
}
```

### 3. Add your AppsOnAir App ID

Open `example/android/app/src/main/AndroidManifest.xml` and replace the placeholder:

```xml
<meta-data
    android:name="AppsonairAppId"
    android:value="YOUR-APP-ID-HERE" />
```

---

## iOS setup

### 1. Add your AppsOnAir App ID

Open `example/ios/Runner/Info.plist` and replace the placeholder:

```xml
<key>AppsonairAppId</key>
<string>YOUR-APP-ID-HERE</string>
```

### 2. Push Notifications capability

Open `example/ios/Runner.xcworkspace` in Xcode:

1. Select the **Runner** target → **Signing & Capabilities**.
2. Add **Push Notifications**.
3. Add **Background Modes** → tick **Remote notifications**.
4. Set your **Team** and verify the **Bundle Identifier**.

### 3. AppDelegate

No changes needed — the standard Flutter `AppDelegate.swift` is all that's required.
The plugin automatically registers itself as the `UNUserNotificationCenter` delegate,
handles silent push forwarding, and captures kill-mode notification taps internally.

### 4. iOS dependency (no action required)

Flutter resolves the native iOS dependency automatically when you open the workspace
or run `flutter build ios`. No manual step required.

---

## Run the example

```sh
cd example
flutter pub get

# iOS — open in Xcode first to set signing, then:
flutter run -d <your-ios-device-udid>

# Android
flutter run -d <your-android-device-id>
```

> Push notifications require a **physical device** on both platforms.

---

## What to test

### Device registration

1. Run the app — the **Device ID** field populates within a few seconds.
2. Check the AppsOnAir dashboard — the device appears under **Devices**.

### Regular push

1. Send a test push from the AppsOnAir dashboard.
2. **Foreground:** banner appears + `Will display: <title>` logged.
3. **Background tap:** `Tapped: <title>` logged.
4. **Kill-mode tap:** cold-launch → `Tapped: <title>` logged (handled automatically by the plugin).

### Email

Tap **Add email** → `addEmail(user@example.com)` logged.
Verify the email appears in the dashboard against the device.

Tap **Remove email** → `removeEmail(user@example.com)` logged.
Verify the email is cleared in the dashboard.

### Silent push

Tap the push from the dashboard (or send via API with no notification block).

- **Android:** send a data-only FCM message with `"silent": "true"` in the data map.
- **iOS:** send with `content-available: 1`, `apns-push-type: background`, `apns-priority: 5`.

`Silent push received: {...}` appears in the event log on screen.

> The listener is registered in `lib/main.dart` **before** `initialize()` — this is required
> so background-wakeup pushes are not missed.

### Custom sound (Android only)

A `custom_sound.wav` file is included in `android/app/src/main/res/raw/`. The plugin
creates the notification channel automatically on first launch.

Send a push from the dashboard with the data key `"sound": "custom_sound"` — the custom
tone plays instead of the device default.

Verify the channel in **Settings → Apps → [example app] → Notifications** — you should
see a **Push Notifications (custom sound)** channel.

### Tags

Tap **Add tag** → tag `favorite_color=blue` is added.
Tap **Remove tag** → tag is removed.
Verify tag changes appear in the dashboard under the device.

### Login / Logout

Tap **Login** → `login(demo-user-123)` logged, `User changed` event fires.
Tap **Logout** → `logout()` logged, user reverts to anonymous.

### Opt-in / Opt-out

Tap **Opt out** → device stops receiving pushes (token is preserved).
Tap **Opt in** → delivery resumes immediately.

---

## Silent push — platform notes

### iOS

The **Background Modes → Remote notifications** capability must be enabled in Xcode (Runner
target → Signing & Capabilities). No `AppDelegate` code is required — the plugin handles
silent push forwarding internally.

### Android

No additional setup required. Send a data-only FCM message (no `notification` block) with
`"silent": "true"` in the data map.
