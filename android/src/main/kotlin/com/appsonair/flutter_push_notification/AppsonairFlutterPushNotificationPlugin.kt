package com.appsonair.flutter_push_notification

import android.app.Activity
import android.content.Context
import android.os.Handler
import android.os.Looper
import androidx.annotation.NonNull
import com.appsonair.push.AppsOnAirNotificationsNS
import com.appsonair.push.AppsOnAirPush
import com.appsonair.push.AppsOnAirUser
import com.appsonair.push.INotificationClickListener
import com.appsonair.push.INotificationLifecycleListener
import com.appsonair.push.INotificationPermissionObserver
import com.appsonair.push.IPushSubscriptionObserver
import com.appsonair.push.IUserStateObserver
import com.appsonair.push.LogLevel
import com.appsonair.push.NotificationClickEvent
import com.appsonair.push.NotificationWillDisplayEvent
import com.appsonair.push.PushError
import com.appsonair.push.PushListener
import com.appsonair.push.PushNotification
import com.appsonair.push.PushSubscriptionChangedState
import com.appsonair.push.UserChangedState
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.util.UUID

/** AppsonairFlutterPushNotificationPlugin */
class AppsonairFlutterPushNotificationPlugin :
    FlutterPlugin,
    ActivityAware,
    MethodCallHandler,
    EventChannel.StreamHandler,
    PushListener,
    INotificationLifecycleListener,
    INotificationClickListener,
    INotificationPermissionObserver,
    IPushSubscriptionObserver,
    IUserStateObserver {

    private lateinit var channel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var eventSink: EventChannel.EventSink? = null
    private lateinit var applicationContext: Context
    private var activity: Activity? = null

    // FCM delivers PushListener/observer callbacks on its own background thread
    // pool (e.g. "Firebase-Messaging-Intent-Handle" for onNewToken/onNotificationReceived),
    // not the main thread — but EventChannel.EventSink.success() is @UiThread-only and
    // crashes with "Methods marked with @UiThread must be executed on the main thread"
    // otherwise. Every eventSink emission must go through this.
    private val mainHandler = Handler(Looper.getMainLooper())

    private fun sendEvent(event: Map<String, Any?>) {
        mainHandler.post { eventSink?.success(event) }
    }

    // Foreground events currently awaiting a Dart-side preventDefault() decision.
    // Best-effort only — the native SDK's own display-vs-suppress check runs on the
    // next main-thread loop iteration, faster than a Flutter platform-channel round
    // trip can normally resolve, so a discard requested from Dart may already be too
    // late. Kept so a discard is still honoured whenever the round trip is fast enough.
    private val pendingWillDisplayEvents = mutableMapOf<String, NotificationWillDisplayEvent>()

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        applicationContext = flutterPluginBinding.applicationContext
        channel = MethodChannel(
            flutterPluginBinding.binaryMessenger,
            "appsonair_flutter_push_notification/methods"
        )
        channel.setMethodCallHandler(this)
        eventChannel = EventChannel(
            flutterPluginBinding.binaryMessenger,
            "appsonair_flutter_push_notification/events"
        )
        eventChannel.setStreamHandler(this)

        AppsOnAirPush.setListener(this)
        AppsOnAirPush.Notifications.addForegroundLifecycleListener(this)
        AppsOnAirPush.Notifications.addClickListener(this)
        AppsOnAirPush.Notifications.addPermissionObserver(this)
        AppsOnAirUser.PushSubscription.addObserver(this)
        AppsOnAirPush.User.addObserver(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        AppsOnAirPush.setListener(null)
        AppsOnAirPush.Notifications.removeForegroundLifecycleListener(this)
        AppsOnAirPush.Notifications.removeClickListener(this)
        AppsOnAirPush.Notifications.removePermissionObserver(this)
        AppsOnAirUser.PushSubscription.removeObserver(this)
        AppsOnAirPush.User.removeObserver(this)
    }

    // ── ActivityAware ────────────────────────────────────────────────────

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        // Handle a notification tap that cold-started the app.
        AppsOnAirPush.handleNotificationTapIntent(binding.activity.intent)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    // ── EventChannel.StreamHandler ──────────────────────────────────────

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    // ── MethodCallHandler ────────────────────────────────────────────────

    override fun onMethodCall(call: MethodCall, result: Result) {
        try {
            when (call.method) {
                "initialize" -> {
                    // appId is no longer passed to native — Core resolves it from the
                    // "AppsonairAppId" AndroidManifest meta-data. "swizzle" is iOS-only.
                    val debug = call.argument<Boolean>("debug") ?: false
                    AppsOnAirPush.initialize(applicationContext, debug)
                    result.success(null)
                }
                "login" -> {
                    AppsOnAirPush.login(call.argument<String>("externalId") ?: "")
                    result.success(null)
                }
                "logout" -> {
                    AppsOnAirPush.logout()
                    result.success(null)
                }
                "getDeviceId" -> result.success(AppsOnAirPush.getDeviceId())
                "setConsentRequired" -> {
                    AppsOnAirPush.consentRequired = call.argument<Boolean>("value") ?: false
                    result.success(null)
                }
                "setConsentGiven" -> {
                    AppsOnAirPush.consentGiven = call.argument<Boolean>("value") ?: false
                    result.success(null)
                }
                "isPermissionGranted" -> result.success(AppsOnAirPush.isPermissionGranted(applicationContext))
                "clearAllNotifications" -> {
                    AppsOnAirPush.clearAllNotifications(applicationContext)
                    result.success(null)
                }

                // ── User namespace ──────────────────────────────────────
                "user#getExternalId" -> result.success(AppsOnAirUser.externalId)
                "user#pushSubscription#isOptedIn" ->
                    result.success(AppsOnAirUser.PushSubscription.optedIn)
                "user#pushSubscription#getToken" -> result.success(AppsOnAirUser.PushSubscription.token)
                "user#pushSubscription#optIn" -> {
                    AppsOnAirUser.PushSubscription.optIn()
                    result.success(null)
                }
                "user#pushSubscription#optOut" -> {
                    AppsOnAirUser.PushSubscription.optOut()
                    result.success(null)
                }
                "user#addTag" -> {
                    AppsOnAirUser.addTag(
                        call.argument<String>("key") ?: "",
                        call.argument<String>("value") ?: ""
                    )
                    result.success(null)
                }
                "user#addTags" -> {
                    @Suppress("UNCHECKED_CAST")
                    val tags = call.argument<Map<String, String>>("tags") ?: emptyMap()
                    AppsOnAirUser.addTags(tags)
                    result.success(null)
                }
                "user#removeTag" -> {
                    AppsOnAirUser.removeTag(call.argument<String>("key") ?: "")
                    result.success(null)
                }
                "user#removeTags" -> {
                    @Suppress("UNCHECKED_CAST")
                    val keys = call.argument<List<String>>("keys") ?: emptyList()
                    AppsOnAirUser.removeTags(keys)
                    result.success(null)
                }
                "user#getTags" -> AppsOnAirUser.getTags { tags -> result.success(tags) }
                "user#setLanguage" -> {
                    AppsOnAirUser.setLanguage(call.argument<String>("code") ?: "")
                    result.success(null)
                }
                "user#getLanguage" -> result.success(AppsOnAirUser.language)
                "user#addAlias" -> {
                    AppsOnAirUser.addAlias(
                        call.argument<String>("label") ?: "",
                        call.argument<String>("id") ?: ""
                    )
                    result.success(null)
                }
                "user#addAliases" -> {
                    @Suppress("UNCHECKED_CAST")
                    val aliases = call.argument<Map<String, String>>("aliases") ?: emptyMap()
                    AppsOnAirUser.addAliases(aliases)
                    result.success(null)
                }
                "user#removeAlias" -> {
                    AppsOnAirUser.removeAlias(call.argument<String>("label") ?: "")
                    result.success(null)
                }
                "user#removeAliases" -> {
                    @Suppress("UNCHECKED_CAST")
                    val labels = call.argument<List<String>>("labels") ?: emptyList()
                    AppsOnAirUser.removeAliases(labels)
                    result.success(null)
                }
                "user#addEmail" -> {
                    AppsOnAirUser.addEmail(call.argument<String>("address") ?: "")
                    result.success(null)
                }
                "user#removeEmail" -> {
                    AppsOnAirUser.removeEmail(call.argument<String>("address") ?: "")
                    result.success(null)
                }

                // ── Notifications namespace ─────────────────────────────
                "notifications#permission" ->
                    result.success(AppsOnAirNotificationsNS.permission(applicationContext))
                "notifications#canRequestPermission" ->
                    result.success(AppsOnAirNotificationsNS.canRequestPermission(applicationContext))
                "notifications#requestPermission" -> {
                    val currentActivity = activity
                    if (currentActivity == null) {
                        result.error("NO_ACTIVITY", "No attached Activity to request permission from.", null)
                        return
                    }
                    val fallbackToSettings = call.argument<Boolean>("fallbackToSettings") ?: false
                    AppsOnAirNotificationsNS.requestPermission(currentActivity, fallbackToSettings)
                    result.success(null)
                }
                "notifications#registerForProvisionalAuthorization" -> result.success(null) // iOS-only
                "notifications#clearAll" -> {
                    AppsOnAirNotificationsNS.clearAllNotifications(applicationContext)
                    result.success(null)
                }
                "notifications#removeNotification" -> {
                    val id = call.argument<String>("id")
                    if (id != null) {
                        AppsOnAirNotificationsNS.removeNotification(applicationContext, id)
                    }
                    result.success(null)
                }
                "notifications#removeGroupedNotifications" -> {
                    AppsOnAirNotificationsNS.removeGroupedNotifications(
                        applicationContext,
                        call.argument<String>("groupKey") ?: ""
                    )
                    result.success(null)
                }
                "notifications#completeDisplay" -> {
                    val eventId = call.argument<String>("eventId")
                    val discard = call.argument<Boolean>("discard") ?: false
                    val event = eventId?.let { pendingWillDisplayEvents.remove(it) }
                    if (discard) {
                        event?.preventDefault()
                    }
                    result.success(null)
                }

                // ── Debug namespace ─────────────────────────────────────
                "debug#setLogLevel" -> {
                    val level = call.argument<String>("level") ?: "none"
                    AppsOnAirPush.Debug.logLevel = LogLevel.entries.firstOrNull {
                        it.name.equals(level, ignoreCase = true)
                    } ?: LogLevel.NONE
                    result.success(null)
                }
                "debug#getLogLevel" -> result.success(AppsOnAirPush.Debug.logLevel.name.lowercase())

                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            result.error("APPSONAIR_PUSH_ERROR", e.message, null)
        }
    }

    // ── PushListener ─────────────────────────────────────────────────────

    override fun onTokenUpdated(token: String) {
        sendEvent(mapOf("type" to "tokenUpdated", "token" to token, "environment" to null))
    }

    override fun onInstallationIdUpdated(id: String) {
        sendEvent(mapOf("type" to "installationIdUpdated", "id" to id))
    }

    override fun onNotificationReceived(notification: PushNotification) {
        sendEvent(
            mapOf("type" to "notificationReceived", "notification" to notification.toMap())
        )
    }

    override fun onNotificationOpened(notification: PushNotification) {
        sendEvent(
            mapOf("type" to "notificationOpened", "notification" to notification.toMap())
        )
    }

    override fun onError(error: PushError) {
        sendEvent(
            mapOf(
                "type" to "error",
                "code" to wireErrorCode(error.code),
                "message" to error.message
            )
        )
    }

    // ── INotificationLifecycleListener ──────────────────────────────────

    override fun onWillDisplay(event: NotificationWillDisplayEvent) {
        val eventId = UUID.randomUUID().toString()
        pendingWillDisplayEvents[eventId] = event
        sendEvent(
            mapOf(
                "type" to "notificationWillDisplay",
                "eventId" to eventId,
                "notification" to event.notification.toMap()
            )
        )
    }

    // ── INotificationClickListener ──────────────────────────────────────

    override fun onClick(event: NotificationClickEvent) {
        sendEvent(
            mapOf(
                "type" to "notificationClicked",
                "notification" to event.notification.toMap(),
                "actionId" to event.result.actionId
            )
        )
    }

    // ── INotificationPermissionObserver ─────────────────────────────────

    override fun onNotificationPermissionDidChange(permission: Boolean) {
        sendEvent(mapOf("type" to "permissionChanged", "granted" to permission))
    }

    // ── IPushSubscriptionObserver ────────────────────────────────────────

    override fun onPushSubscriptionDidChange(state: PushSubscriptionChangedState) {
        sendEvent(
            mapOf(
                "type" to "subscriptionChanged",
                "previous" to mapOf(
                    "token" to state.previous.token,
                    "isOptedIn" to state.previous.optedIn
                ),
                "current" to mapOf(
                    "token" to state.current.token,
                    "isOptedIn" to state.current.optedIn
                )
            )
        )
    }

    // ── IUserStateObserver ───────────────────────────────────────────────

    override fun onUserStateDidChange(state: UserChangedState) {
        sendEvent(
            mapOf(
                "type" to "userChanged",
                "externalId" to state.current.externalId,
                "appsonairId" to state.current.appsOnAirId
            )
        )
    }

    // ── Helpers ──────────────────────────────────────────────────────────

    private fun PushNotification.toMap(): Map<String, Any?> =
        mapOf("id" to id, "title" to title, "body" to body, "data" to data)

    private fun wireErrorCode(code: PushError.Code): String = when (code) {
        PushError.Code.NOT_INITIALIZED -> "notInitialized"
        PushError.Code.PERMISSION_DENIED -> "permissionDenied"
        PushError.Code.TOKEN_FETCH_FAILED -> "tokenFetchFailed"
        PushError.Code.INSTALLATION_ID_FETCH_FAILED -> "installationIdFetchFailed"
        PushError.Code.UNKNOWN -> "unknown"
    }
}
