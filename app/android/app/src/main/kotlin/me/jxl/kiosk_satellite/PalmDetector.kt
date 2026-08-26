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
import kotlin.math.abs
import kotlin.math.atan2
import kotlin.math.exp
import kotlin.math.max
import kotlin.math.min

/**
 * On-device hand detection for the "Raise a hand" gesture: is someone
 * holding a hand up to the kiosk? The sibling of [FaceDetector], built
 * the same way: MediaPipe's BlazePalm detector (palm_detection_full,
 * Apache 2.0) on LiteRT, run by [CameraMotion] on its analyzer thread,
 * on the same throttled frames the motion grid samples, under the same
 * inference gate and cost pacing, so an idle room costs no inference
 * and a busy one a bounded slice of one core. The model is 192x192,
 * single-shot, and answers with 2016 anchor boxes, each a palm box with
 * seven keypoints (wrist, the four finger knuckles, two thumb joints)
 * and a score.
 *
 * What it reports is the number of raised hands in the frame: palms
 * that survive non-maximum suppression, are at least [MIN_WIDTH] of the
 * tensor wide, and point up. "Up" uses the keypoints: the direction
 * from the wrist to the middle finger's knuckle is within
 * [UPRIGHT_MAX_DEG] of straight up in the upright frame. That is what
 * separates a hand held up at the screen from hands on a keyboard,
 * around a mug or reaching for the tablet, all of which the detector
 * finds just as readily. A box must also carry some light ([MIN_LUMA]):
 * the model's scores on sensor noise in the dark can reach its
 * threshold, and a hand nobody can see is not a gesture. The floor is
 * near black on purpose: a palm held up in a dim bedroom (an Echo Show
 * 8 under a night light) reads at 0.5 to 0.7 with little light on it,
 * and that is the room this gesture is for. The
 * detector cannot tell an open palm from a fist; the hold
 * [CameraMotion] and the gestures manager add on top is the other half
 * of the gesture. Detection is not recognition: nothing is identified,
 * stored or compared.
 *
 * Reach: at its 192 pixel input the model needs a hand spanning about
 * a seventh of the tensor, and a hand a couple of meters from a
 * wide-angle front camera spans a fifteenth of the frame. So the
 * tensor is not always the whole frame: while the motion grid has just
 * seen a large change (a hand coming up), the look is a square of the
 * frame around that change, and while a hand is being tracked, a
 * square around the hand; either roughly doubles the hand's pixels
 * (measured on an Echo Show 8 frame: a hand at 0.07 of the frame's
 * width scored 0.64 whole-frame and 0.95 cropped). The whole frame,
 * letterboxed with black bars as MediaPipe's own graph does, is the
 * look otherwise, and the look after any crop that found nothing, so a
 * hand outside the crop is found again rather than lost. All boxes are
 * reported in upright-frame coordinates whatever the look, so tracking
 * carries across looks. A fixed central crop was tried and dropped: a
 * person standing to the side of the camera holds the hand exactly in
 * the strip it discards.
 */
