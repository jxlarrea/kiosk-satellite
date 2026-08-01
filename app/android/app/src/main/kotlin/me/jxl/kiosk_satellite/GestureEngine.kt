package me.jxl.kiosk_satellite

import android.app.Activity
import android.os.Handler
import android.os.Looper
import android.view.MotionEvent
import android.view.ViewConfiguration
import kotlin.math.abs
import kotlin.math.min

/**
 * Configurable hidden gestures (issue #99).
 *
 * Fed every pointer event from MainActivity.dispatchTouchEvent (via
 * KioskLock.onTouch), the same observe-only tap that powers the exit
 * gesture: nothing here ever consumes a touch, so the dashboard behaves
 * exactly as it would without a gesture armed. Detection therefore favors
 * shapes a WebView tap or scroll cannot produce by accident - taps confined
 * to a corner box, multi-finger taps, and holds much longer than a card's
 * hold action.
 *
 * Supported trigger shapes, pushed from Dart as a list of maps:
 *
 *  - cornerTaps:  {id, type:"corner_taps", corner:"tl|tr|bl|br", taps:2..4}
 *  - cornerHold:  {id, type:"corner_hold", corner, holdMs}
 *  - fingerTaps:  {id, type:"finger_taps", fingers:2|3, taps:1|2}
 *  - fingerHold:  {id, type:"finger_hold", fingers:2|3, holdMs}
 *  - sequence:    {id, type:"corner_sequence", sequence:["tl","tr",...]}
 *
 * Disambiguation: when two mappings differ only by count (2 vs 3 corner
 * taps), the shorter one waits [chainMs] after its last tap to be sure the
 * chain is over; when nothing longer is configured it fires immediately.
 * Holds fire at their deadline while the finger is still down.
 */
