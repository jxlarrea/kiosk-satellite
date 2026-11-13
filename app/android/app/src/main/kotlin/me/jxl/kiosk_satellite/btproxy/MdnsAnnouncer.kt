package me.jxl.kiosk_satellite.btproxy

import android.content.Context
import android.net.wifi.WifiManager
import android.os.Handler
import android.os.Looper
import android.util.Log
import java.io.ByteArrayOutputStream
import java.net.DatagramPacket
import java.net.InetAddress
import java.net.Inet4Address
import java.net.MulticastSocket
import java.net.NetworkInterface
import me.jxl.kiosk_satellite.BoundedWorker

/**
 * Announces the proxy as `<name>._esphomelib._tcp.local` so Home Assistant's
 * ESPHome integration discovers it like any ESP32.
 *
 * Raw mDNS packets on a MulticastSocket, not NsdManager: on several of the
 * devices this app targets (Fire OS derivatives, old LineageOS builds)
 * NsdManager registration callbacks simply never fire, leaving publish state
 * unknowable. Unsolicited announcements every 30 seconds are dumb, cheap,
 * and deterministic; HA's zeroconf caches them, and a goodbye packet
 * (TTL 0) retracts the record on shutdown so a disabled proxy disappears
 * instead of lingering as an unavailable device.
 *
 * The TXT record must claim `platform=ESP32`: HA's discovery filter only
 * accepts ESPHome platforms, and `api_encryption` is what makes the config
 * flow ask for the key up front instead of failing a plaintext probe first.
 *
 * A WifiManager MulticastLock is held while announcing: most Android Wi-Fi
 * drivers drop multicast frames when the screen is off without it, which
 * silently unpublishes the proxy from a dark kiosk.
 */
