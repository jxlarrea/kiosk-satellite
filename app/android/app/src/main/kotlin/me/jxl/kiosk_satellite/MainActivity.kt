package me.jxl.kiosk_satellite

import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.os.PowerManager
import android.view.KeyEvent
import android.view.MotionEvent
import android.view.View
import android.view.inputmethod.InputMethodManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.plugin.common.MethodChannel

/**
 * Attaches to the process-wide engine from [KioskApplication] instead of
 * spinning up its own, so destroying this Activity does not take the Dart
 * isolate (and the admin server with it) down. It only owns the bridges that
 * genuinely need a live Activity — the camera and the launch intent — and tears
 * those down when it detaches; the engine lives on.
 */
/** Native ground truth for "an Activity is in front", readable from Dart
 *  through the background bridge. The engine's own lifecycle reporting is
 *  not trustworthy across a failed re-attach — these callbacks are. */
object ActivityState {
    @Volatile var resumed = false

    /** Whether an Activity is attached to the cached engine right now.
     *  Platform views can only be created while this holds — the engine's
     *  platform-views channel has no handler otherwise — so the Dart side
     *  gates the first dashboard WebView build on it (issue #145: on slow
     *  devices Dart boots and builds the WebView before the Activity's
     *  attach lands, the create dies, and the kiosk sits black). */
    @Volatile var attached = false
}

class MainActivity : FlutterActivity() {
    private var provisionChannel: MethodChannel? = null
    private var adminChannel: MethodChannel? = null
    private var deviceCamera: DeviceCamera? = null
    private var cameraMotion: CameraMotion? = null
    private var screenCapture: ScreenCapture? = null
    private var kioskLock: KioskLock? = null
    private var webViewFreeze: WebViewFreeze? = null

    /** See dispatchKeyEvent: where native focus sits while Flutter owns
     *  the navigation keys. */
    private var focusParking: View? = null

    override fun provideFlutterEngine(context: Context): FlutterEngine? =
        FlutterEngineCache.getInstance().get(KioskApplication.ENGINE_ID)

    override fun onCreate(savedInstanceState: Bundle?) {
        // The home-launcher crash fuse (issue #219): a kiosk that cannot
        // boot while it IS the home app must give HOME back to the OEM
        // launcher instead of stranding whoever is at the screen. Counted
        // before super.onCreate so a crash inside the Flutter attach
        // itself still lands on the counter; the finish() waits until
        // after super, where it is legal, and a finished Activity skips
        // the rest of its lifecycle so the system re-resolves HOME on its
        // next dispatch.
        val fuseTripped = HomeFuse.noteBootAttempt(this)
        super.onCreate(savedInstanceState)
        if (fuseTripped) {
            finish()
            return
        }
        // Lay the window out edge to edge ourselves. Flutter's immersive mode
        // hides the bars through the legacy systemUiVisibility layout flags,
        // and Lenovo's ZUI ROMs honor the hide but not the layout: the status
        // bar strip stays reserved, a permanent gap above the dashboard
        // (discussion #102). Opting into the modern inset pipeline makes those
        // ROMs extend the window under the bars. Everywhere else this is the
        // layout the legacy flags already produced; either way the insets
        // still reach Flutter as viewPadding (zero while the bars are hidden),
        // so on-app screens keep their SafeArea behavior. Flutter never
        // reverts the flag: its disableEdgeToEdge only fires if Dart had
        // requested SystemUiMode.edgeToEdge, which this app never does.
        if (Build.VERSION.SDK_INT >= 30) {
            window.setDecorFitsSystemWindows(false)
        }
        // The cutout half of the layout is a setting (browser.cutout_mode).
        // Dart re-pushes it through KioskLock on every change and on each new
        // Activity, but that lands a beat after the first frame; reading the
        // shared_preferences mirror here means the window never flashes the
        // wrong shape.
        val mode = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            .getString("flutter.ks.browser.cutout_mode", null) ?: "always"
        CutoutLayout.apply(this, mode)
        // One transparent pixel that can hold native focus; see
        // dispatchKeyEvent. Not clickable, so the touch at that pixel
        // falls through to the app.
        focusParking = View(this).apply {
            isFocusable = true
            isFocusableInTouchMode = true
        }
        addContentView(
            focusParking,
            android.view.ViewGroup.LayoutParams(1, 1),
        )
        // The app comes up with the FlutterView focused — with a dpad or
        // keyboard attached that is a green frame around the whole screen
        // before a single key is pressed. Park once the first layout is in.
        window.decorView.post { parkFocusIfIdle() }
    }

