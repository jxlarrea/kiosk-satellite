package me.jxl.kiosk_satellite

import android.app.Application
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugins.GeneratedPluginRegistrant

/**
 * Owns one long-lived [FlutterEngine] for the whole process, rather than
 * letting each Activity create and destroy its own.
 *
 * The point is that the Dart isolate — and everything living in it: the remote
 * admin HTTP server, the wake-word engine, the settings store — must outlive
 * the Activity. Android will destroy a backgrounded Activity while the
 * wake-word foreground service keeps the process alive; with a per-Activity
 * engine that left a running process whose admin server was gone, a socket that
 * accepted connections and never answered. A cached engine survives the
 * Activity, so the admin stays reachable as long as the process lives.
 *
 * Bridges that need no Activity on screen are set up here so they work while
 * backgrounded: the microphone (background wake word), bringing the app forward
 * on a detection, and the device facts the admin reads on demand. Bridges that
 * need a live Activity (the camera, the launch intent) are set up in
 * [MainActivity] instead.
 */
class KioskApplication : Application() {
    companion object {
        const val ENGINE_ID = "main"
    }

    private lateinit var micRecorder: MicRecorder
    private lateinit var background: BackgroundBridge
    private lateinit var deviceDetails: DeviceDetails
    private lateinit var brightness: BrightnessBridge
    private lateinit var sendspin: SendspinBridge
    private lateinit var audioRouting: AudioRoutingBridge
    private lateinit var soundPlayer: SoundPlayer
    private lateinit var apkInstaller: ApkInstaller

    override fun onCreate() {
        super.onCreate()

        val engine = FlutterEngine(this)
        // Plugins before the entrypoint: Dart main() starts the admin server and
        // reads shared_preferences immediately, so shared_preferences,
        // path_provider et al. must already be registered when it runs.
        GeneratedPluginRegistrant.registerWith(engine)
        engine.dartExecutor.executeDartEntrypoint(
            DartExecutor.DartEntrypoint.createDefault(),
        )
        FlutterEngineCache.getInstance().put(ENGINE_ID, engine)

        val messenger = engine.dartExecutor.binaryMessenger
        // Before the mic: MicRecorder resolves its preferred device through
        // AudioRouting, which the bridge initializes.
        audioRouting = AudioRoutingBridge(applicationContext, messenger)
        micRecorder = MicRecorder(applicationContext, messenger)
        background = BackgroundBridge(applicationContext, messenger)
        deviceDetails = DeviceDetails(applicationContext, messenger)
        brightness = BrightnessBridge(applicationContext, messenger)
        sendspin = SendspinBridge(applicationContext, messenger)
        soundPlayer = SoundPlayer(applicationContext, messenger)
        apkInstaller = ApkInstaller(applicationContext, messenger)
    }
}
