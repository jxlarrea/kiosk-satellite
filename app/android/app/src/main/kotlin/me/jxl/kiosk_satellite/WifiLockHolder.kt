package me.jxl.kiosk_satellite

import android.content.Context
import android.net.wifi.WifiManager

/**
 * One process-wide keep-Wi-Fi-awake lock, shared by every feature that must
 * stay reachable while the screen is off.
 *
 * Minutes into a dark spell, OEM Wi-Fi power saving naps the radio. How that
 * lands depends on the hardware: a Galaxy Tab S9 drops the connection outright
 * every 10 to 30 dark minutes, while a Lenovo M10 Plus keeps the association
 * but delays traffic long enough that the MQTT keepalive misses its answer
 * every single cycle, flapping the device's Home Assistant entities
 * unavailable about once a minute (issue #184). Either way, everything that
 * makes a dark kiosk reachable — MQTT, the dashboard's websocket, the remote
 * admin, adb — suffers together.
 *
 * Holders: the keep-alive foreground service for its lifetime (background
 * listening), and the MQTT client for the span it is connected, so a device
 * without background listening still holds the radio while its entities
 * depend on it. Refcounted here so the owners stay independent.
 *
 * HIGH_PERF, not LOW_LATENCY: the low-latency mode only applies while the
 * acquiring app is foreground with the screen ON, and the whole point is the
 * screen-off spell. Deprecated on paper, still the mode that holds the radio
 * through screen-off power saving in practice. Wall-powered kiosks pay
 * nothing that matters for it.
 *
 * From Android 14, WifiLockManager silently converts this acquisition to a
 * low-latency lock (gated on the DeviceConfig flag
 * wifi/high_perf_lock_deprecated, default true), which by the rule above is
 * inert for the entire dark spell: dumpsys wifi shows the lock as type=4
 * instead of type=3 and "Current operation mode: 0" once the screen is off.
 * Nothing an app can do restores it; the shell command
 * `device_config put wifi high_perf_lock_deprecated false` does (documented
 * in docs/permissions.md), and a 30-minute dark soak on a Galaxy Tab S8
 * showed the radio napping at minute 12 without it and staying up with it.
 */
object WifiLockHolder {
    private var lock: WifiManager.WifiLock? = null
    private var refs = 0

    /** Whether the radio is currently being held, for the status page. */
    val isHeld: Boolean
        get() = synchronized(this) { lock?.isHeld == true }

    @Synchronized
    fun acquire(context: Context) {
        refs++
        if (lock != null) return
        try {
            @Suppress("DEPRECATION")
            lock = (context.applicationContext
                .getSystemService(Context.WIFI_SERVICE) as WifiManager)
                .createWifiLock(
                    WifiManager.WIFI_MODE_FULL_HIGH_PERF, "ks:screen-off-wifi")
                .also {
                    it.setReferenceCounted(false)
                    it.acquire()
                }
        } catch (_: Exception) {
            // No Wi-Fi service (ethernet-only hardware): nothing to hold.
        }
    }

    @Synchronized
    fun release() {
        if (refs > 0) refs--
        if (refs > 0) return
        lock?.let { if (it.isHeld) it.release() }
        lock = null
    }
}