    /**
     * Move native focus onto the parking pixel whenever the FlutterView
     * itself holds it (or nothing does) and no field is taking text: One
     * UI paints its hardware-key focus frame around the focused view, and
     * around the screen-filling FlutterView that is a green border
     * wrapping the entire app. Text input is the one thing that genuinely
     * needs the FlutterView focused, and it takes the focus back on its
     * own. A focused WebView is left alone — the frame skips it, and the
     * dashboard needs its focus for page navigation.
     */
    fun parkFocusIfIdle() {
        val parking = focusParking ?: return
        val focused = currentFocus
        if (focused != null &&
            focused !== findViewById<View>(FLUTTER_VIEW_ID)) return
        if (isTextEditing()) return
        parking.requestFocus()
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        // The immersive mode, re-asserted from this side for a window that
        // was just created under the cached engine (SystemBars).
        if (hasFocus) SystemBars.reassertOnFocus(this)
    }

    override fun onResume() {
        super.onResume()
        ActivityState.resumed = true
        // Persisted so the crash self-heal (CrashSelfHeal) can tell "died
        // while on screen" from "user left for another app": only the former
        // may bring the kiosk back on its own. A clean exit and a Home press
        // both pass through onPause first, so the flag is false for those.
        setWasForeground(true)
        // Arm the recovery hooks for a native crash (issue #94): a sticky
        // guard service plus a heartbeat alarm, both no-ops until the process
        // dies with the flag above still true.
        CrashSelfHeal.arm(this)
    }

    override fun onPause() {
        super.onPause()
        ActivityState.resumed = false
        // The panel going dark pauses the Activity too, and that is not
        // the user leaving: the kiosk is still what is on screen, just a
        // screen that is off. A crash while it is off (issue #331: a
        // camera feature kept running through it) must bring the kiosk
        // back like any other, or the next screen-on finds the launcher
        // while the service keeps the device "online" in Home Assistant.
        // A Home press or an app switch happens on a lit screen.
        val power = getSystemService(Context.POWER_SERVICE) as PowerManager
        if (power.isInteractive) setWasForeground(false)
    }

    private fun setWasForeground(value: Boolean) {
        getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            .edit().putBoolean("flutter.ks.crash.was_foreground", value).apply()
    }

    // The engine belongs to the process, not this Activity.
    override fun shouldDestroyEngineWithHost(): Boolean = false

