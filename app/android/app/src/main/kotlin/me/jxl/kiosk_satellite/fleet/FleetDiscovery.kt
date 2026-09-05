package me.jxl.kiosk_satellite.fleet

import android.content.Context
import android.net.wifi.WifiManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.util.Log
import java.io.ByteArrayOutputStream
import java.net.DatagramPacket
import java.net.Inet4Address
import java.net.InetAddress
import java.net.MulticastSocket
import java.net.NetworkInterface

/**
 * How the kiosks on one network find each other, so the remote admin of
 * any of them can list the rest and jump to one.
 *
 * Each kiosk with its remote admin on announces
 * `ks-<id>._kiosk-satellite._tcp.local` over mDNS, with its name, version
 * and admin port in the TXT record, and listens for the same from the
 * others. Raw packets on a MulticastSocket, the way the ESPHome proxy
 * announces itself (btproxy/MdnsAnnouncer): NsdManager's callbacks never
 * fire on several of the devices this app runs on (Fire OS, old LineageOS
 * builds), and its browser is no better. Unsolicited announcements every
 * 30 seconds, a query on start that every running kiosk answers at once,
 * and a goodbye (TTL 0) on stop so a kiosk switched off leaves the list
 * instead of lingering until its records age out.
 *
 * Peers are keyed by the announcing kiosk's id, dropped when their
 * goodbye arrives or when three announcements in a row went missing. The
 * sender's address is what the peer is listed under: it is the address
 * the packet actually came from, which on a device with several
 * interfaces is the one that reaches back.
 *
 * A Wi-Fi MulticastLock is held while running: without it most Android
 * Wi-Fi drivers drop multicast frames with the screen off, which would
 * make a dark kiosk deaf to the others and invisible to them.
 */
