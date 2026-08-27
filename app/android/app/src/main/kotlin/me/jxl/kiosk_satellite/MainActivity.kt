package me.jxl.kiosk_satellite

import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.os.PowerManager
import android.view.KeyEvent
import android.view.MotionEvent
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

    override fun provideFlutterEngine(context: Context): FlutterEngine? =
        FlutterEngineCache.getInstance().get(KioskApplication.ENGINE_ID)

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
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
        // the early-crash net down (issue #127, RendererGuard).
        RendererGuard.noteFirstFrame(this)
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
        return super.dispatchKeyEvent(event)
    }

    override fun dispatchTouchEvent(ev: MotionEvent): Boolean {
        kioskLock?.onTouch(ev)
        return super.dispatchTouchEvent(ev)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        // Activity already running (launchMode singleTop): push instead of pull.
        intent.getStringExtra("ks.provision")?.let {
            provisionChannel?.invokeMethod("provision", it)
        }
    }
}