class PalmDetector(private val context: Context) {
    companion object {
        private const val TAG = "PalmDetector"
        private const val MODEL = "palm_detection_lite.tflite"

        /** Model input edge, and the coordinate scale of its outputs. */
        const val INPUT = 192

        // The anchor layout of the 192 palm model (MediaPipe's
        // SsdAnchorsCalculator with strides 8, 16, 16, 16, one aspect
        // ratio, fixed anchor size): the stride-8 layer is a 24x24 grid
        // with two anchors per cell, then the three stride-16 layers
        // merge into a 12x12 grid with six per cell. Every anchor is a
        // unit square at its cell's center, so only the centers matter:
        // boxes and keypoints are offsets from them in input pixels.
        private const val GRID_A = INPUT / 8
        private const val PER_CELL_A = 2
        private const val ANCHORS_A = GRID_A * GRID_A * PER_CELL_A
        private const val GRID_B = INPUT / 16
        private const val PER_CELL_B = 6
        private const val ANCHORS = ANCHORS_A + GRID_B * GRID_B * PER_CELL_B
        private const val COORDS = 18

        /** Sigmoid score below which an anchor is background: MediaPipe's
         *  own threshold for this model, compared in logit space (0.5 is
         *  logit 0) so the sweep never computes a sigmoid for background.
         *  Lowering it to 0.4 was tried for reach and dropped: a static
         *  something in a bedroom scored 0.45 to 0.51 at a hand-like tilt
         *  and fired the gesture twice in three minutes. */
        private const val MIN_LOGIT = 0f

        /** The permissive start bar for a proposer whose candidates a
         *  landmark stage will judge (see [startScore]). */
        const val PROPOSER_SCORE = 0.3f

        /** The smallest crop, as a fraction of the frame's height, and
         *  the crop's side in widths of the hand (or of the activity) it
         *  is centered on, so a hand that drifts stays inside. */
        private const val CROP_MIN_SIDE = 0.45f
        private const val CROP_HAND_WIDTHS = 4f
        private const val CROP_ACTIVITY_MARGIN = 1.5f

        /** The lower bar for continuing a hand already seen: a candidate
         *  centered within [TRACK_REACH] widths of the last raised hand's
         *  box passes at this score (0.2). A palm under a night light scores anywhere
         *  from 0.2 to 0.9 from one run to the next, and a run that
         *  misses it stalls the hold; once a hand has cleared the full
         *  bar, a candidate in the same box a beat later is far likelier
         *  the hand than noise, and the worst a wrong one can do is keep
         *  a presence alive a little longer. */
        private val TRACK_LOGIT = kotlin.math.ln(0.2f / 0.8f)
        private const val TRACK_REACH = 1.5f

        /** Boxes overlapping a better-scored box by this much are the
         *  same hand: the detector fires several anchors per hand. */
        private const val NMS_IOU = 0.3f

        /** Candidates kept for suppression. A real frame has a handful
         *  above threshold; the cap bounds the work on a pathological one. */
        private const val MAX_CANDIDATES = 32

        /** A raised hand's wrist-to-middle-knuckle direction is within
         *  this many degrees of straight up. Generous enough for a hand
         *  held up naturally (few people hold a palm dead vertical),
         *  tight enough to leave out hands lying flat, reaching in, or
         *  swinging at the side of someone walking past (those read 67
         *  to 91 degrees and fired the gesture when the gate was widened
         *  to 100). A rising hand reads sideways for a look and upright
         *  the next; the hold absorbs that. */
        private const val UPRIGHT_MAX_DEG = 60f

        /** Smallest palm box counted, relative to the tensor's side. The
         *  model's own floor is about this size; anything smaller that
         *  clears the score is noise. */
        private const val MIN_WIDTH = 0.04f

        /** Mean brightness (0..1) a counted box must have: near black
         *  only, since a real palm in a dim room measures little more
         *  than 0.1. Sampled every other pixel of the box. */
        private const val MIN_LUMA = 0.05f
        private const val LUMA_STRIDE = 2

        /** Keypoint order in the 18 coords: box (cx, cy, w, h), then
         *  wrist, index, middle, ring and pinky knuckles, thumb base and
         *  thumb joint as (x, y). */
        private const val KP_WRIST = 4
        private const val KP_MIDDLE = 8

        /** Two threads, unlike the face detector's one: this model costs
         *  two and a half face runs (470 ms single-threaded on an Echo
         *  Show 8's four Cortex-A53 cores) and a gesture is judged by
         *  its latency, while the gate and the cost pacing keep the
         *  average load bounded whatever a single run costs. */
        const val THREADS = 1

        private const val TRACE_EVERY = 100
    }

