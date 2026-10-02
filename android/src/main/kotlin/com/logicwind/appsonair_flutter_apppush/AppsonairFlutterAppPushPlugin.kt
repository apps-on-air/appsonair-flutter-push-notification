package com.logicwind.appsonair_flutter_apppush

import android.app.Activity
import android.content.Context
import android.os.Handler
import android.os.Looper
import androidx.annotation.NonNull
import com.appsonair.apppush.AppPushService
import com.appsonair.apppush.INotificationClickListener
import com.appsonair.apppush.INotificationLifecycleListener
import com.appsonair.apppush.INotificationPermissionObserver
import com.appsonair.apppush.IPushSubscriptionObserver
import com.appsonair.apppush.IUserStateObserver
import com.appsonair.apppush.LogLevel
import com.appsonair.apppush.NotificationClickEvent
import com.appsonair.apppush.NotificationWillDisplayEvent
import com.appsonair.apppush.PushError
import com.appsonair.apppush.PushListener
import com.appsonair.apppush.PushNotification
import com.appsonair.apppush.PushNotifications
import com.appsonair.apppush.PushSubscriptionChangedState
import com.appsonair.apppush.PushUser
import com.appsonair.apppush.UserChangedState
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import java.util.UUID

/** AppsonairFlutterAppPushPlugin */
class AppsonairFlutterAppPushPlugin :
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
    private var activityBinding: ActivityPluginBinding? = null
    private var newIntentListener: PluginRegistry.NewIntentListener? = null

    private val mainHandler = Handler(Looper.getMainLooper())

    private val pendingEvents = mutableListOf<Map<String, Any?>>()

    private fun sendEvent(event: Map<String, Any?>) {
        mainHandler.post {
            val sink = eventSink
            if (sink != null) {
                sink.success(event)
            } else {
                pendingEvents.add(event)
            }
        }
    }

    private val pendingWillDisplayEvents = mutableMapOf<String, NotificationWillDisplayEvent>()

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        applicationContext = flutterPluginBinding.applicationContext
        channel = MethodChannel(
            flutterPluginBinding.binaryMessenger,
            "appsonair_flutter_apppush/methods"
        )
        channel.setMethodCallHandler(this)
        eventChannel = EventChannel(
            flutterPluginBinding.binaryMessenger,
            "appsonair_flutter_apppush/events"
        )
        eventChannel.setStreamHandler(this)

        AppPushService.setListener(this)
        AppPushService.Notifications.addForegroundLifecycleListener(this)
        AppPushService.Notifications.addClickListener(this)
        AppPushService.Notifications.addPermissionObserver(this)
        PushUser.PushSubscription.addObserver(this)
        AppPushService.User.addObserver(this)

        // Pre-create the custom-sound notification channel (Android 8+).
        // Reads the res/raw sound name from the manifest meta-data key
        // "com.appsonair.apppush.default_notification_sound" if present,
        // otherwise falls back to "custom_sound" if that file exists in res/raw.
        // No host-app code required — the channel is created here automatically.
        createDefaultSoundChannelIfNeeded(applicationContext)

        // Silent push — FCM data-only payload with "silent": "true".
        // Fires on the FCM worker thread; sendEvent() posts to the main thread.
        AppPushService.onSilentPushReceived = { data ->
            sendEvent(mapOf("type" to "silentPushReceived", "data" to data))
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        AppPushService.setListener(null)
        AppPushService.onSilentPushReceived = null
        AppPushService.Notifications.removeForegroundLifecycleListener(this)
        AppPushService.Notifications.removeClickListener(this)
        AppPushService.Notifications.removePermissionObserver(this)
        PushUser.PushSubscription.removeObserver(this)
        AppPushService.User.removeObserver(this)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        AppPushService.handleNotificationTapIntent(binding.activity.intent)
        registerNewIntentListener(binding)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        unregisterNewIntentListener()
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        registerNewIntentListener(binding)
    }

    override fun onDetachedFromActivity() {
        unregisterNewIntentListener()
        activity = null
    }


    private fun registerNewIntentListener(binding: ActivityPluginBinding) {
        activityBinding = binding
        val listener = PluginRegistry.NewIntentListener { intent ->
            AppPushService.handleNotificationTapIntent(intent)
            false
        }
        newIntentListener = listener
        binding.addOnNewIntentListener(listener)
    }

    private fun unregisterNewIntentListener() {
        newIntentListener?.let { activityBinding?.removeOnNewIntentListener(it) }
        newIntentListener = null
        activityBinding = null
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        if (events != null && pendingEvents.isNotEmpty()) {
            val buffered = pendingEvents.toList()
            pendingEvents.clear()
            buffered.forEach { events.success(it) }
        }
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        try {
            when (call.method) {
                "initialize" -> {
                    val debug = call.argument<Boolean>("debug") ?: false
                    AppPushService.initialize(applicationContext, debug)
                    result.success(null)
                }
                "login" -> {
                    AppPushService.login(call.argument<String>("externalId") ?: "")
                    result.success(null)
                }
                "logout" -> {
                    AppPushService.logout()
                    result.success(null)
                }
                "getDeviceId" -> result.success(AppPushService.getDeviceId())
                "setConsentRequired" -> {
                    AppPushService.consentRequired = call.argument<Boolean>("value") ?: false
                    result.success(null)
                }
                "setConsentGiven" -> {
                    AppPushService.consentGiven = call.argument<Boolean>("value") ?: false
                    result.success(null)
                }
                "isPermissionGranted" -> result.success(AppPushService.isPermissionGranted(applicationContext))
                "clearAllNotifications" -> {
                    AppPushService.clearAllNotifications(applicationContext)
                    result.success(null)
                }

                "user#getExternalId" -> result.success(PushUser.externalId)
                "user#pushSubscription#isOptedIn" ->
                    result.success(PushUser.PushSubscription.optedIn)
                "user#pushSubscription#getToken" -> result.success(PushUser.PushSubscription.token)
                "user#pushSubscription#optIn" -> {
                    PushUser.PushSubscription.optIn()
                    result.success(null)
                }
                "user#pushSubscription#optOut" -> {
                    PushUser.PushSubscription.optOut()
                    result.success(null)
                }
                "user#addTag" -> {
                    PushUser.addTag(
                        call.argument<String>("key") ?: "",
                        call.argument<String>("value") ?: ""
                    )
                    result.success(null)
                }
                "user#addTags" -> {
                    @Suppress("UNCHECKED_CAST")
                    val tags = call.argument<Map<String, String>>("tags") ?: emptyMap()
                    PushUser.addTags(tags)
                    result.success(null)
                }
                "user#removeTag" -> {
                    PushUser.removeTag(call.argument<String>("key") ?: "")
                    result.success(null)
                }
                "user#removeTags" -> {
                    @Suppress("UNCHECKED_CAST")
                    val keys = call.argument<List<String>>("keys") ?: emptyList()
                    PushUser.removeTags(keys)
                    result.success(null)
                }
                "user#getTags" -> PushUser.getTags { tags -> result.success(tags) }
                "user#setLanguage" -> {
                    PushUser.setLanguage(call.argument<String>("code") ?: "")
                    result.success(null)
                }
                "user#getLanguage" -> result.success(PushUser.language)
                "user#addAlias" -> {
                    PushUser.addAlias(
                        call.argument<String>("label") ?: "",
                        call.argument<String>("id") ?: ""
                    )
                    result.success(null)
                }
                "user#addAliases" -> {
                    @Suppress("UNCHECKED_CAST")
                    val aliases = call.argument<Map<String, String>>("aliases") ?: emptyMap()
                    PushUser.addAliases(aliases)
                    result.success(null)
                }
                "user#removeAlias" -> {
                    PushUser.removeAlias(call.argument<String>("label") ?: "")
                    result.success(null)
                }
                "user#removeAliases" -> {
                    @Suppress("UNCHECKED_CAST")
                    val labels = call.argument<List<String>>("labels") ?: emptyList()
                    PushUser.removeAliases(labels)
                    result.success(null)
                }
                "user#addEmail" -> {
                    PushUser.addEmail(call.argument<String>("address") ?: "")
                    result.success(null)
                }
                "user#removeEmail" -> {
                    PushUser.removeEmail(call.argument<String>("address") ?: "")
                    result.success(null)
                }

                "notifications#permission" ->
                    result.success(PushNotifications.permission(applicationContext))
                "notifications#canRequestPermission" ->
                    result.success(PushNotifications.canRequestPermission(activity ?: applicationContext))
                "notifications#requestPermission" -> {
                    val currentActivity = activity
                    if (currentActivity == null) {
                        result.error("NO_ACTIVITY", "No attached Activity to request permission from.", null)
                        return
                    }
                    val fallbackToSettings = call.argument<Boolean>("fallbackToSettings") ?: false
                    PushNotifications.requestPermission(currentActivity, fallbackToSettings)
                    result.success(null)
                }
                "notifications#registerForProvisionalAuthorization" -> result.success(null)
                "notifications#clearAll" -> {
                    PushNotifications.clearAllNotifications(applicationContext)
                    result.success(null)
                }
                "notifications#removeNotification" -> {
                    val id = call.argument<String>("id")
                    if (id != null) {
                        PushNotifications.removeNotification(applicationContext, id)
                    }
                    result.success(null)
                }
                "notifications#removeGroupedNotifications" -> {
                    PushNotifications.removeGroupedNotifications(
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

                "debug#setLogLevel" -> {
                    val level = call.argument<String>("level") ?: "none"
                    AppPushService.Debug.logLevel = LogLevel.entries.firstOrNull {
                        it.name.equals(level, ignoreCase = true)
                    } ?: LogLevel.NONE
                    result.success(null)
                }
                "debug#getLogLevel" -> result.success(AppPushService.Debug.logLevel.name.lowercase())

                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            result.error("APPSONAIR_PUSH_ERROR", e.message, null)
        }
    }

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

    override fun onClick(event: NotificationClickEvent) {
        sendEvent(
            mapOf(
                "type" to "notificationClicked",
                "notification" to event.notification.toMap(),
                "actionId" to event.result.actionId
            )
        )
    }

    override fun onNotificationPermissionDidChange(permission: Boolean) {
        sendEvent(mapOf("type" to "permissionChanged", "granted" to permission))
    }

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

    override fun onUserStateDidChange(state: UserChangedState) {
        sendEvent(
            mapOf(
                "type" to "userChanged",
                "externalId" to state.current.externalId,
                "appsonairId" to state.current.appsOnAirId
            )
        )
    }

    private fun PushNotification.toMap(): Map<String, Any?> =
        mapOf("id" to id, "title" to title, "body" to body, "data" to data)

    /**
     * Creates a custom-sound notification channel without any host-app or method-channel code.
     *
     * Sound resolution order:
     *   1. Manifest meta-data "com.appsonair.apppush.default_notification_sound" — lets the host
     *      app declare a sound name without writing any Kotlin.
     *   2. "custom_sound" — if a res/raw/custom_sound.* file exists in the host app.
     *   3. Nothing — skip silently; the SDK's default channel (no custom sound) is used.
     *
     * The channel ID follows the SDK convention: appsonair_push_channel_snd_<soundName>.
     * createNotificationChannel() is a no-op if the channel already exists, so calling this
     * on every engine attach is safe.
     */
    private fun createDefaultSoundChannelIfNeeded(context: Context) {
        val soundName = metaDataSoundName(context) ?: fallbackSoundName(context) ?: return
        AppPushService.Notifications.createNotificationChannel(
            context = context,
            id = "appsonair_push_channel_snd_$soundName",
            name = "Push Notifications ($soundName)",
            sound = soundName
        )
    }

    /** Reads "com.appsonair.apppush.default_notification_sound" from AndroidManifest meta-data. */
    private fun metaDataSoundName(context: Context): String? = try {
        val ai = context.packageManager.getApplicationInfo(
            context.packageName, android.content.pm.PackageManager.GET_META_DATA
        )
        ai.metaData?.getString("com.appsonair.apppush.default_notification_sound")
            ?.takeIf { it.isNotBlank() }
    } catch (_: Exception) { null }

    /** Returns "custom_sound" if res/raw/custom_sound.* exists in the host app. */
    private fun fallbackSoundName(context: Context): String? {
        val name = "custom_sound"
        val resId = context.resources.getIdentifier(name, "raw", context.packageName)
        return if (resId != 0) name else null
    }

    private fun wireErrorCode(code: PushError.Code): String = when (code) {
        PushError.Code.NOT_INITIALIZED -> "notInitialized"
        PushError.Code.PERMISSION_DENIED -> "permissionDenied"
        PushError.Code.TOKEN_FETCH_FAILED -> "tokenFetchFailed"
        PushError.Code.INSTALLATION_ID_FETCH_FAILED -> "installationIdFetchFailed"
        PushError.Code.FIREBASE_NOT_CONFIGURED -> "firebaseNotConfigured"
        PushError.Code.UNKNOWN -> "unknown"
    }
}
