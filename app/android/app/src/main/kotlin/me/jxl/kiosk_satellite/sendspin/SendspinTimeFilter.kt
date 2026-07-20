package me.jxl.kiosk_satellite.sendspin

import me.jxl.kiosk_satellite.sendspin.latency.StaticDelaySource
import android.util.Log
import java.util.concurrent.atomic.AtomicLong
import kotlin.math.abs
import kotlin.math.sqrt

/**
 * Two-state Kalman filter that estimates server-clock offset (and an
 * internal drift state) from NTP-style 4-timestamp measurements.
 *
 * ## Public conversion contract
 *
 * [serverToClient] and [clientToServer] convert by **offset only**; drift
 * is intentionally not applied. This is a deliberate divergence from
 * the upstream `Sendspin/time-filter` reference (which applies a
 * significance-gated drift term in its conversions).
 *
 * On Android, hardware DAC clock control is not exposed to userspace, so
 * a drift-applied conversion would produce a predicted server-time the
 * audio renderer cannot achieve, leaving the sample-insert/drop loop to
 * chase a sustained sync error. The same pattern is used by Spotify
 * Connect, Roon RAAT, Snapcast, the AirPlay shairport-sync DAC-clock
 * fallback path, and the Python `sendspin-cli` reference player.
 *
 * Drift compensation lives downstream in `SyncAudioPlayer`'s
 * sample-insert/drop loop, with `SyncErrorFilter` smoothing the
 * measured DAC-vs-expected-server-time error. Do not "fix" the
 * conversions to apply drift without revisiting that architecture.
 *
 * ## Reference
 *
 * Algorithm core matches upstream `Sendspin/time-filter` (Apache-2.0)
 * post-PR #6 (2026-04). Local adaptations are documented at their
 * respective sites in this file.
 */
class SendspinTimeFilter {

    companion object {
        // Algorithm and tunables match upstream Sendspin/time-filter (Apache-2.0)
        // post-PR #6 (2026-04). Local additions on top of upstream are documented
        // at their respective sites:
        //   - IQR outlier pre-rejection
        //   - +/-500 ppm hard drift cap
        //   - freeze/thaw with covariance inflation across reconnects
        //   - drift omitted from public conversions (see class KDoc)

        // Process-noise diffusion coefficients. Upstream defaults: zero offset
        // random walk (offset evolves only through drift*dt), and a tiny drift
        // random walk consistent with stable crystal oscillators.
        // Q grows by (coefficient)^2 * dt per microsecond of elapsed time.
        private const val PROCESS_STD_DEV = 0.0
        private const val DRIFT_PROCESS_STD_DEV = 1e-11
        private const val PROCESS_VARIANCE = PROCESS_STD_DEV * PROCESS_STD_DEV
        private const val DRIFT_PROCESS_VARIANCE = DRIFT_PROCESS_STD_DEV * DRIFT_PROCESS_STD_DEV

        // Measurement-variance pre-scaling. Per upstream PR #6, max_error
        // (= rtt/2) is a worst-case asymmetric-delay bound rather than a 1-sigma
        // estimate, so squaring it directly inflates R ~4x. Pre-scaling by 0.5
        // brings R = (max_error * 0.5)^2 = max_error^2 / 4.
        private const val MAX_ERROR_SCALE = 0.5

        // Adaptive forgetting. Fires when |residual| > FORGETTING_THRESHOLD *
        // max_error (a multiple of the measurement bound, not a fraction of
        // sigma). On fire, all four covariance entries are scaled by
        // FORGETTING_VARIANCE_FACTOR = FORGETTING_FACTOR^2 to accelerate
        // re-convergence. Forgetting is gated by MIN_SAMPLES_FOR_FORGETTING so
        // a few early outliers cannot prevent initial convergence.
        private const val FORGETTING_THRESHOLD = 3.0
        private const val FORGETTING_FACTOR = 2.0
        private const val FORGETTING_VARIANCE_FACTOR = FORGETTING_FACTOR * FORGETTING_FACTOR
        private const val MIN_SAMPLES_FOR_FORGETTING = 100

        // Drift-significance gate. Drift is only used in internal prediction
        // when drift^2 > DRIFT_SIGNIFICANCE_THRESHOLD^2 * drift_covariance,
        // i.e., when the estimate is at least k sigma from zero.
        private const val DRIFT_SIGNIFICANCE_THRESHOLD = 2.0
        private const val DRIFT_SIGNIFICANCE_THRESHOLD_SQUARED =
            DRIFT_SIGNIFICANCE_THRESHOLD * DRIFT_SIGNIFICANCE_THRESHOLD

        // Local: IQR-based outlier pre-rejection ahead of the Kalman update.
        // Defends against heavy-tailed wifi/cellular RTT spikes that upstream
        // does not see in its testbed.
        private const val OUTLIER_WINDOW_SIZE = 10
        private const val OUTLIER_IQR_MULTIPLIER = 3.0
        private const val MIN_OUTLIER_MEASUREMENTS = 5

        // Local: hard cap on drift to keep prediction sane if a measurement
        // sequence transiently suggests an unphysical clock-rate difference.
        // 500 ppm is generous compared to typical phone crystals (10-50 ppm).
        private const val MAX_DRIFT = 5e-4

        // Readiness and convergence reporting.
        private const val MIN_MEASUREMENTS = 2
        private const val MIN_MEASUREMENTS_FOR_CONVERGENCE = 5
        private const val MAX_ERROR_FOR_CONVERGENCE_US = 10_000L

        private const val TAG = "SendspinTimeFilter"
    }

