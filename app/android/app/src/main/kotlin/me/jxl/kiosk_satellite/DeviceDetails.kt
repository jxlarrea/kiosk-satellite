package me.jxl.kiosk_satellite

import android.app.ActivityManager
import android.content.Context
import android.os.Build
import android.os.Environment
import android.os.Handler
import android.os.Looper
import android.os.StatFs
import android.provider.Settings
import android.util.DisplayMetrics
import android.view.WindowManager
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * The device facts Android will still tell an app, for the remote admin's
 * Device Info.
 *
 * Read on demand rather than cached: every one of these can change under us
 * (memory, storage, the WebView being updated), and a stale number presented as
 * current is worse than no number.
 *
 * Deliberately only things obtainable without a further grant. MAC addresses
 * and the foreground app used to be here and are gone: Android returns a fixed
 * 02:00:00:00:00:00 for the first (and by 16 not even an adb shell can read the
 * sysfs node), and the second needs the special "Usage access" grant. Both
 * could only ever have rendered as "not available", which is a row that costs
 * space and teaches nothing.
 */
class DeviceDetails(
    private val context: Context,
    messenger: BinaryMessenger,
) {
    private val channel = MethodChannel(messenger, "kiosk_satellite/device_details")

    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "read" -> result.success(read())
                // The SSAID: stable per device + app signing key, surviving
                // reinstalls (a factory reset changes it). The seed for the
                // licensing Device ID — a value that has to outlive app data.
                "androidId" -> result.success(
                    Settings.Secure.getString(context.contentResolver, Settings.Secure.ANDROID_ID)
                )
                // Dozens of sysfs reads, polled every few seconds while an
                // admin tab is open — off the main thread, so a stats tick
                // can never cost the UI a frame.
                "cpu" -> Thread {
                    val data = cpu()
                    Handler(Looper.getMainLooper()).post { result.success(data) }
                }.start()
                else -> result.notImplemented()
            }
        }
    }

    fun dispose() = channel.setMethodCallHandler(null)

    private fun read(): Map<String, Any?> = mapOf(
        "brand" to Build.BRAND,
        "manufacturer" to Build.MANUFACTURER,
        "model" to Build.MODEL,
        "androidBuild" to Build.DISPLAY,
        "fingerprint" to Build.FINGERPRINT,
        "ram" to ram(),
        "storage" to storage(),
        "screen" to screen(),
        "webview" to webview(),
    )

    private fun ram(): Map<String, Any> {
        val am = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val info = ActivityManager.MemoryInfo()
        am.getMemoryInfo(info)
        return mapOf("free" to info.availMem, "total" to info.totalMem, "low" to info.lowMemory)
    }

    private fun storage(): Map<String, Any> {
        val stat = StatFs(Environment.getDataDirectory().path)
        return mapOf(
            "free" to stat.availableBytes,
            "total" to stat.totalBytes,
        )
    }

    private fun screen(): Map<String, Any> {
        val wm = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            // maximumWindowMetrics, not currentWindowMetrics: the latter needs a
            // visual (Activity) context and throws from the application context
            // this now runs in. The maximum bounds are the full display — the
            // right answer for a fullscreen kiosk anyway.
            val b = wm.maximumWindowMetrics.bounds
            mapOf(
                "width" to b.width(),
                "height" to b.height(),
                "density" to context.resources.displayMetrics.density,
            )
        } else {
            @Suppress("DEPRECATION")
            val dm = DisplayMetrics().also { wm.defaultDisplay.getRealMetrics(it) }
            mapOf("width" to dm.widthPixels, "height" to dm.heightPixels, "density" to dm.density)
        }
    }

    /**
     * Live CPU load and temperature, both `null` when the platform won't answer.
     *
     * Neither comes from `/proc/stat` — an app can't read it (SELinux denies
     * `proc_stat`), and the WebView renderer is an isolated process whose CPU we
     * couldn't see anyway. What sysfs *does* let an untrusted app read is the
     * cpufreq state and the thermal zones, and those actually answer the two
     * questions better: every process on the device drives the governor, so a
     * frequency-derived load reflects the whole device, and the thermal zone is
     * the real silicon temperature no matter which process is heating it.
     */
    private fun cpu(): Map<String, Any?> = mapOf(
        "usage" to cpuUsage(),
        "temp" to cpuTemp(),
    )

    /**
     * Load estimated from clock speed: per online core, how far its current
     * frequency sits between its min and max, averaged. Idle cores park at min
     * (→0), a pegged device ramps every core to max (→100). Not the exact
     * utilisation `/proc/stat` would give, but it tracks it and it is readable.
     */
    private fun cpuUsage(): Double? {
        val cores = File("/sys/devices/system/cpu")
            .listFiles { f -> f.name.matches(Regex("cpu[0-9]+")) } ?: return null
        var sum = 0.0
        var n = 0
        for (core in cores) {
            val fq = File(core, "cpufreq")
            val cur = readLong(File(fq, "scaling_cur_freq")) ?: continue
            val min = readLong(File(fq, "cpuinfo_min_freq")) ?: continue
            val max = readLong(File(fq, "cpuinfo_max_freq")) ?: continue
            if (max <= min) continue
            sum += ((cur - min).toDouble() / (max - min)).coerceIn(0.0, 1.0)
            n++
        }
        return if (n == 0) null else sum / n * 100.0
    }

    /**
     * The hottest CPU thermal zone, in °C. Zones are matched by `type`
     * containing "cpu", never by index — the numbering differs per device (an
     * S8 and an S8+ disagree). Values are milli-°C on these SoCs; a few report
     * plain °C, so both scales are accepted and implausible readings dropped.
     */
    private fun cpuTemp(): Double? {
        val zones = File("/sys/class/thermal")
            .listFiles { f -> f.name.startsWith("thermal_zone") } ?: return null
        var max: Double? = null
        for (z in zones) {
            val type = readText(File(z, "type"))?.lowercase() ?: continue
            if (!type.contains("cpu")) continue
            // Threshold pseudo-zones, not sensors: `cpu-hw-trip-*` and
            // friends report the constant throttle limit (105°C on Snapdragon
            // phones), and the hottest-zone pick would return it forever.
            if (type.contains("trip") || type.contains("limit")) continue
            val raw = readLong(File(z, "temp")) ?: continue
            val c = if (raw > 1000) raw / 1000.0 else raw.toDouble()
            if (c in 20.0..130.0 && (max == null || c > max)) max = c
        }
        return max
    }

    private fun readText(file: File): String? = try {
        if (file.canRead()) file.readText().trim() else null
    } catch (e: Exception) {
        null
    }

    private fun readLong(file: File): Long? = readText(file)?.toLongOrNull()

    /** The WebView implementation actually in use — the thing rendering the card. */
    private fun webview(): Map<String, Any?> {
        return try {
            val pkg = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                android.webkit.WebView.getCurrentWebViewPackage()
            } else {
                null
            }
            mapOf("package" to pkg?.packageName, "version" to pkg?.versionName)
        } catch (e: Exception) {
            mapOf("package" to null, "version" to null)
        }
    }
}
