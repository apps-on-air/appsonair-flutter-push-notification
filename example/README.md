# AppsOnAir Push — Flutter example

A minimal working example that demonstrates the
[appsonair_flutter_apppush](https://pub.dev/packages/appsonair_flutter_apppush) plugin.

## What it demonstrates

- SDK initialisation with verbose logging
- Requesting notification permission
- Adding and removing tags
- Login and logout (user identity)
- Adding aliases and email
- Opt-in / opt-out
- Observing foreground notifications, notification taps, subscription state, and user state

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

`example/ios/Runner/AppDelegate.swift` already contains the required SDK overrides.
No changes needed — `AppPushService.initialize(swizzle: false)` is called before
`GeneratedPluginRegistrant.register(with:)` to capture kill-mode notification taps.

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

## Verify it's working

1. Run the app — the **Device ID** field should populate within a few seconds.
2. Check the AppsOnAir dashboard — the device should appear under **Devices**.
3. Send a test push from the dashboard.
4. **Foreground:** banner appears + `Will display` logged.
5. **Background tap:** `Tapped` logged.
6. **Kill-mode tap:** cold-launch → `Tapped` logged (requires the `AppDelegate` overrides above).
