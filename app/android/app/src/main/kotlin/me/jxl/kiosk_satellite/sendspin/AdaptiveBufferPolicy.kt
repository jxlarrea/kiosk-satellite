package me.jxl.kiosk_satellite.sendspin

import kotlin.math.sqrt

/**
 * Computes an adaptive target jitter-buffer size (the `min_buffer_ms` we report
 * to the server) from live network conditions, instead of a fixed value.
 *
 * The server keeps our queue at least `min_buffer_ms` deep for live streams, so
 * a larger value is more cushion (fewer underruns) at the cost of latency, and a
 * smaller value is lower latency at the cost of resilience. The spec allows
 * clients to update this at runtime (debounced); this policy decides the value.
 *
 * The default config is deliberately **generous**: it favours a fat buffer
 * (fewer glitches) for a music player where a second or two of latency is
 * cheap, and only trims latency on a sustained-good link. Use [lowMemory] for
 * the low-memory profile.
 *
 * Behaviour (mirrors the official MA mobile app's AdaptiveBufferManager):
 * - The good-link steady state is [Config.floorMs] — the generous baseline the
 *   policy sits at when the network is healthy.
 * - **Grow fast** on trouble (sync LOST, RTT spike, underrun, or a high drop
 *   rate) up to [Config.ceilingMs], bounded by [Config.growCooldownMs] so a
 *   burst of bad measurements doesn't ratchet repeatedly.
 * - **Shrink slow** back toward the baseline: only after [Config.sustainedGoodMs]
 *   of continuously good conditions, one step per [Config.shrinkCooldownMs], so
 *   a transient spike doesn't pin the buffer (and the group) high forever.
 * - A degraded link sizes to `rtt*2 + jitter*4*qualityMultiplier + dropPenalty`,
 *   clamped to `[floorMs, ceilingMs]`. Jitter is the online std-dev of RTT
 *   (Welford) over a window.
 *
 * Pure and deterministic: the caller passes a monotonic `nowMs` into every
 * [update], so the cooldown/streak logic is fully testable without real time or
 * audio.
 */
class AdaptiveBufferPolicy(private val config: Config = Config()) {

    companion object {
        /** Generous profile for normal mode — the default. */
        fun generous() = Config()

        /** Smaller buffer for low-memory mode (tighter cushion, lower latency). */
        fun lowMemory() = Config(
            floorMs = 500,
            ceilingMs = 1_500,
            initialMs = 500,
            shrinkStepMs = 100,
        )
    }

    data class Config(
        /** Good-link steady state and hard lower bound on the buffer (ms). */
        val floorMs: Int = 1_500,
        /** Hard upper bound under sustained trouble (ms). */
        val ceilingMs: Int = 5_000,
        /** Starting value (ms) — the generous baseline. */
        val initialMs: Int = 1_500,
        /** Minimum time between consecutive grows (ms). */
        val growCooldownMs: Long = 2_000,
        /** Minimum time between consecutive shrink steps (ms). */
        val shrinkCooldownMs: Long = 20_000,
        /** How long conditions must stay good before the first shrink (ms). */
        val sustainedGoodMs: Long = 60_000,
        /** Each shrink step reduces the target by this much (ms). */
        val shrinkStepMs: Int = 250,
        /** On an underrun, bump the target up by at least this much (ms). */
        val growBumpMs: Int = 250,
        /** RTT at/under which a link counts as "good" (ms). */
        val goodRttMs: Double = 30.0,
        /** Jitter at/under which a link counts as "good" (ms). */
        val goodJitterMs: Double = 10.0,
        /** RTT above baseline*this counts as a spike (grow trigger). */
        val rttSpikeFactor: Double = 1.5,
        /** Drop rate above this counts as trouble. */
        val highDropRate: Double = 0.05,
        /** Extra buffer added when the drop rate is high (ms). */
        val dropPenaltyMs: Int = 200,
        /** Window size for the RTT jitter estimate. */
        val jitterWindow: Int = 30,
        /** Smoothing for the RTT baseline EMA (0..1; higher = faster). */
        val baselineAlpha: Double = 0.1,
    )

    enum class SyncQuality { GOOD, DEGRADED, LOST }

    private var targetMs: Int = config.initialMs.coerceIn(config.floorMs, config.ceilingMs)

    // Welford online mean/variance over a sliding RTT window.
    private val rttWindow = ArrayDeque<Double>()
    private var rttMean = 0.0
    private var rttM2 = 0.0

    private var rttBaselineMs = 0.0
    private var baselineInitialized = false