    /** The hands in a frame: [raised] is the count that passes the
     *  upright, size and brightness gates, [seen] every palm the
     *  detector found (what keeps the inference gate open while a hand
     *  is turning into position). [width] (of the frame's width),
     *  [tilt] (degrees off vertical), [luma] and [score] describe the
     *  largest raised hand, or the brightest rejected candidate when
     *  none passed, for the log; [cx] and [cy] are that hand's center
     *  in frame coordinates, [x0]..[y1] its box, [wristX]/[wristY] and
     *  [midX]/[midY] its wrist and middle-knuckle keypoints (what the
     *  hand landmark stage builds its crop from); [crop] is the side of
     *  the square the look covered, as a fraction of the frame's
     *  height, 0 for the whole frame. */
    class Hands(
        val raised: Int,
        val seen: Int,
        val width: Float,
        val tilt: Float,
        val luma: Float,
        val score: Float,
        val cx: Float,
        val cy: Float,
        val x0: Float,
        val y0: Float,
        val x1: Float,
        val y1: Float,
        val wristX: Float,
        val wristY: Float,
        val midX: Float,
        val midY: Float,
        val crop: Float,
    )

    /** Where to look for a hand that is not yet tracked: the center
     *  (fractions of the frame's width and height) and size (fraction
     *  of the frame's height) of the motion grid's last large change. */
    class Hint(val u: Float, val v: Float, val size: Float)

    private var interpreter: Interpreter? = null
    private var regIndex = 0
    private var scoreIndex = 1
    private var failed = false

    // Reused across frames: the input (0..1, black bars when
    // letterboxed) and the two outputs.
    private val input = VisionInput(INPUT, 0f, 1f, bar = 0f)
    private val regressors: ByteBuffer =
        ByteBuffer.allocateDirect(ANCHORS * COORDS * 4).order(ByteOrder.nativeOrder())
    private val scores: ByteBuffer =
        ByteBuffer.allocateDirect(ANCHORS * 4).order(ByteOrder.nativeOrder())

    // Candidate boxes for suppression, reused: score, box edges, and
    // the gates' verdicts per slot.
    private val candScore = FloatArray(MAX_CANDIDATES)
    private val candX0 = FloatArray(MAX_CANDIDATES)
    private val candY0 = FloatArray(MAX_CANDIDATES)
    private val candX1 = FloatArray(MAX_CANDIDATES)
    private val candY1 = FloatArray(MAX_CANDIDATES)
    private val candTilt = FloatArray(MAX_CANDIDATES)
    private val candWristX = FloatArray(MAX_CANDIDATES)
    private val candWristY = FloatArray(MAX_CANDIDATES)
    private val candMidX = FloatArray(MAX_CANDIDATES)
    private val candMidY = FloatArray(MAX_CANDIDATES)

    /** Whether the upright gate applies: on for the raised-hand
     *  gesture, off when a landmark stage will judge the hand itself. */
    var upright = true

    /** The score a candidate needs, 0.5 by default (MediaPipe's own);
     *  lower when a landmark stage judges every candidate anyway, so
     *  that a hand the palm model is unsure of still gets its look. */
    var startScore = 0.5f
        set(value) {
            field = value
            startLogit = kotlin.math.ln(value / (1f - value))
        }
    private var startLogit = MIN_LOGIT
    private val candOrder = IntArray(MAX_CANDIDATES)
    private val candKept = BooleanArray(MAX_CANDIDATES)

    /** The upright frame's size, from the last look. */
    val frameW: Int get() = input.frameW
    val frameH: Int get() = input.frameH

    private var runs = 0
    private var avgMs = 0f

    /** The largest raised hand of the last call that found one, for the
     *  continuation bar (see [TRACK_LOGIT]); consulted only while the
     *  caller says a presence is alive. */
    private var trackX0 = 0f
    private var trackY0 = 0f
    private var trackX1 = 0f
    private var trackY1 = 0f
    private var tracked = false

    /** The square the current run looks at (see the class comment): its
     *  side as a fraction of the frame's height, 0 for the whole frame;
     *  and whether the last crop came up empty, which makes the next
     *  look the whole frame. */
    private var cropSide = 0f
    private var cropMissed = false

