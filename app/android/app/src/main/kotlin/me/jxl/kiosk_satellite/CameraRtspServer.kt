package me.jxl.kiosk_satellite

import java.io.BufferedInputStream
import java.io.ByteArrayOutputStream
import java.net.ServerSocket
import java.net.Socket
import java.net.InetSocketAddress
import java.security.MessageDigest
import java.util.concurrent.ArrayBlockingQueue
import java.util.concurrent.CopyOnWriteArrayList
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit
import kotlin.concurrent.thread

/** RTSP 1.0 and H.264 RTP over TCP, with one bounded queue per viewer.
 * No camera or codec work happens here. The owner supplies compressed access units.
 */
class CameraRtspServer(
    port: Int,
    private val username: String?,
    private val password: String,
    private val base64: (ByteArray) -> String,
    private val onDemand: (Boolean) -> Unit,
    private val onKeyFrame: () -> Unit,
    private val onDiagnostic: (String, String, Throwable?) -> Unit = { _, _, _ -> },
) {
    @Volatile private var running = true
    @Volatile private var sps: ByteArray? = null
    @Volatile private var pps: ByteArray? = null
    @Volatile private var videoError: String? = null
    @Volatile private var listenerError: String? = null
    val error: String? get() = listenerError ?: videoError
    val listening: Boolean get() = running && !server.isClosed && listenerError == null
    @Volatile var demand = false
        private set
    private val formatReady = Object()
    private val clients = CopyOnWriteArrayList<Client>()
    private val scheduler = Executors.newSingleThreadScheduledExecutor()
    private var idleTask: java.util.concurrent.ScheduledFuture<*>? = null
    private val server = ServerSocket().apply {
        reuseAddress = true
        try { bind(InetSocketAddress(port), 4) } catch (e: Exception) { close(); throw e }
    }
    val localPort: Int get() = server.localPort
    val clientCount: Int get() = clients.count { it.playing }
    val clientDetails: List<Map<String, Any>> get() = clients.map { it.details() }

    init {
        thread(name = "camera-rtsp-listener", isDaemon = true) {
            while (running) {
                try {
                    val socket = server.accept()
                    socket.reuseAddress = true
                    val client = synchronized(this) {
                        if (!running || clients.size >= 4) null
                        else Client(socket).also { clients.add(it) }
                    }
                    if (client == null) { socket.close(); continue }
                    thread(name = "camera-rtsp-client", isDaemon = true) { client.readRequests() }
                } catch (e: Exception) {
                    if (running) {
                        onDiagnostic("listener stopped", "port=$localPort", e)
                        listenerError = "RTSP listener stopped: ${e.message}"
                        fail(listenerError!!)
                        close()
                    }
                    break
                }
            }
        }
        scheduler.scheduleAtFixedRate({ clients.forEach { it.checkWriter() } }, 1, 1, TimeUnit.SECONDS)
    }

    @Synchronized private fun updateDemand() {
        if (!running) return
        idleTask?.cancel(false)
        if (clients.any { it.wantsVideo }) {
            if (!demand) {
                demand = true; videoError = null
                onDiagnostic("video demand", "active=true", null)
                onDemand(true)
            }
        } else if (demand) {
            idleTask = scheduler.schedule({
                synchronized(this) {
                    if (running && clients.none { it.wantsVideo }) {
                        demand = false
                        sps = null; pps = null
                        onDiagnostic("video demand", "active=false", null)
                        onDemand(false)
                    }
                }
            }, 2, TimeUnit.SECONDS)
        }
    }

    fun config(units: List<ByteArray>) {
        synchronized(formatReady) {
            for (unit in units) if (unit.isNotEmpty()) when (unit[0].toInt() and 31) {
                7 -> sps = unit
                8 -> pps = unit
            }
            // New parameter sets can recover video, never a failed listener.
            if (sps != null && pps != null) videoError = null
            formatReady.notifyAll()
        }
    }

    fun frame(units: List<ByteArray>, timeUs: Long) {
        val key = units.any { it.isNotEmpty() && it[0].toInt() and 31 == 5 }
        val headers = if (key) listOfNotNull(sps, pps) else emptyList()
        val frame = Frame(headers + units, timeUs * 90 / 1000, key)
        for (client in clients) client.offer(frame)
    }

    fun fail(message: String) {
        synchronized(formatReady) {
            videoError = message
            sps = null
            pps = null
            formatReady.notifyAll()
        }
        clients.filter { it.playing }.forEach { it.close() }
    }

    fun resetVideo(keepPendingClients: Boolean = false) {
        synchronized(formatReady) { sps = null; pps = null }
        clients.filter { !keepPendingClients || it.playing }.forEach { it.close() }
    }

    @Synchronized fun close() {
        running = false
        server.close()
        clients.forEach { it.close() }
        scheduler.shutdownNow()
        synchronized(formatReady) { formatReady.notifyAll() }
        if (demand) { demand = false; onDemand(false) }
    }

    private fun authorized(header: String?, method: String, uri: String, nonce: String): Boolean {
        if (username == null) return true
        if (header == null || !header.startsWith("Digest ")) return false
        val fields = Regex("""([a-zA-Z]+)="([^"]*)"|([a-zA-Z]+)=([^, ]+)""")
            .findAll(header.substring(7)).associate {
                if (it.groupValues[1].isNotEmpty()) it.groupValues[1] to it.groupValues[2]
                else it.groupValues[3] to it.groupValues[4]
            }
        if (fields["username"] != username || fields["realm"] != "Kiosk Satellite" ||
            fields["nonce"] != nonce || fields["uri"] != uri || fields.containsKey("qop") ||
            (fields["algorithm"] != null && fields["algorithm"] != "MD5")) return false
        val expected = md5("${md5("$username:Kiosk Satellite:$password")}:$nonce:${md5("$method:$uri")}")
        return MessageDigest.isEqual(expected.toByteArray(), (fields["response"] ?: "").lowercase().toByteArray())
    }

    private fun md5(text: String) = MessageDigest.getInstance("MD5").digest(text.toByteArray())
        .joinToString("") { "%02x".format(it.toInt() and 255) }

    private data class Frame(val units: List<ByteArray>, val timestamp: Long, val key: Boolean)

    private inner class Client(private val socket: Socket) {
        private val connectedNs = System.nanoTime()
        @Volatile private var userAgent = ""
        @Volatile var playing = false
        @Volatile private var open = true
        @Volatile private var gotKey = false
        @Volatile var wantsVideo = false
        private var setup = false
        private val nonce = java.util.UUID.randomUUID().toString()
        private var lastReportNs = 0L
        private var packets = 0L
        private var octets = 0L
        @Volatile private var writeStartedNs = 0L
        private var sequence = 0
        private var channel = 0
        private val queue = ArrayBlockingQueue<Frame>(20)
        private val output = socket.getOutputStream()
        private val input = BufferedInputStream(socket.getInputStream())
        private val session = java.util.UUID.randomUUID().toString().replace("-", "")
        private val ssrc = session.hashCode()

        fun details(): Map<String, Any> = mapOf(
            "id" to session,
            "ip" to (socket.inetAddress.hostAddress ?: "Unknown"),
            "port" to socket.port,
            "userAgent" to userAgent,
            "playing" to playing,
            "transport" to "TCP",
            "connectedSeconds" to TimeUnit.NANOSECONDS.toSeconds(System.nanoTime() - connectedNs),
        )

        fun offer(frame: Frame) {
            if (!playing) return
            if (!gotKey && !frame.key) return
            gotKey = true
            if (!queue.offer(frame)) { close() }
        }

        private fun line(): String? {
            val bytes = ByteArrayOutputStream()
            while (open) {
                val b = input.read()
                if (b < 0) return null
                if (b == 36 && bytes.size() == 0) {
                    input.read()
                    val high = input.read(); val low = input.read()
                    if (high < 0 || low < 0) return null
                    var remaining = high * 256 + low
                    while (remaining-- > 0) if (input.read() < 0) return null
                    continue
                }
                if (b == 10) return bytes.toString("UTF-8").trimEnd('\r')
                bytes.write(b)
                check(bytes.size() < 8192)
            }
            return null
        }

        fun readRequests() {
            socket.tcpNoDelay = true
            socket.soTimeout = 15_000
            try {
                while (open) {
                    val request = line() ?: break
                    if (request.isBlank()) continue
                    val parts = request.split(' ')
                    if (parts.size != 3 || parts[2] != "RTSP/1.0") break
                    val method = parts[0]
                    val uri = parts[1]
                    val headers = mutableMapOf<String, String>()
                    var headerBytes = 0
                    while (true) {
                        val h = line() ?: break
                        if (h.isEmpty()) break
                        headerBytes += h.length
                        check(headerBytes <= 16384 && headers.size < 64)
                        val colon = h.indexOf(':')
                        if (colon > 0) headers[h.substring(0, colon).lowercase()] = h.substring(colon + 1).trim()
                    }
                    headers["user-agent"]?.let { value ->
                        userAgent = value.filter { !it.isISOControl() }.take(160)
                    }
                    val length = headers["content-length"]?.let { it.toIntOrNull() ?: -1 } ?: 0
                    check(length in 0..8192)
                    repeat(length) { check(input.read() >= 0) }
                    val cseq = headers["cseq"]?.takeIf { it.matches(Regex("[0-9]{1,10}")) } ?: break
                    if (method != "OPTIONS" && !authorized(headers["authorization"], method, uri, nonce)) {
                        reply(cseq, "WWW-Authenticate: Digest realm=\"Kiosk Satellite\", nonce=\"$nonce\", algorithm=MD5\r\n", code = "401 Unauthorized")
                        continue
                    }
                    val path = if (uri == "*") "*" else try { java.net.URI(uri).path.trimEnd('/') } catch (_: Exception) { "" }
                    if (method != "OPTIONS" && path != "/camera" && path != "/camera/trackID=0") {
                        reply(cseq, code = "404 Not Found"); continue
                    }
                    if (method in listOf("PLAY", "GET_PARAMETER", "TEARDOWN") &&
                        (!setup || headers["session"]?.substringBefore(';') != session)) {
                        reply(cseq, code = "454 Session Not Found"); continue
                    }
                    when (method) {
                        "OPTIONS" -> reply(cseq, "Public: OPTIONS, DESCRIBE, SETUP, PLAY, TEARDOWN, GET_PARAMETER\r\n")
                        "DESCRIBE" -> {
                            wantsVideo = true
                            updateDemand()
                            val deadline = System.nanoTime() + 15_000_000_000L
                            synchronized(formatReady) {
                                while (running && open && (sps == null || pps == null) && error == null && System.nanoTime() < deadline) {
                                    formatReady.wait(100)
                                }
                            }
                            val a = sps; val b = pps
                            if (a == null || b == null) { reply(cseq, code = "503 Service Unavailable"); break }
                            val profile = a.drop(1).take(3).joinToString("") { "%02x".format(it.toInt() and 255) }
                            val body = "v=0\r\no=- 0 0 IN IP4 127.0.0.1\r\ns=Kiosk Satellite camera\r\nt=0 0\r\n" +
                                "a=control:*\r\nm=video 0 RTP/AVP 96\r\nc=IN IP4 0.0.0.0\r\n" +
                                "a=rtpmap:96 H264/90000\r\na=fmtp:96 packetization-mode=1;profile-level-id=$profile;" +
                                "sprop-parameter-sets=${base64(a)},${base64(b)}\r\n" +
                                "a=control:trackID=0\r\n"
                            val base = java.net.URI(uri)
                            val clean = java.net.URI(base.scheme, null, base.host, base.port, "/camera/", null, null)
                            reply(cseq, "Content-Type: application/sdp\r\nContent-Base: $clean\r\n", body)
                        }
                        "SETUP" -> {
                            val transport = headers["transport"] ?: ""
                            if (!transport.contains("RTP/AVP/TCP")) { reply(cseq, code = "461 Unsupported Transport"); continue }
                            if (!wantsVideo || playing) { reply(cseq, code = "455 Method Not Valid in This State"); continue }
                            val channels = Regex("interleaved=(\\d+)-(\\d+)").find(transport)
                            channel = channels?.groupValues?.get(1)?.toIntOrNull() ?: 0
                            val second = channels?.groupValues?.get(2)?.toIntOrNull() ?: 1
                            if (channel !in 0..254 || second != channel + 1) { reply(cseq, code = "461 Unsupported Transport"); continue }
                            setup = true
                            reply(cseq, "Transport: RTP/AVP/TCP;unicast;interleaved=$channel-${channel + 1}\r\nSession: $session;timeout=60\r\n")
                        }
                        "PLAY" -> {
                            reply(cseq, "Session: $session;timeout=60\r\nRange: npt=0.000-\r\n")
                            if (!playing) {
                                socket.soTimeout = 120_000
                                playing = true; onKeyFrame()
                                thread(name = "camera-rtsp-send") { sendFrames() }
                            }
                        }
                        "GET_PARAMETER" -> reply(cseq, "Session: $session;timeout=60\r\n")
                        "TEARDOWN" -> { reply(cseq); break }
                        else -> reply(cseq, code = "405 Method Not Allowed")
                    }
                }
            } catch (_: Exception) { } finally { close() }
        }

        private fun reply(cseq: String, headers: String = "", body: String = "", code: String = "200 OK") {
            val bytes = body.toByteArray()
            synchronized(output) {
                writeStartedNs = System.nanoTime()
                output.write(("RTSP/1.0 $code\r\nCSeq: $cseq\r\n$headers" +
                    "Content-Length: ${bytes.size}\r\n\r\n").toByteArray())
                output.write(bytes); output.flush()
                writeStartedNs = 0L
            }
        }

        private fun sendFrames() {
            try {
                while (open) {
                    val frame = queue.poll(1, java.util.concurrent.TimeUnit.SECONDS) ?: continue
                    val units = frame.units.filter { it.isNotEmpty() }
                    if (System.nanoTime() - lastReportNs >= 5_000_000_000L) {
                        senderReport(frame.timestamp)
                        lastReportNs = System.nanoTime()
                    }
                    for ((index, unit) in units.withIndex()) {
                        val last = index == units.lastIndex
                        if (unit.size <= 1200) packet(unit, frame.timestamp, last)
                        else {
                            val indicator = (unit[0].toInt() and 0xe0) or 28
                            val type = unit[0].toInt() and 31
                            var offset = 1
                            while (offset < unit.size) {
                                val count = minOf(1198, unit.size - offset)
                                val end = offset + count == unit.size
                                val fragment = ByteArray(count + 2)
                                fragment[0] = indicator.toByte()
                                fragment[1] = (type or (if (offset == 1) 128 else 0) or (if (end) 64 else 0)).toByte()
                                unit.copyInto(fragment, 2, offset, offset + count)
                                packet(fragment, frame.timestamp, last && end)
                                offset += count
                            }
                        }
                    }
                }
            } catch (_: Exception) { } finally { close() }
        }

        private fun packet(payload: ByteArray, time: Long, marker: Boolean) {
            val length = payload.size + 12
            val bytes = ByteArray(length + 4)
            bytes[0] = 36; bytes[1] = channel.toByte()
            bytes[2] = (length shr 8).toByte(); bytes[3] = length.toByte()
            bytes[4] = 0x80.toByte(); bytes[5] = (96 or if (marker) 128 else 0).toByte()
            bytes[6] = (sequence shr 8).toByte(); bytes[7] = sequence.toByte(); sequence++
            for (i in 0..3) {
                bytes[8 + i] = (time shr (24 - i * 8)).toByte()
                bytes[12 + i] = (ssrc shr (24 - i * 8)).toByte()
            }
            payload.copyInto(bytes, 16)
            synchronized(output) {
                writeStartedNs = System.nanoTime()
                output.write(bytes)
                writeStartedNs = 0L
            }
            packets++; octets += payload.size
        }

        fun checkWriter() {
            val started = writeStartedNs
            if (started != 0L && System.nanoTime() - started > 5_000_000_000L) close()
        }

        private fun senderReport(timestamp: Long) {
            val cname = "kiosk-$session".toByteArray()
            val sdesLength = (4 + 4 + 2 + cname.size + 1 + 3) / 4 * 4
            val packet = java.nio.ByteBuffer.allocate(4 + 28 + sdesLength)
            packet.put(36).put((channel + 1).toByte()).putShort((28 + sdesLength).toShort())
            packet.put(0x80.toByte()).put(200.toByte()).putShort(6).putInt(ssrc)
            val now = System.currentTimeMillis()
            packet.putInt((now / 1000 + 2_208_988_800L).toInt())
            packet.putInt(((now % 1000) * 0x1_0000_0000L / 1000).toInt())
            packet.putInt(timestamp.toInt()).putInt(packets.toInt()).putInt(octets.toInt())
            packet.put(0x81.toByte()).put(202.toByte()).putShort((sdesLength / 4 - 1).toShort())
            packet.putInt(ssrc).put(1).put(cname.size.toByte()).put(cname)
            synchronized(output) {
                writeStartedNs = System.nanoTime()
                output.write(packet.array())
                writeStartedNs = 0L
            }
        }

        fun close() {
            open = false; playing = false
            // Keep the client visible until its socket releases the port.
            // A simultaneous server restart must not miss a closing socket.
            try { socket.close() } catch (_: Exception) { }
            if (!clients.remove(this)) return
            queue.clear()
            updateDemand()
        }
    }

}
