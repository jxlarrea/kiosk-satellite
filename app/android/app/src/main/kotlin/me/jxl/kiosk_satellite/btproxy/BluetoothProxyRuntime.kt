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
        /** Run the BLE scanner and advertise Bluetooth-proxy capability.
         *  Off = pure ESPHome entity device: no radio use, no BT flags. */
        val bluetoothProxy: Boolean = true,
        /** Advertise and serve active GATT connections. */
        val connections: Boolean,
        /** Refuse connects for devices heard below this RSSI; 0 = no gate. */
        val minConnectRssi: Int = 0,
        /** The kiosk's own entities to serve over the API; empty = none. */
        val entities: List<EspEntity> = emptyList(),
        /** Where entity commands from Home Assistant land (objectId, value). */
        val onEntityCommand: (String, Any?) -> Unit = { _, _ -> },
    )

    @Volatile var isRunning = false
        private set

    /** Whether this run carries the Bluetooth proxy (the service
     *  notification says what is actually being served). */
    val bluetoothProxyActive: Boolean get() = engine != null

    private var server: ApiServer? = null
    private var engine: BleScanEngine? = null
    private var gattEngine: GattEngine? = null
    private var entityHub: EntityHub? = null
    private var announcer: MdnsAnnouncer? = null
    private var wakeLock: PowerManager.WakeLock? = null
    private val logRing = ArrayDeque<String>()
    private val nearby = NearbyDeviceTracker()

    @Synchronized
    fun start(context: Context, config: Config) {
        if (isRunning) return
        val appContext = context.applicationContext
        val identity = buildIdentity(appContext, config)

        // With the Bluetooth proxy off, no radio machinery exists at all:
        // the server is a pure entity device and never touches Bluetooth
        // (or its permissions).
        val scanEngine = if (config.bluetoothProxy) {
            BleScanEngine(
                appContext,
                onAdvertisement = { adv ->
                    server?.publishAdvertisement(adv)
                    nearby.observe(adv)
                },
                onStateChange = { state, mode ->
                    server?.reportScannerState(state, mode)
                },
            )
        } else {
            null
        }
        val hub = if (config.entities.isEmpty()) null
            else EntityHub(config.entities, config.onEntityCommand)
        val connections = if (config.bluetoothProxy && config.connections) {
            GattEngine(
                appContext,
                deliver = { event -> server?.deliverGattEvent(event) },
                scanPause = { busy -> scanEngine?.setGattBusy(busy) },
            )
        } else {
            null
        }
        val apiServer = ApiServer(
            identity = identity,
            bluetoothMac = syntheticMac(appContext, salt = "bt"),
            port = config.port,
            psk = config.psk,
            backend = object : ScannerBackend {
                override fun onScanDemand(mode: ScannerMode) {
                    scanEngine?.requestStart(mode)
                }
                override fun onScanRelease() {
                    scanEngine?.requestStop()
                }
            },
            log = ::log,
            bluetoothProxy = config.bluetoothProxy,
            gatt = connections,
            minConnectRssi = config.minConnectRssi,
            rssiOf = nearby::lastRssi,
            entities = hub,
        )

        try {
            apiServer.start()
        } catch (e: Exception) {
            Log.e(TAG, "API server failed to start: $e")
            scanEngine?.shutdown()
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
        gattEngine = connections
        entityHub = hub
        announcer = mdns
        isRunning = true
        log("ESPHome server started as ${identity.name} on :${apiServer.boundPort}" +
            (if (scanEngine != null) " (bluetooth proxy)" else "") +
            (if (connections != null)
                " (connections enabled, ${connections.connectionLimit} slots)" else "") +
            (if (hub != null) " (${config.entities.size} entities)" else ""))
    }

    /** Push one entity's new value; ignored while stopped or unknown ids. */
    fun updateEntityState(objectId: String, value: Any?) {
        entityHub?.updateState(objectId, value)
    }

    /** A fresh camera frame for sessions with an outstanding request. */
    fun publishCameraImage(jpeg: ByteArray) {
        server?.publishCameraImage(jpeg)
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
        gattEngine?.shutdown()
        gattEngine = null
        entityHub = null
        nearby.clear()
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
            "connections" to (s?.activeGattAddresses() ?: emptyList<String>()),
            "connectionSlots" to (gattEngine?.connectionLimit ?: 0),
            "lastAdvertisementAt" to (s?.lastReceivedAt?.get() ?: 0L),
            "log" to synchronized(logRing) { logRing.toList() },
        )
    }

    /** The nearby-device inventory, newest first. Empty while stopped. */
    fun nearbyDevices(): List<Map<String, Any?>> =
        if (isRunning) {
            nearby.snapshot(connected = server?.gattConnectedSet() ?: emptySet())
        } else {
            emptyList()
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