    /**
     * Count the raised hands in [image] (YUV_420_888), or null when
     * there is no hand at all. [rotation] is the frame's rotationDegrees
     * (see [VisionInput.fill]). [tracking] says the caller is timing a
     * presence, which lets a candidate where the last raised hand was
     * pass at the continuation bar and centers the look on it; [hint]
     * is where the motion grid last saw a large change, the look when
     * no hand is tracked. Null also when the model could not be loaded
     * (logged once) or a frame failed; nothing here may take the kiosk
     * down, since the analyzer thread's exceptions are process crashes.
     */
    fun detect(
        image: ImageProxy,
        rotation: Int,
        tracking: Boolean = false,
        hint: Hint? = null,
    ): Hands? {
        val engine = interpreter ?: load() ?: return null
        if (!tracking) tracked = false
        var cropU = 0.5f
        var cropV = 0.5f
        cropSide = 0f
        if (!cropMissed) {
            if (tracked) {
                val w = trackX1 - trackX0
                cropU = (trackX0 + trackX1) / 2f
                cropV = (trackY0 + trackY1) / 2f
                cropSide = (w / input.aspect * CROP_HAND_WIDTHS).coerceIn(CROP_MIN_SIDE, 1f)
            } else if (hint != null) {
                cropU = hint.u
                cropV = hint.v
                cropSide = (hint.size * CROP_ACTIVITY_MARGIN).coerceIn(CROP_MIN_SIDE, 1f)
            }
        }
        return try {
            val startNs = SystemClock.elapsedRealtimeNanos()
            input.fill(image, rotation, cropU, cropV, cropSide)
            regressors.rewind()
            scores.rewind()
            engine.runForMultipleInputsOutputs(
                arrayOf<Any>(input.buffer),
                mapOf<Int, Any>(regIndex to regressors, scoreIndex to scores),
            )
            val hands = decode()
            // A crop that found no raised hand: look at everything next
            // time, then crop again once a hand or a change is back.
            cropMissed = cropSide > 0f && (hands?.raised ?: 0) == 0
            trace((SystemClock.elapsedRealtimeNanos() - startNs) / 1_000_000f)
            hands
        } catch (e: Exception) {
            Log.w(TAG, "inference failed: $e")
            null
        }
    }

