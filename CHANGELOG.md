## 0.0.1-alpha

* Sync with native SDK changes (Core integration on both platforms):
  * `initialize()` no longer sends `appId` to native — Android reads it from
    the `AppsonairAppId` manifest meta-data, iOS from the `AppsonairAppId`
    Info.plist entry (both via AppsOnAir Core). The Dart `appId` parameter is
    now optional and kept only for source compatibility.
  * `initialize()` gained an iOS-only `swizzle` parameter (default `true`).
  * `subscriptionId` / `AppsOnAirPush.User.pushSubscription.id` now returns a
    real value on Android (was hardcoded `null` — the native getter is public
    again).
  * Added `getBadgeCount()` and `incrementBadgeCount(delta)`, matching the
    native SDKs' running-badge-total APIs.
  * `Notifications.createNotificationChannel()` gained an optional `sound`
    parameter (Android only; ignored on iOS).

## 0.0.1

* TODO: Describe initial release.
