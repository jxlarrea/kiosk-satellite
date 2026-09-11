package me.jxl.kiosk_satellite.plugins

/** SDK event contract and per-session bounds for asynchronous commands. */
internal object PluginHostPolicy {
    val events = setOf(
        "screensaver.state", "screensaver.countdown", "screensaver.view",
        "screen.state", "screen.brightness", "screen.ambient",
        "device.power", "device.network", "device.volume", "device.light",
        "detection.motion", "detection.face", "detection.proximity",
        "detection.person", "detection.presence", "voice.interaction",
        "wakeword.state", "wakeword.detected", "stopword.detected", "camera.view", "browser.state",
    )
}

internal class PluginCommandBudget {
    private var windowStart: Long? = null
    private var count = 0
    private var pending = 0

    @Synchronized fun acquire(now: Long = System.nanoTime()) {
        if (windowStart == null || now - windowStart!! >= 1_000_000_000L) { windowStart = now; count = 0 }
        check(pending < 8) { "At most 8 KS commands may be pending" }
        check(count < 20) { "At most 20 KS commands per second" }
        pending++; count++
    }
    @Synchronized fun release() { if (pending > 0) pending-- }
}
