package me.jxl.kiosk_satellite

import android.content.Context
import android.util.Log
import androidx.camera.core.ImageProxy
import org.tensorflow.lite.Interpreter
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.MappedByteBuffer
import java.nio.channels.FileChannel
import android.os.SystemClock
import kotlin.math.abs
import kotlin.math.exp
import kotlin.math.ln
import kotlin.math.max

/**
 * On-device face detection for the screensaver's "Dismiss on face" (issue
 * #304): is someone looking at the kiosk, as opposed to merely moving
 * through the room? Runs inside [CameraMotion]'s analyzer, on the same
 * throttled, smallest-resolution frames the motion grid samples, so the
 * camera is opened once. A run costs a few milliseconds on a mid-range
 * CPU and about 180 ms on an Echo Show 8's armv7 cores; CameraMotion
 * decides when a run is worth it at all (its motion grid is the trigger)
 * and paces runs by the cost measured here, so an idle room costs
 * nothing and a busy one a bounded slice of a single core.
 *
 * The model is MediaPipe's BlazeFace full-range detector (Apache 2.0), a
 * 192x192 single-shot detector tuned for faces up to a few meters from a
 * front camera. It answers with 2304 anchor boxes and their scores; this
 * class decodes them just far enough to find the largest face facing the
 * camera, and reports its width as a fraction of the frame's longer side.
 * That width is the sensitivity metric: a face fills more of the frame the
 * closer it is, so a minimum width is a maximum distance. There is no
 * non-maximum suppression, because nothing here needs the face count.
 *
 * "Facing the camera" uses the model's keypoints: the nose tip projected
 * onto the line between the eyes lands near their midpoint for a frontal
 * face and drifts toward one eye as the head turns away, so a bound on
 * that offset (in eye-distance units) rejects profiles and glances past
 * the screen. The projection makes it roll-invariant.
 *
 * Detection is not recognition: nothing is identified, stored or compared.
 * The runtime is LiteRT, which the wake word engine already brings into
 * the APK, so the only addition is the model file itself.
 */
class FaceDetector(private val context: Context) {
    companion object {
        private const val TAG = "FaceDetector"
        private const val MODEL = "blazeface_full_range.tflite"

        /** Model input edge, and the coordinate scale of its outputs. */
        const val INPUT = 192

        // The anchor layout of the full-range model: one fixed-size anchor
        // per cell of a stride-4 grid, centered in the cell. Boxes and
        // keypoints are offsets from the anchor center in input pixels.
        private const val GRID = INPUT / 4
        private const val ANCHORS = GRID * GRID
        private const val COORDS = 16

        /** Sigmoid score below which an anchor is background. MediaPipe's
         *  own threshold for this model. Compared in logit space so the
         *  2304-anchor sweep never computes a sigmoid for background. */
        private const val MIN_SCORE = 0.6f
        private val MIN_LOGIT = ln(MIN_SCORE / (1f - MIN_SCORE))

        /** Frontal bound: the nose's offset along the eye line, in eye
         *  distances. 0 is dead center; around 0.5 the head is turned far
         *  enough that only one eye still sees the screen. */
        private const val FRONTAL_MAX = 0.6f

        /** Keypoint order in the 16 coords: box (cx, cy, w, h), then right
         *  eye, left eye, nose tip, mouth, right ear, left ear as (x, y). */
        private const val KP_RIGHT_EYE = 4
        private const val KP_LEFT_EYE = 6
        private const val KP_NOSE = 8

        /** One thread: the model is small enough that a second one buys
         *  little, and the kiosks this runs on are low-powered devices
         *  already running a wake word engine that wants the other cores.
         *  The inference gate in CameraMotion keeps the call count low;
         *  this keeps each call from spreading. */
        private const val THREADS = 1

        /** Inference-cost trace: the first run at info, then every this
         *  many runs at debug, as a running average. */
        private const val TRACE_EVERY = 100
    }

    /** The largest camera-facing face in a frame. [width] is relative to
     *  the frame's longer side; [turn] is the frontal measure (see
     *  [FRONTAL_MAX]), for the log. */
    class Face(val width: Float, val score: Float, val turn: Float)

    private var interpreter: Interpreter? = null
    private var regIndex = 0
    private var scoreIndex = 1
    private var failed = false

    // Reused across frames: a 192x192 RGB float tensor and the two outputs.
    private val input: ByteBuffer =
        ByteBuffer.allocateDirect(INPUT * INPUT * 3 * 4).order(ByteOrder.nativeOrder())
    private val regressors: ByteBuffer =
        ByteBuffer.allocateDirect(ANCHORS * COORDS * 4).order(ByteOrder.nativeOrder())
    private val scores: ByteBuffer =
        ByteBuffer.allocateDirect(ANCHORS * 4).order(ByteOrder.nativeOrder())

