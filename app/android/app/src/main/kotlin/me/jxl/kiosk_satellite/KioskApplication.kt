package me.jxl.kiosk_satellite

import android.app.Application
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraManager
import android.util.Log
import androidx.camera.camera2.Camera2Config
import androidx.camera.core.CameraSelector
import androidx.camera.core.CameraXConfig
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
class KioskApplication : Application(), CameraXConfig.Provider {
    companion object {
        const val ENGINE_ID = "main"
    }

    /**
     * CameraX's default init validates every camera facing the device
     * claims — and single-camera hardware whose ROM still advertises both
     * (LineageOS on the Echo Show 5: one front camera, the back-camera
     * feature flag left on) fails that check forever. The
     * ProcessCameraProvider future then never resolves, so snapshots and
     * the hasCamera probe hang with nothing in the app's own log. Limiting
     * CameraX to the facing Camera2 actually reports makes the validator
     * check only what exists; devices with both cameras get no limiter and
     * keep both.
     */
    override fun getCameraXConfig(): CameraXConfig {
        val builder = CameraXConfig.Builder.fromConfig(Camera2Config.defaultConfig())
        try {
            val facings = cameraFacings(this)
            if ("front" in facings && "back" !in facings) {
                builder.setAvailableCamerasLimiter(CameraSelector.DEFAULT_FRONT_CAMERA)
            } else if ("back" in facings && "front" !in facings) {
                builder.setAvailableCamerasLimiter(CameraSelector.DEFAULT_BACK_CAMERA)
            }
        } catch (e: Exception) {
            Log.w("KioskApplication", "camera facings probe failed", e)
        }
        return builder.build()
    }

    private lateinit var micRecorder: MicRecorder
    private lateinit var background: BackgroundBridge
    private lateinit var deviceDetails: DeviceDetails
    private lateinit var brightness: BrightnessBridge
    private lateinit var sendspin: SendspinBridge
    private lateinit var audioRouting: AudioRoutingBridge
    private lateinit var soundPlayer: SoundPlayer
    private lateinit var apkInstaller: ApkInstaller
    private lateinit var lightSensor: LightSensor

    override fun onCreate() {
        super.onCreate()

        // First of all: a crash anywhere past this point must be readable
        // after the restart (see CrashJournal - logcat rotates faster than
        // reporters can copy it).
        CrashJournal.install(this)

        // Before any bridge: they all read volume state through it.
        VolumeController.init(applicationContext)

        // Before anything opens a socket: the native HTTP stacks read the
        // app's user agent from here.
        AppIdentity.configure(applicationContext)

        // Renderer choice before the engine exists: old GPUs whose drivers
        // crash under Impeller get Skia instead (issue #127, RendererGuard).
        val engine = FlutterEngine(this, RendererGuard.engineArgs(this))
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
        lightSensor = LightSensor(applicationContext, messenger)
    }
}
