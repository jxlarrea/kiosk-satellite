package me.jxl.kiosk_satellite

import android.content.Context
import android.content.Intent
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
class MainActivity : FlutterActivity() {
    private var provisionChannel: MethodChannel? = null
    private var cameraMotion: CameraMotion? = null
    private var screenCapture: ScreenCapture? = null

    override fun provideFlutterEngine(context: Context): FlutterEngine? =
        FlutterEngineCache.getInstance().get(KioskApplication.ENGINE_ID)

    // The engine belongs to the process, not this Activity.
    override fun shouldDestroyEngineWithHost(): Boolean = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        // Deliberately not calling super: plugins are registered once on the
        // cached engine in KioskApplication. Only Activity-scoped bridges here.
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        cameraMotion = CameraMotion(this, messenger)
        screenCapture = ScreenCapture(this, messenger)
        provisionChannel = MethodChannel(messenger, "kiosk_satellite/provision")
        provisionChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "getProvisionJson" -> result.success(intent?.getStringExtra("ks.provision"))
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
        provisionChannel?.setMethodCallHandler(null)
        provisionChannel = null
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
