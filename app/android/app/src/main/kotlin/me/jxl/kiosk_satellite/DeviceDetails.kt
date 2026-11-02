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
import android.hardware.display.DisplayManager
import android.net.ConnectivityManager
import android.os.BatteryManager
import android.net.Network
import android.net.NetworkCapabilities
import android.net.wifi.WifiManager
import android.os.Build
import android.os.Environment
import android.os.Handler
import android.os.HardwarePropertiesManager
import android.os.Looper
import android.os.Process
import android.os.StatFs
import android.os.SystemClock
import android.provider.Settings
import android.system.Os
import android.system.OsConstants
import android.system.StructTimeval
import android.util.DisplayMetrics
import android.util.Log
import android.view.Display
import android.view.Surface
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

/** One thermal zone as read from sysfs: its lowercased `type` and the raw
 *  `temp` value, null when the file could not be read. */
internal data class ThermalZone(val type: String, val raw: Long?)

/**
 * The hottest CPU thermal zone in °C, or null when none gives a usable
 * reading. Zones are matched by `type`, never by index: the numbering
 * differs per device (an S8 and an S8+ disagree). Values are milli-°C on
 * these SoCs; a few report plain °C, so both scales are accepted and
 * implausible readings dropped.
 *
 * Matching is two-tier (issue #138): zones naming "cpu" first, and only
 * when a device has none of those, zones whose type is a known SoC
 * spelling. Exynos names its clusters BIG/MID/LITTLE, Qualcomm has
 * tsens/cpuss, MediaTek mtkts* and soc_max, and a package sensor is the
 * same reading under a different label. Never both: on a device with real
 * cpu zones the extras could only replace a right answer with a hotter
 * wrong one.
 *
 * The tier is chosen by which zones exist, not by which ones happen to
 * read plausibly right now (issue #654). The Fire HD 8's mtktscpu returns
 * 0 on the odd read, and falling through to the MediaTek hints on that
 * poll picked mtkts_bts1, an unwired board sensor parked at 125000. The
 * sensor spiked to 125 °C for one update several times a day. A cpu zone
 * that reads nonsense this poll now yields null: the ESPHome sensor skips
 * the update so Home Assistant keeps the previous value, and the admin
 * pages show a gap.
 */
