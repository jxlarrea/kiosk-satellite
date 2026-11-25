package me.jxl.kiosk_satellite

import android.graphics.ImageFormat
import android.graphics.Rect
import android.graphics.YuvImage
import androidx.camera.core.ImageProxy
import me.jxl.kiosk_satellite.plugins.PluginCameraFrames
import java.io.ByteArrayOutputStream
import kotlin.math.max

/**
 * Vision Match: the face and hand looks of [CameraMotion] done by
 * Kiosk Satellite Ground Control instead of the models on this device.
 *
 * The analyzer decides when a look is due exactly as it does for its own
 * models (the motion gate, the activity window, the hand pacing). Here the
 * due frame becomes a JPEG that the Dart side sends to Ground Control's
 * vision socket, and the answer comes back through [CameraMotion]'s control
 * channel. One look is in flight at a time: a frame due while one waits is
 * skipped, so a slow or busy Ground Control slows the looks down instead of
 * queueing them. A look that gets no answer within [ANSWER_TIMEOUT_NS] is
 * given up on, which also covers a Ground Control that is gone.
 *
 * Ground Control tells the kiosk how many looks a second it keeps up with
 * ([setMaxLooks]). Looks are never more frequent than that, on top of the
 * analyzer's own pacing.
 *
 * With Face Recognition, a face that comes into view and is not named yet
 * gets its looks [UNNAMED_INTERVAL_NS] apart for [UNNAMED_SPRINT_NS] (see
 * [hurried]): a name takes two looks at the face more often than not, and
 * at the usual pace that is over a second before the kiosk can act on it.
 */
class GroundControlVision {
    companion object {
        private const val JPEG_QUALITY = 80
        const val ANSWER_TIMEOUT_NS = 2_000_000_000L

        // The face looks while someone in view has no name yet: five a
        // second for two seconds, measured from the first look that found
        // the face. Whoever is still not named after that is a guest and
        // gets the usual pace. A face gone this long starts over.
        const val UNNAMED_INTERVAL_NS = 200_000_000L
        const val UNNAMED_SPRINT_NS = 2_000_000_000L
        const val UNNAMED_GONE_NS = 1_000_000_000L

        /**
         * Whether Ground Control's answer to a face look names nobody while
         * Face Recognition is on. An answer says who is in view ("person"
         * and "people") only with Face Recognition, so one without them is
         * never waiting for a name.
         */
        fun nobodyNamed(answer: Map<*, *>): Boolean {
            if (!answer.containsKey("person")) return false
            if ((answer["person"] as? Map<*, *>)?.get("id") != null) return false
            val people = answer["people"] as? List<*> ?: return true
            return people.none { (it as? Map<*, *>)?.get("id") != null }
        }

        /**
         * The width of the largest face looking at the kiosk, as a fraction
         * of the frame's longer side (the face sensitivity's measure), from
         * Ground Control's faces: boxes as fractions of the upright frame,
         * largest first. Null when no face looks at the kiosk.
         */
        fun frontalWidth(faces: List<*>, uprightWidth: Int, uprightHeight: Int): Float? {
            val longer = max(uprightWidth, uprightHeight).toFloat()
            if (longer <= 0f) return null
            var best: Float? = null
            for (face in faces) {
                val f = face as? Map<*, *> ?: continue
                if (f["frontal"] != true) continue
                val w = ((f["box"] as? List<*>)?.getOrNull(2) as? Number)?.toFloat() ?: continue
                val width = w * uprightWidth / longer
                if (best == null || width > best) best = width
            }
            return best
        }

        /**
         * Ground Control's hand as the hand leg's report: how many hands (0
         * or 1, the shown one) and its reading when the gesture holds up a
         * number of fingers. A hand whose gesture has no count is a hand
         * with no reading, like a hand the landmark stage could not judge.
         */
        fun handReport(hand: Map<*, *>?): Pair<Int, HandRead?> {
            if (hand == null) return 0 to null
            val fingers = (hand["fingers"] as? Number)?.toInt() ?: return 1 to null
            val gesture = hand["gesture"] as? String ?: "?"
            return 1 to HandRead(fingers, emptyList(), 0f, "ground control: $gesture")
        }
    }

