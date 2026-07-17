package me.jxl.kiosk_satellite

import android.app.Activity
import android.app.ActivityManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.graphics.PixelFormat
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.provider.Settings
import android.view.Gravity
import android.view.KeyEvent
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * The Activity-scoped half of kiosk lockdown. Dart pushes the armed flags via
 * "apply"; this class does what each one needs a real Activity (or window)
 * for:
 *
 *  - volume:    swallowed in [onKey] (MainActivity forwards dispatchKeyEvent).
 *  - power:     cannot be intercepted on Android — a SCREEN_OFF receiver
 *               re-wakes the display instead.
 *  - statusBar: an overlay shield over the top edge eats the pull-down swipe;
 *               needs the draw-over-apps grant.
 *  - home:      OS screen pinning (lock task). Without device-owner Android
 *               shows a one-time confirmation, and that is the honest limit
 *               of what a store app can do.
 *  - gestureTaps: N fast taps anywhere (counted in [onTouch], which sees
 *               every pointer before the WebView does) fire "exitGesture"
 *               back to Dart, which owns the PIN prompt and the menu.
 */
class KioskLock(private val activity: Activity, messenger: BinaryMessenger) {
    private val channel = MethodChannel(messenger, "kiosk_satellite/kiosk_lock")
    private val main = Handler(Looper.getMainLooper())

    @Volatile private var blockVolume = false
    @Volatile private var blockBack = false
    @Volatile private var gestureTaps = 0

    private var wakeOnScreenOff = false
    private var screenOffReceiver: BroadcastReceiver? = null
    private var shield: View? = null

    private var tapCount = 0
    private var lastTapAt = 0L

    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "apply" -> {
                    blockVolume = call.argument<Boolean>("volume") ?: false
                    blockBack = call.argument<Boolean>("back") ?: false
                    gestureTaps = call.argument<Int>("gestureTaps") ?: 0
                    setWakeOnScreenOff(call.argument<Boolean>("power") ?: false)
                    setShield(call.argument<Boolean>("statusBar") ?: false)
                    setPinned(call.argument<Boolean>("home") ?: false)
                    result.success(null)
                }
                "hasOverlayPermission" ->
                    result.success(Settings.canDrawOverlays(activity))
                "requestOverlayPermission" -> {
                    activity.startActivity(
                        Intent(
                            Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                            Uri.parse("package:${activity.packageName}"),
                        )
                    )
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
        // The engine outlives Activities; each new Activity announces itself
        // so Dart re-pushes the flags (a fresh Activity starts unarmed).
        channel.invokeMethod("ready", null)
    }

    /** Forwarded from MainActivity.dispatchKeyEvent. True = consumed. */
    fun onKey(event: KeyEvent): Boolean {
        when (event.keyCode) {
            KeyEvent.KEYCODE_VOLUME_UP,
            KeyEvent.KEYCODE_VOLUME_DOWN,
            KeyEvent.KEYCODE_VOLUME_MUTE -> if (blockVolume) return true
            // Back would background the whole kiosk. Swallowed here; Dart
            // decides what it means instead (close the menu, step the page's
            // history) — never leaving the app.
            KeyEvent.KEYCODE_BACK -> if (blockBack) {
                if (event.action == KeyEvent.ACTION_UP) {
                    main.post { channel.invokeMethod("backPressed", null) }
                }
                return true
            }
        }
        return false
    }

    /**
     * Forwarded from MainActivity.dispatchTouchEvent (never consumes). Fast
     * consecutive DOWNs — under 400 ms apart — count toward the exit gesture;
     * a pause resets. Normal dashboard use never chains that many taps that
     * fast, and a false positive only costs a PIN prompt.
     */
    fun onTouch(event: MotionEvent) {
        val needed = gestureTaps
        if (needed <= 0 || event.actionMasked != MotionEvent.ACTION_DOWN) return
        val now = event.eventTime
        tapCount = if (now - lastTapAt <= 400) tapCount + 1 else 1
        lastTapAt = now
        if (tapCount >= needed) {
            tapCount = 0
            main.post { channel.invokeMethod("exitGesture", null) }
        }
    }

    private fun setWakeOnScreenOff(enabled: Boolean) {
        if (enabled == wakeOnScreenOff) return
        wakeOnScreenOff = enabled
        if (enabled) {
            if (Build.VERSION.SDK_INT >= 27) {
                activity.setShowWhenLocked(true)
                activity.setTurnScreenOn(true)
            }
            val receiver = object : BroadcastReceiver() {
                override fun onReceive(context: Context, intent: Intent) {
                    // ACQUIRE_CAUSES_WAKEUP is the entire point; the
                    // deprecated full-wake-lock combination is still the only
                    // way to relight the panel without device-owner powers.
                    @Suppress("DEPRECATION")
                    val lock = (context.getSystemService(Context.POWER_SERVICE)
                            as PowerManager).newWakeLock(
                        PowerManager.SCREEN_BRIGHT_WAKE_LOCK
                                or PowerManager.ACQUIRE_CAUSES_WAKEUP,
                        "ks:kioskRewake",
                    )
                    lock.acquire(3000)
                }
            }
            screenOffReceiver = receiver
            activity.registerReceiver(
                receiver, IntentFilter(Intent.ACTION_SCREEN_OFF))
        } else {
            screenOffReceiver?.let { activity.unregisterReceiver(it) }
            screenOffReceiver = null
            if (Build.VERSION.SDK_INT >= 27) {
                activity.setShowWhenLocked(false)
                activity.setTurnScreenOn(false)
            }
        }
    }

    private fun setShield(enabled: Boolean) {
        if (enabled && shield == null) {
            if (!Settings.canDrawOverlays(activity)) return
            val height = activity.resources.let { res ->
                val id = res.getIdentifier(
                    "status_bar_height", "dimen", "android")
                if (id > 0) res.getDimensionPixelSize(id)
                else (32 * res.displayMetrics.density).toInt()
            }
            val view = View(activity)
            // Consuming every touch on the top strip means the system never
            // sees the edge swipe that expands the status bar.
            view.setOnTouchListener { v, _ -> v.performClick(); true }
            val params = WindowManager.LayoutParams(
                WindowManager.LayoutParams.MATCH_PARENT,
                height,
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE
                        or WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
                PixelFormat.TRANSLUCENT,
            )
            params.gravity = Gravity.TOP
            activity.getSystemService(WindowManager::class.java)
                .addView(view, params)
            shield = view
        } else if (!enabled && shield != null) {
            activity.getSystemService(WindowManager::class.java)
                .removeView(shield)
            shield = null
        }
    }

    private fun setPinned(enabled: Boolean) {
        val am = activity.getSystemService(ActivityManager::class.java)
        val pinned =
            am.lockTaskModeState != ActivityManager.LOCK_TASK_MODE_NONE
        try {
            if (enabled && !pinned) activity.startLockTask()
            if (!enabled && pinned) activity.stopLockTask()
        } catch (_: Exception) {
            // Racing the pin state (or a denied confirmation) is not fatal.
        }
    }

    fun dispose() {
        setShield(false)
        screenOffReceiver?.let { activity.unregisterReceiver(it) }
        screenOffReceiver = null
        channel.setMethodCallHandler(null)
    }
}
