package me.jxl.kiosk_satellite

/** Pace rendered frames without changing the camera's analysis cadence. */
internal class RtspFramePacer(fps: Int) {
    private val interval = 1_000_000_000L / fps.coerceIn(1, 60)
    private var next = Long.MIN_VALUE
    private var previous = Long.MIN_VALUE

    fun accept(timestampNs: Long): Boolean {
        if (previous != Long.MIN_VALUE && timestampNs <= previous) {
            if (timestampNs == previous) return false
            next = Long.MIN_VALUE
        }
        previous = timestampNs
        if (next != Long.MIN_VALUE && timestampNs < next - interval / 10) return false
        next = if (next == Long.MIN_VALUE) timestampNs + interval
            else maxOf(next + interval, timestampNs + interval / 2)
        return true
    }
}