    /** One look sent and not answered yet. */
    class Look(
        val id: Int,
        val sentAtNs: Long,
        val face: Boolean,
        val hands: Boolean,
        val uprightWidth: Int,
        val uprightHeight: Int,
    )

    @Volatile var faceIntervalNs = 0L
        private set
    @Volatile var handIntervalNs = 0L
        private set

    private var nextId = 0
    private var inFlight: Look? = null
    private var timedOut = 0
    private var unnamedSinceNs = 0L
    private var lastFaceNs = 0L

    /**
     * Analyzer thread: a face look was answered. [faces] is whether it
     * found any face, also one cut off by the frame or turned away, and
     * [unnamed] whether Face Recognition has named nobody (see
     * [nobodyNamed]).
     */
    fun faceLook(faces: Boolean, unnamed: Boolean, now: Long) {
        if (!faces) return
        if (!unnamed) {
            unnamedSinceNs = 0L
        } else if (unnamedSinceNs == 0L || now - lastFaceNs > UNNAMED_GONE_NS) {
            unnamedSinceNs = now
        }
        lastFaceNs = now
    }

    /**
     * Analyzer thread. True while a face in view waits for its name and
     * the faster looks still apply.
     */
    fun hurried(now: Long): Boolean =
        unnamedSinceNs != 0L && now - unnamedSinceNs <= UNNAMED_SPRINT_NS &&
            now - lastFaceNs <= UNNAMED_GONE_NS

    /** Analyzer thread. True while a look waits for its answer. */
    fun busy(now: Long): Boolean {
        val look = inFlight ?: return false
        if (now - look.sentAtNs < ANSWER_TIMEOUT_NS) return true
        inFlight = null
        timedOut++
        return false
    }

    /** Looks that got no answer in time since the session started, for the log. */
    val unanswered: Int get() = timedOut

    fun setMaxLooks(face: Double?, hands: Double?) {
        faceIntervalNs = if (face != null && face > 0) (1e9 / face).toLong() else 0L
        handIntervalNs = if (hands != null && hands > 0) (1e9 / hands).toLong() else 0L
    }

    /**
     * Analyzer thread: encode [image] for a look and say which. Returns the
     * event for the Dart side, or null when the frame can't be encoded.
     */
    fun prepare(image: ImageProxy, face: Boolean, hands: Boolean, now: Long): Map<String, Any>? {
        val started = System.nanoTime()
        val bytes = try {
            val nv21 = PluginCameraFrames.copy(image, true)
            val out = ByteArrayOutputStream(48 * 1024)
            YuvImage(nv21, ImageFormat.NV21, image.width, image.height, null)
                .compressToJpeg(Rect(0, 0, image.width, image.height), JPEG_QUALITY, out)
            out.toByteArray()
        } catch (e: Exception) {
            android.util.Log.w("GroundControlVision", "frame not encoded: $e")
            return null
        }
        val rotation = image.imageInfo.rotationDegrees
        val turned = rotation == 90 || rotation == 270
        val look = Look(
            id = ++nextId,
            sentAtNs = now,
            face = face,
            hands = hands,
            uprightWidth = if (turned) image.height else image.width,
            uprightHeight = if (turned) image.width else image.height,
        )
        inFlight = look
        val want = buildList {
            if (face) add("face")
            if (hands) add("hands")
        }
        // How long the frame took to encode, for the vision session on Ground Control.
        val encodeMs = Math.round((System.nanoTime() - started) / 1e5) / 10.0
        return mapOf("vision" to bytes, "id" to look.id, "rotation" to rotation, "want" to want, "encode_ms" to encodeMs)
    }

    /** Analyzer thread: the look [id] was answered or failed. The look, or null when it is not the one waiting. */
    fun answered(id: Int): Look? {
        val look = inFlight ?: return null
        if (look.id != id) return null
        inFlight = null
        return look
    }

    /** Analyzer thread: forget any look in flight, for a new session or a reset gate. */
    fun reset() {
        inFlight = null
        timedOut = 0
        unnamedSinceNs = 0L
        lastFaceNs = 0L
    }
}
