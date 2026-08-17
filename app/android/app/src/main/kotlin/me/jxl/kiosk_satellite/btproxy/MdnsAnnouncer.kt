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
) {
    private companion object {
        const val TAG = "KsBtProxy"
        const val ANNOUNCE_INTERVAL_MS = 30_000L
        val GROUP: InetAddress = InetAddress.getByName("224.0.0.251")
        const val MDNS_PORT = 5353
    }

    private val handler = Handler(Looper.getMainLooper())
    private var socket: MulticastSocket? = null
    private var multicastLock: WifiManager.MulticastLock? = null
    private var running = false

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
        Thread({
            // Source port 5353 is not a nicety: RFC 6762 has receivers
            // silently ignore responses from any other port, and Home
            // Assistant's zeroconf does exactly that, so an announcer on an
            // ephemeral port is invisible however perfect its packets. The
            // fallback stays for devices where something already holds the
            // port exclusively; direct-IP setup still works there. TTL 255
            // is the mDNS convention (the default of 1 dies at the first
            // multicast reflector between VLANs).
            socket = runCatching { MulticastSocket(MDNS_PORT) }
                .getOrElse {
                    Log.w(TAG, "mDNS port 5353 unavailable, announcing from an ephemeral port")
                    runCatching { MulticastSocket() }.getOrNull()
                }
            runCatching { socket?.timeToLive = 255 }
            // Burst of three announcements a second apart (per RFC 6762),
            // then the steady 30s cadence.
            handler.post(announcer)
            handler.postDelayed({ if (running) sendAnnouncement(4500, 120) }, 1_000)
            handler.postDelayed({ if (running) sendAnnouncement(4500, 120) }, 2_000)
        }, "btproxy-mdns-init").start()
    }

    fun stop() {
        if (!running) return
        running = false
        handler.removeCallbacks(announcer)
        // Goodbye: TTL 0 retracts the records from every cache.
        sendAnnouncement(ttl = 0, hostTtl = 0)
        runCatching { socket?.close() }
        socket = null
        multicastLock?.let { runCatching { if (it.isHeld) it.release() } }
        multicastLock = null
    }

    /** Re-announce immediately, e.g. after a network change. */
    fun nudge() {
        if (running) sendAnnouncement(4500, 120)
    }

    private fun sendAnnouncement(ttl: Int, hostTtl: Int) {
        val address = localIpv4() ?: run {
            Log.w(TAG, "mDNS announce skipped: no IPv4 yet")
            return
        }
        val packet = buildPacket(address, ttl, hostTtl)
        Thread({
            try {
                socket?.send(DatagramPacket(packet, packet.size, GROUP, MDNS_PORT))
            } catch (e: Exception) {
                Log.w(TAG, "mDNS send failed: $e")
            }
        }, "btproxy-mdns-tx").start()
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