class FleetDiscovery(
    private val context: Context,
    private val onChange: (Snapshot) -> Unit,
) {
    data class Peer(
        val id: String,
        val name: String,
        val version: String,
        val address: String,
        val port: Int,
        val seenAt: Long,
    ) {
        fun toMap(): Map<String, Any?> = mapOf(
            "id" to id,
            "name" to name,
            "version" to version,
            "address" to address,
            "port" to port,
        )
    }

    /**
     * This kiosk as it announces itself, and everyone else heard.
     * `listening` is whether the socket got port 5353, which is what
     * hearing anyone takes; it is known once the socket thread has bound,
     * so it travels with the snapshot rather than the start call.
     */
    data class Snapshot(val self: Peer?, val peers: List<Peer>, val listening: Boolean) {
        fun toMap(): Map<String, Any?> = mapOf(
            "self" to self?.toMap(),
            "peers" to peers.map { it.toMap() },
            "listening" to listening,
        )
    }

    private companion object {
        const val TAG = "KsFleet"
        const val SERVICE = "_kiosk-satellite._tcp.local"
        const val ANNOUNCE_INTERVAL_MS = 30_000L
        // Three announcements missed and a peer is gone.
        const val PEER_TTL_MS = 100_000L
        // The record TTLs, the mDNS conventions: 75 minutes for the
        // service, 2 minutes for the host.
        const val RECORD_TTL = 4500
        const val HOST_TTL = 120
        val GROUP: InetAddress = InetAddress.getByName("224.0.0.251")
        const val MDNS_PORT = 5353
        const val TYPE_A = 1
        const val TYPE_PTR = 12
        const val TYPE_TXT = 16
        const val TYPE_SRV = 33
        const val TYPE_ANY = 255
    }

    private val handler = Handler(Looper.getMainLooper())
    private var socket: MulticastSocket? = null
    private var multicastLock: WifiManager.MulticastLock? = null
    @Volatile private var running = false

    /** Whether the socket got port 5353, which is what receiving takes. */
    var listening = false
        private set

    private val id: String = runCatching {
        Settings.Secure.getString(context.contentResolver, Settings.Secure.ANDROID_ID)
    }.getOrNull()?.takeIf { it.isNotBlank() } ?: "unknown"

    private val version: String = runCatching {
        context.packageManager.getPackageInfo(context.packageName, 0).versionName
    }.getOrNull() ?: "0"

    private var name: String = ""
    private var port: Int = 0
    private val peers = LinkedHashMap<String, Peer>()
    private var lastAnsweredAt = 0L

    private val instance get() = "ks-$id.$SERVICE"
    private val host get() = "ks-$id.local"

    private val announcer = object : Runnable {
        override fun run() {
            if (!running) return
            sendAnnouncement(RECORD_TTL, HOST_TTL)
            if (expire()) publish()
            handler.postDelayed(this, ANNOUNCE_INTERVAL_MS)
        }
    }

    fun start(name: String, port: Int) {
        this.name = name.ifBlank { Build.MODEL ?: "Kiosk Satellite" }
        this.port = port
        if (running) {
            // A rename or a port change: the next announcement carries it,
            // and it goes out now rather than at the tick.
            sendAnnouncement(RECORD_TTL, HOST_TTL)
            publish()
            return
        }
        running = true
        runCatching {
            multicastLock = (context.applicationContext
                .getSystemService(Context.WIFI_SERVICE) as WifiManager)
                .createMulticastLock("ks:fleet-mdns")
                .also { it.setReferenceCounted(false); it.acquire() }
        }
        Thread({
            // Port 5353 or nothing to hear: multicast answers go to 5353,
            // and a socket bound anywhere else only ever sends. The
            // ephemeral fallback keeps this kiosk announcing (the others
            // read the sender's address, not the port) even where something
            // holds 5353 exclusively.
            val s = runCatching { MulticastSocket(MDNS_PORT).also { listening = true } }
                .getOrElse {
                    Log.w(TAG, "mDNS port 5353 unavailable, announce only")
                    listening = false
                    runCatching { MulticastSocket() }.getOrNull()
                }
            if (s == null) {
                Log.w(TAG, "no multicast socket, fleet discovery off")
                return@Thread
            }
            runCatching { s.timeToLive = 255 }
            runCatching { @Suppress("DEPRECATION") s.joinGroup(GROUP) }
                .onFailure { Log.w(TAG, "joinGroup failed: $it") }
            socket = s
            if (listening) Thread(::receiveLoop, "fleet-mdns-rx").start()
            handler.post(announcer)
            // The burst of three a second apart per RFC 6762, and a query
            // so the kiosks already running answer now instead of at
            // their next tick.
            handler.postDelayed({ if (running) sendAnnouncement(RECORD_TTL, HOST_TTL) }, 1_000)
            handler.postDelayed({ if (running) sendAnnouncement(RECORD_TTL, HOST_TTL) }, 2_000)
            sendQuery()
            handler.post { publish() }
        }, "fleet-mdns-init").start()
    }

    fun stop() {
        if (!running) return
        running = false
        handler.removeCallbacks(announcer)
        sendAnnouncement(ttl = 0, hostTtl = 0)
        // After the goodbye left: the send runs on its own thread.
        handler.postDelayed({
            runCatching { socket?.close() }
            socket = null
        }, 300)
        multicastLock?.let { runCatching { if (it.isHeld) it.release() } }
        multicastLock = null
        synchronized(peers) { peers.clear() }
        publish()
    }

    /** Re-announce and ask again, e.g. after a network change. */
    fun nudge() {
        if (!running) return
        sendAnnouncement(RECORD_TTL, HOST_TTL)
        sendQuery()
    }

    fun snapshot(): Snapshot {
        val list = synchronized(peers) { peers.values.toList() }
        val self = if (!running) null else Peer(
            id = id,
            name = name,
            version = version,
            address = localIpv4()?.hostAddress ?: "",
            port = port,
            seenAt = System.currentTimeMillis(),
        )
        return Snapshot(self, list, listening && running)
    }

    private fun publish() {
        val snap = snapshot()
        handler.post { onChange(snap) }
    }

    /** Drops peers not heard from in [PEER_TTL_MS]; true when any went. */
    private fun expire(): Boolean {
        val cutoff = System.currentTimeMillis() - PEER_TTL_MS
        synchronized(peers) {
            val stale = peers.values.filter { it.seenAt < cutoff }.map { it.id }
            stale.forEach { peers.remove(it) }
            return stale.isNotEmpty()
        }
    }

    // ── Receiving ─────────────────────────────────────────────────────

    private fun receiveLoop() {
        val buf = ByteArray(9000)
        while (running) {
            val s = socket ?: break
            val packet = DatagramPacket(buf, buf.size)
            try {
                s.receive(packet)
            } catch (e: Exception) {
                if (running) Log.w(TAG, "receive failed: $e")
                break
            }
            try {
                handle(packet)
            } catch (e: Exception) {
                Log.w(TAG, "bad mDNS packet: $e")
            }
        }
    }

    private fun handle(packet: DatagramPacket) {
        val r = DnsReader(packet.data, packet.offset, packet.length)
        r.u16() // transaction id
        val flags = r.u16()
        val qd = r.u16(); val an = r.u16(); val ns = r.u16(); val ar = r.u16()
        val isResponse = flags and 0x8000 != 0
        if (!isResponse) {
            // A kiosk starting up asks for the service; answer, at most
            // once a second, so a burst of queries is one announcement.
            var asked = false
            repeat(qd) {
                val qname = r.name()
                val qtype = r.u16(); r.u16()
                if ((qtype == TYPE_PTR || qtype == TYPE_ANY) && qname.equals(SERVICE, true)) {
                    asked = true
                }
            }
            if (asked) {
                val now = System.currentTimeMillis()
                if (now - lastAnsweredAt > 1_000) {
                    lastAnsweredAt = now
                    handler.postDelayed({ if (running) sendAnnouncement(RECORD_TTL, HOST_TTL) }, 200)
                }
            }
            return
        }
        repeat(qd) { r.name(); r.u16(); r.u16() }
        // One packet, every record it carries; a kiosk's announcement holds
        // its PTR, SRV, TXT and A together, so a single pass finds the set.
        val instances = LinkedHashSet<String>()
        val srv = HashMap<String, Pair<Int, String>>()
        val txt = HashMap<String, Map<String, String>>()
        val ttls = HashMap<String, Int>()
        val addresses = HashMap<String, String>()
        repeat(an + ns + ar) {
            val rname = r.name()
            val rtype = r.u16(); r.u16()
            val ttl = r.u32()
            val rdlen = r.u16()
            val end = r.pos + rdlen
            when (rtype) {
                TYPE_PTR -> if (rname.equals(SERVICE, true)) {
                    val target = r.name()
                    instances.add(target.lowercase())
                    ttls[target.lowercase()] = ttl
                }
                TYPE_SRV -> {
                    r.u16(); r.u16()
                    val p = r.u16()
                    val target = r.name()
                    srv[rname.lowercase()] = p to target.lowercase()
                    ttls[rname.lowercase()] = ttl
                }
                TYPE_TXT -> {
                    val entries = HashMap<String, String>()
                    while (r.pos < end) {
                        val len = r.u8()
                        val entry = r.bytes(len).toString(Charsets.UTF_8)
                        val eq = entry.indexOf('=')
                        if (eq > 0) entries[entry.substring(0, eq)] = entry.substring(eq + 1)
                    }
                    txt[rname.lowercase()] = entries
                }
                TYPE_A -> if (rdlen == 4) {
                    val b = r.bytes(4)
                    addresses[rname.lowercase()] =
                        "${b[0].toInt() and 0xFF}.${b[1].toInt() and 0xFF}.${b[2].toInt() and 0xFF}.${b[3].toInt() and 0xFF}"
                }
            }
            r.pos = end
        }
        val own = instance.lowercase()
        var changed = false
        val now = System.currentTimeMillis()
        val suffix = ".$SERVICE"
        for (inst in instances + srv.keys + txt.keys) {
            if (!inst.endsWith(suffix) || inst == own) continue
            val record = srv[inst] ?: continue
            val entries = txt[inst] ?: continue
            val peerId = entries["id"] ?: inst.removeSuffix(suffix).removePrefix("ks-")
            val ttl = ttls[inst] ?: RECORD_TTL
            synchronized(peers) {
                if (ttl == 0) {
                    if (peers.remove(peerId) != null) changed = true
                } else {
                    val sender = (packet.address as? Inet4Address)?.hostAddress
                    val address = sender ?: addresses[record.second] ?: return
                    val peer = Peer(
                        id = peerId,
                        name = entries["name"] ?: inst.removeSuffix(suffix),
                        version = entries["version"] ?: "",
                        address = address,
                        port = entries["port"]?.toIntOrNull() ?: record.first,
                        seenAt = now,
                    )
                    val before = peers[peerId]
                    peers[peerId] = peer
                    if (before == null || before.copy(seenAt = 0) != peer.copy(seenAt = 0)) {
                        changed = true
                    }
                }
            }
        }
        if (changed) publish()
    }

    /** A cursor over one DNS message, with name decompression. */
    private class DnsReader(private val buf: ByteArray, private val start: Int, length: Int) {
        var pos = start
        private val end = start + length

        fun u8(): Int {
            if (pos >= end) throw IndexOutOfBoundsException("dns")
            return buf[pos++].toInt() and 0xFF
        }
        fun u16(): Int = (u8() shl 8) or u8()
        fun u32(): Int = (u16() shl 16) or u16()
        fun bytes(n: Int): ByteArray {
            if (pos + n > end) throw IndexOutOfBoundsException("dns")
            return buf.copyOfRange(pos, pos + n).also { pos += n }
        }

        fun name(): String {
            val labels = ArrayList<String>()
            var p = pos
            var jumped = false
            var hops = 0
            while (true) {
                if (p >= end) throw IndexOutOfBoundsException("dns name")
                val len = buf[p].toInt() and 0xFF
                when {
                    len == 0 -> { p++; break }
                    len and 0xC0 == 0xC0 -> {
                        if (p + 1 >= end) throw IndexOutOfBoundsException("dns pointer")
                        val target = start + (((len and 0x3F) shl 8) or (buf[p + 1].toInt() and 0xFF))
                        if (!jumped) pos = p + 2
                        jumped = true
                        p = target
                        if (++hops > 32) throw IllegalStateException("dns pointer loop")
                    }
                    else -> {
                        p++
                        if (p + len > end) throw IndexOutOfBoundsException("dns label")
                        labels.add(String(buf, p, len, Charsets.UTF_8))
                        p += len
                    }
                }
            }
            if (!jumped) pos = p
            return labels.joinToString(".")
        }
    }

    // ── Sending ───────────────────────────────────────────────────────

    private fun send(packet: ByteArray) {
        Thread({
            try {
                socket?.send(DatagramPacket(packet, packet.size, GROUP, MDNS_PORT))
            } catch (e: Exception) {
                Log.w(TAG, "mDNS send failed: $e")
            }
        }, "fleet-mdns-tx").start()
    }

    private fun sendQuery() {
        val out = ByteArrayOutputStream(64)
        out.u16(0); out.u16(0); out.u16(1); out.u16(0); out.u16(0); out.u16(0)
        out.name(SERVICE); out.u16(TYPE_PTR); out.u16(1)
        send(out.toByteArray())
    }

    private fun sendAnnouncement(ttl: Int, hostTtl: Int) {
        val address = localIpv4() ?: run {
            if (ttl != 0) Log.w(TAG, "announce skipped: no IPv4 yet")
            return
        }
        send(buildAnnouncement(address, ttl, hostTtl))
    }

    /**
     * The device's site-local IPv4, preferring wlan interfaces. Ethernet
     * docks and USB adapters still work through the general fallback.
     */
    private fun localIpv4(): Inet4Address? = runCatching {
        NetworkInterface.getNetworkInterfaces().toList()
            .filter { it.isUp && !it.isLoopback }
            .sortedByDescending { it.name.startsWith("wlan") }
            .flatMap { nic -> nic.inetAddresses.toList() }
            .filterIsInstance<Inet4Address>()
            .firstOrNull { it.isSiteLocalAddress }
    }.getOrNull()

    private fun buildAnnouncement(address: Inet4Address, ttl: Int, hostTtl: Int): ByteArray {
        val out = ByteArrayOutputStream(512)
        // Header: response + authoritative, five answers, no compression.
        out.u16(0); out.u16(0x8400); out.u16(0); out.u16(5); out.u16(0); out.u16(0)

        out.name("_services._dns-sd._udp.local"); out.u16(TYPE_PTR); out.u16(1); out.u32(ttl)
        out.lengthPrefixed { it.name(SERVICE) }
        out.name(SERVICE); out.u16(TYPE_PTR); out.u16(1); out.u32(ttl)
        out.lengthPrefixed { it.name(instance) }

        out.name(instance); out.u16(TYPE_SRV); out.u16(0x8001); out.u32(hostTtl)
        out.lengthPrefixed { it.u16(0); it.u16(0); it.u16(port); it.name(host) }

        out.name(instance); out.u16(TYPE_TXT); out.u16(0x8001); out.u32(ttl)
        out.lengthPrefixed { t ->
            for (entry in listOf("id=$id", "name=$name", "version=$version", "port=$port")) {
                // A TXT entry is at most 255 bytes; a name past that is cut.
                val bytes = entry.toByteArray(Charsets.UTF_8).take(255).toByteArray()
                t.write(bytes.size)
                t.write(bytes)
            }
        }

        out.name(host); out.u16(TYPE_A); out.u16(0x8001); out.u32(hostTtl)
        out.lengthPrefixed { it.write(address.address) }
        return out.toByteArray()
    }

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
