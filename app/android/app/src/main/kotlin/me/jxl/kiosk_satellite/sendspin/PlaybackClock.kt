package me.jxl.kiosk_satellite.sendspin

import kotlin.math.exp

/** Smooths the Android playback head without inventing progress during startup. */
internal class PlaybackClock {
    private var rawHead = 0L
    private var headWraps = 0L
    private var lastHead = 0L
    private var headChangedNs = 0L
    private var lastSampleNs = 0L
    private var smoothFrames = 0.0
    private var advancing = false

    fun reset() {
        rawHead = 0
        headWraps = 0
        lastHead = 0
        headChangedNs = 0
        lastSampleNs = 0
        smoothFrames = 0.0
        advancing = false
    }

    fun position(
        head32: Long,
        nowNs: Long,
        written: Long,
        sampleRate: Int,
        maxTrailFrames: Long,
    ): Long {
        val raw = head32 and 0xFFFF_FFFFL
        if (raw < rawHead && rawHead - raw > 0x8000_0000L) {
            headWraps++
            rawHead = raw
        } else if (raw >= rawHead) {
            rawHead = raw
        }
        // A small backward step is a bad position report, not a 32-bit wrap.
        val head = rawHead + (headWraps shl 32)
        if (!advancing) {
            lastSampleNs = nowNs
            lastHead = head
            headChangedNs = nowNs
            smoothFrames = head.toDouble().coerceAtMost(written.toDouble())
            advancing = head > 0
            return smoothFrames.toLong()
        }

        val elapsed = (nowNs - lastSampleNs).coerceAtLeast(0)
        lastSampleNs = nowNs
        if (head != lastHead) {
            lastHead = head
            headChangedNs = nowNs
        }
        // Interpolate mixer strides but stop extrapolating a stalled output.
        if (nowNs - headChangedNs < 300_000_000L) {
            smoothFrames += elapsed * sampleRate / 1_000_000_000.0
        }
        // A half-second time constant stays the same when polls are delayed
        // or the status endpoint reads the clock between feedback polls.
        val weight = 1.0 - exp(-elapsed / 500_000_000.0)
        smoothFrames += (head - smoothFrames) * weight
        smoothFrames = smoothFrames
            .coerceIn(head - maxTrailFrames.toDouble(), head + sampleRate / 10.0)
            .coerceIn(0.0, written.toDouble())
        return smoothFrames.toLong()
    }
}