    private var lastGrowMs = Long.MIN_VALUE
    private var lastShrinkMs = Long.MIN_VALUE
    private var goodSinceMs = Long.MIN_VALUE
    private var lastUpdateMs = Long.MIN_VALUE

    /** Current target buffer size (ms). */
    val currentTargetMs: Int get() = targetMs

    /** Current RTT jitter estimate (ms, std-dev over the window). */
    val jitterMs: Double
        get() = if (rttWindow.size < 2) 0.0 else sqrt(rttM2 / (rttWindow.size - 1))

    /**
     * Feed one measurement and return the (possibly updated) target buffer ms.
     *
     * @param nowMs monotonic timestamp (e.g. elapsedRealtime); only differences matter
     * @param rttMs round-trip time of this measurement
     * @param quality current clock-sync quality
     * @param dropRate fraction of chunks dropped recently (0..1)
     * @param underrun true if a buffer underrun occurred since the last update
     */
    fun update(
        nowMs: Long,
        rttMs: Double,
        quality: SyncQuality,
        dropRate: Double = 0.0,
        underrun: Boolean = false,
    ): Int {
        pushRtt(rttMs)
        val spike = baselineInitialized && rttMs > rttBaselineMs * config.rttSpikeFactor
        // Update the baseline AFTER spike detection so a spike doesn't poison it.
        rttBaselineMs = if (!baselineInitialized) {
            baselineInitialized = true
            rttMs
        } else {
            rttBaselineMs + config.baselineAlpha * (rttMs - rttBaselineMs)
        }

        val jitter = jitterMs
        val qualityMultiplier = when (quality) {
            SyncQuality.GOOD -> 1.0
            SyncQuality.DEGRADED -> 1.5
            SyncQuality.LOST -> 2.0
        }
        val dropPenalty = if (dropRate > config.highDropRate) config.dropPenaltyMs else 0
        val ideal = (rttMs * 2 + jitter * 4 * qualityMultiplier + dropPenalty)
            .toInt()
            .coerceIn(config.floorMs, config.ceilingMs)

        val good = quality == SyncQuality.GOOD &&
            rttMs <= config.goodRttMs &&
            jitter <= config.goodJitterMs &&
            dropRate <= 0.0 &&
            !underrun
        val trouble = underrun ||
            dropRate > config.highDropRate ||
            quality == SyncQuality.LOST ||
            spike

        if (good) {
            if (goodSinceMs == Long.MIN_VALUE) goodSinceMs = nowMs
        } else {
            goodSinceMs = Long.MIN_VALUE
        }

        if (trouble) {
            val cooled = lastGrowMs == Long.MIN_VALUE || nowMs - lastGrowMs >= config.growCooldownMs
            if (cooled) {
                // An underrun proves the current buffer was too small, so bump
                // beyond it even when the steady-state ideal is lower.
                val bumped = if (underrun) targetMs + config.growBumpMs else targetMs
                val grown = maxOf(bumped, ideal).coerceIn(config.floorMs, config.ceilingMs)
                if (grown > targetMs) {
                    targetMs = grown
                    lastGrowMs = nowMs
                }
            }
        } else if (good && targetMs > ideal) {
            val sustained = goodSinceMs != Long.MIN_VALUE &&
                nowMs - goodSinceMs >= config.sustainedGoodMs
            val cooled = lastShrinkMs == Long.MIN_VALUE ||
                nowMs - lastShrinkMs >= config.shrinkCooldownMs
            if (sustained && cooled) {
                targetMs = (targetMs - config.shrinkStepMs)
                    .coerceAtLeast(maxOf(ideal, config.floorMs))
                lastShrinkMs = nowMs
            }
        }

        lastUpdateMs = nowMs
        return targetMs
    }

    private fun pushRtt(rttMs: Double) {
        rttWindow.addLast(rttMs)
        // Incremental Welford add.
        val n = rttWindow.size
        val delta = rttMs - rttMean
        rttMean += delta / n
        rttM2 += delta * (rttMs - rttMean)
        if (rttWindow.size > config.jitterWindow) {
            // Remove oldest and recompute (window is small; O(window) is fine).
            rttWindow.removeFirst()
            recomputeWelford()
        }
    }

    private fun recomputeWelford() {
        rttMean = 0.0
        rttM2 = 0.0
        var n = 0
        for (v in rttWindow) {
            n++
            val delta = v - rttMean
            rttMean += delta / n
            rttM2 += delta * (v - rttMean)
        }
    }
}