    // Lock for protecting filter state mutations (addMeasurement, reset, freeze, thaw).
    // Hot-path readers (serverToClient, clientToServer) use @Volatile fields instead of
    // locking to avoid blocking the audio thread.
    private val lock = Any()

    // State vector: [offset, drift]
    // offset is stored as AtomicLong (bit-cast from Double via toRawBits /
    // fromBits) so reads on 32-bit JVMs are atomic. The covariance matrix
    // (p00, p01, p10, p11) is still guarded by [lock] on writes. Readers
    // on the audio thread (serverToClient, clientToServer) read offset
    // lock-free via the Double property accessor below.
    private val offsetBits = AtomicLong(0L)

    private var offset: Double
        get() = Double.fromBits(offsetBits.get())
        set(value) { offsetBits.set(value.toRawBits()) }

    private var drift: Double = 0.0

    // Covariance matrix (2x2)
    private var p00: Double = Double.MAX_VALUE  // offset variance
    private var p01: Double = 0.0               // offset-drift covariance
    private var p10: Double = 0.0               // drift-offset covariance
    private var p11: Double = 0.0               // drift variance

    // Timing state. lastUpdateTime is @Volatile because [lastUpdateTimeUs]
    // is read lock-free from non-filter threads (e.g. SendSpinClient.
    // getLastTimeSyncAgeMs); without it, a 64-bit Long load is not
    // guaranteed atomic on 32-bit JVMs and visibility is not guaranteed
    // anywhere.
    @Volatile private var lastUpdateTime: Long = 0
    private var measurementCount: Int = 0

    private var useDrift: Boolean = false

    // Outlier pre-rejection: tracks recent accepted offset measurements
    private val recentOffsets = DoubleArray(OUTLIER_WINDOW_SIZE)
    private var recentOffsetsIndex = 0
    private var recentOffsetsCount = 0
    private var rejectedCount = 0  // Consecutive rejections (for forced acceptance)

    // Baseline time for relative calculations - prevents drift accumulation over long periods
    // Set when first measurement is received, used as reference point for time conversions
    private var baselineClientTime: Long = 0

    // Static delay = auto-measured output latency + user sync offset.
    // Each source is tracked separately so auto-measurement and user
    // corrections don't clobber each other. [staticDelayMs] returns the sum.
    // @Volatile fields: read by audio thread (serverToClient), written from
    // UI/main or estimator threads.
    @Volatile private var autoMeasuredDelayMicros: Long = 0
    @Volatile private var userSyncOffsetMicros: Long = 0
    @Volatile var staticDelaySource: StaticDelaySource = StaticDelaySource.NONE
        private set

    // Convergence tracking
    private var convergenceTimeMs: Long = 0L       // Time to reach isConverged
    private var firstMeasurementTimeMs: Long = 0L  // Timestamp of first measurement
    private var hasLoggedConvergence: Boolean = false

    // Frozen state for reconnection - preserves sync across network drops
    @Volatile private var frozenState: FrozenState? = null

