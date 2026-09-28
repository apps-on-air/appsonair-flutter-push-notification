## 1.0.2-beta

- Kill-mode notification tap analytics now tracked correctly on iOS.
- Fixed click event delivery race condition in kill-mode (native buffer + Dart buffer).
- Flutter apps must call `AppPushService.initialize(swizzle: false)` natively in `AppDelegate` before `GeneratedPluginRegistrant.register()` for kill-mode support.
- Bumped iOS native SDK dependency to `AppsOnAir-AppPush 1.0.4-beta`.
- Bumped Android native SDK dependency to `appsonair-android-push-notification 1.0.2-beta`.

## 1.0.1-beta

Event analytics improvement.
Updated native SDK dependencies to 1.0.1-beta (iOS: AppsOnAir-AppPush, Android: appsonair-android-push-notification).

## 1.0.0-beta

Minor SDK improvements.

## 0.0.4-alpha

Minor SDK improvements.

## 0.0.3-alpha

Minor SDK improvements.

## 0.0.2-alpha

Minor SDK improvements (Sound).
Analytics integration.

## v0.0.1-alpha
AppsOnAir Push Notification service. (Alpha Internal Release).
