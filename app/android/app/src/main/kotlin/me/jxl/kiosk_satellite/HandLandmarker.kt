package me.jxl.kiosk_satellite

import android.content.Context
import android.os.SystemClock
import android.util.Log
import androidx.camera.core.ImageProxy
import org.tensorflow.lite.Interpreter
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.MappedByteBuffer
import java.nio.channels.FileChannel
import kotlin.math.acos
import kotlin.math.atan2
import kotlin.math.cos
import kotlin.math.max
import kotlin.math.sin
import kotlin.math.sqrt

/**
 * The second stage of the hand gestures: MediaPipe's hand landmark model
 * (hand_landmark_lite, Apache 2.0) on the crop [PalmDetector] proposes,
 * answering whether there is a hand there at all (its presence score
 * is what validates a palm candidate: a wall patch scores 0.003, a hand
 * 0.99) and where its 21 joints are, from which the extended fingers
 * are counted. The crop is built the way MediaPipe's own graph does:
 * the palm box turned so the wrist-to-middle-knuckle line points up,
 * scaled 2.6 times and shifted half a box toward the fingers, resized
 * to 224 with black outside the frame, RGB in 0..1.
 *
 * A finger counts as extended when its tip is clearly farther from the
 * wrist than its middle joint (a curled finger's tip comes back toward
 * the wrist) and the angle at that joint is not sharply bent; the
 * angle alone hovered around the threshold on a hand a few steps from
 * an Echo Show 8 (a curled pinky read 129 to 155 degrees one look to
 * the next) and flickered the count. The thumb has no such joint to
 * read, so it counts when its tip is farther from the pinky's knuckle
 * than its own joint is, by a margin of the palm's size: a tucked
 * thumb crosses the palm toward the pinky, an extended one points
 * away. All rules are orientation and handedness invariant. Costs
 * about a third of a palm run.
 *
 * Tracking: once a hand has been confirmed, the next look can skip the
 * palm stage and run this model alone on a square around the last
 * landmarks (MediaPipe's own tracking mode), a third of the cost and a
 * look every frame slot; a look that finds no hand there drops the
 * track and the palm stage proposes again.
 */
class HandLandmarker(private val context: Context) {
    companion object {
        private const val TAG = "HandLandmarker"
        private const val MODEL = "hand_landmark_lite.tflite"
        const val INPUT = 224
        private const val POINTS = 21

        /** Hand presence below which the crop held no hand. */
        const val MIN_PRESENCE = 0.5f

        /** Crop geometry (MediaPipe's rect_transformation for hands): from
         *  a palm box, and from the previous landmarks when tracking. */
        private const val CROP_SCALE = 2.6f
        private const val CROP_SHIFT = 0.5f
        private const val TRACK_SCALE = 2.0f

        /** Extended-finger rules (see the class comment): the tip's lead
         *  over the middle joint in wrist distance, as a fraction of the
         *  palm's size, and the bend a finger may still have. */
        private const val TIP_LEAD = 0.25f
        private const val MIN_ANGLE_DEG = 120f
        private const val THUMB_MARGIN = 0.05f

        const val THREADS = 1
        private const val TRACE_EVERY = 100

        // Landmark indices.
        private const val WRIST = 0
        private const val THUMB_IP = 3
        private const val THUMB_TIP = 4
        private const val MIDDLE_MCP = 9
        private const val PINKY_MCP = 17
        private val FINGERS = arrayOf(
            intArrayOf(5, 6, 8), intArrayOf(9, 10, 12), intArrayOf(13, 14, 16), intArrayOf(17, 18, 20),
        )
    }

    /** One judged crop: whether a hand is there, how many fingers it
     *  shows, and the four finger angles plus the thumb margin for the
     *  log. */
    class Hand(
        val presence: Float,
        val fingers: Int,
        val angles: FloatArray,
        val thumb: Float,
    )

    private var interpreter: Interpreter? = null
    private var landmarksIndex = 0
    private var presenceIndex = 1
    private var failed = false

    private val input = VisionInput(INPUT, 0f, 1f, bar = 0f)
    private val landmarks: ByteBuffer =
        ByteBuffer.allocateDirect(POINTS * 3 * 4).order(ByteOrder.nativeOrder())
    private val presence: ByteBuffer = ByteBuffer.allocateDirect(4).order(ByteOrder.nativeOrder())
    private val spare1: ByteBuffer = ByteBuffer.allocateDirect(4).order(ByteOrder.nativeOrder())
    private val spare2: ByteBuffer =
        ByteBuffer.allocateDirect(POINTS * 3 * 4).order(ByteOrder.nativeOrder())
    private val outputs = HashMap<Int, Any>()
    private val pts = FloatArray(POINTS * 3)