    private data class FrozenState(
        val offset: Double,
        val drift: Double,
        val p00: Double,
        val p01: Double,
        val p10: Double,
        val p11: Double,
        val measurementCount: Int,
        val baselineClientTime: Long,
        val lastUpdateTime: Long,
        val recentOffsets: DoubleArray,
        val recentOffsetsIndex: Int,
        val recentOffsetsCount: Int,
        val serverName: String?,
        val serverId: String?
    )

    /**
     * Whether enough measurements have been collected for reliable time conversion.
     * This is the minimum threshold - playback can start, but may need corrections.
     */
    val isReady: Boolean
        get() = measurementCount >= MIN_MEASUREMENTS && p00.isFinite()

    /**
     * Whether the filter has converged to a high-quality sync. Stricter
     * than [isReady]: requires `MIN_MEASUREMENTS_FOR_CONVERGENCE` accepted
     * measurements and an estimated offset standard deviation below
     * `MAX_ERROR_FOR_CONVERGENCE_US`. When true, sync corrections should
     * be minimal.
     */
    val isConverged: Boolean
        get() {
            if (measurementCount < MIN_MEASUREMENTS_FOR_CONVERGENCE || !p00.isFinite()) return false
            return errorMicros < MAX_ERROR_FOR_CONVERGENCE_US
        }

    /**
     * Current estimated offset in microseconds.
     */
    val offsetMicros: Long
        get() = offset.toLong()

    /**
     * Estimated error (standard deviation) in microseconds.
     */
    val errorMicros: Long
        get() = if (p00.isFinite() && p00 >= 0) sqrt(p00).toLong() else Long.MAX_VALUE

    /**
     * Number of measurements collected so far.
     */
    val measurementCountValue: Int
        get() = measurementCount

    /**
     * Current drift in parts per million (ppm).
     * Positive = server clock running faster than client.
     */
    val driftPpm: Double
        get() = drift * 1_000_000.0

    /**
     * Time of last measurement update in microseconds (client time).
     */
    val lastUpdateTimeUs: Long
        get() = lastUpdateTime

    /**
     * Effective static delay in milliseconds. Sum of the auto-measured
     * hardware latency and the user's sync-offset correction. Both
     * components may be written independently by their respective setters.
     *
     * Positive = delay playback (plays later), Negative = advance (plays earlier).
     */
    val staticDelayMs: Double
        get() = (autoMeasuredDelayMicros + userSyncOffsetMicros) / 1000.0

    /**
     * Raw auto-measured component (milliseconds).
     */
    val autoMeasuredDelayMs: Double
        get() = autoMeasuredDelayMicros / 1000.0

    /**
     * Raw user sync-offset component (milliseconds).
     */
    val userSyncOffsetMs: Double
        get() = userSyncOffsetMicros / 1000.0

    /**
     * Write the auto-measured hardware output latency. Called by
     * [OutputLatencyEstimator] when measurement converges (source=AUTO)
     * or times out (source=NONE).
     */
    fun setAutoMeasuredDelayMicros(micros: Long, source: StaticDelaySource) {
        autoMeasuredDelayMicros = micros
        staticDelaySource = source
    }

    /**
     * Write the user's manual sync-offset correction (milliseconds).
     * Called by the settings slider's broadcast path.
     */
    fun setUserSyncOffsetMs(ms: Double) {
        userSyncOffsetMicros = (ms * 1000).toLong()
        staticDelaySource = StaticDelaySource.USER
    }

    /**
     * Write a server-pushed sync-offset (from `client/sync_offset`).
     * Goes into the same field as the user slider because both are
     * semantically "corrections on top of the measured hardware latency".
     */
    fun setServerSyncOffsetMs(ms: Double) {
        userSyncOffsetMicros = (ms * 1000).toLong()
        staticDelaySource = StaticDelaySource.SERVER
    }

    /**
     * Time to reach convergence in milliseconds.
     * 0 if not yet converged.
     */
    val convergenceTimeMillis: Long
        get() = convergenceTimeMs

    /**
     * Filter stability score. Always 1.0 with the upstream-aligned model
     * (fixed Q + adaptive forgetting); retained for binary compatibility
     * with stats UI bindings that bundled this value.
     */
    val stability: Double
        get() = 1.0

