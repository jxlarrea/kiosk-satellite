package me.jxl.kiosk_satellite

/** Holds a playback session until its last sound has released it. */
internal class PlaybackLeasePool(
    private val start: () -> Boolean,
    private val stop: () -> Unit,
) {
    private var users = 0
    val active: Boolean get() = users > 0

    fun acquire(): AutoCloseable? {
        if (users == 0 && !start()) return null
        users++
        var closed = false
        return AutoCloseable {
            if (!closed) {
                closed = true
                users--
                if (users == 0) stop()
            }
        }
    }
}
