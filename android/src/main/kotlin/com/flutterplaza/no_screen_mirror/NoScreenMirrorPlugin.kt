package com.flutterplaza.no_screen_mirror

import android.content.Context
import android.hardware.display.DisplayManager
import android.media.MediaRouter
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.view.Display
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject

const val START_LISTENING_CONST = "startListening"
const val STOP_LISTENING_CONST = "stopListening"
const val MIRROR_METHOD_CHANNEL = "com.flutterplaza.no_screen_mirror_methods"
const val MIRROR_EVENT_CHANNEL = "com.flutterplaza.no_screen_mirror_streams"

class NoScreenMirrorPlugin : FlutterPlugin, MethodChannel.MethodCallHandler, ActivityAware,
    EventChannel.StreamHandler {
    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private lateinit var context: Context
    private val handler = Handler(Looper.getMainLooper())
    private var eventSink: EventChannel.EventSink? = null
    private var lastEventJson: String = ""
    private var hasPendingEvent: Boolean = false
    private var isListening: Boolean = false

    private var displayManager: DisplayManager? = null
    private var mediaRouter: MediaRouter? = null
    private var displayListener: DisplayManager.DisplayListener? = null
    private var mediaRouterCallback: MediaRouter.Callback? = null

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext

        methodChannel = MethodChannel(flutterPluginBinding.binaryMessenger, MIRROR_METHOD_CHANNEL)
        methodChannel.setMethodCallHandler(this)

        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, MIRROR_EVENT_CHANNEL)
        eventChannel.setStreamHandler(this)
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        stopDetection()
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {}
    override fun onDetachedFromActivityForConfigChanges() {}
    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {}
    override fun onDetachedFromActivity() {}

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: MethodChannel.Result) {
        when (call.method) {
            START_LISTENING_CONST -> {
                startDetection()
                result.success("Listening started")
            }
            STOP_LISTENING_CONST -> {
                stopDetection()
                result.success("Listening stopped")
            }
            else -> result.notImplemented()
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        handler.postDelayed(streamRunnable, 1000)
    }

    override fun onCancel(arguments: Any?) {
        handler.removeCallbacks(streamRunnable)
        eventSink = null
    }

    private fun startDetection() {
        if (isListening) return
        isListening = true

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR1) {
            displayManager = context.getSystemService(Context.DISPLAY_SERVICE) as? DisplayManager
            displayListener = object : DisplayManager.DisplayListener {
                override fun onDisplayAdded(displayId: Int) { updateState() }
                override fun onDisplayRemoved(displayId: Int) { updateState() }
                override fun onDisplayChanged(displayId: Int) { updateState() }
            }
            displayManager?.registerDisplayListener(displayListener, handler)

            mediaRouter = context.getSystemService(Context.MEDIA_ROUTER_SERVICE) as? MediaRouter
            mediaRouterCallback = object : MediaRouter.Callback() {
                override fun onRouteSelected(router: MediaRouter?, type: Int, info: MediaRouter.RouteInfo?) {
                    updateState()
                }
                override fun onRouteUnselected(router: MediaRouter?, type: Int, info: MediaRouter.RouteInfo?) {
                    updateState()
                }
                override fun onRouteChanged(router: MediaRouter?, info: MediaRouter.RouteInfo?) {
                    updateState()
                }
            }
            mediaRouter?.addCallback(MediaRouter.ROUTE_TYPE_LIVE_VIDEO, mediaRouterCallback)
        }

        updateState()
    }

    private fun stopDetection() {
        if (!isListening) return
        isListening = false

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR1) {
            displayListener?.let { displayManager?.unregisterDisplayListener(it) }
            mediaRouterCallback?.let { mediaRouter?.removeCallback(it) }
        }

        displayListener = null
        mediaRouterCallback = null
        displayManager = null
        mediaRouter = null
    }

    private fun updateState() {
        var displayCount = 1
        var isExternalDisplayConnected = false
        var isScreenMirrored = false

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR1) {
            val displays = displayManager?.displays ?: emptyArray()
            displayCount = displays.size.coerceAtLeast(1)

            for (display in displays) {
                if (display.displayId != Display.DEFAULT_DISPLAY) {
                    isExternalDisplayConnected = true
                    if (display.flags and Display.FLAG_PRESENTATION != 0) {
                        isExternalDisplayConnected = true
                    }
                }
            }

            // Check wireless mirroring via MediaRouter
            val route = mediaRouter?.getSelectedRoute(MediaRouter.ROUTE_TYPE_LIVE_VIDEO)
            if (route != null && route.playbackType == MediaRouter.RouteInfo.PLAYBACK_TYPE_REMOTE) {
                isScreenMirrored = true
            }
        }

        val json = JSONObject(
            mapOf(
                "is_screen_mirrored" to isScreenMirrored,
                "is_external_display_connected" to isExternalDisplayConnected,
                "display_count" to displayCount
            )
        ).toString()

        if (lastEventJson != json) {
            lastEventJson = json
            hasPendingEvent = true
        }
    }

    private val streamRunnable = object : Runnable {
        override fun run() {
            if (hasPendingEvent) {
                eventSink?.success(lastEventJson)
                hasPendingEvent = false
            }
            handler.postDelayed(this, 1000)
        }
    }
}
