package me.jxl.kiosk_satellite

import android.content.Context
import android.content.Intent
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
}

class MainActivity : FlutterActivity() {
    private var provisionChannel: MethodChannel? = null
    private var adminChannel: MethodChannel? = null
    private var cameraMotion: CameraMotion? = null
    private var screenCapture: ScreenCapture? = null
    private var kioskLock: KioskLock? = null

    override fun provideFlutterEngine(context: Context): FlutterEngine? =
        FlutterEngineCache.getInstance().get(KioskApplication.ENGINE_ID)

    override fun onResume() {
        super.onResume()
        ActivityState.resumed = true
        // Persisted so the crash self-heal (WakeWordService) can tell "died
        // while on screen" from "user left for another app": only the former
        // may bring the kiosk back on its own. A clean exit and a Home press
        // both pass through onPause first, so the flag is false for those.
        setWasForeground(true)
    }

    override fun onPause() {
        super.onPause()
        ActivityState.resumed = false
        setWasForeground(false)
    }

    private fun setWasForeground(value: Boolean) {
        getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            .edit().putBoolean("flutter.ks.crash.was_foreground", value).apply()
    }

    // The engine belongs to the process, not this Activity.
    override fun shouldDestroyEngineWithHost(): Boolean = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        // Deliberately not calling super: plugins are registered once on the
        // cached engine in KioskApplication. Only Activity-scoped bridges here.
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        cameraMotion = CameraMotion(this, messenger)
        screenCapture = ScreenCapture(this, messenger)
        kioskLock = KioskLock(this, messenger)
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
        cameraMotion?.dispose()
        cameraMotion = null
        screenCapture?.dispose()
        screenCapture = null
        kioskLock?.dispose()
        kioskLock = null
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
