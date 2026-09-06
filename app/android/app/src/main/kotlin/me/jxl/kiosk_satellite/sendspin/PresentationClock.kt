package me.jxl.kiosk_satellite.sendspin

import kotlin.math.abs

/** Checks presentation timestamp consistency and retains a calibrated head fallback. */
internal class PresentationClock {
    companion object {
        private const val STARTUP_WAIT_NS = 300_000_000L
        private const val TIMESTAMP_STARTUP_NS = 2_000_000_000L
        private const val STALE_NS = 500_000_000L
        private const val MAX_RATE_ERROR_NS = 5_000_000L
    }

    var source = "warming_up"
        private set
    var fallbackReason: String? = null
        private set
    var latencyUs = 0L
        private set
    var canPollTimestamp = true
        private set

    private var startedNs = 0L
    private var referenceNs = 0L
    private var referenceFrames = 0L
    private var lastAdvanceNs = 0L
    private var goodSamples = 0
    private var calibrated = false

    fun reset(nowNs: Long, estimatedLatencyUs: Long) {
        source = "warming_up"
        fallbackReason = null
        latencyUs = estimatedLatencyUs
        startedNs = nowNs
        referenceNs = 0
        referenceFrames = 0
        lastAdvanceNs = nowNs
        goodSamples = 0
        calibrated = false
        canPollTimestamp = true
    }

    fun position(
        nowNs: Long,
        headFrames: Long,
        written: Long,
        sampleRate: Int,
        timestampFrames: Long?,
        timestampNs: Long?,
    ): Long {
        if (canPollTimestamp && timestampFrames != null && timestampNs != null) {
            val valid = timestampNs > 0 && timestampNs >= startedNs &&
                timestampNs <= nowNs && nowNs - timestampNs <= STALE_NS &&
                timestampFrames in 0..written
            if (valid && timestampNs != referenceNs) {
                val deltaNs = timestampNs - referenceNs
                val deltaFrames = timestampFrames - referenceFrames
                val rateError = if (referenceNs == 0L) 0L else
                    abs(deltaFrames * 1_000_000_000L / sampleRate - deltaNs)
                if (referenceNs == 0L ||
                    (deltaNs > 0 && deltaFrames > 0 && rateError <= MAX_RATE_ERROR_NS)
                ) {
                    referenceNs = timestampNs
                    referenceFrames = timestampFrames
                    lastAdvanceNs = nowNs
                    goodSamples++
                    if (goodSamples >= 3) {
                        source = "timestamp"
                        fallbackReason = null
                    }
                    if (source == "timestamp") {
                        val presented = referenceFrames + (nowNs - referenceNs) * sampleRate / 1_000_000_000L
                        // Keep the same presentation reference if timestamps later freeze.
                        // The head clock has already removed mixer-period jitter.
                        val measuredUs = ((headFrames - presented) * 1_000_000 / sampleRate)
                            .coerceIn(0, 1_000_000)
                        latencyUs = if (calibrated) (latencyUs * 7 + measuredUs) / 8 else measuredUs
                        calibrated = true
                    }
                } else if (source == "timestamp") {
                    fallBack("inconsistent_timestamp")
                } else {
                    referenceNs = timestampNs
                    referenceFrames = timestampFrames
                    goodSamples = 1
                }
            }
        }
        if (source == "timestamp" &&
            (nowNs - lastAdvanceNs > STALE_NS || nowNs - referenceNs > STALE_NS)
        ) {
            fallBack("stalled_timestamp")
        }
        if (source == "warming_up" && nowNs - startedNs >= STARTUP_WAIT_NS) {
            fallBack("timestamp_unavailable")
        }
        // Some drivers need more than the priming window to publish three
        // advancing timestamps. Let those establish the physical reference
        // without holding up playback. A rejected live clock never returns.
        if (source == "playback_head" && nowNs - startedNs >= TIMESTAMP_STARTUP_NS) {
            canPollTimestamp = false
        }
        val frames = when (source) {
            "timestamp" -> referenceFrames + (nowNs - referenceNs) * sampleRate / 1_000_000_000L
            "playback_head" -> headFrames - latencyUs * sampleRate / 1_000_000
            else -> 0
        }
        return frames.coerceIn(0, written)
    }

    private fun fallBack(reason: String) {
        source = "playback_head"
        fallbackReason = reason
        if (reason != "timestamp_unavailable") canPollTimestamp = false
    }
}
