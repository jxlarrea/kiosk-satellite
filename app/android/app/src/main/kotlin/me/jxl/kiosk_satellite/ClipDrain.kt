package me.jxl.kiosk_satellite

/** Waits for speaker presentation, not just time since AudioTrack.play(). */
internal class ClipDrain(private val frames: Long, private val sampleRate: Int) {
    private var headFinishedNs: Long? = null
    private var presentationEndNs: Long? = null

    fun complete(
        nowNs: Long,
        headFrames: Long,
        timestampFrames: Long?,
        timestampNs: Long?,
        fallbackLatencyNs: Long,
    ): Boolean {
        if (headFrames < frames) return false
        val finished = headFinishedNs ?: nowNs.also { headFinishedNs = it }
        if (timestampFrames != null && timestampNs != null &&
            timestampFrames in 1..frames && timestampNs > 0) {
            val remainingNs = (frames - timestampFrames) * 1_000_000_000L / sampleRate
            // Some drivers keep updating the timestamp's time after its
            // frame position has stopped. Keep the first drain estimate so
            // that stalled timestamp cannot move completion forward forever.
            if (presentationEndNs == null) {
                presentationEndNs = (timestampNs + remainingNs + 20_000_000L)
                    .coerceAtMost(finished + 2_000_000_000L)
            }
        }
        // Some drivers do not expose presentation timestamps. Once the
        // mixer consumes the clip, allow its remaining output buffer to drain.
        return nowNs >= (presentationEndNs ?: (finished + fallbackLatencyNs))
    }
}