    private fun decode(): Hands? {
        // The interpreter leaves each output positioned at its end; a
        // float view starts at the position, so rewind first.
        regressors.rewind()
        scores.rewind()
        val reg = regressors.asFloatBuffer()
        val cls = scores.asFloatBuffer()
        var n = 0
        var topRaw = -100f
        for (i in 0 until ANCHORS) {
            val raw = cls.get(i)
            if (raw > topRaw) topRaw = raw
            if (raw < startLogit && !(tracked && raw >= TRACK_LOGIT)) continue
            val score = 1f / (1f + exp(-raw.coerceIn(-100f, 100f)))
            val ax: Float
            val ay: Float
            if (i < ANCHORS_A) {
                val cell = i / PER_CELL_A
                ax = ((cell % GRID_A) + 0.5f) / GRID_A
                ay = ((cell / GRID_A) + 0.5f) / GRID_A
            } else {
                val cell = (i - ANCHORS_A) / PER_CELL_B
                ax = ((cell % GRID_B) + 0.5f) / GRID_B
                ay = ((cell / GRID_B) + 0.5f) / GRID_B
            }
            val base = i * COORDS
            // Tensor coordinates, then the upright frame's.
            val cx = input.originU + (reg.get(base) / INPUT + ax) * input.spanU
            val cy = input.originV + (reg.get(base + 1) / INPUT + ay) * input.spanV
            val w = reg.get(base + 2) / INPUT * input.spanU
            val h = reg.get(base + 3) / INPUT * input.spanV
            val x0 = cx - w / 2f
            val y0 = cy - h / 2f
            val x1 = cx + w / 2f
            val y1 = cy + h / 2f
            // Under the full bar, only the tracked hand's box qualifies.
            if (raw < startLogit && !nearTracked(cx, cy)) continue
            // The slot: a free one, else the weakest candidate if this
            // one beats it.
            var slot = n
            if (n == MAX_CANDIDATES) {
                slot = 0
                for (j in 1 until n) if (candScore[j] < candScore[slot]) slot = j
                if (candScore[slot] >= score) continue
            } else {
                n++
            }
            candX0[slot] = x0
            candY0[slot] = y0
            candX1[slot] = x1
            candY1[slot] = y1
            candScore[slot] = score
            candWristX[slot] = input.originU + (reg.get(base + KP_WRIST) / INPUT + ax) * input.spanU
            candWristY[slot] = input.originV + (reg.get(base + KP_WRIST + 1) / INPUT + ay) * input.spanV
            candMidX[slot] = input.originU + (reg.get(base + KP_MIDDLE) / INPUT + ax) * input.spanU
            candMidY[slot] = input.originV + (reg.get(base + KP_MIDDLE + 1) / INPUT + ay) * input.spanV
            // Tilt off vertical of the wrist-to-middle-knuckle direction,
            // in degrees: 0 points straight up the upright frame, 180
            // straight down.
            val dx = reg.get(base + KP_MIDDLE) - reg.get(base + KP_WRIST)
            val dy = reg.get(base + KP_MIDDLE + 1) - reg.get(base + KP_WRIST + 1)
            candTilt[slot] = Math.toDegrees(atan2(abs(dx), -dy).toDouble()).toFloat()
        }
        if (n == 0) {
            if (topRaw > -1.4f) {
                val topScore = 1f / (1f + exp(-topRaw.coerceIn(-100f, 100f)))
                Log.d(TAG, "no hand: top score ${"%.2f".format(topScore)}")
            }
            return null
        }
        // Greedy suppression in score order. The tilt gate comes after,
        // so a hand's own duplicates never survive as a second hand.
        for (i in 0 until n) candOrder[i] = i
        for (i in 1 until n) {
            val v = candOrder[i]
            var j = i - 1
            while (j >= 0 && candScore[candOrder[j]] < candScore[v]) {
                candOrder[j + 1] = candOrder[j]
                j--
            }
            candOrder[j + 1] = v
        }
        var seen = 0
        var raised = 0
        var bestWidth = 0f
        var bestTilt = 0f
        var bestLuma = 0f
        var bestScore = 0f
        var bestX0 = 0f
        var bestY0 = 0f
        var bestX1 = 0f
        var bestY1 = 0f
        var best = -1
        // The rejected candidate with the most light on it, for the log:
        // the way to tell "nothing there" from "a hand the gates refused"
        // when tuning on a device.
        var rejectedLuma = -1f
        var rejectedWidth = 0f
        var rejectedTilt = 0f
        var rejectedScore = 0f
        for (oi in 0 until n) {
            val i = candOrder[oi]
            var duplicate = false
            for (oj in 0 until oi) {
                val j = candOrder[oj]
                if (candKept[j] && iou(i, j) >= NMS_IOU) {
                    duplicate = true
                    break
                }
            }
            candKept[i] = !duplicate
            if (duplicate) continue
            seen++
            val width = candX1[i] - candX0[i]
            val luma = luma(i)
            if (width < MIN_WIDTH || (upright && candTilt[i] > UPRIGHT_MAX_DEG) || luma < MIN_LUMA) {
                if (luma > rejectedLuma) {
                    rejectedLuma = luma
                    rejectedWidth = width
                    rejectedTilt = candTilt[i]
                    rejectedScore = candScore[i]
                }
                continue
            }
            raised++
            if (width > bestWidth) {
                bestWidth = width
                bestTilt = candTilt[i]
                bestLuma = luma
                bestScore = candScore[i]
                bestX0 = candX0[i]
                bestY0 = candY0[i]
                bestX1 = candX1[i]
                bestY1 = candY1[i]
                best = i
            }
        }
        return if (raised > 0) {
            tracked = true
            trackX0 = bestX0
            trackY0 = bestY0
            trackX1 = bestX1
            trackY1 = bestY1
            Hands(
                raised, seen, bestWidth, bestTilt, bestLuma, bestScore,
                (bestX0 + bestX1) / 2f, (bestY0 + bestY1) / 2f,
                bestX0, bestY0, bestX1, bestY1,
                candWristX[best], candWristY[best], candMidX[best], candMidY[best],
                cropSide,
            )
        } else {
            Hands(
                0, seen, rejectedWidth, rejectedTilt, rejectedLuma, rejectedScore,
                0f, 0f, 0f, 0f, 0f, 0f, 0f, 0f, 0f, 0f, cropSide,
            )
        }
    }

