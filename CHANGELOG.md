## 0.0.1-alpha

AppsOnAir Push Notification service. (Alpha Internal Release).

* Push token delivery (FCM on Android, APNs on iOS).
* Notification received, opened, and click listeners.
* Foreground display control via `addForegroundWillDisplayListener`.
* Identity management: `login`, `logout`, device ID.
* User segmentation: tags, aliases, email, language.
* Opt-in / opt-out (`pushSubscription.optIn` / `optOut`).
* GDPR consent gate (`setConsentRequired`, `setConsentGiven`).
* Notification permission check and request (with fallback to system Settings).
* Delivered notification management: `clearAllNotifications`, `removeNotification`,
  `removeGroupedNotifications` (Android only).
* Debug logging via `Debug.setLogLevel`.
* `initialize()` reads the app ID from `AppsonairAppId` manifest meta-data (Android)
  or Info.plist entry (iOS) — no need to pass it from Dart.
* `initialize()` has an iOS-only `swizzle` parameter (default `true`).
* iOS: `AppPushService.User.pushSubscription.id` returns a real subscription ID.
