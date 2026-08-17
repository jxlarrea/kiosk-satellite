package me.jxl.kiosk_satellite.btproxy

import android.annotation.SuppressLint
import android.content.Context
import android.os.PowerManager
import android.provider.Settings
import android.util.Log

/**
 * Owns the three moving parts of the Bluetooth proxy (API server, BLE scan
 * engine, mDNS announcer) and their glue. Process-wide singleton, started
 * and stopped by the bridge; [BluetoothProxyService] separately holds the
 * foreground-service exemption that keeps all of this scheduled while the
 * app is not on screen.
 *
 * A non-expiring partial wake lock is held for the whole run. The timeout-
 * plus-renewal pattern other proxies use has a hole: the renewal timer is
 * itself frozen by the sleep it is supposed to prevent, producing periodic
 * multi-minute blackouts. Kiosks are wall-powered; holding the lock
 * outright is the honest version.
 */
internal object BluetoothProxyRuntime {
    private const val TAG = "KsBtProxy"

    class Config(
        val friendlyName: String,
        val psk: ByteArray,
        val port: Int,
        val projectVersion: String,
    )

    @Volatile var isRunning = false
        private set

    private var server: ApiServer? = null
    private var engine: BleScanEngine? = null
    private var announcer: MdnsAnnouncer? = null
    private var wakeLock: PowerManager.WakeLock? = null
    private val logRing = ArrayDeque<String>()

    @Synchronized
    fun start(context: Context, config: Config) {
        if (isRunning) return
        val appContext = context.applicationContext
        val identity = buildIdentity(appContext, config)

        val scanEngine = BleScanEngine(
            appContext,
            onAdvertisement = { adv -> server?.publishAdvertisement(adv) },
            onStateChange = { state, mode -> server?.reportScannerState(state, mode) },
        )
        val apiServer = ApiServer(
            identity = identity,
            bluetoothMac = syntheticMac(appContext, salt = "bt"),
            port = config.port,
            psk = config.psk,
            backend = object : ScannerBackend {
                override fun onScanDemand(mode: ScannerMode) = scanEngine.requestStart(mode)
                override fun onScanRelease() = scanEngine.requestStop()
            },
            log = ::log,
        )

        try {
            apiServer.start()
        } catch (e: Exception) {
            Log.e(TAG, "API server failed to start: $e")
            scanEngine.shutdown()
            throw e
        }
        val mdns = MdnsAnnouncer(appContext, identity, apiServer.boundPort)
        mdns.start()

        runCatching {
            wakeLock = (appContext.getSystemService(Context.POWER_SERVICE) as PowerManager)
                .newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "ks:btproxy")
                .also { it.setReferenceCounted(false); it.acquire() }
        }

        server = apiServer
        engine = scanEngine
        announcer = mdns
        isRunning = true
        log("Bluetooth proxy started as ${identity.name} on :${apiServer.boundPort}")
    }

    @Synchronized
    fun stop() {
        if (!isRunning) return
        isRunning = false
        announcer?.stop()
        announcer = null
        engine?.shutdown()
        engine = null
        server?.stop()
        server = null
        wakeLock?.let { runCatching { if (it.isHeld) it.release() } }
        wakeLock = null
        log("Bluetooth proxy stopped")
    }

    fun status(): Map<String, Any> {
        val s = server
        val e = engine
        return mapOf(
            "running" to isRunning,
            "scanning" to (e?.isScanning ?: false),
            "received" to (s?.receivedCount?.get() ?: 0L),
            "forwarded" to (s?.forwardedCount?.get() ?: 0L),
            "subscribers" to (s?.hasAdvertisementSubscribers() ?: false),
            "lastAdvertisementAt" to (s?.lastReceivedAt?.get() ?: 0L),
            "log" to synchronized(logRing) { logRing.toList() },
        )
    }

    private fun buildIdentity(context: Context, config: Config): ProxyIdentity {
        val suffix = stableSuffix(context)
        return ProxyIdentity(
            name = "kiosk-satellite-$suffix",
            friendlyName = config.friendlyName,
            macAddress = syntheticMac(context, salt = "api"),
            // The version HA's repair system compares against its minimum
            // supported ESPHome release. Bump alongside app releases; HA
            // nags proxies that report versions it considers stale.
            esphomeVersion = "2026.8.0",
            model = android.os.Build.MODEL,
            manufacturer = android.os.Build.MANUFACTURER,
            projectName = "kiosk_satellite.bluetooth_proxy",
            projectVersion = config.projectVersion,
        )
    }

    /**
     * Stable per-install identity material. ANDROID_ID survives reboots and
     * app updates (it changes only on factory reset or reinstall with a new
     * signing key), which is exactly the stability mDNS names and the HA
     * device registry need.
     */
    @SuppressLint("HardwareIds")
    private fun stableSuffix(context: Context): String {
        val androidId = Settings.Secure.getString(
            context.contentResolver, Settings.Secure.ANDROID_ID) ?: "0000000000000000"
        return androidId.takeLast(6).lowercase()
    }

    /**
     * A synthetic MAC derived from the install identity: Android has not
     * exposed real MAC addresses to apps for years, and HA only needs a
     * stable unique key. Locally-administered unicast bits keep it out of
     * any real OUI space.
     */
    @SuppressLint("HardwareIds")
    private fun syntheticMac(context: Context, salt: String): String {
        val androidId = Settings.Secure.getString(
            context.contentResolver, Settings.Secure.ANDROID_ID) ?: "kiosk"
        val digest = java.security.MessageDigest.getInstance("SHA-256")
            .digest((androidId + salt).toByteArray())
        val bytes = digest.copyOfRange(0, 6)
        bytes[0] = ((bytes[0].toInt() and 0xFC) or 0x02).toByte()
        return bytes.joinToString(":") { "%02X".format(it) }
    }

    private fun log(line: String) {
        Log.i(TAG, line)
        synchronized(logRing) {
            logRing.addLast(line)
            while (logRing.size > 50) logRing.removeFirst()
        }
    }
}
