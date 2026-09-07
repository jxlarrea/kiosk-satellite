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
import java.net.NetworkInterface
import me.jxl.kiosk_satellite.fleet.MdnsPackets.DnsReader
import me.jxl.kiosk_satellite.fleet.MdnsPackets.buildHostAnswer
import me.jxl.kiosk_satellite.fleet.MdnsPackets.hostRecords
import me.jxl.kiosk_satellite.fleet.MdnsPackets.lengthPrefixed
import me.jxl.kiosk_satellite.fleet.MdnsPackets.name
import me.jxl.kiosk_satellite.fleet.MdnsPackets.u16
import me.jxl.kiosk_satellite.fleet.MdnsPackets.u32

/**
 * How the kiosks on one network find each other, so the remote admin of
 * any of them can list the rest and jump to one, and how one kiosk is
 * found by name.
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
 * The same announcer carries the kiosk's hostname (issue #470): an A
 * record for `<hostname>.local`, announced with the rest and answered
 * when asked for. Answering is what makes the name usable from a
 * laptop: a resolver that caches nothing it did not ask for (Windows,
 * and macOS for a name it has not seen) sends a query for the A record
 * and expects an answer, which an announce-only publisher never gives.
 * How the answer is sent matters as much as sending one, see
 * [handleQuery]: a plain multicast reply never reached a MacBook or a
 * phone on a Wi-Fi network that filters multicast toward its clients,
 * while their queries reached the kiosk fine. The reply includes an
 * NSEC saying there is no AAAA, so IPv6 lookups can finish without a
 * timeout. The hostname part runs with Find other kiosks off too: the
 * service records and listening for peers follow that switch. The A
 * record and hostname conflict checks follow the remote admin.
 *
 * Peers are keyed by the announcing kiosk's id, dropped when their
 * goodbye arrives or when three announcements in a row went missing. The
 * sender's address is what the peer is listed under: it is the address
 * the packet actually came from, which on a device with several
 * interfaces is the one that reaches back. A peer announcing the same
 * hostname as this kiosk is reported in the snapshot: both answer, and a
 * browser lands on either.
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
        val host: String = "",
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
     * `hostClash` is the hostname another kiosk was heard answering to as
     * well, empty when none was.
     */
    data class Snapshot(
        val self: Peer?,
        val peers: List<Peer>,
        val listening: Boolean,
        val hostClash: String = "",
    ) {
        fun toMap(): Map<String, Any?> = mapOf(
            "self" to self?.toMap(),
            "peers" to peers.map { it.toMap() },
            "listening" to listening,
            "hostClash" to hostClash,
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
        const val TYPE_AAAA = 28
        const val TYPE_SRV = 33
        const val TYPE_ANY = 255
    }

    private val handler = Handler(Looper.getMainLooper())
    private var socket: MdnsSocket? = null
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
    /** The label this kiosk answers to as `<hostname>.local`; empty for none. */
    @Volatile private var hostname: String = ""
    /** Whether the service records go out and the others are listened for. */
    @Volatile private var fleet: Boolean = true
    @Volatile private var hostClash: String = ""
    private val peers = LinkedHashMap<String, Peer>()
    private var lastAnsweredAt = 0L
    private var lastHostAnsweredAt = 0L

    private val instance get() = "ks-$id.$SERVICE"
    private val host get() = "ks-$id.local"
    private val userHost get() = if (hostname.isEmpty()) "" else "$hostname.local"

    private val announcer = object : Runnable {
        override fun run() {
            if (!running) return
            sendAnnouncement(RECORD_TTL, HOST_TTL)
            if (expire()) publish()
            handler.postDelayed(this, ANNOUNCE_INTERVAL_MS)
        }
    }

    fun start(name: String, port: Int, hostname: String = "", fleet: Boolean = true) {
        this.name = name.ifBlank { Build.MODEL ?: "Kiosk Satellite" }
        this.port = port
        if (this.hostname != hostname) hostClash = ""
        this.hostname = hostname.lowercase()
        val fleetWas = this.fleet
        this.fleet = fleet
        if (running) {
            // A rename, a port change or a new hostname: the next
            // announcement carries it, and it goes out now rather than at
            // the tick. Fleet switched off mid-run: the service records
            // are retracted and the peers dropped.
            if (fleetWas && !fleet) {
                sendFleetGoodbye()
                synchronized(peers) { peers.clear() }
            }
            sendAnnouncement(RECORD_TTL, HOST_TTL)
            if (fleet && !fleetWas) sendQuery()
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
            val s = runCatching { MdnsSocket(MDNS_PORT).also { listening = true } }
                .getOrElse {
                    Log.w(TAG, "mDNS port 5353 unavailable, announce only")
                    listening = false
                    runCatching { MdnsSocket() }.getOrNull()
                }
            if (s == null) {
                Log.w(TAG, "no multicast socket, fleet discovery off")
                return@Thread
            }
            runCatching { s.timeToLive = 255 }
            runCatching { s.setUnicastTtl() }
                .onFailure { Log.w(TAG, "unicast TTL not set: $it") }
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
            if (fleet) sendQuery()
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
        hostClash = ""
        publish()
    }

    /** Re-announce and ask again, e.g. after a network change. */
    fun nudge() {
        if (!running) return
        sendAnnouncement(RECORD_TTL, HOST_TTL)
        if (fleet) sendQuery()
    }

    fun snapshot(): Snapshot {
        val list = synchronized(peers) { peers.values.toList() }
        val self = if (!running || !fleet) null else Peer(
            id = id,
            name = name,
            version = version,
            address = localIpv4()?.hostAddress ?: "",
            port = port,
            seenAt = System.currentTimeMillis(),
            host = hostname,
        )
        return Snapshot(self, list, listening && running, hostClash)
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
        val qid = r.u16()
        val flags = r.u16()
        val qd = r.u16(); val an = r.u16(); val ns = r.u16(); val ar = r.u16()
        val isResponse = flags and 0x8000 != 0
        if (!isResponse) {
            handleQuery(packet, r, qd, qid)
            return
        }
        val mine = userHost
        if (mine.isNotEmpty() && hostClash != hostname) {
            val localAddresses = localIpv4Addresses().mapNotNull { it.hostAddress }.toSet()
            val conflict = MdnsPackets.conflictingHostAddress(packet, mine, localAddresses)
            if (conflict != null) {
                Log.w(TAG, "$conflict also answers to $mine")
                hostClash = hostname
                publish()
            }
        }
        if (!fleet) return
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
                        host = entries["host"]?.lowercase() ?: "",
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

    /**
     * A query: for the fleet service, answered with an announcement (at
     * most once a second, so a burst of queries is one announcement); for
     * this kiosk's hostname or its fleet host, answered with the address.
     *
     * Three kinds of asker, three replies (RFC 6762 sections 5.4 and 6.7):
     *  - A query from a port other than 5353 is a legacy one, from a plain
     *    DNS resolver that happens to send to the multicast group (Android's
     *    own resolver for `.local` names does this, so does `dig`). It is
     *    answered unicast to the sender, with the query's id and question
     *    echoed, the TTL capped at ten seconds and no cache-flush bit, or
     *    the resolver throws the reply away as not matching its question.
     *  - A query with the unicast-response bit set (the first one macOS
     *    and iOS send for a name) is answered unicast to the sender's
     *    port 5353 as well as multicast. The unicast copy is what reaches
     *    a client on an access point that does not deliver multicast to
     *    it, which is common on Wi-Fi with multicast filtering on.
     *  - Anything else is answered multicast, at most once a second.
     */
    private fun handleQuery(packet: DatagramPacket, r: DnsReader, qd: Int, qid: Int) {
        var asked = false
        var wantsUnicast = false
        val hosts = LinkedHashSet<String>()
        val mine = userHost
        val fleetHost = host
        val questionsStart = r.pos
        repeat(qd) {
            val qname = r.name()
            val qtype = r.u16()
            val qclass = r.u16()
            if (fleet && (qtype == TYPE_PTR || qtype == TYPE_ANY) && qname.equals(SERVICE, true)) {
                asked = true
            }
            if (qtype == TYPE_A || qtype == TYPE_AAAA || qtype == TYPE_ANY) {
                var hit = false
                if (mine.isNotEmpty() && qname.equals(mine, true)) { hosts.add(mine); hit = true }
                if (fleet && qname.equals(fleetHost, true)) { hosts.add(fleetHost); hit = true }
                if (hit && qclass and 0x8000 != 0) wantsUnicast = true
            }
        }
        val questionsEnd = r.pos
        val now = System.currentTimeMillis()
        if (asked && now - lastAnsweredAt > 1_000) {
            lastAnsweredAt = now
            handler.postDelayed({ if (running) sendAnnouncement(RECORD_TTL, HOST_TTL) }, 200)
        }
        if (hosts.isEmpty()) return
        val legacy = packet.port != MDNS_PORT
        // Debug level: who asks for this kiosk by name is the first thing
        // to know when a name resolves from one machine and not another.
        Log.d(
            TAG,
            "query for ${hosts.joinToString()} from ${packet.address?.hostAddress}:${packet.port}" +
                (if (legacy) " (legacy)" else if (wantsUnicast) " (unicast reply)" else ""),
        )
        val address = localIpv4() ?: return
        if (legacy) {
            val questions = packet.data.copyOfRange(questionsStart, questionsEnd)
            send(buildHostAnswer(hosts, address, HOST_TTL, qid = qid, questions = questions, qd = qd, legacy = true),
                packet.address, packet.port)
            return
        }
        val answer = buildHostAnswer(hosts, address, HOST_TTL)
        if (wantsUnicast) send(answer, packet.address, MDNS_PORT)
        if (now - lastHostAnsweredAt >= 1_000) {
            lastHostAnsweredAt = now
            send(answer)
        }
    }

    // ── Sending ───────────────────────────────────────────────────────

    private fun send(packet: ByteArray, to: InetAddress = GROUP, port: Int = MDNS_PORT) {
        Thread({
            try {
                socket?.send(DatagramPacket(packet, packet.size, to, port))
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
        send(buildAnnouncement(address, ttl, hostTtl, fleet, userHost))
    }

    /** Retracts the service records alone; the hostname stays up. */
    private fun sendFleetGoodbye() {
        val address = localIpv4() ?: return
        send(buildAnnouncement(address, 0, 0, fleet = true, userHost = ""))
    }

    /**
     * The device's site-local IPv4, preferring wlan interfaces. Ethernet
     * docks and USB adapters still work through the general fallback.
     */
    private fun localIpv4(): Inet4Address? =
        localIpv4Addresses().firstOrNull { it.isSiteLocalAddress }

    private fun localIpv4Addresses(): List<Inet4Address> = runCatching {
        NetworkInterface.getNetworkInterfaces().toList()
            .filter { it.isUp && !it.isLoopback }
            .sortedByDescending { it.name.startsWith("wlan") }
            .flatMap { nic -> nic.inetAddresses.toList() }
            .filterIsInstance<Inet4Address>()
    }.getOrDefault(emptyList())

    /**
     * The unsolicited announcement: the fleet's five records when [fleet]
     * is on and the hostname's address and NSEC when [userHost] is set.
     * Neither and nothing goes out.
     */
    private fun buildAnnouncement(
        address: Inet4Address,
        ttl: Int,
        hostTtl: Int,
        fleet: Boolean,
        userHost: String,
    ): ByteArray {
        val body = ByteArrayOutputStream(512)
        var count = 0
        if (fleet) {
            body.name("_services._dns-sd._udp.local"); body.u16(TYPE_PTR); body.u16(1); body.u32(ttl)
            body.lengthPrefixed { it.name(SERVICE) }
            body.name(SERVICE); body.u16(TYPE_PTR); body.u16(1); body.u32(ttl)
            body.lengthPrefixed { it.name(instance) }

            body.name(instance); body.u16(TYPE_SRV); body.u16(0x8001); body.u32(hostTtl)
            body.lengthPrefixed { it.u16(0); it.u16(0); it.u16(port); it.name(host) }

            body.name(instance); body.u16(TYPE_TXT); body.u16(0x8001); body.u32(ttl)
            body.lengthPrefixed { t ->
                val entries = listOf("id=$id", "name=$name", "version=$version", "port=$port") +
                    (if (hostname.isEmpty()) emptyList() else listOf("host=$hostname"))
                for (entry in entries) {
                    // A TXT entry is at most 255 bytes; a name past that is cut.
                    val bytes = entry.toByteArray(Charsets.UTF_8).take(255).toByteArray()
                    t.write(bytes.size)
                    t.write(bytes)
                }
            }

            body.name(host); body.u16(TYPE_A); body.u16(0x8001); body.u32(hostTtl)
            body.lengthPrefixed { it.write(address.address) }
            count += 5
        }
        if (userHost.isNotEmpty()) {
            count += body.hostRecords(userHost, address, hostTtl)
        }
        val out = ByteArrayOutputStream(512 + body.size())
        // Header: response + authoritative, no compression.
        out.u16(0); out.u16(0x8400); out.u16(0); out.u16(count); out.u16(0); out.u16(0)
        body.writeTo(out)
        return out.toByteArray()
    }
}
