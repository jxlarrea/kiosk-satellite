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

        // The vision inference gate (issue #304, shared by the face and
        // the palm detector). The models are the one expensive thing in
        // this class, and most kiosks are low-powered devices already
        // running a wake word engine, so they must not run per frame in
        // an empty room. The motion grid is the trigger: it costs a few
        // hundred byte reads and already knows whether anything in the
        // frame changed. The detectors run only while (a) the grid saw a
        // real, non-lighting change within the window, (b) one of them
        // found its subject within the window (a viewer sitting still
        // keeps it alive, so Postpone on face works for someone reading
        // the dashboard, and a hand held up keeps being measured), or
        // (c) the camera opened within the window, for whoever is already
        // standing there. Between those, an idle room costs no inference
        // at all. On top, runs are capped at VISION_MIN_INTERVAL_NS apart
        // no matter the configured frame rate, and paced further by the
        // measured cost of a run (both models' when both are wanted) so
        // inference never takes more than about 1/VISION_DUTY of one core
        // while the gate is open: 0.5 s on a Tab S8 (a few ms per run),
        // about 0.9 s on an Echo Show 8 (180 ms per face run on its armv7
        // cores). A fifth of a core is the balance between cost and a
        // wake-up that still feels immediate.
        private const val VISION_ACTIVITY_WINDOW_NS = 3_000_000_000L
        private const val VISION_MIN_INTERVAL_NS = 500_000_000L
        private const val VISION_DUTY = 5L

        // While a raised hand is being timed, the pace tightens: for the
        // first PALM_SPRINT_NS of a presence (the longest hold plus a
        // margin) runs go back to back (PALM_SPRINT_DUTY, one core, at
        // the analyzer's own frame slot of 0.5 s), then settle at
        // PALM_ACTIVE_DUTY (half a core) while the hand stays up, since
        // the mapping has fired by then and only the presence's end is
        // being watched. A gesture should land a beat after its hold,
        // not two paced runs later (2.3 s each on an Echo Show 8).
        private const val PALM_SPRINT_DUTY = 1L
        private const val PALM_SPRINT_NS = 3_500_000_000L
        private const val PALM_ACTIVE_DUTY = 2L

        // A presence is dated from the start of the entry that brought
        // the hand up (the first large grid change after a quiet spell of
        // PALM_ENTRY_GAP_NS) when the first sighting follows within
        // PALM_BACKDATE_NS of that start: the hand was up from then, the
        // detector just took a frame or two to commit, and the hold
        // should not pay for that.
        // The analyzer's frame slot while hands are wanted (see onListen).
        private const val PALM_FRAME_SLOT_NS = 125_000_000L

        private const val PALM_ENTRY_GAP_NS = 1_500_000_000L
        private const val PALM_BACKDATE_NS = 3_000_000_000L


        // Adaptive exposure while hands are wanted: a front camera meters
        // the whole room and left the analysis frames at a tenth of full
        // scale in a lit bedroom, while a fixed two stops over-exposed
        // them (and the snapshots) once every light was on. The frame's
        // own mean luminance (the grid's average) steers the camera's
        // exposure compensation a step at a time, between no
        // compensation and what the camera offers, checked this often.
        private const val EXPOSURE_CHECK_NS = 2_000_000_000L
        private const val EXPOSURE_DARK = 60
        private const val EXPOSURE_BRIGHT = 150

        // A hand coming up changes 11 to 46 of the grid's 192 cells in
        // one frame (measured on an Echo Show 8, arm's length to a few
        // steps away), against the 1 to 5 of someone shifting in place.
        // A change this size pulls one run forward instead of waiting
        // out the paced interval, so the first sighting lands within a
        // frame of the hand; one such run per paced interval keeps the
        // cost bounded under continuous large motion (at most twice the
        // duty).
        private const val BURST_CELLS = 8
        private const val BURST_MAGNITUDE = 5f

        // The fast pace also holds this long after a large change (see
        // BURST_CELLS): a hand that came up but was missed on its first
        // look (mid-rise, blurred) gets its second within a second.
        private const val PALM_ENTRY_NS = 2_500_000_000L


        // A raised-hand count that differs from the one being timed is
        // accepted after this many consecutive runs. One run's flicker
        // (a phantom second hand, a hand half out of the crop) would
        // otherwise restart the hold and fire the action again.
        private const val PALM_COUNT_RUNS = 2

        // How long after the last sighting the detector keeps its
        // tracking aids (see PalmDetector.detect).
        private const val PALM_TRACK_LINGER_NS = 5_000_000_000L

        // A hand the palm detector misses for a few runs is still there:
        // on a dim, wide-angle frame the model's score for a hand held
        // still swings between 0.2 and 0.98 from one run to the next
        // (measured on an Echo Show 8 under a night light), so the
        // presence being timed keeps counting through a gap of a few
        // missed runs, and only a longer absence ends it. The gap is
        // measured in run slots (PALM_GRACE_RUNS of the paced interval,
        // about a second while a hand is tracked) with this floor for
        // fast devices.
        private const val PALM_GRACE_NS = 1_500_000_000L
        private const val PALM_GRACE_RUNS = 4L

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

    /** Face detection (issue #304) and hand detection (the Raise a hand
     *  gesture): each built on the first analyzed frame that asks for it
     *  and kept for the handler's lifetime (the models are megabytes;
     *  reloading them per screensaver session buys nothing). Touched
     *  only on [analysisExecutor]. */
    private var faceDetector: FaceDetector? = null
    private var palmDetector: PalmDetector? = null
    private var handLandmarker: HandLandmarker? = null

    /** What this listen wants emitted: motion ticks, face sightings,
     *  raised hands, any mix. Set in onListen before the bind, read on
     *  [analysisExecutor]. The frame analysis itself always runs (its
     *  exposure-hunt watchdog guards the CPU either way); only the
     *  emissions are gated. */
    @Volatile private var motionWanted = true
    @Volatile private var facesWanted = false
    @Volatile private var palmsWanted = false

    /** Whether hands are judged by the landmark stage and reported with
     *  their finger count (the Show N fingers gesture). Implies palms. */
    @Volatile private var fingersWanted = false

    /** Bumped per presence, so a hold timer from an ended presence
     *  reports nothing. Analyzer state, read on the main thread. */
    @Volatile private var presenceId = 0

    /** Smallest face worth reporting, relative to the frame's longer side
     *  (the Dart side maps the sensitivity slider to it). */
    @Volatile private var faceMinWidth = 0.1f

    /** Face sightings get their own 1/s rate limit, independent of motion's. */
    private var lastFaceEmitNs = 0L

    /** The vision inference gate (see [VISION_ACTIVITY_WINDOW_NS]): when
     *  the grid last saw a real change, when the detectors last ran, when
     *  one last found its subject, and when analysis began. Analyzer
     *  state. */
    private var lastActivityNs = 0L
    private var lastVisionRunNs = 0L
    private var lastSightingNs = 0L
    private var firstAnalyzedNs = 0L

    /** The raised-hand presence being timed: how many hands, since when
     *  that count holds, since when any hand has been up, and when hands
     *  were last seen (see [PALM_GRACE_NS]). The Dart side turns the
     *  held times into the gesture's hold. Analyzer state. */
    private var palmCount = 0
    private var palmSinceNs = 0L
    private var presenceSinceNs = 0L
    private var lastPalmSeenNs = 0L

    /** The bound camera, for runtime exposure compensation; the current
     *  index and when it was last considered. */
    @Volatile private var boundCamera: androidx.camera.core.Camera? = null
    private var exposureIndex = 0
    private var lastExposureCheckNs = 0L

    /** A different count seen on the last run(s), and since when (see
     *  [PALM_COUNT_RUNS]). Analyzer state. */
    private var pendingCount = 0
    private var pendingRuns = 0
    private var pendingSinceNs = 0L

    /** The paced interval between vision runs as last computed, which
     *  sizes the palm grace (see [PALM_GRACE_RUNS]). Analyzer state. */
    private var visionIntervalNs = VISION_MIN_INTERVAL_NS

    /** How many analyzed frames apart the grid's two frames are (1 at
     *  the configured rate; more while hands raise the sampling rate),
     *  and the recent grids to compare against. Analyzer state. */
    private var gridStride = 1
    private val recentGrids = ArrayDeque<IntArray>()

    /** Whether a burst run (see [BURST_CELLS]) may be pulled forward
     *  before the next paced run, when the grid last changed by that
     *  much (see [PALM_ENTRY_NS]), and where: the changed cells' bounding
     *  box in upright-frame coordinates, the palm detector's hint for
     *  where to look. Analyzer state. */
    private var burstCredit = true
    private var lastBigChangeNs = 0L
    private var entryStartNs = 0L
    private var activityU = 0.5f
    private var activityV = 0.5f
    private var activitySize = 1f

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
        motionWanted = args?.get("motion") != false
        facesWanted = args?.get("faces") == true
        fingersWanted = args?.get("fingers") == true
        palmsWanted = fingersWanted
        faceMinWidth =
            ((args?.get("faceMinWidth") as? Number)?.toFloat() ?: 0.1f).coerceIn(0.01f, 1f)
        lastFaceEmitNs = 0L
        resetVisionGate()

        // With hands wanted the analyzer samples at least 4 fps so a hand
        // coming up is looked at within a quarter second; the motion
        // grid then compares each frame with the one gridStride back, so
        // its deltas stay those of the configured rate and motion
        // detection is unchanged (see analyze).
        frameIntervalNs = (1_000_000_000.0 / fps).toLong()
        gridStride = 1
        if (palmsWanted && frameIntervalNs > PALM_FRAME_SLOT_NS) {
            gridStride = (frameIntervalNs / PALM_FRAME_SLOT_NS).toInt().coerceIn(1, 8)
            frameIntervalNs /= gridStride
        }
        // Sensitivity → how many of the grid's cells must change. High
        // sensitivity needs only a cell or two; low sensitivity needs roughly
        // half the frame. Never zero.
        minChangedCells = max(1, ((100 - sensitivity) * CELLS / 200.0).roundToInt())
        prevGrid = null
        recentGrids.clear()
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

            // The grid reads a fixed handful of pixels per cell and the
            // detectors a fixed 192x192, so the analysis size costs the
            // CPU nothing; it is what the palm detector's crop is cut
            // from, and a crop of a 320x240 frame is upscaled into the
            // tensor (about 108 real pixels for a typical crop) where the
            // same crop of a 640x480 frame fills it. The larger stream is
            // asked for only when hands are wanted, since it is what the
            // camera pipeline hands over per frame.
            val analysisSize = if (palmsWanted) Size(640, 480) else Size(320, 240)
            val resolution = ResolutionSelector.Builder()
                .setResolutionStrategy(
                    ResolutionStrategy(
                        analysisSize,
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
                boundCamera = camera
                exposureIndex = 0
                lastExposureCheckNs = 0L
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
                Log.i(
                    TAG,
                    "camera bound (fps slot=${frameIntervalNs / 1_000_000}ms, " +
                        "minCells=$minChangedCells, motion=$motionWanted, " +
                        "faces=$facesWanted" +
                        (if (facesWanted) " minWidth=${"%.2f".format(faceMinWidth)}" else "") +
                        ", palms=$palmsWanted, fingers=$fingersWanted)",
                )
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
            // The frame gridStride analyzed frames back, so the deltas
            // are those of the configured rate whatever the sampling.
            recentGrids.addLast(grid)
            while (recentGrids.size > gridStride + 1) recentGrids.removeFirst()
            val prev = if (recentGrids.size > gridStride) recentGrids.first() else null
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
            if (palmsWanted) steerExposure(grid, now)

            var changed = 0
            var rawChanged = 0
            var brighter = 0
            var changedMagnitude = 0f
            var cx0 = GRID_W
            var cy0 = GRID_H
            var cx1 = -1
            var cy1 = -1
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
                    val gx = i % GRID_W
                    val gy = i / GRID_W
                    if (gx < cx0) cx0 = gx
                    if (gx > cx1) cx1 = gx
                    if (gy < cy0) cy0 = gy
                    if (gy > cy1) cy1 = gy
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

            // The vision legs, gated on the grid (see
            // VISION_ACTIVITY_WINDOW_NS). Both detectors run in the same
            // slot on the same frame, and the slot is paced by their
            // combined cost.
            if (facesWanted || palmsWanted) {
                val face = if (facesWanted) {
                    faceDetector ?: FaceDetector(context).also { faceDetector = it }
                } else null
                val palm = if (palmsWanted) {
                    palmDetector ?: PalmDetector(context).also { palmDetector = it }
                } else null
                if (firstAnalyzedNs == 0L) firstAnalyzedNs = now
                if (changed > 0 && !illumination) lastActivityNs = now
                val window = VISION_ACTIVITY_WINDOW_NS
                // CPU time, not wall time: a look on several threads costs
                // the cores that many times its duration, and the duty is a
                // budget of one core.
                val costMs = (face?.costMs ?: 0f) +
                    (palm?.costMs ?: 0f) * PalmDetector.THREADS +
                    (if (fingersWanted) (handLandmarker?.costMs ?: 0f) * HandLandmarker.THREADS else 0f)
                // A hand coming up changed 11 to 18 cells at a magnitude of
                // 20 or more in every measured raise; at a pinned frame rate
                // the noise model settles so low that pixel jitter of 1 or 2
                // trips 8 to 10 cells, so the magnitude has to be real too.
                val bigChange = palmsWanted && !illumination && changed >= BURST_CELLS &&
                    changedMagnitude / changed >= BURST_MAGNITUDE
                if (bigChange) {
                    if (lastBigChangeNs == 0L || now - lastBigChangeNs > PALM_ENTRY_GAP_NS) {
                        entryStartNs = now
                    }
                    lastBigChangeNs = now
                    noteActivity(cx0, cy0, cx1, cy1, image.imageInfo.rotationDegrees)
                }
                val entering = lastBigChangeNs != 0L && now - lastBigChangeNs <= PALM_ENTRY_NS
                val sprinting = palmCount > 0 && now - presenceSinceNs <= PALM_SPRINT_NS
                // The finger gestures look every frame slot whenever
                // something moves or a hand is tracked: they are judged
                // by their latency, and the landmark stage keeps the
                // looks from costing anything but time.
                val duty = when {
                    sprinting || (fingersWanted && (entering || palmCount > 0)) -> PALM_SPRINT_DUTY
                    palmCount > 0 || entering -> PALM_ACTIVE_DUTY
                    else -> VISION_DUTY
                }
                val paced = (costMs * 1_000_000L * duty).toLong()
                visionIntervalNs = max(VISION_MIN_INTERVAL_NS, paced)
                val due = now - lastVisionRunNs >= visionIntervalNs
                val burst = !due && burstCredit && bigChange &&
                    now - lastVisionRunNs >= VISION_MIN_INTERVAL_NS
                // The finger gestures look only after a real change (a hand
                // coming up moves 4 cells or more) or while a hand is
                // tracked: a room's flicker of a cell or two must not keep
                // two models running (it cost 46% of a core at idle).
                // ... but a hand that comes up slowly, or is held still
                // past that window before a look confirmed it, still gets
                // its paced looks while anything at all changed recently:
                // gating on the large change alone missed half the shows.
                val worthIt = if (fingersWanted) {
                    entering || palmCount > 0 || now - lastActivityNs <= window
                } else {
                    now - lastActivityNs <= window ||
                        now - lastSightingNs <= window ||
                        now - firstAnalyzedNs <= window
                }
                if ((due || burst) && worthIt) {
                    burstCredit = !burst
                    lastVisionRunNs = now
                    if (face != null && detectFace(face, image, now, sink)) lastSightingNs = now
                    if (palm != null && detectPalms(palm, image, now, sink)) lastSightingNs = now
                }
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

            if (motionWanted && !illumination && changed >= minChangedCells &&
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
     * The face leg (issue #304): run the detector on this analyzed frame
     * and report the largest camera-facing face when it is at least the
     * requested size. A sighting is its own event kind ({"face": width})
     * so the Dart side can tell it from a motion tick, and it has its own
     * 1/s rate limit so a face and a movement in the same second both get
     * through. Runs on [analysisExecutor] on the same throttled frame; the
     * detector rotates the frame upright itself. Returns whether any face
     * was found, size aside, which is what keeps the inference gate open.
     */
    private fun detectFace(
        detector: FaceDetector,
        image: ImageProxy,
        now: Long,
        sink: EventChannel.EventSink,
    ): Boolean {
        val face = detector.detect(image, image.imageInfo.rotationDegrees) ?: return false
        Log.d(
            TAG,
            "face: width=${"%.2f".format(face.width)} score=${"%.2f".format(face.score)} " +
                "turn=${"%.2f".format(face.turn)}",
        )
        if (face.width < faceMinWidth) return true
        if (now - lastFaceEmitNs < EMIT_INTERVAL_NS) return true
        lastFaceEmitNs = now
        mainHandler.post { sink.success(mapOf("face" to face.width.toDouble())) }
        return true
    }

    /**
     * The hand leg (the Raise a hand gesture): count the raised hands in
     * this analyzed frame and report the presence being timed. Every run
     * that sees hands reports {"palms": n, "heldMs": p, "countHeldMs": c},
     * p being how long at least one hand has been up without a break and
     * c how long exactly n have; a run that sees none after the grace
     * without one reports {"palms": 0} once, so the Dart side re-arms.
     * The hold itself lives there, per mapping: this side only measures.
     * Runs are already spaced by the gate, so no rate limit of its own.
     * Returns whether any hand was found, raised or not, which is what
     * keeps the inference gate open.
     */
    private fun detectPalms(
        detector: PalmDetector,
        image: ImageProxy,
        now: Long,
        sink: EventChannel.EventSink,
    ): Boolean {
        // Tracking (the lower bar for the last box) lingers a few seconds past a
        // presence, so a hand lost to a couple of weak frames is found
        // again where it was rather than from scratch.
        // With a landmark stage to judge the hand, the palm stage is only
        // a proposer: any pose, a low bar, and the judgement decides. And
        // once a hand is confirmed, the next looks skip the palm stage
        // and run the landmark model on the hand's own square.
        detector.upright = false
        detector.startScore = if (fingersWanted) PalmDetector.PROPOSER_SCORE else 0.5f
        val judge = if (fingersWanted) {
            handLandmarker ?: HandLandmarker(context).also { handLandmarker = it }
        } else null
        var hands: PalmDetector.Hands? = null
        var trackedHand: HandLandmarker.Hand? = null
        if (judge != null && judge.tracking) {
            trackedHand = judge.judgeTracked(image, image.imageInfo.rotationDegrees)
            if (trackedHand != null && trackedHand.presence >= HandLandmarker.MIN_PRESENCE) {
                val w = judge.trackWidth
                val u = judge.trackU
                val v = judge.trackV
                hands = PalmDetector.Hands(
                    1, 1, w, 0f, 1f, 1f, u, v, u - w / 2f, v - w / 2f, u + w / 2f, v + w / 2f,
                    0f, 0f, 0f, 0f, -1f,
                )
            } else {
                trackedHand = null
                judge.dropTrack()
            }
        }
        if (hands == null) {
            hands = detector.detect(
                image,
                image.imageInfo.rotationDegrees,
                tracking = lastPalmSeenNs != 0L && now - lastPalmSeenNs <= PALM_TRACK_LINGER_NS,
                hint = if (lastBigChangeNs != 0L && now - lastBigChangeNs <= PALM_ENTRY_NS) {
                    PalmDetector.Hint(activityU, activityV, activitySize)
                } else null,
            )
        }
        var raised = hands?.raised ?: 0
        var fingers = -1
        if (judge != null && hands != null && raised > 0) {
            val hand = trackedHand ?: judge.judge(
                image, image.imageInfo.rotationDegrees, hands,
                detector.frameW, detector.frameH,
            )
            if (hand == null || hand.presence < HandLandmarker.MIN_PRESENCE) {
                Log.d(
                    TAG,
                    "hand: rejected by landmarks (presence=${"%.2f".format(hand?.presence ?: -1f)}) " +
                        "palm score=${"%.2f".format(hands.score)} width=${"%.2f".format(hands.width)} " +
                        "at (${"%.2f".format(hands.cx)},${"%.2f".format(hands.cy)}) crop=${"%.2f".format(hands.crop)}" +
                        (if (trackedHand != null) " (tracked)" else ""),
                )
                raised = 0
            } else {
                fingers = hand.fingers
                Log.d(
                    TAG,
                    "hand: presence=${"%.2f".format(hand.presence)} fingers=$fingers " +
                        "angles=${hand.angles.joinToString(",") { "%.0f".format(it) }} " +
                        "thumb=${"%.2f".format(hand.thumb)}" +
                        (if (trackedHand != null) " (tracked)" else ""),
                )
            }
        }
        if (raised > 0) {
            if (palmCount == 0) {
                // A presence starts on the spot (only changes of count
                // within one are debounced), dated from the grid change
                // that brought the hand up when that was moments ago.
                palmCount = raised
                val since = if (entryStartNs != 0L && now - entryStartNs <= PALM_BACKDATE_NS) {
                    entryStartNs
                } else now
                palmSinceNs = since
                presenceSinceNs = since
                pendingCount = 0
                presenceId++
            } else if (raised != palmCount) {
                if (raised == pendingCount) {
                    pendingRuns++
                    if (pendingRuns >= PALM_COUNT_RUNS) {
                        palmCount = raised
                        palmSinceNs = pendingSinceNs
                        pendingCount = 0
                    }
                } else {
                    pendingCount = raised
                    pendingRuns = 1
                    pendingSinceNs = now
                }
            } else {
                pendingCount = 0
            }
            lastPalmSeenNs = now
            val count = palmCount
            val fingerCount = fingers
            mainHandler.post {
                sink.success(
                    mapOf("palms" to count, "fingers" to fingerCount),
                )
            }
        } else if (palmCount > 0 &&
            now - lastPalmSeenNs > max(PALM_GRACE_NS, PALM_GRACE_RUNS * visionIntervalNs)
        ) {
            palmCount = 0
            pendingCount = 0
            presenceId++
            mainHandler.post {
                sink.success(mapOf("palms" to 0, "fingers" to -1))
            }
        }
        return hands != null && hands.seen > 0
    }

    /**
     * Where the grid just changed, for the palm detector's look: the
     * changed cells' bounding box (grid coordinates, sensor orientation)
     * turned upright by [rotation], as a center in fractions of the
     * upright frame's width and height and a size in fractions of its
     * height (the larger side).
     */
    private fun noteActivity(gx0: Int, gy0: Int, gx1: Int, gy1: Int, rotation: Int) {
        if (gx1 < gx0 || gy1 < gy0) return
        // Sensor-frame normalized box.
        val sx0 = gx0.toFloat() / GRID_W
        val sx1 = (gx1 + 1).toFloat() / GRID_W
        val sy0 = gy0.toFloat() / GRID_H
        val sy1 = (gy1 + 1).toFloat() / GRID_H
        // Upright: the inverse of the sampling in VisionInput.fill.
        val u0: Float
        val u1: Float
        val v0: Float
        val v1: Float
        when (rotation) {
            90 -> { u0 = 1f - sy1; u1 = 1f - sy0; v0 = sx0; v1 = sx1 }
            180 -> { u0 = 1f - sx1; u1 = 1f - sx0; v0 = 1f - sy1; v1 = 1f - sy0 }
            270 -> { u0 = sy0; u1 = sy1; v0 = 1f - sx1; v1 = 1f - sx0 }
            else -> { u0 = sx0; u1 = sx1; v0 = sy0; v1 = sy1 }
        }
        val turned = rotation == 90 || rotation == 270
        // Width over height of the upright frame, to put the horizontal
        // extent in units of the height.
        val widthOverHeight = if (turned) GRID_H.toFloat() / GRID_W else GRID_W.toFloat() / GRID_H
        activityU = (u0 + u1) / 2f
        activityV = (v0 + v1) / 2f
        activitySize = max((u1 - u0) * widthOverHeight, v1 - v0)
    }

    /**
     * Adaptive exposure (see [EXPOSURE_CHECK_NS]): a step up when the
     * frame is dark, a step down when it is bright, applied through
     * CameraX's exposure compensation without rebinding.
     */
    private fun steerExposure(grid: IntArray, now: Long) {
        if (lastExposureCheckNs != 0L && now - lastExposureCheckNs < EXPOSURE_CHECK_NS) return
        lastExposureCheckNs = now
        val camera = boundCamera ?: return
        val state = camera.cameraInfo.exposureState
        if (!state.isExposureCompensationSupported) return
        var sum = 0L
        for (v in grid) sum += v
        val mean = (sum / CELLS).toInt()
        val range = state.exposureCompensationRange
        val step = state.exposureCompensationStep
        // One EV per adjustment, in the camera's own steps.
        val perEv = if (step.numerator > 0) max(1, (step.denominator / step.numerator)) else 1
        var wanted = exposureIndex
        if (mean < EXPOSURE_DARK && exposureIndex < range.upper) wanted = minOf(range.upper, exposureIndex + perEv)
        if (mean > EXPOSURE_BRIGHT && exposureIndex > 0) wanted = maxOf(0, exposureIndex - perEv)
        if (wanted == exposureIndex) return
        exposureIndex = wanted
        Log.i(TAG, "exposure: frame mean $mean, compensation index $wanted of ${range.lower}..${range.upper}")
        mainHandler.post {
            try {
                camera.cameraControl.setExposureCompensationIndex(wanted)
            } catch (e: Exception) {
                Log.w(TAG, "exposure compensation failed: $e")
            }
        }
    }

    /** Fresh gate and presence state for a (re)bound session. */
    private fun resetVisionGate() {
        lastActivityNs = 0L
        lastVisionRunNs = 0L
        lastSightingNs = 0L
        firstAnalyzedNs = 0L
        palmCount = 0
        presenceId++
        palmSinceNs = 0L
        presenceSinceNs = 0L
        lastPalmSeenNs = 0L
        pendingCount = 0
        pendingRuns = 0
        pendingSinceNs = 0L
        visionIntervalNs = VISION_MIN_INTERVAL_NS
        burstCredit = true
        lastBigChangeNs = 0L
        entryStartNs = 0L
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
        recentGrids.clear()
        noiseGrid = null
        frameCount = 0
        lastProcessedNs = 0L
        lastEmitNs = 0L
        analyzeFromNs = 0L
        huntStreak = 0
        slowAeApplied = false
        resetVisionGate()
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
            // With hands wanted the analyzer looks 8 times a second and
            // nothing needs frames faster: the lowest fixed rate that
            // covers it. On a legacy camera HAL (an Echo Show 8) every
            // delivered frame is copied through GL, and at the default
            // 30 fps delivery that copy plus the analyzer's receipt of it
            // cost half a core at idle; at 10 fps a sixth of that.
            val handRate = if (palmsWanted) {
                val want8 = ceil(1_000_000_000.0 / PALM_FRAME_SLOT_NS).toInt()
                ranges.filter { it.lower == it.upper && it.upper >= want8 }
                    .minByOrNull { it.upper }
            } else null
            val range = if (handRate != null) {
                handRate
            } else if (aeLevel >= 1) {
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
            slowAeApplied = handRate == null && aeLevel < 2
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
            boundCamera = null
            analysis?.clearAnalyzer()
            lifecycle?.destroy()
            lifecycle = null
            provider?.unbindAll()
            analysis = null
            prevGrid = null
            recentGrids.clear()
            noiseGrid = null
            Log.i(TAG, "camera released")
        }
    }

    fun dispose() {
        eventChannel.setStreamHandler(null)
        onCancel(null)
        // On the analyzer's own thread, after any frame still in flight.
        analysisExecutor.execute {
            faceDetector?.close()
            faceDetector = null
            palmDetector?.close()
            palmDetector = null
            handLandmarker?.close()
            handLandmarker = null
        }
        analysisExecutor.shutdown()
    }

}
