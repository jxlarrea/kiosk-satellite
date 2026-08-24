package me.jxl.kiosk_satellite

import android.content.Context
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CaptureRequest
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.os.SystemClock
import android.util.Log
import androidx.camera.camera2.interop.Camera2CameraInfo
import androidx.camera.camera2.interop.Camera2Interop
import androidx.camera.camera2.interop.ExperimentalCamera2Interop
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.ImageProxy
import androidx.camera.core.resolutionselector.ResolutionSelector
import androidx.camera.core.resolutionselector.ResolutionStrategy
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.core.content.ContextCompat
import android.util.Size
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import java.util.concurrent.Executors
import kotlin.math.abs
import kotlin.math.ceil
import kotlin.math.max
import kotlin.math.roundToInt

/**
 * Camera motion detection that stays cheap enough to leave running.
 *
 * The whole design is about doing almost nothing per frame. Fully Kiosk pulls
 * full-resolution preview frames and diffs them as RGB bitmaps at the camera's
 * native rate; this instead:
 *
 *  - asks CameraX for the smallest analysis resolution the device offers and
 *    reads only the Y (luminance) plane of the YUV frame, so there is no bitmap
 *    allocation and no color conversion at all;
 *  - throttles to a configurable frame rate (default a couple per second) by
 *    dropping every frame that arrives before the next slot is due;
 *  - reduces each processed frame to a small grid of sparsely-sampled cell
 *    averages and diffs that against the previous grid — a few hundred byte
 *    reads, not a per-pixel sweep.
 *
 * Dark rooms get two extra measures, both still cheap. Each cell learns its
 * own frame-to-frame jitter (a sigma-delta noise model) and flags change at a
 * multiple of it, so the few-count deltas a dim scene produces are detectable
 * without lowering the bright-room bar into sensor noise. And AE is asked for
 * the slowest frame-rate range the sensor offers, trading frame rate nobody
 * needs (analysis is throttled far below it) for longer exposures, which means
 * more photons per frame instead of cranked gain.
 *
 * Lighting is rejected on two levels. Each cell is thresholded on its
 * deviation from the frame's MEAN delta, not its raw delta: a light change
 * plus the AE compensation that follows it is, to first order, a uniform
 * shift of the whole grid, and subtracting the mean removes it — a body is a
 * localized departure from whatever the global shift is. (This matters with
 * the camera running across screensaver transitions: the raw transition is
 * monotone, but half a second later AE has partially re-exposed, and
 * screen-lit cells darkening while AE lifts the rest arrives mixed-sign —
 * shaped exactly like a body.) What the mean cannot absorb — light landing
 * unevenly, a lamp reaching only half the room — is caught by the raw-delta
 * sign veto: same-signed raw change is illumination, while a frame-diff of a
 * moving body has both signs at once.
 *
 * Only a "motion" tick ever crosses the channel, rate-limited to one per second.
 * The Dart side decides what motion means (waking the screensaver); the camera
 * is bound only while something is listening, and [onCancel] frees it.
 *
 * The camera is shared with [DeviceCamera]: an ImageCapture use case is
 * pre-bound into this session so a Home Assistant snapshot rides it instead
 * of contending for the sensor (see DeviceCamera for why pre-binding, not
 * on-demand binding, is the part that matters).
 */
