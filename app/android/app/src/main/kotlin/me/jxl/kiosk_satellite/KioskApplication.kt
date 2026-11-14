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
            .apply {
                // A HAL1 camera leaks two threads on every failed open, so
                // CameraX's own reopen retries are kept short there.
                if (LegacyCameraShim.marked(this@KioskApplication)) {
                    setCameraOpenRetryMaxTimeoutInMillisWhileResuming(LegacyCameraShim.RETRY_CAP_MS)
                }
            }
            .build()

    private lateinit var micRecorder: MicRecorder
    private lateinit var background: BackgroundBridge
    private lateinit var alarms: AlarmBridge
    private lateinit var dlnaAudio: DlnaAudio
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
    private lateinit var plugins: me.jxl.kiosk_satellite.plugins.PluginBridge
    private lateinit var fleet: FleetBridge
    private lateinit var intercomAudio: IntercomAudio
    private lateinit var intercomVideo: IntercomVideo
    private lateinit var realtimeAudio: RealtimeAudio
    private lateinit var mediaSessions: MediaSessionBridge
    private lateinit var airPlay: AirPlayBridge
    private lateinit var voiceIntents: VoiceIntentBridge

    override fun onCreate() {
        super.onCreate()

        // First of all: a crash anywhere past this point must be readable
        // after the restart (see CrashJournal - logcat rotates faster than
        // reporters can copy it).
        CrashJournal.install(this)
        // A deadlocked main thread takes every other recovery down with it
        // (issue #1166), so this one watches from its own thread.
        MainThreadWatchdog.start(this)

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

        // A device without a screen renders nothing, so the engine starts
        // in software and the renderer crash net (which waits for a first
        // frame that never comes there) stays out of it.
        val headless = Headless.active(this)
        if (headless) Headless.useSoftwareRenderer()
        val engine = FlutterEngine(
            this,
            null,
            SurfaceTeardownJni(),
            if (headless) Headless.engineArgs else RendererGuard.engineArgs(this),
            true,
        )
        // Plugins before the entrypoint: Dart main() starts the admin server and
        // reads shared_preferences immediately, so shared_preferences,
        // path_provider et al. must already be registered when it runs.
        GeneratedPluginRegistrant.registerWith(engine)
        // The QR scanner's detach can throw on old camera HALs and would take
        // the process down from Activity.onDestroy (ScannerPluginShield).
        ScannerPluginShield.install(engine)
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
        ImageScaler(applicationContext, messenger)
        alarms = AlarmBridge(applicationContext, messenger)
        dlnaAudio = DlnaAudio(applicationContext, messenger)
        deviceDetails = DeviceDetails(applicationContext, messenger)
        brightness = BrightnessBridge(applicationContext, messenger)
        sendspin = SendspinBridge(applicationContext, messenger)
        soundPlayer = SoundPlayer(applicationContext, messenger)
        apkInstaller = ApkInstaller(applicationContext, messenger)
        lightSensor = LightSensor(applicationContext, messenger)
        proximitySensor = ProximitySensor(applicationContext, messenger)
        LogTail(messenger)
        locationSensor = LocationSensor(applicationContext, messenger)
        OrientationSensor(applicationContext, messenger)
        haptics = HapticsBridge(applicationContext, messenger)
        tapSound = TapSoundBridge(applicationContext, messenger)
        bluetoothProxy = BluetoothProxyBridge(applicationContext, messenger)
        TlsBridge(applicationContext, messenger)
        fleet = FleetBridge(applicationContext, messenger)
        intercomAudio = IntercomAudio(applicationContext, messenger)
        intercomVideo = IntercomVideo(messenger, engine.renderer)
        realtimeAudio = RealtimeAudio(applicationContext, messenger)
        mediaSessions = MediaSessionBridge(applicationContext, messenger)
        airPlay = AirPlayBridge(applicationContext, messenger)
        voiceIntents = VoiceIntentBridge(applicationContext, messenger)
        EventBroadcastBridge(applicationContext, messenger)
        HardwareKeys.attach(applicationContext, messenger)
        LedBridge(applicationContext, messenger)
        SystemUpdateBridge(applicationContext, messenger)
        plugins = me.jxl.kiosk_satellite.plugins.PluginBridge(applicationContext, messenger)
        // Plugin overlays are platform views on the cached engine, built
        // with the Activity's context whenever one is attached.
        engine.platformViewsController.registry.registerViewFactory(
            me.jxl.kiosk_satellite.plugins.PluginOverlayViews.VIEW_TYPE,
            plugins.overlayViews,
        )
        // A process Android started with no Activity, on a kiosk that was
        // on screen when its last process ended, gets its screen back.
        if (!headless) CrashSelfHeal.watchStart(this)
        // Headless, no Activity ever arms the keep-alive service, so the
        // process does it as it starts, however it was started.
        if (headless) KioskSatelliteService.ensureRunning(this)
        // A device without a screen can never be the home app: the
        // Activity finishes as it starts, and Android starts HOME again
        // at once, many times a second, until the device runs out of
        // memory (issue #1108). The role can be left over from a settings
        // import, and a data wipe keeps both the alias and the device
        // owner's preferred entry, so give it back on every start.
        if (headless && HomeRole.aliasEnabled(this)) HomeRole.release(this, null)
    }
}
