package me.jxl.kiosk_satellite

import android.content.Context
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CaptureRequest
import android.os.Build
import android.os.Handler
import android.os.Looper
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

        // Auto-exposure settles over the first frames after the camera opens and
        // swings luminance globally; skip them so it does not read as motion.
        private const val WARMUP_FRAMES = 3

        private const val EMIT_INTERVAL_NS = 1_000_000_000L // rate-limit: 1/s
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

        requestedFps = fps

        // CameraX binding must happen on the main thread.
        mainHandler.post {
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
        val future = ProcessCameraProvider.getInstance(context)
        future.addListener({
            if (session != mySession) return@addListener
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
            imageAnalysis.setAnalyzer(analysisExecutor) { image -> analyze(image, sink) }
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
                if (imageCapture != null) {
                    try {
                        cameraProvider.bindToLifecycle(
                            owner, selector, imageAnalysis, imageCapture)
                        deviceCamera.sharedCapture = imageCapture
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
                Log.i(TAG, "camera bound (fps slot=${frameIntervalNs / 1_000_000}ms, minCells=$minChangedCells)")
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

    private fun analyze(image: ImageProxy, sink: EventChannel.EventSink) {
        try {
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
     * Ask AE for the slowest frame-rate range the sensor offers so dark
     * scenes get long exposures (more photons per frame) instead of cranked
     * gain (more noise). Analysis is throttled far below the sensor rate, so
     * the slower delivery costs nothing; in bright light AE still picks short
     * exposures and the range is irrelevant. Where the device supports it
     * (Android 15+), low-light boost AE mode is enabled on top.
     *
     * Best effort: any failure here just leaves the default AE behavior.
     */
    @OptIn(ExperimentalCamera2Interop::class)
    private fun applyLowLightExposure(
        builder: ImageAnalysis.Builder,
        cameraProvider: ProcessCameraProvider,
        selector: CameraSelector,
    ) {
        try {
            val info = selector.filter(cameraProvider.availableCameraInfos).firstOrNull() ?: return
            val camera2Info = Camera2CameraInfo.from(info)
            // Sanity-clamp guards against the legacy quirk of ranges
            // misreported in millifps (7000..30000).
            val ranges = camera2Info.getCameraCharacteristic(
                CameraCharacteristics.CONTROL_AE_AVAILABLE_TARGET_FPS_RANGES,
            )?.filter { it.lower >= 1 && it.upper <= 120 }
            if (ranges.isNullOrEmpty()) return
            val minLower = ranges.minOf { it.lower }
            val candidates = ranges.filter { it.lower == minLower }
            // Prefer the tightest range that can still deliver the requested
            // processing rate; fall back to the widest one.
            val want = ceil(requestedFps).toInt()
            val range = candidates.filter { it.upper >= want }.minByOrNull { it.upper }
                ?: candidates.maxByOrNull { it.upper }
                ?: return
            val extender = Camera2Interop.Extender(builder)
            extender.setCaptureRequestOption(CaptureRequest.CONTROL_AE_TARGET_FPS_RANGE, range)
            var boost = false
            if (Build.VERSION.SDK_INT >= 35) {
                val modes = camera2Info.getCameraCharacteristic(
                    CameraCharacteristics.CONTROL_AE_AVAILABLE_MODES,
                )
                if (modes?.contains(AE_MODE_LOW_LIGHT_BOOST) == true) {
                    extender.setCaptureRequestOption(
                        CaptureRequest.CONTROL_AE_MODE, AE_MODE_LOW_LIGHT_BOOST)
                    boost = true
                }
            }
            Log.i(TAG, "AE fps range $range of ${ranges.joinToString()}, low-light boost=$boost")
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
