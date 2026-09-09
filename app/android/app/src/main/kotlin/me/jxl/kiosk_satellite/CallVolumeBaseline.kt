package me.jxl.kiosk_satellite

/** Applies an intentional baseline once per process or explicit re-enable. */
internal class CallVolumeBaseline {
    private var enabled = false
    private var initialized = false

    fun setEnabled(value: Boolean): Boolean {
        if (enabled == value) return false
        enabled = value
        initialized = false
        return true
    }

    fun initialize(apply: () -> Boolean) {
        if (enabled && !initialized && apply()) initialized = true
    }
}