    /** Mean brightness of candidate [i]'s box in the input tensor (RGB
     *  averaged, 0..1), sampled on a stride. The box is in frame
     *  coordinates; the tensor holds the look's square. */
    private fun luma(i: Int): Float {
        val x0 = ((candX0[i] - input.originU) / input.spanU * INPUT).toInt().coerceIn(0, INPUT - 1)
        val y0 = ((candY0[i] - input.originV) / input.spanV * INPUT).toInt().coerceIn(0, INPUT - 1)
        val x1 = ((candX1[i] - input.originU) / input.spanU * INPUT).toInt().coerceIn(x0 + 1, INPUT)
        val y1 = ((candY1[i] - input.originV) / input.spanV * INPUT).toInt().coerceIn(y0 + 1, INPUT)
        val px = input.buffer.asFloatBuffer()
        var sum = 0f
        var count = 0
        var y = y0
        while (y < y1) {
            var x = x0
            while (x < x1) {
                val o = (y * INPUT + x) * 3
                sum += px.get(o) + px.get(o + 1) + px.get(o + 2)
                count++
                x += LUMA_STRIDE
            }
            y += LUMA_STRIDE
        }
        return if (count == 0) 0f else sum / (3f * count)
    }

    /** Whether a candidate centered at ([cx], [cy]) is where the tracked
     *  hand was, within [TRACK_REACH] of its width: a hand held up drifts
     *  and tilts between looks, and a box of a fifth of the frame moved
     *  by half its width already fails an overlap test. Frame
     *  coordinates, the vertical one scaled to the horizontal. */
    private fun nearTracked(cx: Float, cy: Float): Boolean {
        if (!tracked) return false
        val w = trackX1 - trackX0
        val dx = cx - (trackX0 + trackX1) / 2f
        val dy = (cy - (trackY0 + trackY1) / 2f) * input.aspect
        return dx * dx + dy * dy <= (TRACK_REACH * w) * (TRACK_REACH * w)
    }

    private fun iou(a: Int, b: Int): Float {
        val iw = max(0f, min(candX1[a], candX1[b]) - max(candX0[a], candX0[b]))
        val ih = max(0f, min(candY1[a], candY1[b]) - max(candY0[a], candY0[b]))
        val inter = iw * ih
        val union = (candX1[a] - candX0[a]) * (candY1[a] - candY0[a]) +
            (candX1[b] - candX0[b]) * (candY1[b] - candY0[b]) - inter
        return if (union <= 0f) 0f else inter / union
    }

    /** Running average cost of one [detect] call in milliseconds, 0
     *  until measured; the first run (delegate warm-up) is logged but
     *  kept out of it. The caller paces itself by it. */
    val costMs: Float get() = avgMs

    private fun trace(ms: Float) {
        runs++
        if (runs == 1) {
            Log.i(TAG, "palm inference ${"%.1f".format(ms)} ms (first run)")
            return
        }
        avgMs += (ms - avgMs) / minOf(runs - 1, 20).toFloat()
        if (runs == 10) {
            Log.i(TAG, "palm inference avg ${"%.1f".format(avgMs)} ms (steady state)")
        } else if (runs % TRACE_EVERY == 0) {
            Log.d(TAG, "palm inference avg ${"%.1f".format(avgMs)} ms over $runs runs")
        }
    }

    private fun load(): Interpreter? {
        if (failed) return null
        return try {
            val engine = Interpreter(mapModel(), Interpreter.Options().setNumThreads(THREADS))
            // The two outputs are told apart by shape, not by the order
            // the converter happened to emit them in.
            for (i in 0 until engine.outputTensorCount) {
                val last = engine.getOutputTensor(i).shape().last()
                if (last == COORDS) regIndex = i
                if (last == 1) scoreIndex = i
            }
            interpreter = engine
            Log.i(TAG, "palm model loaded")
            engine
        } catch (e: Exception) {
            failed = true
            Log.w(TAG, "palm model unavailable: ${e.message}")
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
