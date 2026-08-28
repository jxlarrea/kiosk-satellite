package me.jxl.kiosk_satellite

import kotlin.math.abs

/**
 * The light sensor's damping, pure so it can be tested: which readings
 * cross the platform channel and when.
 *
 * A reading is sent when it moved at least [MIN_DELTA_LX] and
 * [MIN_DELTA_SHARE] of the last one sent, and at most every
 * [MIN_INTERVAL_MS]; the first reading always passes.
 *
 * The rate limit keeps the trailing edge. The sensor is on-change and says
 * nothing while the value holds, so a reading that arrives inside the
 * window after a send and is simply dropped is a reading nobody ever
 * hears: lights going out ramp 43, 29, 17, 8, 2 within a second, the 29
 * goes out, the 2 does not, and the room reads 29 lx all night. A reading
 * the window holds back is parked and sent when the window closes, unless
 * a later one came back inside the deadband of what was sent.
 *
 * Single-threaded by contract: the sensor listener, the scheduled flush
 * and [reset] all run on one looper.
 */
class LuxDamper(
    private val now: () -> Long,
    /** Arrange for [flush] to run after this many milliseconds. */
    private val schedule: (delayMs: Long) -> Unit,
    /** Cancel a scheduled [flush], if any. */
    private val cancel: () -> Unit,
    private val send: (Float) -> Unit,
) {
    private var lastSent = -1f
    private var lastSentAt = 0L

    /** A reading held back by the rate limit; -1 when none. */
    private var pending = -1f

    /** A fresh reading from the sensor. */
    fun offer(lux: Float) {
        if (!passesDeadband(lux)) {
            // Back within the deadband of what was sent: whatever was
            // parked is no longer the latest word.
            if (pending >= 0) cancel()
            pending = -1f
            return
        }
        val wait = MIN_INTERVAL_MS - (now() - lastSentAt)
        if (lastSent >= 0 && wait > 0) {
            if (pending < 0) schedule(wait)
            pending = lux
            return
        }
        if (pending >= 0) cancel()
        pending = -1f
        emit(lux)
    }

    /** The window closed: send what was parked, if it still stands. */
    fun flush() {
        val lux = pending
        pending = -1f
        if (lux < 0 || !passesDeadband(lux)) return
        emit(lux)
    }

    /** A new sensor, or the stream closed: the next reading is a first. */
    fun reset() {
        if (pending >= 0) cancel()
        pending = -1f
        lastSent = -1f
        lastSentAt = 0L
    }

    private fun emit(lux: Float) {
        lastSent = lux
        lastSentAt = now()
        send(lux)
    }

    private fun passesDeadband(lux: Float): Boolean {
        if (lastSent < 0) return true
        val delta = abs(lux - lastSent)
        return delta >= MIN_DELTA_LX && delta >= lastSent * MIN_DELTA_SHARE
    }

    companion object {
        const val MIN_INTERVAL_MS = 2000L
        const val MIN_DELTA_LX = 1f
        const val MIN_DELTA_SHARE = 0.1f
    }
}