    /**
     * Reset the filter to initial state.
     * Thread-safe: synchronized to prevent concurrent mutation.
     */
    fun reset() = synchronized(lock) {
        offset = 0.0
        drift = 0.0
        p00 = Double.MAX_VALUE
        p01 = 0.0
        p10 = 0.0
        p11 = 0.0
        lastUpdateTime = 0
        measurementCount = 0
        baselineClientTime = 0
        useDrift = false
        recentOffsetsIndex = 0
        recentOffsetsCount = 0
        rejectedCount = 0
        convergenceTimeMs = 0
        firstMeasurementTimeMs = 0
        hasLoggedConvergence = false
    }

    /**
     * Whether the filter has frozen state that can be restored.
     */
    val isFrozen: Boolean
        get() = frozenState != null

    /**
     * Capture a snapshot of the current sync state so [thaw] can restore it
     * after a reconnect to the same server. No-op if the filter is not yet
     * [isReady].
     *
     * @param serverName Display name of the currently-connected server (from server/hello).
     * @param serverId   Stable identifier of the currently-connected server (from server/hello).
     */
    fun freeze(serverName: String?, serverId: String?) {
        synchronized(lock) {
            if (!isReady) return

            frozenState = FrozenState(
                offset = offset,
                drift = drift,
                p00 = p00,
                p01 = p01,
                p10 = p10,
                p11 = p11,
                measurementCount = measurementCount,
                baselineClientTime = baselineClientTime,
                lastUpdateTime = lastUpdateTime,
                recentOffsets = recentOffsets.copyOf(),
                recentOffsetsIndex = recentOffsetsIndex,
                recentOffsetsCount = recentOffsetsCount,
                serverName = serverName,
                serverId = serverId
            )
        }
    }

    /**
     * Restore a frozen sync state captured by [freeze] if and only if the
     * provided identity matches the one captured at freeze-time. On
     * identity mismatch the frozen snapshot is discarded.
     *
     * Call this after a reconnect handshake completes, before resuming time
     * sync.
     *
     * @param serverName Display name of the just-handshook server.
     * @param serverId   Stable identifier of the just-handshook server.
     * @return true if state was restored, false if no frozen state existed
     *         or the identity did not match.
     */
    fun thaw(serverName: String?, serverId: String?): Boolean {
        synchronized(lock) {
            val frozen = frozenState ?: return false

            if (frozen.serverName != serverName || frozen.serverId != serverId) {
                frozenState = null
                return false
            }

            offset = frozen.offset
            drift = frozen.drift

            p00 = frozen.p00 * 100.0
            p01 = frozen.p01 * 10.0
            p10 = frozen.p10 * 10.0
            p11 = frozen.p11 * 100.0

            measurementCount = MIN_MEASUREMENTS
            baselineClientTime = frozen.baselineClientTime
            lastUpdateTime = frozen.lastUpdateTime

            frozen.recentOffsets.copyInto(recentOffsets)
            recentOffsetsIndex = frozen.recentOffsetsIndex
            recentOffsetsCount = frozen.recentOffsetsCount
            rejectedCount = 0
            useDrift = false

            hasLoggedConvergence = false
            convergenceTimeMs = 0
            firstMeasurementTimeMs = System.currentTimeMillis()

            frozenState = null
            return true
        }
    }

    /**
     * Discard frozen state and perform full reset.
     * Call this when reconnection fails and we need to start fresh.
     * Thread-safe: synchronized to prevent concurrent mutation.
     */
    fun resetAndDiscard() = synchronized(lock) {
        frozenState = null
        offset = 0.0
        drift = 0.0
        p00 = Double.MAX_VALUE
        p01 = 0.0
        p10 = 0.0
        p11 = 0.0
        lastUpdateTime = 0
        measurementCount = 0
        baselineClientTime = 0
        useDrift = false
        recentOffsetsIndex = 0
        recentOffsetsCount = 0
        rejectedCount = 0
        convergenceTimeMs = 0
        firstMeasurementTimeMs = 0
        hasLoggedConvergence = false
    }