internal class MdnsAnnouncer(
    private val context: Context,
    private val identity: ProxyIdentity,
    private val port: Int,
    private val onLog: (String) -> Unit = {},
    private val openSocket: (Int) -> MulticastSocket = { MulticastSocket(it) },
) {
    private companion object {
        const val TAG = "KsEsphome"
        val io = BoundedWorker("btproxy-mdns-tx", capacity = 32)
        const val ANNOUNCE_INTERVAL_MS = 30_000L
        val GROUP: InetAddress = InetAddress.getByName("224.0.0.251")
        const val MDNS_PORT = 5353
    }

    private val handler = Handler(Looper.getMainLooper())
    private var socket: MulticastSocket? = null
    private var multicastLock: WifiManager.MulticastLock? = null
    private var running = false
    private var generation = 0L
    // Logged on change only: announcements repeat every 30 seconds and the
    // ring log holds 50 lines. Which address Home Assistant is told to
    // connect to is THE question when discovery finds a device that then
    // refuses to connect (issue #239): a multi-interface device announcing
    // the wrong one is invisible without this line. Read and written on the
    // worker thread only.
    private var loggedAddress: String? = null

    private val announcer = object : Runnable {
        override fun run() {
            if (!running) return
            sendAnnouncement(ttl = 4500, hostTtl = 120)
            handler.postDelayed(this, ANNOUNCE_INTERVAL_MS)
        }
    }

    fun start() {
        if (running) return
        running = true
        runCatching {
            multicastLock = (context.applicationContext
                .getSystemService(Context.WIFI_SERVICE) as WifiManager)
                .createMulticastLock("ks:btproxy-mdns")
                .also { it.setReferenceCounted(false); it.acquire() }
        }
        val run = ++generation
        if (!io.execute {
            val opened = runCatching { openSocket(MDNS_PORT) }
                .getOrElse {
                    Log.w(TAG, "mDNS port 5353 unavailable, announcing from an ephemeral port")
                    runCatching { openSocket(0) }.getOrNull()
                }
            runCatching { opened?.timeToLive = 255 }
            handler.post {
                if (!running || generation != run) {
                    opened?.close()
                    return@post
                }
                if (opened == null) {
                    stop()
                    return@post
                }
                socket = opened
                handler.post(announcer)
                for (delay in listOf(1_000L, 2_000L)) {
                    handler.postDelayed({
                        if (running && generation == run) sendAnnouncement(4500, 120)
                    }, delay)
                }
            }
        }) {
            Log.w(TAG, "mDNS worker unavailable")
            stop()
        }
    }

    fun stop() {
        if (!running) return
        running = false
        ++generation
        handler.removeCallbacks(announcer)
        sendAnnouncement(ttl = 0, hostTtl = 0)
        val oldSocket = socket
        socket = null
        if (oldSocket != null) {
            val close = Runnable { runCatching { oldSocket.close() } }
            handler.postDelayed(close, 300)
            if (!io.execute { close.run(); handler.removeCallbacks(close) }) close.run()
        }
        multicastLock?.let { runCatching { if (it.isHeld) it.release() } }
        multicastLock = null
    }

    /** Re-announce immediately, e.g. after a network change. */
    fun nudge() {
        if (running) sendAnnouncement(4500, 120)
    }

    /**
     * The address lookup runs on the worker with the send, never on the
     * main thread: getifaddrs can sit in the kernel for a minute on some
     * devices (Echo Show 8 among them), and from the main looper that got
     * the process restarted by the main thread watchdog. A worker still
     * stuck in a lookup drops the announcements behind it once its backlog
     * is full, and the next one that fits goes out.
     */
    private fun sendAnnouncement(ttl: Int, hostTtl: Int) {
        val target = socket ?: return
        io.execute {
            val address = localIpv4() ?: run {
                Log.w(TAG, "mDNS announce skipped: no IPv4 yet")
                if (ttl != 0 && loggedAddress != "none") {
                    loggedAddress = "none"
                    onLog("mDNS announce skipped: no IPv4 address yet")
                }
                return@execute
            }
            if (ttl != 0) { // the goodbye packet is not an announcement
                val ip = address.hostAddress ?: address.toString()
                if (ip != loggedAddress) {
                    loggedAddress = ip
                    onLog("announcing $ip:$port to Home Assistant (mDNS)")
                }
            }
            val packet = buildPacket(address, ttl, hostTtl)
            try {
                if (!target.isClosed) target.send(DatagramPacket(packet, packet.size, GROUP, MDNS_PORT))
            } catch (e: Exception) {
                Log.w(TAG, "mDNS send failed: $e")
            }
        }
    }

    /**
     * The device's site-local IPv4, preferring wlan interfaces. Ethernet
     * docks and USB adapters still work through the general fallback.
     */
    private fun localIpv4(): Inet4Address? {
        val candidates = runCatching {
            NetworkInterface.getNetworkInterfaces().toList()
                .filter { it.isUp && !it.isLoopback }
                .sortedByDescending { it.name.startsWith("wlan") }
                .flatMap { nic -> nic.inetAddresses.toList() }
                .filterIsInstance<Inet4Address>()
                .filter { it.isSiteLocalAddress }
        }.getOrDefault(emptyList())
        return candidates.firstOrNull()
    }

    private fun buildPacket(address: Inet4Address, ttl: Int, hostTtl: Int): ByteArray {
        val instance = "${identity.name}._esphomelib._tcp.local"
        val service = "_esphomelib._tcp.local"
        val host = "${identity.name}.local"
        val out = ByteArrayOutputStream(512)

        // Header: response + authoritative, five answer records, no compression.
        out.u16(0); out.u16(0x8400); out.u16(0); out.u16(5); out.u16(0); out.u16(0)

        // PTR: service enumeration and instance pointer.
        out.name("_services._dns-sd._udp.local"); out.u16(12); out.u16(1); out.u32(ttl)
        out.lengthPrefixed { it.name(service) }
        out.name(service); out.u16(12); out.u16(1); out.u32(ttl)
        out.lengthPrefixed { it.name(instance) }

        // SRV with cache-flush: the record HA resolves to find host + port.
        out.name(instance); out.u16(33); out.u16(0x8001); out.u32(hostTtl)
        out.lengthPrefixed {
            it.u16(0); it.u16(0); it.u16(port); it.name(host)
        }

        // TXT with cache-flush.
        out.name(instance); out.u16(16); out.u16(0x8001); out.u32(ttl)
        out.lengthPrefixed { txt ->
            for (entry in txtEntries()) {
                val bytes = entry.toByteArray(Charsets.UTF_8)
                txt.write(bytes.size)
                txt.write(bytes)
            }
        }

        // A record with cache-flush.
        out.name(host); out.u16(1); out.u16(0x8001); out.u32(hostTtl)
        out.lengthPrefixed { it.write(address.address) }

        return out.toByteArray()
    }

    private fun txtEntries(): List<String> = listOf(
        "version=${identity.esphomeVersion}",
        "mac=${identity.macAddress.replace(":", "").lowercase()}",
        "platform=ESP32",
        "board=android",
        "network=wifi",
        "api_encryption=Noise_NNpsk0_25519_ChaChaPoly_SHA256",
        "friendly_name=${identity.friendlyName}",
        "project_name=${identity.projectName}",
        "project_version=${identity.projectVersion}",
    )

    private fun ByteArrayOutputStream.u16(v: Int) {
        write((v ushr 8) and 0xFF); write(v and 0xFF)
    }

    private fun ByteArrayOutputStream.u32(v: Int) {
        write((v ushr 24) and 0xFF); write((v ushr 16) and 0xFF)
        write((v ushr 8) and 0xFF); write(v and 0xFF)
    }

    private fun ByteArrayOutputStream.name(dotted: String) {
        for (label in dotted.split(".")) {
            val bytes = label.toByteArray(Charsets.UTF_8)
            write(bytes.size)
            write(bytes)
        }
        write(0)
    }

    private fun ByteArrayOutputStream.lengthPrefixed(fill: (ByteArrayOutputStream) -> Unit) {
        val body = ByteArrayOutputStream(64)
        fill(body)
        u16(body.size())
        body.writeTo(this)
    }
}