    private var runs = 0
    private var avgMs = 0f
    val costMs: Float get() = avgMs

    /** The square the last confirmed hand's landmarks fit in, in
     *  upright-frame pixels, for the next tracking look; null when no
     *  hand is being tracked. */
    private var trackCx = 0f
    private var trackCy = 0f
    private var trackSide = 0f
    private var trackRot = 0f
    var tracking = false
        private set

    /** The tracked hand's center and width as fractions of the frame,
     *  for the caller's presence bookkeeping and log. */
    val trackU: Float get() = if (input.frameW > 0) trackCx / input.frameW else 0.5f
    val trackV: Float get() = if (input.frameH > 0) trackCy / input.frameH else 0.5f
    val trackWidth: Float get() = if (input.frameW > 0) trackSide / TRACK_SCALE / input.frameW else 0f

    fun dropTrack() {
        tracking = false
    }

    /**
     * Judge the hand [palm] found in [image] (YUV_420_888, rotationDegrees
     * [rotation]), or null when the model is unavailable or the frame
     * failed. [palm]'s box and keypoints are in upright-frame normalized
     * coordinates; [frameW] and [frameH] are the upright frame's size.
     */
    fun judge(
        image: ImageProxy,
        rotation: Int,
        palm: PalmDetector.Hands,
        frameW: Int,
        frameH: Int,
    ): Hand? {
        // The crop, in upright-frame pixels.
        val bw = (palm.x1 - palm.x0) * frameW
        val bh = (palm.y1 - palm.y0) * frameH
        val long = max(bw, bh)
        val vx = (palm.midX - palm.wristX) * frameW
        val vy = (palm.midY - palm.wristY) * frameH
        // The rotation that stands the hand up: MediaPipe targets the
        // wrist-to-middle-knuckle vector at 90 degrees.
        val rot = (Math.PI / 2 - atan2(-vy.toDouble(), vx.toDouble())).toFloat()
        val ux = sin(rot)
        val uy = -cos(rot)
        val cx = (palm.x0 + palm.x1) / 2f * frameW + ux * CROP_SHIFT * long
        val cy = (palm.y0 + palm.y1) / 2f * frameH + uy * CROP_SHIFT * long
        return judgeRect(image, rotation, cx, cy, long * CROP_SCALE, rot)
    }

    /** A tracking look: the model alone, on the square around the last
     *  confirmed hand's landmarks. Null when nothing is tracked. */
    fun judgeTracked(image: ImageProxy, rotation: Int): Hand? {
        if (!tracking) return null
        return judgeRect(image, rotation, trackCx, trackCy, trackSide, trackRot)
    }

    private fun judgeRect(
        image: ImageProxy,
        rotation: Int,
        cx: Float,
        cy: Float,
        side: Float,
        rot: Float,
    ): Hand? {
        val engine = interpreter ?: load() ?: return null
        return try {
            val startNs = SystemClock.elapsedRealtimeNanos()
            input.fillRotated(image, rotation, cx, cy, side, rot)
            landmarks.rewind()
            presence.rewind()
            spare1.rewind()
            spare2.rewind()
            engine.runForMultipleInputsOutputs(arrayOf<Any>(input.buffer), outputs)
            presence.rewind()
            val p = presence.asFloatBuffer().get(0)
            landmarks.rewind()
            landmarks.asFloatBuffer().get(pts)
            val hand = count(p)
            if (p >= MIN_PRESENCE) retrack(cx, cy, side, rot) else tracking = false
            trace((SystemClock.elapsedRealtimeNanos() - startNs) / 1_000_000f)
            hand
        } catch (e: Exception) {
            Log.w(TAG, "inference failed: $e")
            null
        }
    }