    /**
     * Add a new time measurement to the filter.
     *
     * Includes outlier pre-rejection: measurements that deviate significantly from
     * recent history are rejected before reaching the Kalman filter, protecting
     * against cellular congestion spikes and handoff transients.
     *
     * Thread-safe: synchronized to prevent concurrent mutation of filter state.
     *
     * @param measurementOffset The measured offset in microseconds
     * @param maxError The maximum error (uncertainty) in microseconds
     * @param clientTimeMicros The client timestamp when measurement was taken
     * @param rtt Optional round-trip time in microseconds (ignored, kept for API compatibility)
     * @return true if measurement was accepted, false if rejected as outlier
     */
    fun addMeasurement(
        measurementOffset: Long,
        maxError: Long,
        clientTimeMicros: Long,
        rtt: Long = 0L
    ): Boolean = synchronized(lock) {
        if (measurementCount > 0 && clientTimeMicros <= lastUpdateTime) {
            return false
        }

        val measurement = measurementOffset.toDouble()
        val maxErrorD = maxError.toDouble().coerceAtLeast(1.0)
        val updateStdDev = maxErrorD * MAX_ERROR_SCALE
        val measurementVariance = updateStdDev * updateStdDev

        if (measurementCount == 0) {
            firstMeasurementTimeMs = System.currentTimeMillis()
        }

        when (measurementCount) {
            0 -> {
                offset = measurement
                p00 = measurementVariance
                lastUpdateTime = clientTimeMicros
                baselineClientTime = clientTimeMicros
                measurementCount = 1
                recordAcceptedOffset(measurement)
            }
            1 -> {
                val dt = (clientTimeMicros - lastUpdateTime).toDouble()
                drift = ((measurement - offset) / dt).coerceIn(-MAX_DRIFT, MAX_DRIFT)
                p11 = (p00 + measurementVariance) / (dt * dt)
                offset = measurement
                p00 = measurementVariance
                lastUpdateTime = clientTimeMicros
                measurementCount = 2
                recordAcceptedOffset(measurement)
            }
            else -> {
                if (!shouldAcceptMeasurement(measurement, maxErrorD)) {
                    rejectedCount++
                    return false
                }
                rejectedCount = 0

                kalmanUpdate(measurement, maxErrorD, clientTimeMicros)
                recordAcceptedOffset(measurement)

                checkConvergence()
            }
        }
        return true
    }

    /**
     * Check for convergence and log milestone.
     */
    private fun checkConvergence() {
        if (!hasLoggedConvergence && isConverged) {
            hasLoggedConvergence = true
            convergenceTimeMs = System.currentTimeMillis() - firstMeasurementTimeMs
            Log.i(TAG, "Kalman locked: time=${convergenceTimeMs}ms, " +
                    "offset=${offset.toLong()}us (+/-$errorMicros), drift=${String.format("%.2f", driftPpm)}ppm")
        }
    }

    /**
     * Determine if a measurement should be accepted or rejected as an outlier.
     *
     * Uses robust statistics (median + IQR) to detect measurements that are
     * far from the recent accepted history. This protects the Kalman filter
     * from being pulled by cellular congestion spikes (200ms+ outliers).
     *
     * Force-accepts after 3 consecutive rejections to handle genuine step changes
     * (e.g., network route change where ALL measurements shift).
     */
    private fun shouldAcceptMeasurement(measurement: Double, maxError: Double): Boolean {
        // Accept during early warmup - not enough history for outlier detection
        if (recentOffsetsCount < MIN_OUTLIER_MEASUREMENTS) return true

        // Force-accept after consecutive rejections (genuine step change)
        if (rejectedCount >= 3) return true

        val count = minOf(recentOffsetsCount, OUTLIER_WINDOW_SIZE)
        val sorted = DoubleArray(count)
        for (i in 0 until count) {
            sorted[i] = recentOffsets[(recentOffsetsIndex - count + i + OUTLIER_WINDOW_SIZE) % OUTLIER_WINDOW_SIZE]
        }
        sorted.sort()

        val median = if (count % 2 == 0) {
            (sorted[count / 2 - 1] + sorted[count / 2]) / 2.0
        } else {
            sorted[count / 2]
        }

        val q1 = sorted[count / 4]
        val q3 = sorted[(count * 3) / 4]
        val iqr = q3 - q1

        // Threshold: at least RTT-sized window (maxError), or IQR-based
        val threshold = maxOf(OUTLIER_IQR_MULTIPLIER * iqr, maxError)

        return abs(measurement - median) <= threshold
    }

