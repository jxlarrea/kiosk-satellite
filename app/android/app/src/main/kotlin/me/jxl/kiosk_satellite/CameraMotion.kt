package me.jxl.kiosk_satellite

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.ImageProxy
import androidx.camera.core.resolutionselector.ResolutionSelector
import androidx.camera.core.resolutionselector.ResolutionStrategy
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.core.content.ContextCompat
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.LifecycleRegistry
import android.util.Size
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import java.util.concurrent.Executors
import kotlin.math.abs
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
 *    allocation and no colour conversion at all;
 *  - throttles to a configurable frame rate (default a couple per second) by
 *    dropping every frame that arrives before the next slot is due;
 *  - reduces each processed frame to a small grid of sparsely-sampled cell
 *    averages and diffs that against the previous grid — a few hundred byte
 *    reads, not a per-pixel sweep.
 *
 * Only a "motion" tick ever crosses the channel, rate-limited to one per second.
 * The Dart side decides what motion means (waking the screensaver); the camera
 * is bound only while something is listening, and [onCancel] frees it.
 */
class CameraMotion(
    private val context: Context,
    messenger: BinaryMessenger,
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

        // A cell counts as "changed" when its average luminance moves by this
        // much (0..255). Above sensor noise, below a real body-sized change.
        private const val CELL_DELTA = 16

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
    private var lifecycle: MotionLifecycle? = null

    // Analyzer state (touched only on analysisExecutor).
    private var prevGrid: IntArray? = null
    private var frameCount = 0
    private var lastProcessedNs = 0L
    private var lastEmitNs = 0L
    private var frameIntervalNs = 0L
    private var minChangedCells = 1

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

        frameIntervalNs = (1_000_000_000.0 / fps).toLong()
        // Sensitivity → how many of the grid's cells must change. High
        // sensitivity needs only a cell or two; low sensitivity needs roughly
        // half the frame. Never zero.
        minChangedCells = max(1, ((100 - sensitivity) * CELLS / 200.0).roundToInt())
        prevGrid = null
        frameCount = 0
        lastProcessedNs = 0L
        lastEmitNs = 0L

        // CameraX binding must happen on the main thread.
        mainHandler.post { start(facing, sink) }
    }

    private fun start(facing: CameraSelector, sink: EventChannel.EventSink) {
        val future = ProcessCameraProvider.getInstance(context)
        future.addListener({
            val cameraProvider = try {
                future.get()
            } catch (e: Exception) {
                sink.error("camera", "camera provider unavailable: ${e.message}", null)
                return@addListener
            }
            provider = cameraProvider

            val resolution = ResolutionSelector.Builder()
                .setResolutionStrategy(
                    ResolutionStrategy(
                        Size(320, 240),
                        ResolutionStrategy.FALLBACK_RULE_CLOSEST_LOWER_THEN_HIGHER,
                    ),
                )
                .build()

            val imageAnalysis = ImageAnalysis.Builder()
                .setResolutionSelector(resolution)
                .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
                .build()
            imageAnalysis.setAnalyzer(analysisExecutor) { image -> analyze(image, sink) }
            analysis = imageAnalysis

            val owner = MotionLifecycle().also { lifecycle = it }
            try {
                cameraProvider.unbindAll()
                cameraProvider.bindToLifecycle(owner, facing, imageAnalysis)
                owner.resume()
                Log.i(TAG, "camera bound (fps slot=${frameIntervalNs / 1_000_000}ms, minCells=$minChangedCells)")
            } catch (e: Exception) {
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
            if (prev == null || frameCount <= WARMUP_FRAMES) return

            var changed = 0
            for (i in 0 until CELLS) {
                if (abs(grid[i] - prev[i]) >= CELL_DELTA) changed++
            }
            if (changed >= minChangedCells && now - lastEmitNs >= EMIT_INTERVAL_NS) {
                lastEmitNs = now
                mainHandler.post { sink.success(mapOf("cells" to changed)) }
            }
        } finally {
            image.close()
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
            analysis?.clearAnalyzer()
            lifecycle?.destroy()
            lifecycle = null
            provider?.unbindAll()
            analysis = null
            prevGrid = null
            Log.i(TAG, "camera released")
        }
    }

    fun dispose() {
        eventChannel.setStreamHandler(null)
        onCancel(null)
        analysisExecutor.shutdown()
    }

    /**
     * A self-driven lifecycle so the camera's lifetime is exactly the listen
     * span, independent of the activity. Mutated only on the main thread.
     */
    private class MotionLifecycle : LifecycleOwner {
        private val registry = LifecycleRegistry(this)
        override val lifecycle: Lifecycle get() = registry
        fun resume() { registry.currentState = Lifecycle.State.RESUMED }
        fun destroy() { registry.currentState = Lifecycle.State.DESTROYED }
    }
}