class GestureEngine(
    private val activity: Activity,
    private val onGesture: (String) -> Unit,
) {
    private class Spec(
        val id: String,
        val type: String,
        val corner: String?,
        val taps: Int,
        val fingers: Int,
        val holdMs: Long,
        val sequence: List<String>,
    )

    companion object {
        /** Down-to-up above this is a hold or a drag, not a tap. */
        private const val TAP_MAX_MS = 350L

        /** Up-to-next-down window chaining taps, and the wait a shorter
         *  mapping observes before firing when a longer one exists. */
        private const val CHAIN_MS = 450L

        /** Corner sequences tolerate a slower rhythm than tap chains. */
        private const val SEQ_GAP_MS = 1500L

        /** Longest sequence a mapping may declare. */
        private const val SEQ_MAX = 8

        /** Corner box edge in dp, capped below at 30% of the short side. */
        private const val CORNER_DP = 120
    }

    private val main = Handler(Looper.getMainLooper())
    private val slop = ViewConfiguration.get(activity).scaledTouchSlop * 2

    @Volatile private var specs: List<Spec> = emptyList()

    // ── one in-flight touch gesture ────────────────────────────────────
    private var downAt = 0L
    private var maxPointers = 0
    private var moved = false
    private var downX = 0f
    private var downY = 0f
    private var startX = FloatArray(0)
    private var startY = FloatArray(0)
    private var startId = IntArray(0)
    private var holdFired = false
    private val holdRunnables = mutableListOf<Runnable>()

    // ── tap chains ─────────────────────────────────────────────────────
    private var chainCorner: String? = null
    private var chainFingers = 0
    private var chainCount = 0
    private var chainLastUp = 0L
    private var pendingResolve: Runnable? = null

    // ── corner sequence buffer ─────────────────────────────────────────
    private val seqBuffer = ArrayDeque<String>()
    private var seqLastUp = 0L

    /** Replace the armed mappings; an empty list disarms everything. */
    fun configure(raw: List<Map<String, Any?>>?) {
        val parsed = mutableListOf<Spec>()
        for (m in raw ?: emptyList()) {
            val id = m["id"] as? String ?: continue
            val type = m["type"] as? String ?: continue
            val sequence = (m["sequence"] as? List<*>)
                ?.filterIsInstance<String>()?.take(SEQ_MAX) ?: emptyList()
            parsed.add(
                Spec(
                    id = id,
                    type = type,
                    corner = m["corner"] as? String,
                    taps = (m["taps"] as? Number)?.toInt() ?: 1,
                    fingers = (m["fingers"] as? Number)?.toInt() ?: 1,
                    holdMs = (m["holdMs"] as? Number)?.toLong() ?: 1500L,
                    sequence = sequence,
                )
            )
        }
        specs = parsed
        main.post { reset() }
    }

    /** Observe (never consume) a pointer event. Main thread. */
    fun onTouch(event: MotionEvent) {
        if (specs.isEmpty()) return
        when (event.actionMasked) {
            MotionEvent.ACTION_DOWN -> {
                downAt = event.eventTime
                maxPointers = 1
                moved = false
                holdFired = false
                downX = event.x
                downY = event.y
                snapshotPointers(event)
                scheduleHolds()
            }
            MotionEvent.ACTION_POINTER_DOWN -> {
                maxPointers = maxOf(maxPointers, event.pointerCount)
                snapshotPointers(event)
                // The finger count changed: single-finger holds are off the
                // table, multi-finger holds restart from this moment.
                scheduleHolds()
            }
            MotionEvent.ACTION_MOVE -> {
                if (!moved && driftedPast(event)) {
                    moved = true
                    cancelHolds()
                }
            }
            MotionEvent.ACTION_POINTER_UP -> cancelHolds()
            MotionEvent.ACTION_UP -> {
                cancelHolds()
                if (!holdFired) classifyTap(event)
            }
            MotionEvent.ACTION_CANCEL -> {
                cancelHolds()
                maxPointers = 0
            }
        }
    }

    /** Forget everything in flight (config change, Activity teardown). */
    fun reset() {
        cancelHolds()
        pendingResolve?.let { main.removeCallbacks(it) }
        pendingResolve = null
        chainCorner = null
        chainFingers = 0
        chainCount = 0
        seqBuffer.clear()
        maxPointers = 0
    }

    // ── taps ───────────────────────────────────────────────────────────

    private fun classifyTap(event: MotionEvent) {
        val duration = event.eventTime - downAt
        if (duration > TAP_MAX_MS || moved) return
        val now = event.eventTime
        if (maxPointers == 1) {
            val corner = cornerAt(downX, downY) ?: run {
                // A stray tap outside every corner breaks chains and
                // sequences alike - that is what makes them deliberate.
                breakChain()
                seqBuffer.clear()
                return
            }
            extendChain(corner, 0, now)
            extendSequence(corner, now)
        } else {
            extendChain(null, maxPointers, now)
        }
    }

    /** One more tap on the given corner (or with the given finger count). */
    private fun extendChain(corner: String?, fingers: Int, now: Long) {
        pendingResolve?.let { main.removeCallbacks(it) }
        pendingResolve = null
        val continues = chainCount > 0 &&
            chainCorner == corner && chainFingers == fingers &&
            now - chainLastUp <= CHAIN_MS + TAP_MAX_MS
        chainCorner = corner
        chainFingers = fingers
        chainCount = if (continues) chainCount + 1 else 1
        chainLastUp = now

        val count = chainCount
        val match = tapSpecFor(corner, fingers, count)
        val longerExists = specs.any {
            tapSpecShape(it, corner, fingers) && it.taps > count
        }
        if (match != null && !longerExists) {
            breakChain()
            fire(match)
        } else if (match != null) {
            // A longer mapping could still be in progress; fire only once
            // the chain has demonstrably ended.
            val resolve = Runnable {
                pendingResolve = null
                breakChain()
                fire(match)
            }
            pendingResolve = resolve
            main.postDelayed(resolve, CHAIN_MS)
        } else if (!longerExists) {
            // Nothing this chain could still become; let the next tap
            // start fresh instead of counting past every mapping.
            breakChain()
        }
    }

    private fun breakChain() {
        chainCount = 0
        chainCorner = null
        chainFingers = 0
    }

    private fun tapSpecFor(corner: String?, fingers: Int, taps: Int): Spec? =
        specs.firstOrNull {
            tapSpecShape(it, corner, fingers) && it.taps == taps
        }

    private fun tapSpecShape(s: Spec, corner: String?, fingers: Int): Boolean =
        if (fingers == 0) s.type == "corner_taps" && s.corner == corner
        else s.type == "finger_taps" && s.fingers == fingers

    // ── corner sequences ───────────────────────────────────────────────

    private fun extendSequence(corner: String, now: Long) {
        if (specs.none { it.type == "corner_sequence" }) return
        if (now - seqLastUp > SEQ_GAP_MS) seqBuffer.clear()
        seqLastUp = now
        seqBuffer.addLast(corner)
        while (seqBuffer.size > SEQ_MAX) seqBuffer.removeFirst()
        val hit = specs.firstOrNull {
            it.type == "corner_sequence" &&
                it.sequence.size in 2..seqBuffer.size &&
                seqBuffer.toList().takeLast(it.sequence.size) == it.sequence
        } ?: return
        seqBuffer.clear()
        breakChain()
        fire(hit)
    }

    // ── holds ──────────────────────────────────────────────────────────

    /** (Re)arm hold deadlines for the current finger count. */
    private fun scheduleHolds() {
        cancelHolds()
        if (moved) return
        val fingers = maxPointers
        val corner = if (fingers == 1) cornerAt(downX, downY) else null
        for (spec in specs) {
            val wants = when (spec.type) {
                "corner_hold" -> fingers == 1 && spec.corner == corner
                "finger_hold" -> fingers > 1 && spec.fingers == fingers
                else -> false
            }
            if (!wants) continue
            val r = Runnable {
                holdFired = true
                breakChain()
                seqBuffer.clear()
                fire(spec)
            }
            holdRunnables.add(r)
            main.postDelayed(r, spec.holdMs)
        }
    }

    private fun cancelHolds() {
        for (r in holdRunnables) main.removeCallbacks(r)
        holdRunnables.clear()
    }

    // ── geometry ───────────────────────────────────────────────────────

    private fun snapshotPointers(event: MotionEvent) {
        val n = event.pointerCount
        startX = FloatArray(n)
        startY = FloatArray(n)
        startId = IntArray(n)
        for (i in 0 until n) {
            startX[i] = event.getX(i)
            startY[i] = event.getY(i)
            startId[i] = event.getPointerId(i)
        }
    }

    private fun driftedPast(event: MotionEvent): Boolean {
        for (i in 0 until startId.size) {
            val idx = event.findPointerIndex(startId[i])
            if (idx < 0) continue
            if (abs(event.getX(idx) - startX[i]) > slop ||
                abs(event.getY(idx) - startY[i]) > slop
            ) return true
        }
        return false
    }

    /** Which corner box the point falls in, or null. Reads the decor view
     *  each time so rotation needs no bookkeeping. */
    private fun cornerAt(x: Float, y: Float): String? {
        val decor = activity.window?.decorView ?: return null
        val w = decor.width.toFloat()
        val h = decor.height.toFloat()
        if (w <= 0 || h <= 0) return null
        val density = activity.resources.displayMetrics.density
        val box = min(CORNER_DP * density, min(w, h) * 0.3f)
        val left = x <= box
        val right = x >= w - box
        val top = y <= box
        val bottom = y >= h - box
        return when {
            top && left -> "tl"
            top && right -> "tr"
            bottom && left -> "bl"
            bottom && right -> "br"
            else -> null
        }
    }

    private fun fire(spec: Spec) {
        onGesture(spec.id)
    }
}