    /**
     * Record an accepted offset measurement in the recent history window.
     */
    private fun recordAcceptedOffset(measurement: Double) {
        recentOffsets[recentOffsetsIndex] = measurement
        recentOffsetsIndex = (recentOffsetsIndex + 1) % OUTLIER_WINDOW_SIZE
        if (recentOffsetsCount < OUTLIER_WINDOW_SIZE) recentOffsetsCount++
    }

    private fun kalmanUpdate(measurement: Double, maxError: Double, clientTimeMicros: Long) {
        val dt = (clientTimeMicros - lastUpdateTime).toDouble()
        if (dt <= 0) return
        val dtSquared = dt * dt
        val updateStdDev = maxError * MAX_ERROR_SCALE
        val measurementVariance = updateStdDev * updateStdDev

        // Predict: x = F * x, P = F * P * F^T + Q with F = [[1, dt], [0, 1]]
        // and Q = diag(PROCESS_VARIANCE, DRIFT_PROCESS_VARIANCE) * dt.
        val effectiveDrift = if (useDrift) drift else 0.0
        val offsetPredicted = offset + effectiveDrift * dt

        var p00New = p00 + 2 * p01 * dt + p11 * dtSquared + PROCESS_VARIANCE * dt
        var p01New = p01 + p11 * dt
        var p10New = p10 + p11 * dt
        var p11New = p11 + DRIFT_PROCESS_VARIANCE * dt

        val innovation = measurement - offsetPredicted

        // Adaptive forgetting: residuals exceeding FORGETTING_THRESHOLD * max_error
        // indicate a step change (route flip, server clock jump, etc). Inflate the
        // entire predicted covariance so the next gain step is large enough to
        // adopt the new measurement quickly. Gated by measurement count so a
        // handful of early outliers cannot wipe the model.
        if (measurementCount >= MIN_SAMPLES_FOR_FORGETTING &&
            abs(innovation) > FORGETTING_THRESHOLD * maxError
        ) {
            p00New *= FORGETTING_VARIANCE_FACTOR
            p01New *= FORGETTING_VARIANCE_FACTOR
            p10New *= FORGETTING_VARIANCE_FACTOR
            p11New *= FORGETTING_VARIANCE_FACTOR
        }

        // Update: K = P * H^T * S^-1, x = x + K * y, P = (I - K * H) * P
        // with H = [1, 0] and S = P[0,0] + R.
        val s = p00New + measurementVariance
        if (s <= 0) return

        val k0 = p00New / s
        val k1 = p10New / s

        offset = offsetPredicted + k0 * innovation
        drift = (drift + k1 * innovation).coerceIn(-MAX_DRIFT, MAX_DRIFT)

        p00 = (1 - k0) * p00New
        p01 = (1 - k0) * p01New
        p10 = p10New - k1 * p00New
        p11 = p11New - k1 * p01New

        useDrift = drift * drift > DRIFT_SIGNIFICANCE_THRESHOLD_SQUARED * p11

        lastUpdateTime = clientTimeMicros
        measurementCount++

        if (measurementCount == MIN_MEASUREMENTS) {
            Log.i(TAG, "Time sync ready: offset=${offset.toLong()}us, error=${errorMicros}us, " +
                    "drift=${String.format("%.3f", driftPpm)}ppm (after $measurementCount measurements)")
        }
    }

    /**
     * Convert a server timestamp into the client-clock domain. Includes
     * the auto-measured output-latency and user/server sync-offset
     * components so the result is the wall-clock instant at which the
     * audio sink should render the corresponding samples.
     *
     * Offset-only — see the class docstring for why drift is not applied.
     *
     * Lock-free; safe to call from the audio thread.
     */
    fun serverToClient(serverTimeMicros: Long): Long {
        val baseResult = serverTimeMicros - offset.toLong()
        return baseResult + autoMeasuredDelayMicros + userSyncOffsetMicros
    }

    /**
     * Inverse of [serverToClient]. Offset-only — see the class docstring
     * for why drift is not applied. Lock-free.
     */
    fun clientToServer(clientTimeMicros: Long): Long {
        return clientTimeMicros + offset.toLong() - autoMeasuredDelayMicros - userSyncOffsetMicros
    }
}
