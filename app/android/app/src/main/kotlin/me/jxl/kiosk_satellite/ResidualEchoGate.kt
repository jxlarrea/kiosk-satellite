package me.jxl.kiosk_satellite

/**
 * Playback processing requests, with realtime taking priority over a call.
 * The WebRTC realtime path uses an extra residual gate. Calls and the
 * custom filter keep cleaned capture without that gate so quiet nearby
 * speech stays audible during double talk.
 * Calls run under SoftwareEcho's lock.
 */
internal class ResidualEchoGate {
    enum class Mode { REALTIME, INTERCOM }

    private val owners = mutableMapOf<Any, Mode>()
    private var mode: Mode? = null
    private var hangover = 0

    val intercomOnly: Boolean get() = mode == Mode.INTERCOM
    val realtime: Boolean get() = mode == Mode.REALTIME

    fun set(owner: Any, mode: Mode?) {
        if (mode == null) owners.remove(owner) else owners[owner] = mode
        val next = when {
            Mode.REALTIME in owners.values -> Mode.REALTIME
            Mode.INTERCOM in owners.values -> Mode.INTERCOM
            else -> null
        }
        if (next != this.mode) reset()
        this.mode = next
    }

    fun reset() {
        hangover = 0
    }

    /** One 10 ms frame, measured before cancellation, in the reference and after cancellation. */
    fun suppress(heard: Int, played: Int, left: Int, subtractionOnly: Boolean = false): Boolean {
        // The custom filter preserves overlapping speech by subtraction.
        // An energy gate here would undo that after the native processing.
        if (subtractionOnly) return false
        if (hangover > 0) hangover--
        if (mode != Mode.REALTIME) return false
        if (played < 100 || heard < 300) return false
        if (left >= minOf(heard * 0.3, 200.0)) {
            hangover = 20
            return false
        }
        return hangover == 0
    }
}
