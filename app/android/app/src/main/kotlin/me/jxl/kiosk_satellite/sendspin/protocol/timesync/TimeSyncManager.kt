package me.jxl.kiosk_satellite.sendspin.protocol.timesync

import me.jxl.kiosk_satellite.sendspin.SendspinTimeFilter
import me.jxl.kiosk_satellite.sendspin.protocol.SendSpinProtocol
import me.jxl.kiosk_satellite.sendspin.protocol.TimeMeasurement
import android.util.Log
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.currentCoroutineContext
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch

/**
 * Drives the NTP-style time-sync burst loop and feeds its filter.
 *
 * Threading: [start] launches the burst-send loop on the supplied scope
 * (in production a dedicated single-thread dispatcher). [onServerTime]
 * is called from the WebSocket transport's receive thread:
 *   - During a burst window, replies are queued under
 *     `pendingBurstMeasurements` and processed later on the burst-loop
 *     thread.
 *   - Outside a burst window, the reply is fed straight to the filter
 *     on the receive thread.
 *
 * The two paths can therefore both call `timeFilter.addMeasurement` on
 * different threads. That is safe by design: the filter's internal
 * mutex serialises both paths, and out-of-burst replies are not in
 * competition with any burst's best-of-RTT selection (no burst is
 * active by definition).
 */
