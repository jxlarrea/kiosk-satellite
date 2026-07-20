package me.jxl.kiosk_satellite.sendspin.latency

/**
 * Measures device output latency (time from AudioTrack.write() to sound
 * leaving the DAC) by cross-referencing write timestamps against DAC
 * timestamp callbacks.
 *
 * Pure Kotlin, no Android dependencies. Takes write events in via
 * [recordWrite] and DAC timestamp events in via [recordDacTimestamp];
 * emits a single [Result] via the callback when the session converges
 * or times out.
 *
 * @param nowNs monotonic clock source (System.nanoTime in production,
 *              a mock in tests).
 * @param ringCapacity how many recent writes to retain; must be larger
 *              than the expected lag between write and DAC callback.
 */
class OutputLatencyEstimator(
    private val nowNs: () -> Long,
    private val ringCapacity: Int = DEFAULT_RING_CAPACITY,
) {
    companion object {
        const val DEFAULT_RING_CAPACITY = 64
        // Reject latency samples outside [0, 1_000 ms]. Negative = measurement
        // bug, > 1 s = pathological device or Bluetooth routing. Don't poison
        // the mean with these.
        const val MAX_REASONABLE_LATENCY_NS = 1_000_000_000L  // 1 second
        const val CONVERGENCE_SAMPLE_COUNT = 20
        const val TIMEOUT_NS = 2_000_000_000L  // 2 seconds
    }

    enum class Status { Idle, Measuring, Converged, TimedOut, Cancelled }

    sealed class Result {
        data class Converged(val latencyMicros: Long, val sampleCount: Int) : Result()
        data class TimedOut(val sampleCount: Int) : Result()
    }

    // Ring buffer entry: (framesWritten cumulative, writeTimeNs)
    private data class WriteEntry(val framesWritten: Long, val writeTimeNs: Long)

    @Volatile var status: Status = Status.Idle
        private set

    private val lock = Any()
    private var onResult: ((Result) -> Unit)? = null
    private val ring = ArrayDeque<WriteEntry>(DEFAULT_RING_CAPACITY)
    private val samples = ArrayDeque<Long>()  // latency values in nanoseconds
    private var rejectedSamples = 0
    private var startNs: Long = 0L

    fun start(onResult: (Result) -> Unit) {
        synchronized(lock) {
            if (status != Status.Idle) return
            this.onResult = onResult
            ring.clear()
            samples.clear()
            rejectedSamples = 0
            startNs = nowNs()
            status = Status.Measuring
        }
    }

    fun cancel() {
        synchronized(lock) {
            if (status != Status.Measuring) return
            status = Status.Cancelled
            onResult = null
        }
    }

    fun recordWrite(framesWritten: Long, writeTimeNs: Long) {
        synchronized(lock) {
            if (status != Status.Measuring) return
            if (ring.size >= ringCapacity) ring.removeFirst()
            ring.addLast(WriteEntry(framesWritten, writeTimeNs))
        }
    }

    fun recordDacTimestamp(framePosition: Long, dacTimeNs: Long) {
        synchronized(lock) {
            if (status != Status.Measuring) return
            val writeTimeNs = lookupWriteTime(framePosition) ?: run {
                rejectedSamples++
                return
            }
            val latencyNs = dacTimeNs - writeTimeNs
            if (latencyNs <= 0 || latencyNs > MAX_REASONABLE_LATENCY_NS) {
                rejectedSamples++
                return
            }
            samples.addLast(latencyNs)
            if (samples.size >= CONVERGENCE_SAMPLE_COUNT) {
                val sum = samples.sum()
                val meanNs = sum / samples.size
                val result = Result.Converged(
                    latencyMicros = meanNs / 1_000,
                    sampleCount = samples.size,
                )
                status = Status.Converged
                val cb = onResult
                onResult = null
                cb?.invoke(result)
            }
        }
    }

    /**
     * Linear scan for the write entry whose `framesWritten` is >= the query
     * frame — i.e., the earliest write that contains the requested frame.
     * Returns its `writeTimeNs`, or null if the frame is older than the
     * oldest entry in the ring.
     */
    private fun lookupWriteTime(framePosition: Long): Long? {
        for (entry in ring) {
            if (entry.framesWritten >= framePosition) return entry.writeTimeNs
        }
        return null
    }

    /**
     * Check the timeout clock. Call this periodically from any thread that
     * also calls [recordWrite] / [recordDacTimestamp] (so the same lock
     * serializes state). When the timeout has elapsed and the session has
     * not yet converged, fires [Result.TimedOut].
     */
    fun tick() {
        synchronized(lock) {
            if (status != Status.Measuring) return
            if (nowNs() - startNs < TIMEOUT_NS) return
            val result = Result.TimedOut(sampleCount = samples.size)
            status = Status.TimedOut
            val cb = onResult
            onResult = null
            cb?.invoke(result)
        }
    }
}
