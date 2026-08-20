package me.jxl.kiosk_satellite

import android.app.Activity
import android.app.ActivityManager
import android.app.admin.DevicePolicyManager
import android.content.ComponentName
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
import android.os.SystemClock
import android.provider.Settings
import android.view.Gravity
import android.view.KeyEvent
import android.view.MotionEvent
import android.view.View
import android.view.ViewConfiguration
import android.view.WindowInsets
import android.view.WindowManager
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import kotlin.math.abs

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
 *               With gestureTapHold set the last tap must also be held
 *               still for a second (issue #120).
 *  - gestures:  configurable hidden gestures (issue #99), detected by
 *               [GestureEngine] on the same observe-only feed; each hit
 *               fires "gesture" with the mapping id back to Dart.
 */
class KioskLock(private val activity: Activity, messenger: BinaryMessenger) {
    companion object {
        /**
         * When this app last powered the screen off on purpose, on the
         * elapsed-realtime clock (0 = never).
         *
         * The power-button defence below cannot tell a button press from any
         * other reason the display went dark, because Android reports both as
         * the same broadcast. Without this, "turn the screen off" from Home
         * Assistant, the remote admin or a schedule was undone a second later
         * by our own re-wake, leaving the panel back on and showing the lock
         * screen (issue #51).
         */
        @Volatile private var appScreenOffAt = 0L

        /**
         * Height of the status-bar shield in dp. Tall enough that the
         * shade-opening swipe (which must start at the display's very
         * edge) always lands on the shield, short enough that a page's
         * own top-edge UI stays tappable (issue #142).
         */
        private const val SHIELD_EDGE_DP = 12

        /** Called by [BackgroundBridge] immediately before its lockNow. */
        fun noteAppScreenOff() {
            appScreenOffAt = SystemClock.elapsedRealtime()
        }

        /**
         * Whether the screen-off now being reported is the one this app just
         * asked for. The broadcast follows lockNow within milliseconds; the
         * window is wide only so a busy device cannot squeeze past it.
         */
        private fun screenOffWasOurs(): Boolean {
            val at = appScreenOffAt
            return at != 0L && SystemClock.elapsedRealtime() - at < 5_000
        }
    }

    private val channel = MethodChannel(messenger, "kiosk_satellite/kiosk_lock")
    private val main = Handler(Looper.getMainLooper())

    @Volatile private var blockVolume = false
    @Volatile private var blockBack = false
    @Volatile private var gestureTaps = 0
    @Volatile private var gestureTapHold = false
    private var barWatch = false
    private var barTicker: Runnable? = null

    private var wakeOnScreenOff = false
    private var screenOffReceiver: BroadcastReceiver? = null
    private var shield: View? = null

    private var tapCount = 0
    private var lastTapAt = 0L
    private var exitHold: Runnable? = null
    private var exitHoldX = 0f
    private var exitHoldY = 0f
    private val slop = ViewConfiguration.get(activity).scaledTouchSlop * 2

    private val gestures = GestureEngine(activity) { id ->
        main.post { channel.invokeMethod("gesture", id) }
    }

    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "apply" -> {
                    blockVolume = call.argument<Boolean>("volume") ?: false
                    blockBack = call.argument<Boolean>("back") ?: false
                    gestureTaps = call.argument<Int>("gestureTaps") ?: 0
                    gestureTapHold =
                        call.argument<Boolean>("gestureTapHold") ?: false
                    gestures.configure(
                        call.argument<List<Map<String, Any?>>>("gestures"))
                    setWakeOnScreenOff(call.argument<Boolean>("power") ?: false)
                    setShield(call.argument<Boolean>("statusBar") ?: false)
                    setPinned(
                        call.argument<Boolean>("home") ?: false,
                        call.argument<Boolean>("homeSilent") ?: false,
                    )
                    setBarWatch(call.argument<Boolean>("bars") ?: false)
                    // The System UI guard, if the owner enabled it in
                    // Accessibility settings; a no-op otherwise.
                    KioskAccessibilityService.guardShade =
                        call.argument<Boolean>("a11yShade") ?: false
                    KioskAccessibilityService.guardRecents =
                        call.argument<Boolean>("a11yRecents") ?: false
                    // The screen-level lockdown shield. Its window consumes
                    // every touch, so the exit-gesture counter is fed from
                    // there instead of the Activity while it is up.
                    LockShieldOverlay.onTouch = { ev -> onTouch(ev) }
                    LockShieldOverlay.sync(
                        activity.applicationContext,
                        call.argument<Boolean>("lockShield") ?: false,
                        call.argument<Boolean>("lockBlackout") ?: false,
                    )
                    // Not a lockdown flag; it rides this channel because the
                    // channel already re-pushes on every settings change and
                    // to every new Activity. MainActivity.onCreate seeds the
                    // same value from the settings mirror.
                    call.argument<String>("cutout")?.let {
                        CutoutLayout.apply(activity, it)
                    }
                    result.success(null)
                }
                "hasOverlayPermission" ->
                    result.success(Settings.canDrawOverlays(activity))
                "hasUiGuard" ->
                    result.success(KioskAccessibilityService.running)
                "isPinned" -> {
                    val am = activity.getSystemService(ActivityManager::class.java)
                    result.success(
                        am.lockTaskModeState !=
                            ActivityManager.LOCK_TASK_MODE_NONE
                    )
                }
                "lockShieldPassThrough" -> {
                    LockShieldOverlay.setPassThrough(
                        activity.applicationContext,
                        call.argument<Boolean>("value") ?: false,
                    )
                    result.success(null)
                }
                "openUiGuardSettings" -> {
                    activity.startActivity(
                        Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                    )
                    result.success(null)
                }
                "requestOverlayPermission" -> {
                    activity.startActivity(
                        Intent(
                            Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                            Uri.parse("package:${activity.packageName}"),
                        )
                    )
                    result.success(null)
                }
                // Stand the pin down for a sanctioned outward launch (issue
                // #250): Android refuses to switch away from a pinned task,
                // so launchApp under Disable home button only produced the
                // system's unpin toast. Returns whether a pin was actually
                // dropped, so Dart can re-arm right away if the launch then
                // fails (its resume re-pin never fires without a pause).
                "unpin" -> {
                    val am = activity.getSystemService(ActivityManager::class.java)
                    val pinned = am.lockTaskModeState !=
                        ActivityManager.LOCK_TASK_MODE_NONE
                    if (pinned) {
                        try {
                            activity.stopLockTask()
                        } catch (_: Exception) {
                            // Racing the pin state is not fatal.
                        }
                    }
                    result.success(pinned)
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
     *
     * With [gestureTapHold] set, reaching the count arms a one-second
     * deadline on the tap that got there instead of firing: the finger must
     * stay down and still (issue #120). Tapping a dashboard button
     * repeatedly can reach any count, but every mash ends in a lift, never
     * a hold. An early lift keeps the chain, so the next fast tap re-arms.
     */
    fun onTouch(event: MotionEvent) {
        gestures.onTouch(event)
        val needed = gestureTaps
        if (needed <= 0) return
        when (event.actionMasked) {
            MotionEvent.ACTION_DOWN -> {
                val now = event.eventTime
                tapCount = if (now - lastTapAt <= 400) tapCount + 1 else 1
                lastTapAt = now
                if (tapCount < needed) return
                if (!gestureTapHold) {
                    tapCount = 0
                    main.post { channel.invokeMethod("exitGesture", null) }
                    return
                }
                exitHoldX = event.x
                exitHoldY = event.y
                val fire = Runnable {
                    exitHold = null
                    tapCount = 0
                    channel.invokeMethod("exitGesture", null)
                }
                cancelExitHold()
                exitHold = fire
                main.postDelayed(fire, 1000)
            }
            MotionEvent.ACTION_MOVE -> {
                if (exitHold != null &&
                    (abs(event.x - exitHoldX) > slop ||
                        abs(event.y - exitHoldY) > slop)
                ) cancelExitHold()
            }
            MotionEvent.ACTION_POINTER_DOWN,
            MotionEvent.ACTION_UP,
            MotionEvent.ACTION_CANCEL -> cancelExitHold()
        }
    }

    private fun cancelExitHold() {
        exitHold?.let { main.removeCallbacks(it) }
        exitHold = null
    }

    /**
     * In *sticky* immersive the transient bars are a system override: they
     * notify nothing and ignore app re-hide requests, so kiosk mode runs in
     * plain immersive instead (Dart flips the mode with the master switch),
     * where a revealed bar is an ordinary one that hide() dismisses. This
     * ticker is the guarantee that the request keeps being made, whatever
     * notification the platform did or did not deliver.
     */
    private fun setBarWatch(enabled: Boolean) {
        if (Build.VERSION.SDK_INT < 30 || enabled == barWatch) return
        barWatch = enabled
        barTicker?.let { main.removeCallbacks(it) }
        barTicker = null
        if (enabled) {
            val tick = object : Runnable {
                override fun run() {
                    if (!barWatch) return
                    hideBars()
                    main.postDelayed(this, 400)
                }
            }
            barTicker = tick
            main.postDelayed(tick, 400)
        }
    }

    private fun hideBars() {
        if (Build.VERSION.SDK_INT >= 30) {
            // Only when a bar is actually showing: an unconditional hide()
            // kicks a no-op insets animation even when everything is already
            // hidden, and at this ticker's cadence that renders the whole
            // window at ~20fps forever - measured as a third of the app's
            // constant CPU burn (and its allocation churn) on an Echo Show 5.
            val insets = activity.window.decorView.rootWindowInsets
            val visible = insets == null ||
                insets.isVisible(WindowInsets.Type.statusBars()) ||
                insets.isVisible(WindowInsets.Type.navigationBars())
            if (!visible) return
            activity.window.insetsController?.hide(
                WindowInsets.Type.statusBars()
                        or WindowInsets.Type.navigationBars())
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
                    // Not every screen-off is a power-button press: this app
                    // turns the display off itself on request, and undoing
                    // that would make the feature impossible to use while
                    // kiosk mode is armed (issue #51).
                    if (screenOffWasOurs()) return
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
            // Only the very edge, NOT the full status_bar_height: the
            // shade-opening swipe has to BEGIN within the first few
            // pixels of the display (measured on One UI: a swipe from
            // y=1 opens the full shade through immersive mode, a swipe
            // from y=30 already belongs to the page). A full-height
            // shield also swallowed taps on page UI living along the
            // top edge - a Home Assistant dashboard's view-tab bar sits
            // exactly there (issue #142).
            val band =
                (SHIELD_EDGE_DP * activity.resources.displayMetrics.density)
                    .toInt()
            val view = View(activity)
            // Consuming the drag in the edge band stops the one-motion
            // shade pull. It cannot stop everything: the system still
            // flashes the transient bar on an edge swipe (that detection
            // is the system's, independent of who consumes the touches),
            // and a second drag starting ON the visible bar goes to the
            // status bar window, which sits above any app overlay — true
            // of the old full-height shield too, verified side by side.
            // The hard guarantee against that is lock task mode (the
            // Disable home button setting), where the OS itself disables
            // the shade.
            view.setOnTouchListener { v, _ -> v.performClick(); true }
            val params = WindowManager.LayoutParams(
                WindowManager.LayoutParams.MATCH_PARENT,
                band,
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

    private fun setPinned(enabled: Boolean, silentOnly: Boolean) {
        val am = activity.getSystemService(ActivityManager::class.java)
        val pinned =
            am.lockTaskModeState != ActivityManager.LOCK_TASK_MODE_NONE
        try {
            if (enabled && !pinned) {
                // Device owner (provisioned with `dpm set-device-owner`):
                // whitelist ourselves first, so startLockTask enters the
                // real LOCKED mode — no confirmation, no "app is pinned"
                // toast, no Back+Recents escape, home and recents removed
                // from the bar. Without it, plain screen pinning: the
                // ceiling Android sets for a store app.
                val dpm = activity.getSystemService(DevicePolicyManager::class.java)
                val owner = dpm.isDeviceOwnerApp(activity.packageName)
                // Plain pinning is consent-gated: SystemUI holds the pin
                // until whoever is at the screen answers a dialog that
                // offers "No thanks" and spells out the unpin gesture —
                // every entry, not just the first. A silent-only request
                // (lockdown, flipped remotely with nobody cooperative in
                // front of the device) therefore pins only on the device
                // owner path; Dart covers the gap by reclaiming the
                // foreground when the app loses it.
                if (silentOnly && !owner) return
                if (owner) {
                    val admin = ComponentName(activity, KioskAdminReceiver::class.java)
                    dpm.setLockTaskPackages(admin, arrayOf(activity.packageName))
                    if (Build.VERSION.SDK_INT >= 28) {
                        dpm.setLockTaskFeatures(
                            admin, DevicePolicyManager.LOCK_TASK_FEATURE_NONE)
                    }
                }
                activity.startLockTask()
            }
            if (!enabled && pinned) activity.stopLockTask()
        } catch (_: Exception) {
            // Racing the pin state (or a denied confirmation) is not fatal.
        }
    }

    fun dispose() {
        cancelExitHold()
        gestures.reset()
        setBarWatch(false)
        setShield(false)
        // The lock shield outlives the Activity on purpose (it holds the
        // screen while the reclaim watchdog rebuilds the kiosk); only the
        // stale tap hook is dropped. The next Activity re-hooks in apply.
        LockShieldOverlay.onTouch = null
        screenOffReceiver?.let { activity.unregisterReceiver(it) }
        screenOffReceiver = null
        channel.setMethodCallHandler(null)
    }
}
