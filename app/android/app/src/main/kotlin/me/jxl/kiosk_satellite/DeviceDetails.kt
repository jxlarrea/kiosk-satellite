package me.jxl.kiosk_satellite

import android.app.ActivityManager
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.ConnectivityManager
import android.os.BatteryManager
import android.net.Network
import android.os.Build
import android.os.Environment
import android.os.Handler
import android.os.Looper
import android.os.Process
import android.os.StatFs
import android.os.SystemClock
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
/** SoC-package zone spellings accepted when no zone names "cpu" at all:
 *  Qualcomm (tsens, cpuss is cpu-matched anyway), Exynos clusters
 *  (BIG/MID/LITTLE, lowercased by the reader), per-cluster core names
 *  (gold/silver/prime), MediaTek (mtkts*, soc_max, ap_ntc board sensor). */
private val SOC_ZONE_HINTS = listOf(
    "soc", "tsens", "cluster", "big", "little", "mid", "prime", "gold",
    "silver", "mtkts", "ap_ntc",
)

/** Zone types never accepted as the CPU, whatever else they match. */
private val NOT_CPU_ZONE = listOf(
    "trip", "limit", "batt", "pmic", "charg", "wifi", "wlan", "usb", "skin",
    "gpu", "cam", "flash", "modem", "mdpa", "nrpa", "dram",
)