    /** The letterbox geometry the input buffer's bars were last zeroed
     *  for (packed ow/oh/ox/oy); the bars are rewritten only when it
     *  changes, since the frame region overwrites everything else. */
    private var barsFor = -1

    // Cost trace (see TRACE_EVERY).
    private var runs = 0
    private var avgMs = 0f

    /**
     * Find the largest face looking at the camera in [image] (YUV_420_888),
     * or null. [rotation] is the frame's rotationDegrees: the model is not
     * rotation invariant, and an analysis frame arrives in sensor
     * orientation, so it is turned upright first. Null also when the model
     * could not be loaded (logged once); the caller then simply never sees
     * a face.
     */
    fun detect(image: ImageProxy, rotation: Int): Face? {
        val engine = interpreter ?: load() ?: return null
        // Nothing in here may take the kiosk down: this runs on the camera
        // analyzer's thread, where an uncaught exception is a process
        // crash. A failing frame is a missed face, logged and moved past.
        return try {
            val startNs = SystemClock.elapsedRealtimeNanos()
            fill(image, rotation)
            input.rewind()
            regressors.rewind()
            scores.rewind()
            engine.runForMultipleInputsOutputs(
                arrayOf<Any>(input),
                mapOf<Int, Any>(regIndex to regressors, scoreIndex to scores),
            )
            val face = decode()
            trace((SystemClock.elapsedRealtimeNanos() - startNs) / 1_000_000f)
            face
        } catch (e: Exception) {
            Log.w(TAG, "inference failed: $e")
            null
        }
    }

    private fun decode(): Face? {
        // The interpreter leaves each output buffer positioned at its end;
        // a float view starts at the position, so rewind first or the view
        // is empty (limit 0).
        regressors.rewind()
        scores.rewind()
        val reg = regressors.asFloatBuffer()
        val cls = scores.asFloatBuffer()
        var best: Face? = null
        var topRaw = -100f
        for (i in 0 until ANCHORS) {
            val raw = cls.get(i)
            if (raw > topRaw) topRaw = raw
            if (raw < MIN_LOGIT) continue
            val score = 1f / (1f + exp(-raw.coerceIn(-100f, 100f)))
            val base = i * COORDS
            val ax = ((i % GRID) + 0.5f) / GRID
            val ay = ((i / GRID) + 0.5f) / GRID
            val width = reg.get(base + 2) / INPUT
            if (best != null && width <= best.width) continue
            val rex = reg.get(base + KP_RIGHT_EYE) / INPUT + ax
            val rey = reg.get(base + KP_RIGHT_EYE + 1) / INPUT + ay
            val lex = reg.get(base + KP_LEFT_EYE) / INPUT + ax
            val ley = reg.get(base + KP_LEFT_EYE + 1) / INPUT + ay
            val nx = reg.get(base + KP_NOSE) / INPUT + ax
            val ny = reg.get(base + KP_NOSE + 1) / INPUT + ay
            val ex = lex - rex
            val ey = ley - rey
            val eyeDist2 = ex * ex + ey * ey
            if (eyeDist2 <= 0f) continue
            val mx = (lex + rex) / 2f
            val my = (ley + rey) / 2f
            val turn = ((nx - mx) * ex + (ny - my) * ey) / eyeDist2
            if (abs(turn) > FRONTAL_MAX) continue
            best = Face(width, score, turn)
        }
        // Debug-level trace of the strongest candidate even when nothing
        // passes: the way to tell "no face in frame" from "the frame is not
        // reaching the model right" when tuning on a device.
        if (best == null && topRaw > -1.4f) {
            val topScore = 1f / (1f + exp(-topRaw.coerceIn(-100f, 100f)))
            Log.d(TAG, "no face: top score ${"%.2f".format(topScore)}")
        }
        return best
    }

    /** Running average cost of one [detect] call in milliseconds, 0 until
     *  measured. The caller paces itself by it. The first run is logged
     *  but kept out of the average: it carries the delegate's warm-up
     *  (274 ms on an Echo Show 8 against a steady state well under 100). */
    val costMs: Float get() = avgMs

    private fun trace(ms: Float) {
        runs++
        // A plain mean until the window fills, an EMA after, so the pacing
        // settles within a few runs instead of trusting the second one.
        if (runs == 1) {
            Log.i(TAG, "face inference ${"%.1f".format(ms)} ms (first run)")
            return
        }
        avgMs += (ms - avgMs) / minOf(runs - 1, 20).toFloat()
        if (runs == 10) {
            Log.i(TAG, "face inference avg ${"%.1f".format(avgMs)} ms (steady state)")
        } else if (runs % TRACE_EVERY == 0) {
            Log.d(TAG, "face inference avg ${"%.1f".format(avgMs)} ms over $runs runs")
        }
    }

