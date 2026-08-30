package me.jxl.kiosk_satellite

import android.app.Application
import android.util.Log
import androidx.camera.camera2.Camera2Config
import androidx.camera.core.CameraXConfig
import androidx.camera.lifecycle.ProcessCameraProvider
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
     * CameraX's default init validates every camera the device claims and
     * its own lens-facing filter reads every camera's facing, so hardware
     * whose camera list does not match reality never initialized at all:
     * a ROM advertising a back camera the device lacks (LineageOS on the
     * Echo Show 5: one front camera, the back-camera feature flag left
     * on) wedged the ProcessCameraProvider future forever, and a HAL
     * padding the list with a phantom camera whose facing is unreadable
     * (a Unisoc wall tablet: LENS_FACING 255 beside the real front
     * camera) threw before the real camera could be picked. Limiting
     * CameraX to the cameras whose facing reads makes it see only what
     * exists, and a limiter without a facing of its own keeps the
     * validator from checking feature flags against the camera list.
     */
    override fun getCameraXConfig(): CameraXConfig =
        CameraXConfig.Builder.fromConfig(Camera2Config.defaultConfig())
            .setAvailableCamerasLimiter(readableCamerasSelector())
            .build()

    private lateinit var micRecorder: MicRecorder
    private lateinit var background: BackgroundBridge
    private lateinit var deviceDetails: DeviceDetails
    private lateinit var brightness: BrightnessBridge
    private lateinit var sendspin: SendspinBridge
    private lateinit var audioRouting: AudioRoutingBridge
    private lateinit var soundPlayer: SoundPlayer
    private lateinit var apkInstaller: ApkInstaller
    private lateinit var lightSensor: LightSensor
    private lateinit var proximitySensor: ProximitySensor
    private lateinit var locationSensor: LocationSensor
    private lateinit var haptics: HapticsBridge
    private lateinit var tapSound: TapSoundBridge
    private lateinit var bluetoothProxy: BluetoothProxyBridge

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
        // crash under Impeller get Skia instead (issue #127, RendererGuard),
        // and old GPUs that cannot hand Flutter's overlay frames back draw
        // the dashboard through a texture (issue #302). Both settle before
        // Dart reads the settings they write.
        WebViewCompositingGuard.check(this)

        // CameraX before the plugins: the QR scanner (mobile_scanner)
        // configures CameraX itself the moment it attaches, with a plain
        // Camera2Config, and an explicitly configured instance wins over
        // this Application's CameraXConfig.Provider, which CameraX consults
        // only when nothing called configureInstance. That left the
        // camera limiter below unread for as long as the scanner has been
        // in the app. The plugin swallows the IllegalStateException it
        // gets for configuring second, so the app claiming the slot first
        // is the whole fix; the catch here is for a process that somehow
        // configured earlier still.
        try {
            ProcessCameraProvider.configureInstance(getCameraXConfig())
        } catch (e: IllegalStateException) {
            Log.w("KioskApplication", "CameraX was configured before the app could", e)
        }

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
        proximitySensor = ProximitySensor(applicationContext, messenger)
        locationSensor = LocationSensor(applicationContext, messenger)
        haptics = HapticsBridge(applicationContext, messenger)
        tapSound = TapSoundBridge(applicationContext, messenger)
        bluetoothProxy = BluetoothProxyBridge(applicationContext, messenger)
    }
}