    override fun onFlutterUiDisplayed() {
        super.onFlutterUiDisplayed()
        // A frame is on screen, so the renderer works on this GPU: stand
        // the early-crash net down (issue #127, RendererGuard) and the
        // home-launcher fuse with it (issue #219, HomeFuse).
        RendererGuard.noteFirstFrame(this)
        HomeFuse.noteHealthy(this)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != HomeRole.REQ_HOME_ROLE) return
        // The dialog's resultCode is not trustworthy across OEMs; what the
        // role actually resolves to is. Denials are counted because Android
        // quietly auto-denies the dialog after about two refusals, at which
        // point the UI switches to the system's home settings screen.
        val held = HomeRole.isHeld(this)
        HomeFuse.noteRoleResult(this, held)
        kioskLock?.notifyHomeRoleResult(held)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        // Deliberately not calling super: plugins are registered once on the
        // cached engine in KioskApplication. Only Activity-scoped bridges here.
        //
        // The delegate calls this after attachToActivity, so the engine's
        // platform-views surface is live by the time the flag flips.
        ActivityState.attached = true
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        // The snapshot bridge first: motion detection pre-binds its capture
        // use case so the two share one camera session.
        deviceCamera = DeviceCamera(this, messenger)
        cameraMotion = CameraMotion(this, messenger, deviceCamera)
        screenCapture = ScreenCapture(this, messenger)
        kioskLock = KioskLock(this, messenger)
        webViewFreeze = WebViewFreeze(this, messenger)
        provisionChannel = MethodChannel(messenger, "kiosk_satellite/provision")
        provisionChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "getProvisionJson" -> result.success(intent?.getStringExtra("ks.provision"))
                else -> result.notImplemented()
            }
        }
        // Device-admin grant for "Screen off" (lockNow). Launched from the
        // Activity, not the application context: Samsung only presents the
        // proper one-tap activation dialog to a foreground Activity — the
        // NEW_TASK variant lands on the admin-apps list instead (or nowhere).
        adminChannel = MethodChannel(messenger, "kiosk_satellite/admin")
        adminChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "requestScreenOffAdmin" -> {
                    try {
                        startActivity(
                            Intent(android.app.admin.DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN).apply {
                                putExtra(
                                    android.app.admin.DevicePolicyManager.EXTRA_DEVICE_ADMIN,
                                    android.content.ComponentName(
                                        this@MainActivity, KioskAdminReceiver::class.java),
                                )
                                putExtra(
                                    android.app.admin.DevicePolicyManager.EXTRA_ADD_EXPLANATION,
                                    "Lets Kiosk Satellite turn the screen off on request.",
                                )
                            },
                        )
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("admin", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
        // Cold launch: Dart's provisioning pull runs at process start, before
        // this Activity exists, so push the launch-intent extra now.
        intent?.getStringExtra("ks.provision")?.let {
            provisionChannel?.invokeMethod("provision", it)
        }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        // Counterpart to configureFlutterEngine: drop the Activity-scoped
        // bridges as we detach. The engine (and its Dart isolate) stays.
        ActivityState.attached = false
        cameraMotion?.dispose()
        cameraMotion = null
        deviceCamera?.dispose()
        deviceCamera = null
        screenCapture?.dispose()
        screenCapture = null
        kioskLock?.dispose()
        kioskLock = null
        webViewFreeze?.dispose()
        webViewFreeze = null
        provisionChannel?.setMethodCallHandler(null)
        provisionChannel = null
        adminChannel?.setMethodCallHandler(null)
        adminChannel = null
    }

    // Kiosk lockdown sees every key and pointer first: volume keys may be
    // swallowed, and fast taps are counted toward the exit gesture. Touches
    // are observed, never consumed.
    override fun dispatchKeyEvent(event: KeyEvent): Boolean {
        if (kioskLock?.onKey(event) == true) return true
        // Dpad, arrow and select keys are routed by hand, whichever native
        // view holds focus (issue #377): left unrouted they sink into
        // whatever view happens to be focused, and a TV remote has no way
        // to reach the menu. While Flutter has a surface up that navigates
        // (drawer, settings, screensaver, lockdown — the navCapture flag),
        // every key goes into the FlutterView; over the bare dashboard,
        // left goes to Flutter (it opens the drawer) and the rest go to
        // the frontmost WebView, so the page keeps its scrolling and its
        // own key handling. Text entry is the exception — arrows belong to
        // the cursor while a field is taking input, wherever that field
        // lives.
        if (isNavKey(event.keyCode) && !isTextEditing()) {
            val toFlutter = kioskLock?.navCapture == true ||
                event.keyCode == KeyEvent.KEYCODE_DPAD_LEFT
            if (toFlutter && event.action == KeyEvent.ACTION_DOWN) {
                // Park native focus on the one-pixel spot even while
                // Flutter owns the keys (they are routed by hand below,
                // native focus plays no part): One UI paints a green focus
                // frame around the natively focused view during
                // hardware-key navigation, and around the screen-filling
                // FlutterView that is a green border wrapping the entire
                // app. Around one transparent pixel it paints nothing
                // anyone can see. The WebView cannot be the spot: focusing
                // it echoes back into Flutter's focus tree and steals the
                // focused menu row. A Flutter text field taking input
                // pulls focus back to the FlutterView for the IME on its
                // own.
                focusParking?.takeIf { !it.isFocused }?.requestFocus()
            }
            if (!toFlutter) {
                frontWebView(findViewById(FLUTTER_VIEW_ID))?.let {
                    // Chromium quietly drops keys while its renderer is
                    // unfocused, and nothing on a touchless device had ever
                    // focused the WebView.
                    if (!it.hasFocus()) it.requestFocus()
                    it.dispatchKeyEvent(webViewKey(event))
                    return true
                }
            }
            findViewById<View>(FLUTTER_VIEW_ID)?.let {
                it.dispatchKeyEvent(event)
                return true
            }
        }
        return super.dispatchKeyEvent(event)
    }

    /** The keys a TV remote or a keyboard's arrows navigate with. */
    private fun isNavKey(code: Int): Boolean = when (code) {
        KeyEvent.KEYCODE_DPAD_UP,
        KeyEvent.KEYCODE_DPAD_DOWN,
        KeyEvent.KEYCODE_DPAD_LEFT,
        KeyEvent.KEYCODE_DPAD_RIGHT,
        KeyEvent.KEYCODE_DPAD_CENTER,
        KeyEvent.KEYCODE_ENTER,
        KeyEvent.KEYCODE_NUMPAD_ENTER -> true
        else -> false
    }

    /** Whether the focused view is taking text right now. */
    private fun isTextEditing(): Boolean =
        (getSystemService(Context.INPUT_METHOD_SERVICE) as? InputMethodManager)
            ?.isAcceptingText == true

    /**
     * The key as the page should see it. Dpad up and down become Tab and
     * Shift+Tab: a dashboard's controls are focusables the way a desktop
     * browser walks them with Tab — Chromium hands the dpad to the page as
     * plain arrow keys, which a Home Assistant dashboard ignores. Focus
     * movement scrolls the page along with it. Right stays an arrow (a
     * focused slider answers to it); center and enter already activate the
     * focused control.
     */
    private fun webViewKey(event: KeyEvent): KeyEvent = when (event.keyCode) {
        KeyEvent.KEYCODE_DPAD_UP -> KeyEvent(
            event.downTime, event.eventTime, event.action,
            KeyEvent.KEYCODE_TAB, event.repeatCount, KeyEvent.META_SHIFT_ON,
        )
        KeyEvent.KEYCODE_DPAD_DOWN -> KeyEvent(
            event.downTime, event.eventTime, event.action,
            KeyEvent.KEYCODE_TAB, event.repeatCount, 0,
        )
        else -> event
    }

    /**
     * The WebView a navigation key belongs to: the last shown one in tree
     * order. Platform views attach in creation order, so a rotation's
     * overlay page sits after the dashboard it covers, and a frozen
     * (hidden) plane is skipped by the isShown check.
     */
    private fun frontWebView(root: View?): android.webkit.WebView? {
        if (root == null) return null
        var found: android.webkit.WebView? = null
        fun walk(v: View) {
            if (v is android.webkit.WebView && v.isShown) found = v
            if (v is android.view.ViewGroup) {
                for (i in 0 until v.childCount) walk(v.getChildAt(i))
            }
        }
        walk(root)
        return found
    }

    override fun dispatchTouchEvent(ev: MotionEvent): Boolean {
        kioskLock?.onTouch(ev)
        return super.dispatchTouchEvent(ev)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        // Activity already running (launchMode singleTask finds the one
        // instance): push instead of pull.
        intent.getStringExtra("ks.provision")?.let {
            provisionChannel?.invokeMethod("provision", it)
        }
        // A HOME press while the kiosk is the home app and already in
        // front lands here. Everywhere else HOME means "back to the start
        // screen", so the kiosk honors that: Dart closes whatever is open
        // and returns to the dashboard (issue #219).
        if (intent.action == Intent.ACTION_MAIN &&
            intent.hasCategory(Intent.CATEGORY_HOME)
        ) {
            kioskLock?.notifyHomePressed()
        }
    }
}