    /**
     * Convert the frame to the model's input: rotated upright, scaled to
     * fit the 192 square on its longer side, centered with black bars, RGB
     * in -1..1. Nearest-neighbor sampling from the YUV planes straight
     * into the float tensor: at the analyzer's 320x240 that is 27k pixels,
     * no bitmap and no intermediate buffer.
     */
    private fun fill(image: ImageProxy, rotation: Int) {
        val yPlane = image.planes[0]
        val uPlane = image.planes[1]
        val vPlane = image.planes[2]
        val yBuf = yPlane.buffer
        val uBuf = uPlane.buffer
        val vBuf = vPlane.buffer
        val w = image.width
        val h = image.height
        val turned = rotation == 90 || rotation == 270
        val rw = if (turned) h else w
        val rh = if (turned) w else h
        val scale = max(rw, rh).toFloat() / INPUT
        val ow = (rw / scale).toInt().coerceIn(1, INPUT)
        val oh = (rh / scale).toInt().coerceIn(1, INPUT)
        val ox = (INPUT - ow) / 2
        val oy = (INPUT - oh) / 2

        input.rewind()
        val out = input.asFloatBuffer()
        // Letterbox bars: zero is mid-gray in the model's input space. The
        // frame region below overwrites the rest every time, so the bars
        // only need writing when the geometry changes.
        val geometry = (ow shl 24) or (oh shl 16) or (ox shl 8) or oy
        if (geometry != barsFor) {
            for (i in 0 until INPUT * INPUT * 3) out.put(i, 0f)
            barsFor = geometry
        }

        val yLimit = yBuf.limit()
        val uLimit = uBuf.limit()
        val vLimit = vBuf.limit()
        for (iy in 0 until oh) {
            val sy = ((iy + 0.5f) * scale).toInt().coerceIn(0, rh - 1)
            for (ix in 0 until ow) {
                val sx = ((ix + 0.5f) * scale).toInt().coerceIn(0, rw - 1)
                // (sx, sy) is a pixel of the upright frame; map it back to
                // the sensor frame the buffers hold.
                val px: Int
                val py: Int
                when (rotation) {
                    90 -> { px = sy; py = h - 1 - sx }
                    180 -> { px = w - 1 - sx; py = h - 1 - sy }
                    270 -> { px = w - 1 - sy; py = sx }
                    else -> { px = sx; py = sy }
                }
                val yIdx = py * yPlane.rowStride + px * yPlane.pixelStride
                val uIdx = (py / 2) * uPlane.rowStride + (px / 2) * uPlane.pixelStride
                val vIdx = (py / 2) * vPlane.rowStride + (px / 2) * vPlane.pixelStride
                if (yIdx >= yLimit || uIdx >= uLimit || vIdx >= vLimit) continue
                val yv = (yBuf.get(yIdx).toInt() and 0xFF) - 16
                val uv = (uBuf.get(uIdx).toInt() and 0xFF) - 128
                val vv = (vBuf.get(vIdx).toInt() and 0xFF) - 128
                val yl = 1.164f * yv
                val r = (yl + 1.596f * vv).coerceIn(0f, 255f)
                val g = (yl - 0.813f * vv - 0.391f * uv).coerceIn(0f, 255f)
                val b = (yl + 2.018f * uv).coerceIn(0f, 255f)
                val o = ((oy + iy) * INPUT + (ox + ix)) * 3
                out.put(o, r / 127.5f - 1f)
                out.put(o + 1, g / 127.5f - 1f)
                out.put(o + 2, b / 127.5f - 1f)
            }
        }
    }

    private fun load(): Interpreter? {
        if (failed) return null
        return try {
            val model = mapModel()
            val engine = Interpreter(model, Interpreter.Options().setNumThreads(THREADS))
            // The two outputs are told apart by shape, not by the order
            // the converter happened to emit them in.
            for (i in 0 until engine.outputTensorCount) {
                val shape = engine.getOutputTensor(i).shape()
                val last = shape.last()
                if (last == COORDS) regIndex = i
                if (last == 1) scoreIndex = i
            }
            interpreter = engine
            Log.i(TAG, "face model loaded")
            engine
        } catch (e: Exception) {
            failed = true
            Log.w(TAG, "face model unavailable: ${e.message}")
            null
        }
    }

    private fun mapModel(): MappedByteBuffer {
        val fd = context.assets.openFd(MODEL)
        fd.createInputStream().use { stream ->
            return stream.channel.map(
                FileChannel.MapMode.READ_ONLY, fd.startOffset, fd.declaredLength)
        }
    }

    fun close() {
        interpreter?.close()
        interpreter = null
    }
}