    /** The next tracking square from this look's landmarks: their
     *  bounding square in frame pixels, scaled, turned to stand the hand
     *  up (wrist to middle knuckle at 90 degrees). */
    private fun retrack(cx: Float, cy: Float, side: Float, rot: Float) {
        val c = cos(rot)
        val s = sin(rot)
        var minX = Float.MAX_VALUE
        var minY = Float.MAX_VALUE
        var maxX = -Float.MAX_VALUE
        var maxY = -Float.MAX_VALUE
        var wristFx = 0f
        var wristFy = 0f
        var midFx = 0f
        var midFy = 0f
        for (i in 0 until POINTS) {
            val tx = px(i) / INPUT - 0.5f
            val ty = py(i) / INPUT - 0.5f
            val fx = cx + (tx * c + ty * s) * side
            val fy = cy + (-tx * s + ty * c) * side
            if (fx < minX) minX = fx
            if (fx > maxX) maxX = fx
            if (fy < minY) minY = fy
            if (fy > maxY) maxY = fy
            if (i == WRIST) { wristFx = fx; wristFy = fy }
            if (i == MIDDLE_MCP) { midFx = fx; midFy = fy }
        }
        trackCx = (minX + maxX) / 2f
        trackCy = (minY + maxY) / 2f
        trackSide = max(maxX - minX, maxY - minY) * TRACK_SCALE
        trackRot = (Math.PI / 2 - atan2(-(midFy - wristFy).toDouble(), (midFx - wristFx).toDouble()))
            .toFloat()
        tracking = trackSide > 8f
    }

    private fun px(i: Int) = pts[i * 3]
    private fun py(i: Int) = pts[i * 3 + 1]

    private fun dist(a: Int, b: Int): Float {
        val dx = px(a) - px(b)
        val dy = py(a) - py(b)
        return sqrt(dx * dx + dy * dy)
    }

    /** The angle at [b] between [a] and [c], in degrees. */
    private fun angle(a: Int, b: Int, c: Int): Float {
        val v1x = px(a) - px(b)
        val v1y = py(a) - py(b)
        val v2x = px(c) - px(b)
        val v2y = py(c) - py(b)
        val n = sqrt(v1x * v1x + v1y * v1y) * sqrt(v2x * v2x + v2y * v2y) + 1e-6f
        val cosang = ((v1x * v2x + v1y * v2y) / n).coerceIn(-1f, 1f)
        return Math.toDegrees(acos(cosang.toDouble())).toFloat()
    }

    private fun count(presence: Float): Hand {
        val angles = FloatArray(4)
        var n = 0
        val palm = max(dist(WRIST, MIDDLE_MCP), 1e-3f)
        for ((k, f) in FINGERS.withIndex()) {
            angles[k] = angle(f[0], f[1], f[2])
            val lead = (dist(WRIST, f[2]) - dist(WRIST, f[1])) / palm
            if (lead > TIP_LEAD && angles[k] > MIN_ANGLE_DEG) n++
        }
        val thumb = (dist(THUMB_TIP, PINKY_MCP) - dist(THUMB_IP, PINKY_MCP)) / max(palm, 1e-3f)
        if (thumb > THUMB_MARGIN) n++
        return Hand(presence, n, angles, thumb)
    }

    private fun trace(ms: Float) {
        runs++
        if (runs == 1) {
            Log.i(TAG, "landmark inference ${"%.1f".format(ms)} ms (first run)")
            return
        }
        avgMs += (ms - avgMs) / minOf(runs - 1, 20).toFloat()
        if (runs == 10) {
            Log.i(TAG, "landmark inference avg ${"%.1f".format(avgMs)} ms (steady state)")
        } else if (runs % TRACE_EVERY == 0) {
            Log.d(TAG, "landmark inference avg ${"%.1f".format(avgMs)} ms over $runs runs")
        }
    }

    private fun load(): Interpreter? {
        if (failed) return null
        return try {
            val engine = Interpreter(mapModel(), Interpreter.Options().setNumThreads(THREADS))
            // Outputs by name: Identity = landmarks (21 x 3, input pixels),
            // Identity_1 = hand presence (already a probability),
            // Identity_2 = handedness, Identity_3 = world landmarks.
            outputs.clear()
            for (i in 0 until engine.outputTensorCount) {
                val t = engine.getOutputTensor(i)
                when (t.name()) {
                    "Identity" -> { landmarksIndex = i; outputs[i] = landmarks }
                    "Identity_1" -> { presenceIndex = i; outputs[i] = presence }
                    "Identity_2" -> outputs[i] = spare1
                    else -> outputs[i] = spare2
                }
            }
            interpreter = engine
            Log.i(TAG, "hand landmark model loaded")
            engine
        } catch (e: Exception) {
            failed = true
            Log.w(TAG, "hand landmark model unavailable: ${e.message}")
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