class TimeSyncManager(
    private val timeFilter: SendspinTimeFilter,
    private val sendClientTime: () -> Unit,
    private val onMeasurementApplied: (rttMicros: Long) -> Unit = {},
    private val tag: String = "TimeSyncManager"
) {
    companion object {
        private const val MAX_ACCEPTABLE_RTT_US = 10_000_000L
        private const val RTT_HISTORY_SIZE = 15
        private const val BURST_COUNT_HIGH_JITTER = 15
        private const val BURST_COUNT_LOW_JITTER = 5
        private const val INTERVAL_MS_HIGH_JITTER = 200L
        private const val INTERVAL_MS_LOW_JITTER = 500L
        private const val BURST_COUNT_CONVERGED = 3
        private const val INTERVAL_MS_CONVERGED = 3000L
        private const val HIGH_JITTER_THRESHOLD_US = 20_000L
        private const val LOW_JITTER_THRESHOLD_US = 5_000L
    }

    @Volatile
    private var running = false
    private var syncJob: Job? = null

    private val pendingBurstMeasurements = mutableListOf<TimeMeasurement>()
    @Volatile
    private var burstInProgress = false

    private val rttHistory = LongArray(RTT_HISTORY_SIZE)
    private var rttHistoryIndex = 0
    private var rttHistoryCount = 0

    private var currentBurstCount = SendSpinProtocol.TimeSync.BURST_COUNT
    private var currentIntervalMs = SendSpinProtocol.TimeSync.INTERVAL_MS

    val isRunning: Boolean
        get() = running

    // Visible for testing: burst strategy and RTT history state
    internal val testCurrentBurstCount: Int get() = synchronized(pendingBurstMeasurements) { currentBurstCount }
    internal val testCurrentIntervalMs: Long get() = synchronized(pendingBurstMeasurements) { currentIntervalMs }
    internal val testRttHistoryCount: Int get() = synchronized(pendingBurstMeasurements) { rttHistoryCount }

    fun start(scope: CoroutineScope) {
        if (running) return
        running = true

        syncJob = scope.launch {
            sendTimeSyncBurst()

            while (running && isActive) {
                delay(currentIntervalMs)
                if (running) {
                    sendTimeSyncBurst()
                }
            }
        }
    }

    fun stop() {
        running = false
        syncJob?.cancel()
        syncJob = null
        synchronized(pendingBurstMeasurements) {
            pendingBurstMeasurements.clear()
            burstInProgress = false
            rttHistoryIndex = 0
            rttHistoryCount = 0
            currentBurstCount = SendSpinProtocol.TimeSync.BURST_COUNT
            currentIntervalMs = SendSpinProtocol.TimeSync.INTERVAL_MS
        }
    }

    /**
     * Feed a `server/time` measurement to the manager.
     *
     * @return `true` if the measurement was buffered for the in-progress
     *   burst's best-of-RTT selection. `false` if it was processed
     *   immediately (out-of-burst path), dropped as stale, or arrived
     *   while the manager is stopped. Callers that just want to forward
     *   the measurement can ignore the return value.
     */
    fun onServerTime(measurement: TimeMeasurement): Boolean {
        if (!running) return false

        synchronized(pendingBurstMeasurements) {
            if (burstInProgress) {
                pendingBurstMeasurements.add(measurement)
                return true
            }
        }

        if (measurement.rtt > MAX_ACCEPTABLE_RTT_US) {
            Log.v(tag, "Ignoring stale time response: RTT=${measurement.rtt / 1_000_000}s")
            return false
        }

        val maxError = computeMaxError(measurement.rtt)
        timeFilter.addMeasurement(measurement.offset, maxError, measurement.clientReceived, measurement.rtt)

        if (timeFilter.isReady) {
            Log.v(tag, "Time sync: offset=${timeFilter.offsetMicros}μs, error=${timeFilter.errorMicros}μs")
        }

        onMeasurementApplied(measurement.rtt)
        return false
    }

    private suspend fun sendTimeSyncBurst() {
        synchronized(pendingBurstMeasurements) {
            pendingBurstMeasurements.clear()
            burstInProgress = true
        }

        try {
            repeat(currentBurstCount) {
                if (!running || !currentCoroutineContext().isActive) return
                sendClientTime()
                delay(SendSpinProtocol.TimeSync.BURST_DELAY_MS)
            }

            delay(SendSpinProtocol.TimeSync.BURST_DELAY_MS * 2)

            processBurstResults()
        } finally {
            synchronized(pendingBurstMeasurements) {
                burstInProgress = false
            }
        }
    }

    private fun processBurstResults() {
        var bestRttMicros = 0L
        synchronized(pendingBurstMeasurements) {
            burstInProgress = false

            if (pendingBurstMeasurements.isEmpty()) {
                Log.w(tag, "No time sync responses received in burst")
                return
            }

            val validMeasurements = pendingBurstMeasurements.filter { it.rtt < MAX_ACCEPTABLE_RTT_US }
            if (validMeasurements.isEmpty()) {
                Log.w(tag, "All ${pendingBurstMeasurements.size} responses had RTT > ${MAX_ACCEPTABLE_RTT_US / 1_000_000}s - skipping burst")
                pendingBurstMeasurements.clear()
                return
            }

            val best = validMeasurements.minByOrNull { it.rtt }!!
            bestRttMicros = best.rtt

            val maxError = computeMaxError(best.rtt)

            recordRtt(best.rtt)
            updateBurstStrategy()

            val staleCount = pendingBurstMeasurements.size - validMeasurements.size
            Log.v(tag, "Time sync burst: ${validMeasurements.size}/$currentBurstCount responses" +
                    (if (staleCount > 0) " ($staleCount stale rejected)" else "") +
                    ", best RTT=${best.rtt}μs, offset=${best.offset}μs")

            val accepted = timeFilter.addMeasurement(best.offset, maxError, best.clientReceived, best.rtt)

            if (timeFilter.isReady) {
                Log.v(tag, "Time sync: offset=${timeFilter.offsetMicros}μs, error=${timeFilter.errorMicros}μs, " +
                        "drift=${"%.3f".format(timeFilter.driftPpm)}ppm" +
                        if (!accepted) " [rejected]" else "")
            }

            pendingBurstMeasurements.clear()
        }
        onMeasurementApplied(bestRttMicros)
    }

    private fun computeMaxError(rtt: Long): Long = (rtt / 2L).coerceAtLeast(1L)

    private fun recordRtt(rtt: Long) {
        rttHistory[rttHistoryIndex] = rtt
        rttHistoryIndex = (rttHistoryIndex + 1) % RTT_HISTORY_SIZE
        if (rttHistoryCount < RTT_HISTORY_SIZE) rttHistoryCount++
    }

    private fun updateBurstStrategy() {
        if (rttHistoryCount < 5) return

        val count = minOf(rttHistoryCount, RTT_HISTORY_SIZE)
        val sorted = LongArray(count)
        for (i in 0 until count) {
            sorted[i] = rttHistory[i]
        }
        sorted.sort()

        val q1 = sorted[count / 4]
        val q3 = sorted[(count * 3) / 4]
        val jitter = q3 - q1

        when {
            jitter > HIGH_JITTER_THRESHOLD_US -> {
                currentBurstCount = BURST_COUNT_HIGH_JITTER
                currentIntervalMs = INTERVAL_MS_HIGH_JITTER
            }
            jitter < LOW_JITTER_THRESHOLD_US -> {
                currentBurstCount = BURST_COUNT_LOW_JITTER
                currentIntervalMs = INTERVAL_MS_LOW_JITTER
            }
            else -> {
                currentBurstCount = SendSpinProtocol.TimeSync.BURST_COUNT
                currentIntervalMs = SendSpinProtocol.TimeSync.INTERVAL_MS
            }
        }

        if (timeFilter.isConverged) {
            currentBurstCount = BURST_COUNT_CONVERGED
            currentIntervalMs = INTERVAL_MS_CONVERGED
        }
    }
}