class DeviceDetails(
    private val context: Context,
    messenger: BinaryMessenger,
) {
    private val channel = MethodChannel(messenger, "kiosk_satellite/device_details")

    /**
     * When the current default network came up, on the elapsedRealtime clock,
     * or `null` while there is none. An app only learns about the network from
     * callback registration onward, so this clock starts at app start at the
     * earliest — "network uptime" reads as "how long since this app last saw
     * the network come up", which is the drop-detection number issue #75 asks
     * for, not the router's association time (Android does not expose that).
     */
    @Volatile private var networkSince: Long? = null

    /**
     * The network [networkSince] belongs to. On a switch (WiFi to ethernet)
     * the new default's onAvailable can arrive before the old network's
     * onLost; without this the late onLost would zero a clock that belongs
     * to the network we are happily using.
     */
    @Volatile private var currentNetwork: Network? = null

    private val networkCallback = object : ConnectivityManager.NetworkCallback() {
        override fun onAvailable(network: Network) {
            currentNetwork = network
            networkSince = SystemClock.elapsedRealtime()
        }

        override fun onLost(network: Network) {
            if (network == currentNetwork) {
                currentNetwork = null
                networkSince = null
            }
        }
    }

    init {
        try {
            (context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager)
                .registerDefaultNetworkCallback(networkCallback)
        } catch (e: Exception) {
            // Too many callbacks registered on this device, or no such
            // service: network uptime stays null rather than wrong.
        }
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "read" -> result.success(read())
                "uptime" -> result.success(uptime())
                "plugged" -> result.success(plugged())
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

    fun dispose() {
        channel.setMethodCallHandler(null)
        try {
            (context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager)
                .unregisterNetworkCallback(networkCallback)
        } catch (e: Exception) {
            // Never registered; nothing to undo.
        }
    }

    /**
     * Seconds this process has been alive (`app`) and seconds since the
     * default network last came up (`network`, `null` while offline — see
     * [networkSince] for what "came up" can mean). Both from the
     * elapsedRealtime clock, so a wall-clock change cannot bend either.
     */
    private fun uptime(): Map<String, Any?> = mapOf(
        "app" to (SystemClock.elapsedRealtime() - Process.getStartElapsedRealtime()) / 1000,
        "network" to networkSince?.let { (SystemClock.elapsedRealtime() - it) / 1000 },
    )

    /**
     * Whether external power is connected, from the sticky
     * ACTION_BATTERY_CHANGED broadcast's EXTRA_PLUGGED — the charger's own
     * online flag, not the battery status. Some kernels report a status of
     * "charging" forever (a LineageOS Fire 7, issue #205), while plugged
     * tracks the cable. Null when the platform won't say.
     */
    private fun plugged(): Boolean? {
        val intent = try {
            context.registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
        } catch (e: Exception) {
            null
        } ?: return null
        val plugged = intent.getIntExtra(BatteryManager.EXTRA_PLUGGED, -1)
        return if (plugged < 0) null else plugged > 0
    }

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
        // Prefer the kernel's MemAvailable over availMem: availMem subtracts
        // every mapped file page (APK, dex, framework code), so for hours
        // after a start it "declines" as code faults in - a leak-shaped
        // artifact that had users (and us) chasing phantoms. MemAvailable is
        // the kernel's own estimate of what could be reclaimed without
        // swapping, which is what "available" should mean on a graph.
        return mapOf(
            "free" to (memAvailable() ?: info.availMem),
            "total" to info.totalMem,
            "low" to info.lowMemory,
        )
    }

    private fun memAvailable(): Long? = try {
        File("/proc/meminfo").useLines { lines ->
            lines.firstOrNull { it.startsWith("MemAvailable") }
                ?.replace(Regex("[^0-9]"), "")
                ?.toLongOrNull()
                ?.times(1024)
        }
    } catch (e: Exception) {
        null
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
     * `proc_stat`), and on some kernels its idle field is broken anyway (an
     * Echo Show 5 reports idle jumps of half a million seconds). What sysfs
     * does let an untrusted app read, under the same label as the cpufreq
     * files, is cpuidle: each core's cumulative residency in its idle states.
     * Time not spent idle is the definition of utilisation, so the usage
     * number is derived from that (see [cpuUsage]), with the old
     * frequency-position estimate as the fallback where cpuidle is absent.
     */
    private fun cpu(): Map<String, Any?> {
        val temp = cpuTemp()
        val out = mutableMapOf<String, Any?>(
            "usage" to cpuUsage(),
            "temp" to temp,
        )
        // Field diagnosis for devices that report no temperature (issue
        // #138): what the thermal directory actually looks like from this
        // app's sandbox, carried only while the answer is null so the Dart
        // side can put it in the app logs a reporter pastes.
        if (temp == null) out["thermalZones"] = thermalZoneDump()
        return out
    }

    /** Every thermal zone's type (with "?" for an unreadable type and a
     *  "!" suffix when its temp file cannot be read), or ["unlisted"] when
     *  the directory itself cannot be enumerated. */
    private fun thermalZoneDump(): List<String> {
        if (thermalBlocked) return listOf("unlisted")
        val zones = File("/sys/class/thermal")
            .listFiles { f -> f.name.startsWith("thermal_zone") }
            ?: return listOf("unlisted")
        return zones.sortedBy { it.name }.map { z ->
            val type = readText(File(z, "type")) ?: "?"
            val readable = readLong(File(z, "temp")) != null
            if (readable) type else "$type!"
        }
    }

    /** One reading of every core's summed idle-state residency (µs) and
     *  entry count, with its online flag and when the reading was taken. */
    private class IdleSnapshot(
        val atNanos: Long,
        val idleUs: Map<String, Long>,
        val entries: Map<String, Long>,
        val online: Map<String, Boolean>,
    )

    /** The previous snapshot, so each report covers the window since the
     *  last one instead of blocking to measure a fresh window. */
    private var lastIdle: IdleSnapshot? = null

    private fun idleSnapshot(): IdleSnapshot? {
        val cores = File("/sys/devices/system/cpu")
            .listFiles { f -> f.name.matches(Regex("cpu[0-9]+")) } ?: return null
        val idle = HashMap<String, Long>()
        val entries = HashMap<String, Long>()
        val online = HashMap<String, Boolean>()
        for (core in cores) {
            val states = File(core, "cpuidle")
                .listFiles { f -> f.name.startsWith("state") } ?: continue
            var timeSum = 0L
            var usageSum = 0L
            var any = false
            for (state in states) {
                val t = readLong(File(state, "time")) ?: continue
                timeSum += t
                usageSum += readLong(File(state, "usage")) ?: 0L
                any = true
            }
            if (!any) continue
            idle[core.name] = timeSum
            entries[core.name] = usageSum
            // No `online` file (cpu0 on most kernels) means not unpluggable,
            // so online.
            online[core.name] = readLong(File(core, "online"))?.let { it != 0L } ?: true
        }
        if (idle.isEmpty()) return null
        return IdleSnapshot(SystemClock.elapsedRealtimeNanos(), idle, entries, online)
    }

    /**
     * Utilisation as 1 minus idle residency, averaged over cores.
     *
     * The previous estimate read each core's position between its min and max
     * clock, which pins at 100% on any device whose governor parks the cores
     * at max — LineageOS's interactive governor does exactly that, so Echo
     * Shows and ThinkSmarts reported a flat 100% forever (issue #76). Idle
     * residency is what the silicon actually did, whatever the clocks claim.
     *
     * The window is whatever elapsed since the previous call (the admin polls
     * every few seconds, MQTT once a minute). A first call, or a window so
     * stale it may span a suspend (cpuidle counters stop during suspend, the
     * clock does not), takes a short paired sample instead.
     */
    @Synchronized
    private fun cpuUsage(): Double? {
        var first = lastIdle ?: idleSnapshot() ?: return frequencyLoad()
        val age = SystemClock.elapsedRealtimeNanos() - first.atNanos
        if (age < 500_000_000L || age > 300_000_000_000L) {
            first = idleSnapshot() ?: return frequencyLoad()
            try {
                Thread.sleep(500)
            } catch (_: InterruptedException) {
                return frequencyLoad()
            }
        }
        val now = idleSnapshot() ?: return frequencyLoad()
        lastIdle = now
        val wallUs = (now.atNanos - first.atNanos) / 1000.0
        if (wallUs <= 0) return frequencyLoad()
        var busySum = 0.0
        var n = 0
        for ((name, idleNow) in now.idleUs) {
            val idleBefore = first.idleUs[name] ?: continue
            // Hotplugging governors park idle cores, and a parked core's
            // counters freeze, which is indistinguishable from pegged by the
            // idle delta alone (issue #76: parked cores read as a permanent
            // 100%). Rules, in order:
            //  - offline at either edge of the window: parked for (most of)
            //    it. That is free capacity, not load.
            //  - online at both edges but the counters never moved: a core
            //    that genuinely never idled, i.e. pegged.
            //  - otherwise: one minus its idle share of the window.
            val offlineAtEdge =
                first.online[name] == false || now.online[name] == false
            val frozen = idleNow == idleBefore &&
                now.entries[name] == first.entries[name]
            val busy = when {
                offlineAtEdge -> 0.0
                frozen -> 1.0
                else -> (1.0 - (idleNow - idleBefore) / wallUs).coerceIn(0.0, 1.0)
            }
            busySum += busy
            n++
        }
        if (n == 0) return frequencyLoad()
        return busySum / n * 100.0
    }

    /**
     * The old estimate, kept as the fallback for kernels without cpuidle
     * sysfs: per core, how far the current clock sits between min and max.
     */
    private fun frequencyLoad(): Double? {
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
     * The hottest CPU thermal zone, in °C. Zones are matched by `type`,
     * never by index — the numbering differs per device (an S8 and an S8+
     * disagree). Values are milli-°C on these SoCs; a few report plain °C,
     * so both scales are accepted and implausible readings dropped.
     *
     * Matching is two-tier (issue #138): zones naming "cpu" first, and only
     * when a device has none of those, zones whose type is a known SoC
     * spelling — Exynos names its clusters BIG/MID/LITTLE, Qualcomm has
     * tsens/cpuss, MediaTek mtkts* and soc_max — since a package sensor is
     * the same reading under a different label. Never both: on a device
     * with real cpu zones the extras could only replace a right answer
     * with a hotter wrong one.
     */
    private fun cpuTemp(): Double? =
        hottest { it.contains("cpu") }
            ?: hottest { type -> SOC_ZONE_HINTS.any { type.contains(it) } }

    /** Latched once /sys/class/thermal fails to enumerate: some OEM SELinux
     *  policies (Lenovo, issue #138) deny untrusted apps the directory read
     *  outright, and retrying on every stats poll would spray avc denials
     *  into logcat forever. Never unlatched: a policy does not change while
     *  the process lives. */
    private var thermalBlocked = false

    private fun hottest(wanted: (String) -> Boolean): Double? {
        if (thermalBlocked) return null
        val zones = File("/sys/class/thermal")
            .listFiles { f -> f.name.startsWith("thermal_zone") }
        if (zones == null) {
            thermalBlocked = true
            return null
        }
        var max: Double? = null
        for (z in zones) {
            val type = readText(File(z, "type"))?.lowercase() ?: continue
            if (!wanted(type)) continue
            // Pseudo-zones and lookalike sensors. trip/limit report the
            // constant throttle threshold (105°C on Snapdragon phones), and
            // the hottest-zone pick would return it forever; the rest are
            // real sensors of the wrong thing (battery, radios, connector,
            // case surface), several of which sit inside the plausibility
            // window below.
            if (NOT_CPU_ZONE.any { type.contains(it) }) continue
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
