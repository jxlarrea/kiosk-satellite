package me.jxl.kiosk_satellite.sendspin

import kotlin.math.abs
import kotlin.math.sqrt

/**
 * Two-state Kalman smoother for the per-loop DAC sync error fed by
 * `SyncAudioPlayer`. Inputs are scalar `(measurement, timeUs)` samples
 * representing the current measured `dacPlaybackServerTime - cursorAtDac`
 * difference; the smoother's `offsetMicros` output drives the
 * sample-insert/drop correction loop.
 *
 * Algorithm shape matches `SendspinTimeFilter` post-Phase-2 with one
 * deliberate divergence: the drift-significance gate is omitted.
 * Upstream gates drift in its time-conversion API (which we don't
 * expose); for the prediction step, drift is always applied here, so
 * the drift estimate isn't biased by suppressing its own contribution
 * to predicted offset.
 *
 * Defaults are tuned for the higher-rate (~10 Hz) DAC-error stream
 * rather than the lower-rate (~0.1 Hz post-convergence) NTP-style
 * burst stream that the time-sync filter sees.
 *
 * Not thread-safe; the playback loop is the sole writer / reader.
 *
 * @param processStdDev      Increase to model offset random walk.
 *                           Default `0.0` -- offset evolves only via drift.
 * @param driftProcessStdDev Increase to model drift random walk.
 *                           Default matches upstream's stable-crystal value.
 * @param measurementNoiseUs Expected measurement standard deviation (1σ)
 *                           in microseconds.
 */
class SyncErrorFilter(
    private val processStdDev: Double = 0.0,
    private val driftProcessStdDev: Double = 1e-11,
    private val measurementNoiseUs: Long = 5_000L
) {
    companion object {
        private const val MIN_MEASUREMENTS = 2

        // Adaptive forgetting fires when |residual| > FORGETTING_RESIDUAL_SIGMAS *
        // measurementNoiseUs, scaling the predicted covariance by
        // FORGETTING_VARIANCE_FACTOR. 6 sigma + 4x matches the structural
        // disruption response of upstream Sendspin/time-filter (where
        // |residual| > 3 * max_error == 6 * sigma after PR #6's max_error_scale).
        private const val FORGETTING_RESIDUAL_SIGMAS = 6.0
        private const val FORGETTING_FACTOR = 2.0
        private const val FORGETTING_VARIANCE_FACTOR = FORGETTING_FACTOR * FORGETTING_FACTOR

        // At ~10 Hz update cadence, this gates forgetting until the filter has
        // built ~2 s of history. Upstream uses 100 because its sample rate is
        // ~0.1 Hz post-convergence; the same wall-clock warmup at our rate
        // would over-suppress disruption response.
        private const val MIN_SAMPLES_FOR_FORGETTING = 20

        // Hard cap on drift magnitude. +/-500 ppm is generous for any
        // physically realistic DAC vs network-clock divergence.
        private const val MAX_DRIFT = 5e-4
    }

    private val processVariance = processStdDev * processStdDev
    private val driftProcessVariance = driftProcessStdDev * driftProcessStdDev

    private var offset: Double = 0.0
    private var drift: Double = 0.0

    private var p00: Double = Double.MAX_VALUE
    private var p01: Double = 0.0
    private var p10: Double = 0.0
    private var p11: Double = 0.0

    private var lastUpdateTimeUs: Long = 0
    private var measurementCount: Int = 0

    /**
     * True once enough measurements have been collected for [offsetMicros]
     * to be a meaningful estimate.
     */
    val isReady: Boolean
        get() = measurementCount >= MIN_MEASUREMENTS && p00.isFinite()

    /** Smoothed sync-error offset in microseconds. */
    val offsetMicros: Long
        get() = offset.toLong()

    /** Estimated rate-of-change of sync error (dimensionless, µs/µs). */
    val driftValue: Double
        get() = drift

    /** Estimated offset standard deviation in microseconds. */
    val errorMicros: Long
        get() = if (p00.isFinite() && p00 >= 0) sqrt(p00).toLong() else Long.MAX_VALUE

    /** Reset to the uninitialized state. */
    fun reset() {
        offset = 0.0
        drift = 0.0
        p00 = Double.MAX_VALUE
        p01 = 0.0
        p10 = 0.0
        p11 = 0.0
        lastUpdateTimeUs = 0
        measurementCount = 0
    }

    /**
     * Feed a new sync-error measurement. Non-monotonic timestamps are
     * silently dropped after the first sample.
     *
     * @param measurement Measured sync error in microseconds.
     * @param timeUs      Client-time of the measurement in microseconds.
     */
    fun update(measurement: Long, timeUs: Long) {
        if (measurementCount > 0 && timeUs <= lastUpdateTimeUs) return

        val measDouble = measurement.toDouble()
        val measurementVariance = (measurementNoiseUs.toDouble() * measurementNoiseUs).coerceAtLeast(1.0)

        when (measurementCount) {
            0 -> {
                offset = measDouble
                p00 = measurementVariance
                lastUpdateTimeUs = timeUs
                measurementCount = 1
            }
            1 -> {
                val dt = (timeUs - lastUpdateTimeUs).toDouble()
                drift = ((measDouble - offset) / dt).coerceIn(-MAX_DRIFT, MAX_DRIFT)
                p11 = (p00 + measurementVariance) / (dt * dt)
                offset = measDouble
                p00 = measurementVariance
                lastUpdateTimeUs = timeUs
                measurementCount = 2
            }
            else -> kalmanUpdate(measDouble, measurementVariance, timeUs)
        }
    }

    private fun kalmanUpdate(measurement: Double, variance: Double, timeUs: Long) {
        val dt = (timeUs - lastUpdateTimeUs).toDouble()
        val dtSquared = dt * dt

        val offsetPredicted = offset + drift * dt

        var p00New = p00 + 2 * p01 * dt + p11 * dtSquared + processVariance * dt
        var p01New = p01 + p11 * dt
        var p10New = p10 + p11 * dt
        var p11New = p11 + driftProcessVariance * dt

        val innovation = measurement - offsetPredicted

        if (measurementCount >= MIN_SAMPLES_FOR_FORGETTING &&
            abs(innovation) > FORGETTING_RESIDUAL_SIGMAS * measurementNoiseUs
        ) {
            p00New *= FORGETTING_VARIANCE_FACTOR
            p01New *= FORGETTING_VARIANCE_FACTOR
            p10New *= FORGETTING_VARIANCE_FACTOR
            p11New *= FORGETTING_VARIANCE_FACTOR
        }

        val s = p00New + variance
        if (s <= 0) return

        val k0 = p00New / s
        val k1 = p10New / s

        offset = offsetPredicted + k0 * innovation
        drift = (drift + k1 * innovation).coerceIn(-MAX_DRIFT, MAX_DRIFT)

        p00 = (1 - k0) * p00New
        p01 = (1 - k0) * p01New
        p10 = p10New - k1 * p00New
        p11 = p11New - k1 * p01New

        lastUpdateTimeUs = timeUs
        measurementCount++
    }
}