class CameraMotion(
    private val context: Context,
    messenger: BinaryMessenger,
    private val deviceCamera: DeviceCamera? = null,
) : EventChannel.StreamHandler {
    companion object {
        const val CHANNEL = "kiosk_satellite/motion"
        private const val TAG = "CameraMotion"

        // The analysis grid. Coarse on purpose: presence is a whole-body change
        // across the frame, not a pixel edge. 16x12 keeps the aspect roughly 4:3.
        private const val GRID_W = 16
        private const val GRID_H = 12
        private const val CELLS = GRID_W * GRID_H

        // Samples per cell per axis (so SAMPLES*SAMPLES reads per cell). Sparse:
        // a cell average from 4 points is stable enough at this grid size.
        private const val SAMPLES = 2

        // Per-cell change thresholds (0..255 luminance). A cell counts as
        // "changed" when its average moves by NOISE_K times its own observed
        // frame-to-frame jitter, clamped to this band. The ceiling matches the
        // old fixed delta so bright rooms behave as before; the floor keeps a
        // dark scene's tiny-but-real deltas detectable without dropping into
        // per-sample quantization noise.
        private const val THRESHOLD_FLOOR = 4f
        private const val THRESHOLD_CEILING = 16f
        private const val NOISE_K = 4f

        // EMA rate of the per-cell jitter estimate; only quiet cells feed it.
        // At ~2 processed fps this settles in a handful of seconds.
        private const val NOISE_ALPHA = 0.08f

        // First threshold is the ceiling (old behavior) until jitter is learned.
        private const val INITIAL_NOISE = THRESHOLD_CEILING / NOISE_K

        // Illumination veto: when SAME_SIGN_PERCENT of the changed cells moved
        // in the same direction, the cause is lighting, not a body. Light is
        // monotone within a frame (a lamp toggling, AE hunting, a monitor or
        // the screensaver lighting the room differently brightens or darkens
        // everything it reaches), while a frame-diff of a moving body has both
        // signs at once: its leading edge gains what the space it left loses.
        // Measured on device: reflected monitor flicker in a 1 lux room flags
        // 30..90 percent of the grid at exactly 100 percent sign purity.
        // VETO_MIN_CELLS keeps small counts out of the rule, where purity is
        // likely by chance.
        private const val SAME_SIGN_PERCENT = 85
        private const val VETO_MIN_CELLS = 12

        // CameraMetadata.CONTROL_AE_MODE_ON_LOW_LIGHT_BOOST_BRIGHTNESS_PRIORITY,
        // spelled as a literal so this compiles against pre-35 SDKs.
        private const val AE_MODE_LOW_LIGHT_BOOST = 6

        // The exposure-hunt fallback (issue #164). Some vendor auto-exposure
        // loops never converge once the slow fps range below is requested:
        // the Galaxy Tab S6 Lite's LIMITED front camera oscillates exposure
        // forever, which pins a core in the camera HAL for as long as the
        // camera is bound. The analyzer sees that clearly, as an endless run
        // of frames whose change is global and same-signed (the illumination
        // veto) with no local structure at all, something no real scene
        // sustains for this long: a body is local, a slide change or lamp is
        // over in a frame or two, and even a flickering TV lands only
        // veto-shaped frames interleaved with quiet ones as the flicker
        // beats against the analysis rate. HUNT_FRAMES consecutive hits
        // (about 10 s at the default 2 fps) escalates the aeLevel ladder
        // and restarts the session; hardware level is deliberately not
        // the trigger, because healthy LIMITED cameras (the Tab S8's front
        // one among them) benefit from the long exposures.
        private const val HUNT_FRAMES = 20

        // A hunting frame has essentially no mean-relative change: AE gain
        // moves every cell together and the mean subtraction absorbs it.
        private const val HUNT_MAX_LOCAL_CELLS = 3

        // Auto-exposure settles over the first frames after the camera opens and
        // swings luminance globally; skip them so it does not read as motion.
        private const val WARMUP_FRAMES = 3

        private const val EMIT_INTERVAL_NS = 1_000_000_000L // rate-limit: 1/s

        // Backstop for a CameraX init that never resolves (a wedged camera
        // service; a Galaxy Tab A took 20s+ in issue #271): the Dart side
        // must hear an error and own the retry, not wait forever on a
        // listener that will never run. Mirrors DeviceCamera's backstop.
        private const val PROVIDER_TIMEOUT_MS = 20_000L

        // The screen-off suspension watchdog (issue #271). One UI 11
        // (Galaxy Tab A 10.1) closes the capture session seconds after the
        // panel powers off - the camera foreground service type
        // notwithstanding - and surfaces no CameraState error, so the
        // observer in start() never hears: the analyzer just stops
        // receiving frames, and motion can never wake the dark panel.
        // Frames are the ground truth for session health (a live camera
        // delivers them regardless of scene or lighting), so a dark-panel
        // session this long without one is suspended. The threshold is 5x
        // the slowest analysis interval (0.5 fps = 2s between frames).
        private const val SUSPEND_CHECK_MS = 5_000L
        private const val SUSPEND_AFTER_MS = 10_000L
    }

    private val eventChannel = EventChannel(messenger, CHANNEL)
    private val mainHandler = Handler(Looper.getMainLooper())

    private var provider: ProcessCameraProvider? = null
    private var analysis: ImageAnalysis? = null
    private val analysisExecutor = Executors.newSingleThreadExecutor()
    private var lifecycle: CameraLifecycle? = null

    /** Guards the async camera-ready callback: bumped by every listen and
     *  cancel (main thread only), so a callback from a session that was
     *  cancelled while the provider future was still resolving does not
     *  bind a camera nothing will ever release. */
    private var session = 0

    /** Target for the pre-bound snapshot capture, from the listen args
     *  (the Camera settings' resolution tier). Main thread only. */
    private var snapshotTarget: Size? = null

    // Analyzer state (touched only on analysisExecutor).
    private var prevGrid: IntArray? = null
    private var noiseGrid: FloatArray? = null
    private var frameCount = 0
    private var lastProcessedNs = 0L
    private var lastEmitNs = 0L
    private var frameIntervalNs = 0L
    private var minChangedCells = 1

    /** Extra blindness after the stream starts (discussion #159), on top of
     *  [WARMUP_FRAMES]. Hardware with a pop-up camera sweeps the lens through
     *  the scene as the motor deploys it, which is a genuine both-signed
     *  change no lighting veto can reject; the frames are still tracked as
     *  the baseline, they just do not count as motion and never train the
     *  noise model. Nanosecond deadline, armed by the first frame so it
     *  measures from when the camera really started producing. */
    private var startDelayNs = 0L
    private var analyzeFromNs = 0L

    /** Requested processing rate, kept for AE fps-range selection. Main
     *  thread only. */
    private var requestedFps = 2.0

    /** Whether an AE fps-range request is in force on the bound session,
     *  so the hunt detector only ever arms while there is a request left
     *  to escalate away from. Written on the main thread at bind, read on
     *  [analysisExecutor]. */
    @Volatile private var slowAeApplied = false

    /** The hunt fallback's escalation ladder for the current listen
     *  (issue #164). 0: the slowest range the sensor offers, usually wide
     *  ([7,30]), best in the dark. 1: the lowest FIXED range ([15,15]):
     *  a pinned rate keeps the camera pipeline as cheap as the slow range
     *  did — on the Tab S6 Lite the full-rate pipeline alone is the 100%
     *  CPU, so the first fallback's restart to default exposure was the
     *  cure causing the disease — while taking away the rate freedom the
     *  hunt oscillated in. 2: the same pinned range with the detector
     *  disarmed, the end of the ladder; default exposure never returns.
     *  Main thread only. */
    private var aeLevel = 0

    /** Consecutive hunting-shaped frames (see [HUNT_FRAMES]); analyzer
     *  state like [prevGrid]. */
    private var huntStreak = 0

    /** What the current listen bound, kept so the hunt fallback can rebuild
     *  the same session without the slow AE range. Main thread only. */
    private var activeFacing: CameraSelector? = null
    private var activeSink: EventChannel.EventSink? = null

    /** When the analyzer last received a frame (delivery, not the fps
     *  gate), for the screen-off suspension watchdog. Written on
     *  [analysisExecutor], read on the main thread. */
    @Volatile private var lastFrameAtMs = 0L

    init {
        eventChannel.setStreamHandler(this)
    }

    override fun onListen(arguments: Any?, sink: EventChannel.EventSink?) {
        if (sink == null) return
        val args = arguments as? Map<*, *>
        val fps = (args?.get("fps") as? Number)?.toDouble()?.coerceIn(0.5, 30.0) ?: 2.0
        val sensitivity = (args?.get("sensitivity") as? Number)?.toInt()?.coerceIn(1, 100) ?: 40
        val facing = if (args?.get("camera") == "back") {
            CameraSelector.DEFAULT_BACK_CAMERA
        } else {
            CameraSelector.DEFAULT_FRONT_CAMERA
        }
        val snapW = (args?.get("snapshotWidth") as? Number)?.toInt()
        val snapH = (args?.get("snapshotHeight") as? Number)?.toInt()
        val startDelayMs =
            (args?.get("startDelayMs") as? Number)?.toLong()?.coerceIn(0L, 15_000L) ?: 0L

        frameIntervalNs = (1_000_000_000.0 / fps).toLong()
        // Sensitivity → how many of the grid's cells must change. High
        // sensitivity needs only a cell or two; low sensitivity needs roughly
        // half the frame. Never zero.
        minChangedCells = max(1, ((100 - sensitivity) * CELLS / 200.0).roundToInt())
        prevGrid = null
        noiseGrid = null
        frameCount = 0
        lastProcessedNs = 0L
        lastEmitNs = 0L
        startDelayNs = startDelayMs * 1_000_000L
        analyzeFromNs = 0L
        huntStreak = 0
        slowAeApplied = false

        requestedFps = fps

        // CameraX binding must happen on the main thread.
        mainHandler.post {
            aeLevel = 0
            activeFacing = facing
            activeSink = sink
            snapshotTarget = if (snapW != null && snapH != null) {
                Size(snapW, snapH)
            } else {
                null
            }
            start(facing, sink)
        }
    }

    private fun start(facing: CameraSelector, sink: EventChannel.EventSink) {
        val mySession = ++session
        // No camera hardware: say so without waking CameraX, whose presence
        // tracking would retry the missing camera service every second
        // forever (see DeviceCamera's hasCamera comment, issue #193).
        if (cameraFacings(context).isEmpty()) {
            sink.error("camera", NO_CAMERA_MESSAGE, null)
            return
        }
        val future = ProcessCameraProvider.getInstance(context)
        // Both the timeout and the listener run on the main thread, so the
        // flag needs no synchronization; it keeps a provider that resolves
        // after the deadline from binding a camera nothing will release.
        var timedOut = false
        val initTimeout = Runnable {
            timedOut = true
            if (session != mySession) return@Runnable
            Log.w(TAG, "provider timed out")
            sink.error(
                "camera",
                "camera provider unavailable: initialization timed out",
                null,
            )
        }
        mainHandler.postDelayed(initTimeout, PROVIDER_TIMEOUT_MS)
        future.addListener({
            mainHandler.removeCallbacks(initTimeout)
            if (timedOut || session != mySession) return@addListener
            val cameraProvider = try {
                future.get()
            } catch (e: Exception) {
                sink.error("camera", "camera provider unavailable: ${e.message}", null)
                return@addListener
            }
            provider = cameraProvider

            // Same resolution rules as snapshots: honor the configured
            // facing, fall back to the only camera present, say plainly
            // when there is none (a closed privacy shutter unplugs it).
            val selector = resolveCameraSelector(cameraProvider, facing)
            if (selector == null) {
                sink.error("camera", NO_CAMERA_MESSAGE, null)
                return@addListener
            }

            val resolution = ResolutionSelector.Builder()
                .setResolutionStrategy(
                    ResolutionStrategy(
                        Size(320, 240),
                        ResolutionStrategy.FALLBACK_RULE_CLOSEST_LOWER_THEN_HIGHER,
                    ),
                )
                .build()

            val analysisBuilder = ImageAnalysis.Builder()
                .setResolutionSelector(resolution)
                .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
            applyLowLightExposure(analysisBuilder, cameraProvider, selector)
            val imageAnalysis = analysisBuilder.build()
            imageAnalysis.setAnalyzer(analysisExecutor) { image ->
                analyze(image, sink, mySession)
            }
            analysis = imageAnalysis

            val owner = CameraLifecycle().also { lifecycle = it }
            // Pre-bound so a snapshot never reconfigures this session (an
            // AE resettle would read as motion and wake the screensaver).
            val imageCapture = deviceCamera?.let {
                val target = snapshotTarget
                if (target != null) it.buildCapture(target) else it.buildCapture()
            }
            try {
                cameraProvider.unbindAll()
                val camera = if (imageCapture != null) {
                    try {
                        cameraProvider.bindToLifecycle(
                            owner, selector, imageAnalysis, imageCapture)
                            .also { deviceCamera.sharedCapture = imageCapture }
                    } catch (e: Exception) {
                        // Hardware that cannot run analysis and JPEG capture
                        // in one session: motion wins, snapshots report busy
                        // while it runs.
                        Log.w(TAG, "no capture alongside analysis: ${e.message}")
                        cameraProvider.bindToLifecycle(owner, selector, imageAnalysis)
                    }
                } else {
                    cameraProvider.bindToLifecycle(owner, selector, imageAnalysis)
                }
                deviceCamera?.motionSessionActive = true
                owner.resume()
                // The OS revokes a running camera the moment the app stops
                // being visible (5s after the panel powers off, measured on
                // Android 16: "Access has been restricted, isUidVisible
                // false") and when another app takes the sensor. Without
                // this observer the analyzer just stops receiving frames
                // and nothing upstream ever hears about it — the motion
                // sensor stays dead until an app restart (issue from
                // discussion #134 testing). Observed through [owner], so
                // the cancel path's destroy() removes it before teardown's
                // own CLOSING/CLOSED states could echo back as errors.
                camera.cameraInfo.cameraState.observe(owner) { state ->
                    val err = state.error ?: return@observe
                    if (session != mySession) return@observe
                    Log.w(TAG, "camera lost: ${state.type} error ${err.code}")
                    sink.error(
                        "camera",
                        "camera revoked by the OS (error ${err.code})",
                        null,
                    )
                }
                Log.i(TAG, "camera bound (fps slot=${frameIntervalNs / 1_000_000}ms, minCells=$minChangedCells)")
                armSuspendWatchdog(mySession, sink)
            } catch (e: Exception) {
                // Nothing bound: drop the owner so the eventual cancel has
                // nothing to tear down (its registry never left INITIALIZED).
                lifecycle = null
                deviceCamera?.sharedCapture = null
                deviceCamera?.motionSessionActive = false
                sink.error("camera", "could not open camera: ${e.message}", null)
            }
        }, ContextCompat.getMainExecutor(context))
    }

    /**
     * The screen-off suspension watchdog (see [SUSPEND_AFTER_MS]): while a
     * session is bound, check every [SUSPEND_CHECK_MS] whether frames are
     * still arriving. A dark panel with no frames for the threshold means
     * the OS suspended the camera without an error; report it as a stream
     * error so the Dart side logs the plain-language warning and rebinds on
     * the next screen-on, exactly like a loud revocation. A session bind
     * under an already-dark panel is covered too: the seed stamp below
     * starts the clock, so a bind that parks in PENDING_OPEN and never
     * produces (the One UI policy reject) trips the same report instead of
     * staying silent. The check dies with its session: every rebind and
     * cancel bumps [session], and a stale runnable returns without
     * rescheduling.
     */
    private fun armSuspendWatchdog(mySession: Int, sink: EventChannel.EventSink) {
        lastFrameAtMs = SystemClock.elapsedRealtime()
        val power = context.getSystemService(Context.POWER_SERVICE) as PowerManager
        lateinit var check: Runnable
        check = Runnable {
            if (session != mySession) return@Runnable
            val quiet = SystemClock.elapsedRealtime() - lastFrameAtMs
            if (!power.isInteractive && quiet >= SUSPEND_AFTER_MS) {
                Log.w(
                    TAG,
                    "no frames for ${quiet / 1000}s with the screen off; " +
                        "the OS has suspended the camera",
                )
                sink.error(
                    "camera",
                    "the OS suspends this device's camera while the screen " +
                        "is off; motion cannot wake it",
                    null,
                )
                return@Runnable
            }
            mainHandler.postDelayed(check, SUSPEND_CHECK_MS)
        }
        mainHandler.postDelayed(check, SUSPEND_CHECK_MS)
    }

    private fun analyze(
        image: ImageProxy,
        sink: EventChannel.EventSink,
        boundSession: Int,
    ) {
        try {
            lastFrameAtMs = SystemClock.elapsedRealtime()
            val now = System.nanoTime()
            // Drop frames that arrive before the next slot is due.
            if (lastProcessedNs != 0L && now - lastProcessedNs < frameIntervalNs) return
            lastProcessedNs = now

            val grid = sampleGrid(image)
            val prev = prevGrid
            prevGrid = grid
            frameCount++
            // The startup delay runs from the first frame, not from onListen:
            // binding CameraX and opening the device already takes a moment
            // (longer still on a camera that has to deploy), and the point is
            // to skip what the lens sees once it is actually producing.
            if (analyzeFromNs == 0L) analyzeFromNs = now + startDelayNs
            if (prev == null || frameCount <= WARMUP_FRAMES) return
            // Baseline keeps advancing above; only analysis waits, so the
            // sweep never trains the noise model it would otherwise desensitize.
            if (now < analyzeFromNs) return

            val noise = noiseGrid ?: FloatArray(CELLS) { INITIAL_NOISE }.also { noiseGrid = it }

            // The frame's global luminance shift: a light change and the AE
            // gain that answers it move every cell together, and detection
            // works on each cell's departure from this mean, not its raw
            // delta. Computed over all cells; a body large enough to drag
            // the mean drags it by only its own magnitude times the fraction
            // of frame it covers, which the subtraction cannot cancel.
            var sumDelta = 0
            for (i in 0 until CELLS) sumDelta += grid[i] - prev[i]
            val meanDelta = sumDelta / CELLS.toFloat()

            var changed = 0
            var rawChanged = 0
            var brighter = 0
            var changedMagnitude = 0f
            for (i in 0 until CELLS) {
                val delta = grid[i] - prev[i]
                val threshold = (NOISE_K * noise[i])
                    .coerceIn(THRESHOLD_FLOOR, THRESHOLD_CEILING)
                // Raw deltas feed the sign veto only.
                if (abs(delta) >= threshold) {
                    rawChanged++
                    if (delta > 0) brighter++
                }
                val magnitude = abs(delta - meanDelta)
                if (magnitude >= threshold) {
                    changed++
                    changedMagnitude += magnitude
                } else {
                    // Quiet cells teach the jitter model what "still" looks
                    // like at the current gain; changed cells stay out so
                    // motion does not desensitize the detector. Learning on
                    // the mean-relative magnitude keeps global flicker (a
                    // TV lighting the room) from inflating the model.
                    noise[i] += NOISE_ALPHA * (magnitude - noise[i])
                }
            }

            // A same-signed raw change is illumination landing unevenly (a
            // lamp reaching half the room shifts the mean by less than its
            // own cells moved), not a body; see the veto constants. The
            // known cost: something arriving entirely between two frames
            // (or looming right over the camera) reads one-signed and is
            // vetoed for that frame, but its next movement mixes signs and
            // emits, so a real person costs at most a frame of latency.
            val sameSign = max(brighter, rawChanged - brighter)
            val illumination = rawChanged >= VETO_MIN_CELLS &&
                sameSign * 100 >= rawChanged * SAME_SIGN_PERCENT

            if (changed > 0 || rawChanged > 0) {
                Log.d(TAG, "frame: changed=$changed raw=$rawChanged " +
                    "brighter=$brighter mean=${"%.1f".format(meanDelta)} " +
                    "meanMag=${if (changed > 0) (changedMagnitude / changed).roundToInt() else 0} " +
                    "veto=$illumination")
            }

            // The exposure-hunt fallback (see HUNT_FRAMES): a vetoed frame
            // with next to no mean-relative structure is AE moving the whole
            // grid; enough of them in an unbroken run is a 3A loop that will
            // never settle. Fires once per streak, at the threshold exactly;
            // the main thread validates the session and latches.
            if (slowAeApplied && illumination && changed <= HUNT_MAX_LOCAL_CELLS) {
                huntStreak++
                if (huntStreak == HUNT_FRAMES) {
                    mainHandler.post { onExposureHunt(boundSession) }
                }
            } else {
                huntStreak = 0
            }

            if (!illumination && changed >= minChangedCells &&
                now - lastEmitNs >= EMIT_INTERVAL_NS
            ) {
                lastEmitNs = now
                mainHandler.post { sink.success(mapOf("cells" to changed)) }
            }
        } finally {
            image.close()
        }
    }

    /**
     * The analyzer counted [HUNT_FRAMES] straight frames of global
     * same-signed change under an AE request: this camera's exposure loop
     * is not settling with what it was asked for (issue #164). Escalate
     * one rung of the [aeLevel] ladder and rebuild the session; the
     * restarted stream re-warms exactly like a fresh bind, so the
     * transition cannot read as motion. The ladder exists because the
     * first fallback tried default exposure and that was worse: on the
     * Tab S6 Lite the camera pipeline at its full delivery rate IS the
     * 100% CPU (the hunt itself ran at 9%), so the middle rung keeps the
     * rate pinned low and only surrenders the oscillation freedom.
     */
    private fun onExposureHunt(boundSession: Int) {
        if (session != boundSession || aeLevel >= 2) return
        val facing = activeFacing ?: return
        val sink = activeSink ?: return
        aeLevel++
        Log.w(
            TAG,
            "auto exposure kept hunting; restarting the camera " +
                (if (aeLevel == 1) "at a fixed low frame rate"
                else "with the hunt detector disarmed") +
                " (issue #164, level $aeLevel)",
        )
        // The teardown half of onCancel; start() bumps the session, so
        // callbacks of the torn-down bind die on their session checks.
        deviceCamera?.sharedCapture = null
        deviceCamera?.motionSessionActive = false
        analysis?.clearAnalyzer()
        lifecycle?.destroy()
        lifecycle = null
        provider?.unbindAll()
        analysis = null
        prevGrid = null
        noiseGrid = null
        frameCount = 0
        lastProcessedNs = 0L
        lastEmitNs = 0L
        analyzeFromNs = 0L
        huntStreak = 0
        slowAeApplied = false
        start(facing, sink)
    }

    /**
     * Ask AE for the slowest frame-rate range the sensor offers so dark
     * scenes get long exposures (more photons per frame) instead of cranked
     * gain (more noise). Analysis is throttled far below the sensor rate, so
     * the slower delivery costs nothing; in bright light AE still picks short
     * exposures and the range is irrelevant. Where the device supports it
     * (Android 15+), low-light boost AE mode is enabled on top.
     *
     * Best effort: any failure here just leaves the default AE behavior.
     * After a hunt trip ([onExposureHunt], level 1) the ask changes to the
     * lowest FIXED range instead: a pinned rate keeps the pipeline as
     * cheap as the slow range did while removing the rate freedom the
     * hunt oscillated in. A second trip (level 2) leaves AE alone.
     */
    @OptIn(ExperimentalCamera2Interop::class)
    private fun applyLowLightExposure(
        builder: ImageAnalysis.Builder,
        cameraProvider: ProcessCameraProvider,
        selector: CameraSelector,
    ) {
        slowAeApplied = false
        try {
            val info = selector.filter(cameraProvider.availableCameraInfos).firstOrNull() ?: return
            val camera2Info = Camera2CameraInfo.from(info)
            // Sanity-clamp guards against the legacy quirk of ranges
            // misreported in millifps (7000..30000).
            val ranges = camera2Info.getCameraCharacteristic(
                CameraCharacteristics.CONTROL_AE_AVAILABLE_TARGET_FPS_RANGES,
            )?.filter { it.lower >= 1 && it.upper <= 120 }
            if (ranges.isNullOrEmpty()) return
            val want = ceil(requestedFps).toInt()
            val minLowerAll = ranges.minOf { it.lower }
            val slowCandidates = ranges.filter { it.lower == minLowerAll }
            val slowWide = slowCandidates
                .filter { it.upper >= want }.minByOrNull { it.upper }
                ?: slowCandidates.maxByOrNull { it.upper }
                ?: return
            val range = if (aeLevel >= 1) {
                // The hunt fallback: the lowest pinned rate that still
                // covers the analysis cadence, else the lowest pinned rate
                // at all. Cheap comes before stiff: many sensors offer only
                // [30,30] as their fixed range, and restarting into that is
                // restarting into the full-rate pipeline — the very cost
                // this device cannot pay (the Tab S6 Lite's third round of
                // issue #164). A pinned range only wins when its ceiling is
                // no higher than the slow range's; otherwise the slow range
                // stays and this rung only re-warms, with the rung after it
                // disarming the detector. Default exposure never returns.
                val fixed = ranges.filter { it.lower == it.upper }
                val pinned = fixed.filter { it.upper >= want }
                    .minByOrNull { it.upper }
                    ?: fixed.maxByOrNull { it.upper }
                if (pinned != null && pinned.upper <= slowWide.upper) {
                    pinned
                } else {
                    slowWide
                }
            } else {
                // Prefer the tightest range that can still deliver the
                // requested processing rate; fall back to the widest one.
                slowWide
            }
            val extender = Camera2Interop.Extender(builder)
            extender.setCaptureRequestOption(CaptureRequest.CONTROL_AE_TARGET_FPS_RANGE, range)
            // Level 2 keeps the range but disarms the detector: a residual
            // hunt at a pinned low rate costs almost nothing and the veto
            // already keeps it from waking the screensaver.
            slowAeApplied = aeLevel < 2
            var boost = false
            // Low-light boost only on the first rung: it is itself an AE
            // mode with opinions, and the fallback rung is about taking
            // freedom away from a loop that cannot handle it.
            if (aeLevel == 0 && Build.VERSION.SDK_INT >= 35) {
                val modes = camera2Info.getCameraCharacteristic(
                    CameraCharacteristics.CONTROL_AE_AVAILABLE_MODES,
                )
                if (modes?.contains(AE_MODE_LOW_LIGHT_BOOST) == true) {
                    extender.setCaptureRequestOption(
                        CaptureRequest.CONTROL_AE_MODE, AE_MODE_LOW_LIGHT_BOOST)
                    boost = true
                }
            }
            Log.i(
                TAG,
                "AE fps range $range of ${ranges.joinToString()}, " +
                    "low-light boost=$boost, level=$aeLevel",
            )
        } catch (e: Exception) {
            Log.w(TAG, "low-light exposure setup skipped: ${e.message}")
        }
    }

    /** Reduce the Y plane to a [CELLS]-long grid of sparse cell averages. */
    private fun sampleGrid(image: ImageProxy): IntArray {
        val plane = image.planes[0]
        val buffer = plane.buffer
        val rowStride = plane.rowStride
        val pixelStride = plane.pixelStride
        val w = image.width
        val h = image.height
        val grid = IntArray(CELLS)

        for (gy in 0 until GRID_H) {
            val y0 = gy * h / GRID_H
            val y1 = (gy + 1) * h / GRID_H
            for (gx in 0 until GRID_W) {
                val x0 = gx * w / GRID_W
                val x1 = (gx + 1) * w / GRID_W
                var sum = 0
                var n = 0
                for (sy in 0 until SAMPLES) {
                    val py = y0 + (y1 - y0) * (sy * 2 + 1) / (SAMPLES * 2)
                    val rowBase = py * rowStride
                    for (sx in 0 until SAMPLES) {
                        val px = x0 + (x1 - x0) * (sx * 2 + 1) / (SAMPLES * 2)
                        val idx = rowBase + px * pixelStride
                        if (idx in 0 until buffer.limit()) {
                            sum += buffer.get(idx).toInt() and 0xFF
                            n++
                        }
                    }
                }
                grid[gy * GRID_W + gx] = if (n > 0) sum / n else 0
            }
        }
        return grid
    }

    override fun onCancel(arguments: Any?) {
        mainHandler.post {
            session++
            activeFacing = null
            activeSink = null
            deviceCamera?.sharedCapture = null
            deviceCamera?.motionSessionActive = false
            analysis?.clearAnalyzer()
            lifecycle?.destroy()
            lifecycle = null
            provider?.unbindAll()
            analysis = null
            prevGrid = null
            noiseGrid = null
            Log.i(TAG, "camera released")
        }
    }

    fun dispose() {
        eventChannel.setStreamHandler(null)
        onCancel(null)
        analysisExecutor.shutdown()
    }

}
