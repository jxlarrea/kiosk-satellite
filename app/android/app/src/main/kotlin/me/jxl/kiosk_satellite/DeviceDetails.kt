package me.jxl.kiosk_satellite

import android.app.ActivityManager
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothProfile
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
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
import android.system.Os
import android.system.OsConstants
import android.system.StructTimeval
import android.util.DisplayMetrics
import android.view.WindowManager
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.net.NetworkInterface
import java.nio.ByteBuffer
import java.nio.ByteOrder

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
 * space and teaches nothing. The wifiMac method is the one exception, and it
 * is not a display row: it answers only on devices where [WifiMac]'s doors
 * open, and the caller falls back silently where it declines.
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

/** Netlink ABI numbers (linux/netlink.h, rtnetlink.h, if_addr.h). Kernel
 *  ABI, fixed forever; several are missing from OsConstants on the older
 *  API levels this app still runs on, so they are spelled out here. */
private const val AF_NETLINK = 16
private const val NETLINK_ROUTE = 0
private const val RTM_NEWADDR = 20
private const val RTM_GETADDR = 22
private const val NLMSG_ERROR = 2
private const val NLMSG_DONE = 3
private const val NLM_F_REQUEST = 1
private const val NLM_F_DUMP = 0x300
private const val IFA_ADDRESS = 1
private const val IFA_CACHEINFO = 6

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

    /** Bound Bluetooth profile services, by profile constant. */
    private val profileProxies = java.util.concurrent.ConcurrentHashMap<Int, BluetoothProfile>()

    /** Whether the profile binds have been asked for (they are asked once). */
    @Volatile private var profilesRequested = false

    /**
     * Links coming up and going down, pushed to Dart rather than waited for
     * by the minute poll: Home Assistant connecting to a lock through the
     * Bluetooth proxy holds the link for half a minute, which two polls a
     * minute apart can miss entirely (issue #281).
     */
    private val aclReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            when (intent?.action) {
                BluetoothDevice.ACTION_ACL_CONNECTED,
                BluetoothDevice.ACTION_ACL_DISCONNECTED,
                -> Handler(Looper.getMainLooper()).post {
                    try {
                        channel.invokeMethod("bluetoothChanged", null)
                    } catch (e: Exception) {
                        // The engine is gone; nothing to tell.
                    }
                }
            }
        }
    }

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
        try {
            val filter = IntentFilter().apply {
                addAction(BluetoothDevice.ACTION_ACL_CONNECTED)
                addAction(BluetoothDevice.ACTION_ACL_DISCONNECTED)
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                context.registerReceiver(aclReceiver, filter, Context.RECEIVER_EXPORTED)
            } else {
                context.registerReceiver(aclReceiver, filter)
            }
        } catch (e: Exception) {
            // No Bluetooth on this build: the poll still answers.
        }
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "read" -> result.success(read())
                "uptime" -> result.success(uptime())
                "plugged" -> result.success(plugged())
                // The Bluetooth links this device holds (issue #281).
                "bluetooth" -> result.success(bluetooth())
                // The SSAID: stable per device + app signing key, surviving
                // reinstalls (a factory reset changes it). The seed for the
                // licensing Device ID — a value that has to outlive app data.
                "androidId" -> result.success(
                    Settings.Secure.getString(context.contentResolver, Settings.Secure.ANDROID_ID)
                )
                // The real Wi-Fi hardware address, or null where Android
                // hides it (issue #252). See WifiMac for the doors tried.
                "wifiMac" -> result.success(WifiMac.read(context))
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
            context.unregisterReceiver(aclReceiver)
        } catch (e: Exception) {
            // Never registered; nothing to undo.
        }
        val adapter = (context.getSystemService(Context.BLUETOOTH_SERVICE)
            as? BluetoothManager)?.adapter
        for ((profile, proxy) in profileProxies) {
            try {
                adapter?.closeProfileProxy(profile, proxy)
            } catch (e: Exception) {
                // Already gone with the adapter.
            }
        }
        profileProxies.clear()
        try {
            (context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager)
                .unregisterNetworkCallback(networkCallback)
        } catch (e: Exception) {
            // Never registered; nothing to undo.
        }
    }

    /**
     * Seconds this process has been alive (`app`) and seconds since the
     * default network last came up (`network`, `null` while offline). The
     * app clock is elapsedRealtime, so a wall-clock change cannot bend it.
     *
     * The network number prefers the kernel's own timestamp on the default
     * interface's IP address (see [addressAgeSeconds]): the kernel stamps
     * every address when it is configured, so the age survives app
     * restarts — an app that restarts on a device that has sat on Wi-Fi
     * for a week reports the week, not its own age. Where the netlink read
     * is refused or finds nothing, [networkSince] (anchored at app start
     * at the earliest) is the floor. `networkSource` says which one
     * answered, for the app log.
     */
    private fun uptime(): Map<String, Any?> {
        var network: Long? = null
        var source: String? = null
        if (currentNetwork != null) {
            network = try {
                addressAgeSeconds()
            } catch (e: Exception) {
                null
            }
            source = if (network != null) "address" else null
            if (network == null) {
                network = networkSince?.let {
                    (SystemClock.elapsedRealtime() - it) / 1000
                }
                if (network != null) source = "app clock"
            }
        }
        return mapOf(
            "app" to
                (SystemClock.elapsedRealtime() - Process.getStartElapsedRealtime()) / 1000,
            "network" to network,
            "networkSource" to source,
        )
    }

    /**
     * How long the default network's interface has held its current IP
     * address, in seconds, or `null` when that cannot be read.
     *
     * The kernel keeps a creation timestamp (`cstamp`, hundredths of a
     * second on the suspend-excluding jiffies clock) in every address's
     * IFA_CACHEINFO, dumped over an RTM_GETADDR netlink request — the same
     * socket family bionic's getifaddrs uses, so SELinux allows it to
     * untrusted apps. A DHCP renewal replaces the address in place and
     * preserves cstamp; a reconnect deletes and re-adds it, which is
     * exactly the reset this number should show. Compared against
     * uptimeMillis, the matching suspend-excluding clock.
     *
     * IPv4 addresses are preferred; a v6-only network falls back to its
     * oldest non-link-local address (link-local ages tell nothing — they
     * exist from the moment the radio is up, network or not). The oldest
     * address wins within a family: rotating IPv6 privacy addresses are
     * young by design, the stable address carries the history.
     */
    private fun addressAgeSeconds(): Long? {
        val network = currentNetwork ?: return null
        val ifname = (context.getSystemService(Context.CONNECTIVITY_SERVICE)
            as ConnectivityManager).getLinkProperties(network)?.interfaceName
            ?: return null
        val ifindex = NetworkInterface.getByName(ifname)?.index ?: return null
        val fd = Os.socket(AF_NETLINK, OsConstants.SOCK_DGRAM, NETLINK_ROUTE)
        try {
            // A stuck read must not wedge the stats poll.
            Os.setsockoptTimeval(
                fd, OsConstants.SOL_SOCKET, OsConstants.SO_RCVTIMEO,
                StructTimeval.fromMillis(500),
            )
            // nlmsghdr (16 bytes) + ifaddrmsg (8 bytes), AF_UNSPEC so one
            // dump carries both families. Sent unaddressed: an unconnected
            // netlink socket targets the kernel (portid 0) by default.
            val request = ByteBuffer.allocate(24).order(ByteOrder.nativeOrder())
            request.putInt(24)                       // nlmsg_len
            request.putShort(RTM_GETADDR.toShort())  // nlmsg_type
            request.putShort((NLM_F_REQUEST or NLM_F_DUMP).toShort())
            request.putInt(1)                        // nlmsg_seq
            request.putInt(0)                        // nlmsg_pid
            request.putLong(0)                       // ifaddrmsg, all zero
            request.flip()
            Os.write(fd, request)
            var bestV4: Long? = null
            var bestV6: Long? = null
            val response =
                ByteBuffer.allocate(64 * 1024).order(ByteOrder.nativeOrder())
            reading@ while (true) {
                response.clear()
                val read = Os.read(fd, response)
                if (read <= 0) break
                response.flip()
                var offset = 0
                while (offset + 16 <= read) {
                    val messageLength = response.getInt(offset)
                    if (messageLength < 16 || offset + messageLength > read) break
                    when (response.getShort(offset + 4).toInt()) {
                        NLMSG_DONE -> break@reading
                        NLMSG_ERROR -> return null
                        RTM_NEWADDR -> {
                            val age = parseAddressAge(
                                response, offset, messageLength, ifindex)
                            if (age != null) {
                                val (family, seconds) = age
                                if (family == OsConstants.AF_INET) {
                                    bestV4 = maxOf(bestV4 ?: 0, seconds)
                                } else {
                                    bestV6 = maxOf(bestV6 ?: 0, seconds)
                                }
                            }
                        }
                    }
                    offset += (messageLength + 3) and 3.inv()
                }
            }
            return bestV4 ?: bestV6
        } finally {
            Os.close(fd)
        }
    }

    /**
     * One RTM_NEWADDR message: the (family, age seconds) of its
     * IFA_CACHEINFO when it belongs to [ifindex] and is worth counting,
     * else null.
     */
    private fun parseAddressAge(
        buf: ByteBuffer,
        messageOffset: Int,
        messageLength: Int,
        ifindex: Int,
    ): Pair<Int, Long>? {
        // ifaddrmsg: family u8, prefixlen u8, flags u8, scope u8, index u32.
        val family = buf.get(messageOffset + 16).toInt() and 0xFF
        if (family != OsConstants.AF_INET && family != OsConstants.AF_INET6) {
            return null
        }
        if (buf.getInt(messageOffset + 20) != ifindex) return null
        var linkLocal = false
        var cstamp: Long? = null
        var attribute = messageOffset + 24
        val end = messageOffset + messageLength
        while (attribute + 4 <= end) {
            val attributeLength = buf.getShort(attribute).toInt() and 0xFFFF
            if (attributeLength < 4 || attribute + attributeLength > end) break
            when (buf.getShort(attribute + 2).toInt() and 0xFFFF) {
                // IFA_ADDRESS: only read to rule out fe80::/10.
                IFA_ADDRESS -> if (family == OsConstants.AF_INET6 &&
                    attributeLength >= 6 &&
                    buf.get(attribute + 4).toInt() and 0xFF == 0xFE &&
                    buf.get(attribute + 5).toInt() and 0xC0 == 0x80) {
                    linkLocal = true
                }
                // IFA_CACHEINFO: prefered, valid, cstamp, tstamp (u32 each).
                IFA_CACHEINFO -> if (attributeLength >= 20) {
                    cstamp = buf.getInt(attribute + 12).toLong() and 0xFFFFFFFFL
                }
            }
            attribute += (attributeLength + 3) and 3.inv()
        }
        val created = cstamp ?: return null
        if (linkLocal) return null
        val nowHundredths = SystemClock.uptimeMillis() / 10
        // u32 wrap-safe difference (cstamp wraps after ~497 days up).
        val seconds = ((nowHundredths - created) and 0xFFFFFFFFL) / 100
        return family to seconds
    }

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

    /**
     * The Bluetooth devices this kiosk holds a live link to right now
     * (issue #281): `connected` as the count, `devices` as their names, and
     * `enabled` for the adapter's own switch. `null` when Android will not
     * answer at all (no adapter, or the Nearby devices grant missing on
     * Android 12+), which is what keeps the sensor from existing on devices
     * that could only ever report unknown.
     *
     * Three sources, deduplicated by hardware address, because no single one
     * sees every link: bonded devices (the speaker, keyboard or headset a
     * person means by "connected"), the adapter's GATT tables (BLE links,
     * including any the Bluetooth proxy itself holds) and the classic
     * profile proxies (the public route to A2DP and headset connections,
     * which the bonded read misses whenever the hidden isConnected is
     * refused).
     */
    private fun bluetooth(): Map<String, Any?>? {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
            context.checkSelfPermission(android.Manifest.permission.BLUETOOTH_CONNECT)
            != PackageManager.PERMISSION_GRANTED) return null
        val manager = context.getSystemService(Context.BLUETOOTH_SERVICE)
            as? BluetoothManager ?: return null
        val adapter = manager.adapter ?: return null
        if (!adapter.isEnabled) {
            return mapOf("connected" to 0, "devices" to emptyList<String>(), "enabled" to false)
        }
        bindProfileProxies(adapter)
        val byAddress = LinkedHashMap<String, String>()
        fun add(device: BluetoothDevice) {
            val name = try {
                device.name
            } catch (e: Exception) {
                null
            }
            byAddress[device.address] = if (name.isNullOrBlank()) device.address else name
        }
        try {
            for (device in adapter.bondedDevices.orEmpty()) {
                if (isConnected(device)) add(device)
            }
        } catch (e: Exception) {
            // A ROM that refuses the bonded list still has the two reads below.
        }
        for (profile in intArrayOf(BluetoothProfile.GATT, BluetoothProfile.GATT_SERVER)) {
            try {
                for (device in manager.getConnectedDevices(profile)) add(device)
            } catch (e: Exception) {
                // Not every build answers for both tables.
            }
        }
        for (proxy in profileProxies.values) {
            try {
                for (device in proxy.connectedDevices) add(device)
            } catch (e: Exception) {
                // A proxy can outlive its service; the others still count.
            }
        }
        return mapOf(
            "connected" to byAddress.size,
            "devices" to byAddress.values.toList(),
            "enabled" to true,
        )
    }

    /**
     * Whether a bonded device currently holds a link, over the framework's
     * own isConnected. It is not public API and never has been, so the call
     * is reflective and a refusal reads as "not connected": the profile
     * proxies below then answer for everything but exotic profiles, which is
     * why they are bound at all.
     */
    private fun isConnected(device: BluetoothDevice): Boolean = try {
        BluetoothDevice::class.java.getMethod("isConnected").invoke(device) as? Boolean ?: false
    } catch (e: Throwable) {
        false
    }

    /**
     * Binds the classic profile proxies once and keeps them, so every read
     * afterwards is a plain synchronous connectedDevices call. Binding is
     * asynchronous, so the first read after a start can miss a classic
     * connection; the next poll has it.
     */
    private fun bindProfileProxies(adapter: BluetoothAdapter) {
        if (profilesRequested) return
        profilesRequested = true
        // Headset and A2DP are the two the platform lets an ordinary app
        // bind; the input-device profile is system-only, so keyboards and
        // mice are left to the bonded read above.
        val profiles = mutableListOf(BluetoothProfile.HEADSET, BluetoothProfile.A2DP)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            profiles.add(BluetoothProfile.HEARING_AID)
        }
        val listener = object : BluetoothProfile.ServiceListener {
            override fun onServiceConnected(profile: Int, proxy: BluetoothProfile) {
                profileProxies[profile] = proxy
            }

            override fun onServiceDisconnected(profile: Int) {
                profileProxies.remove(profile)
            }
        }
        for (profile in profiles) {
            try {
                adapter.getProfileProxy(context, listener, profile)
            } catch (e: Exception) {
                // A profile this build has no service for: skip it.
            }
        }
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
