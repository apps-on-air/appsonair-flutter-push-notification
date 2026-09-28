# AppsOnAir Flutter Push SDK — Internal Release Notes

> Internal document — not visible to SDK consumers (gitignored).
> Covers every tagged release with full detail of what was integrated, why, and any known issues.

---

## 1.0.2-beta
**Tag:** (pending — current working branch)
**Status:** Ready to tag

### Native SDK Dependencies
- **iOS:** `AppsOnAir-AppPush 1.0.4-beta`
- **Android:** `appsonair-android-push-notification 1.0.2-beta`

### Integration

#### Kill-mode iOS notification tap — full fix
Three-layer fix to ensure kill-mode notification taps are always delivered to listeners and tracked as analytics events:

1. **Native `UNUserNotificationCenterDelegate` set early** (`AppsonairFlutterAppPushPlugin.register(with:)`) — the plugin installs itself as `UNUserNotificationCenter.current().delegate` before `didFinishLaunchingWithOptions` returns. iOS delivers the kill-mode `didReceive(_:withCompletionHandler:)` on the first run-loop turn after launch — before Dart's async `initialize()` ever runs. Without this, the tap was silently dropped.

2. **Native `pendingClickEvents` buffer** (Swift) — `onClick(event:)` queues the click payload when `eventSink` is nil (Dart stream not yet subscribed). The buffer is flushed in `onListen()` the moment the stream connects.

3. **Dart `_pendingKillModeClicks` buffer** (`notifications_manager.dart`) — `dispatchClick()` queues `NotificationClickEvent` when no click listener is registered yet. `addClickListener()` replays all pending events to the first listener that registers.

**Required app-level change:** Flutter apps must call `AppPushService.initialize(swizzle: false)` natively in `AppDelegate.application(_:didFinishLaunchingWithOptions:)` **before** `GeneratedPluginRegistrant.register(with:)`. This ensures the native SDK registers its analytics handler before iOS delivers the kill-mode tap.

#### iOS Native SDK bump → 1.0.4-beta
Updated `ios/appsonair_flutter_apppush.podspec` and `ios/appsonair_flutter_apppush/Package.swift` to depend on `AppsOnAir-AppPush 1.0.4-beta`.

Key fixes pulled in from native iOS 1.0.3-beta and 1.0.4-beta:

**Flutter Delegate Chain Fix (`PushAppDelegateSwizzler`)** — when the swizzler added a new APNs method via `class_addMethod`, it set `original = nil`, silently skipping `FlutterAppDelegate`'s superclass implementations. The native SDK now walks up to the superclass and preserves its IMP, keeping `FlutterAppDelegate` in the chain.

#### `swizzle: false` required for Flutter apps
`AppPushService.initialize(swizzle: false)` must be used in Flutter apps. The Flutter engine intercepts AppDelegate lifecycle methods; swizzling on top of Flutter's own swizzling causes double-intercept and missed callbacks. The README now documents this with the required `AppDelegate` setup and explains the kill-mode call order.

#### `tokenUpdated` event dispatched to subscriptionChanged observers
`_onEvent` in `appsonair_flutter_apppush.dart` now handles the `tokenUpdated` event and synthesises a `PushSubscriptionChangedState` dispatch — ensures all `addObserver` listeners see the token as soon as it arrives (before `subscriptionChanged` fires).

#### Auto-complete foreground display events
`dispatchForeground()` in `notifications_manager.dart` calls `event.completeIfNeeded()` after all listeners have been notified. Without this, if no listener called `preventDefault()`, the native completion handler was never invoked and the foreground banner was silently dropped.

#### pubspec.yaml version synced
`pubspec.yaml` version was at `1.0.1-beta` while `podspec` and `android/build.gradle.kts` were already at `1.0.2-beta`. Synced `pubspec.yaml` to `1.0.2-beta`.

#### README — iOS NSE/NCE Setup (Steps 4 & 5)
Added full NSE and NCE setup documentation including:
- NSE target creation, SPM linking, `AppsOnAirNotificationServiceExtension` subclass
- App Group: both `.entitlements` (Xcode automatic) and `Info.plist` (manual) required on main app and NSE targets
- `mutable-content: 1` payload requirement
- NCE target creation, `NSExtensionPrincipalClass` vs `NSExtensionMainStoryboard`, delete storyboard instruction, `UNNotificationExtensionCategory` must match payload `aps.category`
- `AppDelegate` setup with `swizzle: false` and kill-mode call order warning
- Troubleshooting entries: NSE deployment target, `CODE_SIGN_ENTITLEMENTS` path (Flutter-specific), NCE not shown

#### Android manifest — notification icon
Documented both `com.appsonair.apppush.default_notification_icon` (SDK-rendered data-only) and `com.google.firebase.messaging.default_notification_icon` (Firebase notification-block) — both required for consistent icon rendering across all push delivery paths.

---

### Pending
- **GDPR consent enforcement** — `consentRequired`/`consentGiven` API exists but makes no network calls yet.
- **No unit test coverage.**

---

## 1.0.1-beta
**Tag:** `1.0.1-beta`
**Status:** Released

### Native SDK Dependencies
- **iOS:** `AppsOnAir-AppPush 1.0.1-beta`
- **Android:** `appsonair-android-push-notification 1.0.1-beta`

### Integration
- Bumped native SDK dependencies to `1.0.1-beta` on both platforms.
- Email management API: `addEmail`, `getEmails`, `removeEmail`.
- Alias management API: `addAlias`, `addAliases`, `removeAlias`, `removeAliases`, `getAliases` (sync and async).

---

## 1.0.0-beta
**Tag:** `1.0.0-beta`
**Status:** Released

### Integration
- First beta milestone — promoted from alpha after QA validation.
- Version synced across pubspec, podspec, and Android build.gradle.

---

## 0.0.4-alpha
**Tag:** `0.0.4-alpha`
**Status:** Released

### Integration
- Minor SDK improvements.

---

## 0.0.3-alpha
**Tag:** `0.0.3-alpha`
**Status:** Released

### Integration
- Minor SDK improvements.

---

## 0.0.2-alpha
**Tag:** `0.0.2-alpha`
**Status:** Released

### Integration
- Minor SDK improvements (Sound).
- Analytics integration.

---

## 0.0.1-alpha
**Tag:** `0.0.1-alpha`
**Status:** Released

### Integration
- Initial Flutter plugin wrapping AppsOnAir Push Notification SDK for Android and iOS.

---

*This file is gitignored — for internal SDK team use only.*