internal fun pickCpuTemp(zones: List<ThermalZone>): Double? {
    // Pseudo-zones and lookalike sensors. trip/limit report the constant
    // throttle threshold (105°C on Snapdragon phones), and the hottest-zone
    // pick would return it forever; the rest are real sensors of the wrong
    // thing (battery, radios, connector, case surface), several of which
    // sit inside the plausibility window below.
    val candidates = zones.filter { z -> NOT_CPU_ZONE.none { z.type.contains(it) } }
    val cpu = candidates.filter { it.type.contains("cpu") }
    val tier = if (cpu.isNotEmpty()) cpu
    else candidates.filter { z -> SOC_ZONE_HINTS.any { z.type.contains(it) } }
    var max: Double? = null
    for (z in tier) {
        val raw = z.raw ?: continue
        val c = if (raw > 1000) raw / 1000.0 else raw.toDouble()
        // 125 is where MediaTek parks an NTC input with nothing wired to
        // it, and no CPU runs there: the SoC shuts down first.
        if (c in 20.0..<125.0 && (max == null || c > max)) max = c
    }
    return max
}

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
    private val cpuWorker = MethodWorker("ks-cpu")
    private val linkWorker = MethodWorker("ks-link")
    private val bluetoothWorker = MethodWorker("ks-bluetooth")

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

    /**
     * Every battery broadcast, passed to Dart as a cue to read [plugged]
     * again. The intent is never opened here: a Lenovo TB311XU sends one
     * whose extras throw when read (a duplicate key in the bundle), and
     * battery_plus's receiver, which read them, crashed the process on every
     * battery change. A throw from [plugged] only fails that method call.
     */
    private val powerReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            try {
                channel.invokeMethod("powerChanged", null)
            } catch (e: Exception) {
                // The engine is gone; nothing to tell.
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
        try {
            // A protected system broadcast: no export flag needed.
            context.registerReceiver(powerReceiver, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
        } catch (e: Exception) {
            // The minute poll still covers charging.
        }
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "read" -> result.success(read())
                "uptime" -> result.success(uptime())
                "plugged" -> result.success(plugged())
                "battery" -> result.success(battery())
                // The Bluetooth links this device holds (issue #281). Binder
                // calls into the Bluetooth stack, so off the main thread: a
                // GATT service that never answered held it until the main
                // thread watchdog restarted the process.
                "bluetooth" -> bluetoothWorker.read(result) { bluetooth() }
                // The SSAID: stable per device + app signing key, surviving
                // reinstalls (a factory reset changes it). The seed for the
                // licensing Device ID — a value that has to outlive app data.
                "androidId" -> result.success(
                    Settings.Secure.getString(context.contentResolver, Settings.Secure.ANDROID_ID)
                )
                // The real Wi-Fi hardware address, or null where Android
                // hides it (issue #252). See WifiMac for the doors tried.
                "wifiMac" -> result.success(WifiMac.read(context))
                // The most the Java heap may grow to in this process: 80 MB
                // on an Echo Show, 512 MB on a phone. What ExoPlayer's
                // sample buffers count against, so the screensaver can
                // tell which videos it can afford to play.
                "javaHeapMax" -> result.success(Runtime.getRuntime().maxMemory())
                // Whether videos skip Flutter's texture for a SurfaceView
                // from the start (issue #894).
                "platformVideoFirst" -> result.success(platformVideoFirst())
                // Language tags as names in the app's language, for the text
                // to speech Language pickers. Engines write en_US as often as
                // en-US, so both parse.
                "languageNames" -> {
                    val tags = call.argument<List<String>>("tags") ?: emptyList()
                    val display = java.util.Locale.forLanguageTag(
                        call.argument<String>("display") ?: "en",
                    )
                    result.success(
                        tags.associateWith { tag ->
                            val name = java.util.Locale.forLanguageTag(tag.replace('_', '-'))
                                .getDisplayName(display)
                            if (name.isBlank() || name == tag) tag
                            else name.replaceFirstChar { it.titlecase(display) }
                        },
                    )
                }
                // Dozens of sysfs reads, polled every few seconds while an
                // admin tab is open — off the main thread, so a stats tick
                // can never cost the UI a frame.
                "cpu" -> cpuWorker.read(result) { cpu() }
                // Free and total memory alone, for the stats tick and its
                // history: the full read walks storage, the screen and the
                // WebView to answer a question asked every few seconds.
                "ram" -> result.success(ram())
                // The default network's transport and, on Wi-Fi, its signal.
                // Binder calls into system_server, so off the main thread:
                // a stalled system server must not cost the UI a frame.
                "link" -> linkWorker.read(result) { link() }
                else -> result.notImplemented()
            }
        }
    }

    fun dispose() {
        cpuWorker.shutdown()
        linkWorker.shutdown()
        bluetoothWorker.shutdown()
        channel.setMethodCallHandler(null)
        try {
            context.unregisterReceiver(aclReceiver)
        } catch (e: Exception) {
            // Never registered; nothing to undo.
        }
        try {
            context.unregisterReceiver(powerReceiver)
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
     * Seconds this process has been alive (`app`), seconds since the device
     * booted (`device`) and seconds since the default network last came up
     * (`network`, `null` while offline). The app and device clocks are
     * elapsedRealtime, so a wall-clock change cannot bend them.
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
            "device" to SystemClock.elapsedRealtime() / 1000,
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
     * The battery's charge, from the same sticky broadcast as [plugged]:
     * `present` is the kernel's own word on whether there is a battery at
     * all (EXTRA_PRESENT), and `level` the percent, null for a device
     * without a battery, one whose broadcast carries no level, or a level
     * outside 0..100 (issue #367). The BatteryManager capacity property the
     * battery_plus plugin reads answers Integer.MIN_VALUE for a battery the
     * kernel does not expose (0 on targets before Android 9), and the
     * plugin screens only -1, so a mains-powered box read "-2147483648%".
     * Null when the platform won't say, and the caller falls back.
     *
     * `temp` is the battery's own temperature in °C (EXTRA_TEMPERATURE, in
     * tenths), which needs no permission and no sysfs read, so it answers
     * on devices whose thermal zones the sandbox cannot see. A reading of
     * exactly zero or outside -20..90 °C is a HAL with no sensor behind it
     * and reads null. A battery at zero volts and zero degrees is not there
     * at all: a mains-powered LineageOS Echo Show 8 reports one present at
     * 100% with both at zero, so it counts as absent.
     */
    private fun battery(): Map<String, Any?>? {
        val intent = try {
            context.registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
        } catch (e: Exception) {
            null
        } ?: return null
        val tenths = intent.getIntExtra(BatteryManager.EXTRA_TEMPERATURE, 0)
        val volts = intent.getIntExtra(BatteryManager.EXTRA_VOLTAGE, 0)
        val present = intent.getBooleanExtra(BatteryManager.EXTRA_PRESENT, true) &&
            !(tenths == 0 && volts <= 0)
        val level = intent.getIntExtra(BatteryManager.EXTRA_LEVEL, -1)
        val scale = intent.getIntExtra(BatteryManager.EXTRA_SCALE, -1)
        val percent = if (!present || level < 0 || scale <= 0) {
            null
        } else {
            (level * 100 / scale).takeIf { it in 0..100 }
        }
        val temp = if (!present || tenths == 0 || tenths !in -200..900) {
            null
        } else {
            tenths / 10.0
        }
        return mapOf("present" to present, "level" to percent, "temp" to temp)
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

    /**
     * The panel's size, density and how it sits. `rotation` is the display's
     * turn from its natural orientation in degrees, which the size alone
     * cannot say: a panel mounted sideways reads landscape at 90.
     */
    private fun screen(): Map<String, Any?> {
        val wm = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
        val (width, height, density) = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            // maximumWindowMetrics, not currentWindowMetrics: the latter needs a
            // visual (Activity) context and throws from the application context
            // this now runs in. The maximum bounds are the full display — the
            // right answer for a fullscreen kiosk anyway.
            val b = wm.maximumWindowMetrics.bounds
            Triple(b.width(), b.height(), context.resources.displayMetrics.density)
        } else {
            @Suppress("DEPRECATION")
            val dm = DisplayMetrics().also { wm.defaultDisplay.getRealMetrics(it) }
            Triple(dm.widthPixels, dm.heightPixels, dm.density)
        }
        return mapOf(
            "width" to width,
            "height" to height,
            "density" to density,
            "orientation" to if (width >= height) "landscape" else "portrait",
            "rotation" to rotation(),
        )
    }

    /** The default display's rotation in degrees, or null where it cannot
     *  be read. DisplayManager rather than the context's display, which an
     *  application context does not have. */
    private fun rotation(): Int? = try {
        val dm = context.getSystemService(Context.DISPLAY_SERVICE) as DisplayManager
        when (dm.getDisplay(Display.DEFAULT_DISPLAY)?.rotation) {
            Surface.ROTATION_0 -> 0
            Surface.ROTATION_90 -> 90
            Surface.ROTATION_180 -> 180
            Surface.ROTATION_270 -> 270
            else -> null
        }
    } catch (e: Exception) {
        null
    }

    /**
     * The default network's transport, or null while offline. On Wi-Fi it
     * adds the signal (`rssi`, dBm), the negotiated link speed (`speedMbps`)
     * and the channel frequency (`frequencyMhz`, which says 2.4 or 5 GHz).
     * Android treats none of those as location data, so ACCESS_WIFI_STATE
     * covers them. The SSID and BSSID need a location grant and are left
     * out. Wi-Fi is checked before VPN because a VPN over Wi-Fi carries both
     * transports, and the radio is what explains a panel that drops out.
     * A value Android reports as unknown comes back null.
     */
    private fun link(): Map<String, Any?>? {
        val cm = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        val network = cm.activeNetwork ?: return null
        val caps = cm.getNetworkCapabilities(network) ?: return null
        val type = when {
            caps.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET) -> "ethernet"
            caps.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) -> "wifi"
            caps.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) -> "cellular"
            caps.hasTransport(NetworkCapabilities.TRANSPORT_VPN) -> "vpn"
            else -> "other"
        }
        if (type != "wifi") return mapOf("type" to type)
        // Deprecated at API 31 in favor of the callback's TransportInfo, but
        // still answered, and the one read that works from API 24 up.
        @Suppress("DEPRECATION")
        val info = (context.applicationContext.getSystemService(Context.WIFI_SERVICE)
            as? WifiManager)?.connectionInfo
        return mapOf(
            "type" to type,
            // -127 is WifiInfo.INVALID_RSSI.
            "rssi" to info?.rssi?.takeIf { it in -126..-1 },
            "speedMbps" to info?.linkSpeed?.takeIf { it > 0 },
            "frequencyMhz" to info?.frequency?.takeIf { it > 0 },
        )
    }

    /**
     * Live CPU load, clock and temperature, each `null` when the platform
     * won't answer.
     *
     * `usage` is how busy the cores were, see [cpuUsage]. It is never the
     * clock position: a governor that parks at a fast step while idle made
     * that read 60 to 100% on a nearly idle Raspberry Pi. `clock` is the
     * clock speed itself, in MHz, see [cpuClock].
     */
    private fun cpu(): Map<String, Any?> {
        val temp = cpuTemp()
        val out = mutableMapOf<String, Any?>(
            "usage" to cpuUsage(),
            "clock" to cpuClock(),
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

    /** The previous snapshot, so each report covers the window since the
     *  last one instead of blocking to measure a fresh window. */
    private var lastCpu: CpuSnapshot? = null

    /** Each source latches off the first time it cannot answer, so an
     *  enforcing policy is not asked again (and logs no denial) on every
     *  poll. A policy does not change while the process lives. */
    private var procStatBlocked = false
    private var halBlocked = false

    private val cpuCores: Int by lazy {
        File("/sys/devices/system/cpu")
            .listFiles { f -> f.name.matches(Regex("cpu[0-9]+")) }?.size
            ?: Runtime.getRuntime().availableProcessors()
    }

    private val ticksPerSecond: Long by lazy {
        Os.sysconf(OsConstants._SC_CLK_TCK).takeIf { it > 0 } ?: 100L
    }

    /**
     * One reading from the best source this device lets the app read.
     *
     * `/proc/stat` is the kernel's own busy count. Android's policy denies
     * it to apps (`proc_stat`), but a permissive ROM, such as LineageOS on
     * a Raspberry Pi, an Echo Show or a rooted Portal, lets it through.
     * Next is the thermal HAL's per-core count through
     * HardwarePropertiesManager, which reads the same counters but only
     * answers a device owner, and only where the vendor implemented it.
     * Last is cpuidle residency ([idleSnapshot]), which any app can read
     * but which reads a few points high, and high by more on kernels that
     * hotplug cores between polls, since offline time is not idle time.
     * With none of them, there is no load figure.
     */
    private fun cpuSnapshot(): CpuSnapshot? =
        procStatSnapshot() ?: halSnapshot() ?: idleSnapshot()

    private fun procStatSnapshot(): CpuBusySnapshot? {
        if (procStatBlocked) return null
        val text = try {
            File("/proc/stat").readText()
        } catch (e: Exception) {
            null
        }
        val busy = text?.let { CpuBusySnapshot.parseProcStat(it) }
        if (busy.isNullOrEmpty()) {
            procStatBlocked = true
            return null
        }
        return CpuBusySnapshot(
            SystemClock.elapsedRealtimeNanos(), System.nanoTime(), cpuCores, busy,
            ticksPerSecond = ticksPerSecond,
        )
    }

    private fun halSnapshot(): CpuBusySnapshot? {
        if (halBlocked || Build.VERSION.SDK_INT < Build.VERSION_CODES.N) return null
        val usages = try {
            context.getSystemService(HardwarePropertiesManager::class.java)?.cpuUsages
        } catch (e: SecurityException) {
            // Anything but a device owner.
            null
        } catch (e: Exception) {
            // A system server hiccup, not an answer: ask again next time.
            return null
        }
        val busy = HashMap<Int, Long>()
        val total = HashMap<Int, Long>()
        usages?.forEachIndexed { core, info ->
            // Null for an offline core.
            if (info == null) return@forEachIndexed
            busy[core] = info.active
            total[core] = info.total
        }
        if (usages.isNullOrEmpty() || total.isEmpty()) {
            halBlocked = true
            return null
        }
        return CpuBusySnapshot(
            SystemClock.elapsedRealtimeNanos(), System.nanoTime(), usages.size, busy, total,
        )
    }

    private fun idleSnapshot(): CpuIdleSnapshot? {
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
        // Android's System.nanoTime uses CLOCK_MONOTONIC, which excludes
        // suspend on every supported API level. elapsedRealtime includes
        // suspend and is only used to decide whether a sample is stale.
        return CpuIdleSnapshot(
            SystemClock.elapsedRealtimeNanos(), System.nanoTime(), idle, entries, online,
        )
    }

    /**
     * Utilization over the window since the previous call, from
     * [cpuSnapshot]'s source.
     *
     * The window covers awake time since the previous call (the admin polls
     * every few seconds, ESPHome once a minute). A first call, a window with
     * less than half a second awake or a sample older than five minutes
     * takes a short paired sample instead. Short suspends between regular
     * polls are excluded from the calculation too.
     */
    @Synchronized
    private fun cpuUsage(): Double? {
        var first = lastCpu ?: cpuSnapshot() ?: return null
        val age = SystemClock.elapsedRealtimeNanos() - first.elapsedNanos
        val awakeAge = System.nanoTime() - first.awakeNanos
        if (awakeAge < 500_000_000L || age > 300_000_000_000L) {
            first = cpuSnapshot() ?: return null
            try {
                Thread.sleep(500)
            } catch (_: InterruptedException) {
                return null
            }
        }
        val now = cpuSnapshot() ?: return null
        lastCpu = now
        return now.usageSince(first)
    }

    /**
     * The average current clock of the online cores in MHz, so a
     * big.LITTLE chip weighs each cluster by its core count. Offline cores
     * have no cpufreq to read and are left out.
     */
    private fun cpuClock(): Double? {
        val cores = File("/sys/devices/system/cpu")
            .listFiles { f -> f.name.matches(Regex("cpu[0-9]+")) } ?: return null
        var sum = 0L
        var n = 0
        for (core in cores) {
            val khz = readLong(File(core, "cpufreq/scaling_cur_freq")) ?: continue
            if (khz <= 0) continue
            sum += khz
            n++
        }
        return if (n == 0) null else sum / n / 1000.0
    }

    /** The hottest CPU thermal zone in °C, see [pickCpuTemp]. */
    private fun cpuTemp(): Double? {
        if (thermalBlocked) return null
        val zones = File("/sys/class/thermal")
            .listFiles { f -> f.name.startsWith("thermal_zone") }
        if (zones == null) {
            thermalBlocked = true
            return null
        }
        return pickCpuTemp(
            zones.mapNotNull { z ->
                val type = readText(File(z, "type"))?.lowercase() ?: return@mapNotNull null
                ThermalZone(type, readLong(File(z, "temp")))
            },
        )
    }

    /** Latched once /sys/class/thermal fails to enumerate: some OEM SELinux
     *  policies (Lenovo, issue #138) deny untrusted apps the directory read
     *  outright, and retrying on every stats poll would spray avc denials
     *  into logcat forever. Never unlatched: a policy does not change while
     *  the process lives. */
    private var thermalBlocked = false

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
            // "available" is a verdict only where the platform can give one
            // (API 26+): null below that means unknown, not missing.
            val available = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) pkg != null else null
            mapOf(
                "package" to pkg?.packageName, "version" to pkg?.versionName, "available" to available,
                "duraSpeed" to duraSpeed(),
            )
        } catch (e: Exception) {
            mapOf("package" to null, "version" to null, "available" to null, "duraSpeed" to duraSpeed())
        }
    }

    /**
     * MediaTek's DuraSpeed, where it is installed and switched on by the
     * vendor: a background app control that can refuse to start the
     * WebView's renderer service, which leaves the dashboard black with no
     * settings page to explain it (a Lenovo Tab M8 on Android 13).
     *
     * The vendor property decides where it exists. The global setting does
     * not: the Android 13 Tab M8 refused renderers with it at 0 until it
     * was set to 1 and back. A tablet with the package but no property (a
     * Lenovo Tab M8 on Android 10) has only the setting to go by, and
     * counts as on only when it says 1.
     */
    private fun duraSpeed(): Boolean {
        val installed = try {
            context.packageManager.getPackageInfo("com.mediatek.duraspeed", 0)
            true
        } catch (_: Exception) {
            false
        }
        if (!installed) return false
        val property = runCatching {
            Class.forName("android.os.SystemProperties")
                .getMethod("get", String::class.java, String::class.java)
                .invoke(null, "persist.vendor.duraspeed.app.on", "") as String
        }.getOrDefault("")
        if (property.isNotEmpty()) return property != "0"
        return runCatching {
            Settings.Global.getString(context.contentResolver, "setting.duraspeed.enabled")
        }.getOrNull() == "1"
    }

    /**
     * Whether videos should start on a platform view rather than Flutter's
     * texture (issue #894). Samsung's Exynos decoders hand out SBWC
     * compressed frames, and importing those into Flutter's GPU context
     * runs them through a gralloc decompression that leaks its output
     * buffers: gigabytes of EGL memory on a Galaxy Tab S9 FE within the
     * hour, never returned. A SurfaceView passes the frames straight to
     * SurfaceFlinger, which reads SBWC natively. `Build.SOC_MANUFACTURER`
     * exists from Android 12, which also covers every Exynos with SBWC that
     * Samsung still updates. `adb shell setprop debug.ks.video_platform_view 1`
     * forces the path on any device, to exercise it without one.
     *
     * Google Pixels start there too (issue #1024). Their decoders write a
     * 1080p stream into a 1088 row buffer and crop it, but Flutter draws the
     * whole buffer into the texture, so the 8 padding rows show as a green
     * line under the video. A SurfaceView applies the crop.
     */
    private fun platformVideoFirst(): Boolean {
        val forced = runCatching {
            Class.forName("android.os.SystemProperties")
                .getMethod("get", String::class.java, String::class.java)
                .invoke(null, "debug.ks.video_platform_view", "") as String
        }.getOrDefault("") == "1"
        val exynos = Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
            Build.SOC_MANUFACTURER.equals("Samsung", ignoreCase = true)
        val pixel = Build.MANUFACTURER.equals("Google", ignoreCase = true) &&
            Build.MODEL.startsWith("Pixel", ignoreCase = true)
        val first = forced || exynos || pixel
        if (first) {
            val reason = when {
                forced -> "forced"
                exynos -> "Exynos ${Build.SOC_MODEL}"
                else -> Build.MODEL
            }
            Log.i("DeviceDetails", "videos play on a platform view ($reason)")
        }
        return first
    }
}
