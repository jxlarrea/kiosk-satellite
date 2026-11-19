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
    private val audioEnabled: Boolean = false,
    private val onAudioDemand: (Boolean) -> Unit = {},
    private val onvif: CameraOnvifService? = null,
    private val snapshot: CameraOnvifSnapshot? = null,
    streamName: String = "Kiosk Satellite camera",
    private val tls: javax.net.ssl.SSLContext? = null,
) {
    private val sessionName = streamName.replace('\r', ' ').replace('\n', ' ')
    @Volatile private var running = true
    @Volatile private var sps: ByteArray? = null
    @Volatile private var pps: ByteArray? = null
    @Volatile private var videoError: String? = null
    @Volatile private var listenerError: String? = null
    val error: String? get() = listenerError ?: videoError
    val listening: Boolean get() = running && !server.isClosed && listenerError == null
    @Volatile var demand = false
        private set
    @Volatile var audioDemand = false
        private set
    private val formatReady = Object()
    private val clockNs = System.nanoTime()
    private val clockMs = System.currentTimeMillis()
    private val clients = CopyOnWriteArrayList<Client>()
    private val requestNotes = mutableMapOf<String, Long>()
    private val scheduler = Executors.newSingleThreadScheduledExecutor { task -> Thread(task, "ks-rtsp-scheduler").apply { isDaemon = true } }
    private var idleTask: java.util.concurrent.ScheduledFuture<*>? = null
    private val server = (tls?.serverSocketFactory?.createServerSocket() ?: ServerSocket()).apply {
        if (this is javax.net.ssl.SSLServerSocket) enabledProtocols = supportedProtocols.filter { it == "TLSv1.2" || it == "TLSv1.3" }.toTypedArray()
        reuseAddress = true
        try { bind(InetSocketAddress(port), 4) } catch (e: Exception) { close(); throw e }
    }
    val localPort: Int get() = server.localPort
    val clientCount: Int get() = clients.count { it.playing }
    val clientDetails: List<Map<String, Any>> get() = clients.filter { !it.http }.map { it.details() }

    init {
        thread(name = "camera-rtsp-listener", isDaemon = true) {
            while (running) {
                try {
                    val socket = server.accept()
                    socket.reuseAddress = true
                    val client = synchronized(this) {
                        if (!running || clients.size >= (if (onvif == null) 4 else 12)) null
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
        val audioWanted = audioEnabled && clients.any { it.playing && it.audioSetup }
        if (audioWanted != audioDemand) {
            audioDemand = audioWanted
            onAudioDemand(audioWanted)
        }
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
                7 -> { sps = unit; onvif?.updateParameterSet(unit) }
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

    fun audioFrame(bytes: ByteArray, timeUs: Long) {
        if (!audioDemand || bytes.isEmpty() || bytes.size > 8191) return
        val frame = Frame(listOf(bytes), timeUs * 16 / 1000, true, audio = true)
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
        clients.filter { !it.http && (!keepPendingClients || it.playing) }.forEach { it.close() }
    }

    /** Viewers reconnect for new parameter sets while the listening port stays open. */
    @Synchronized fun reconfigureVideo(width: Int, height: Int, fps: Int, bitrate: Int) {
        onvif?.updateVideo(width, height, fps, bitrate)
        resetVideo()
        idleTask?.cancel(false)
        synchronized(formatReady) { videoError = null }
        if (demand) { demand = false; onDemand(false) }
        if (audioDemand) { audioDemand = false; onAudioDemand(false) }
    }

    @Synchronized fun close() {
        running = false
        server.close()
        onvif?.close()
        clients.forEach { it.close() }
        scheduler.shutdownNow()
        synchronized(formatReady) { formatReady.notifyAll() }
        if (demand) { demand = false; onDemand(false) }
        if (audioDemand) { audioDemand = false; onAudioDemand(false) }
    }

    private fun authorized(header: String?, method: String, uri: String, nonce: String): Boolean {
        if (username == null) return true
        if (header == null || !header.startsWith("Digest ")) return false
        val fields = Regex("""([a-zA-Z]+)="([^"]*)"|([a-zA-Z]+)=([^, ]+)""")
            .findAll(header.substring(7)).associate {
                if (it.groupValues[1].isNotEmpty()) it.groupValues[1] to it.groupValues[2]
                else it.groupValues[3] to it.groupValues[4]
            }
        val digestUri = fields["uri"] ?: return false
        if (fields["username"] != username || fields["realm"] != "Kiosk Satellite" ||
            fields["nonce"] != nonce || !digestUriMatches(digestUri, method, uri) || fields.containsKey("qop") ||
            (fields["algorithm"] != null && fields["algorithm"] != "MD5")) return false
        val expected = md5("${md5("$username:Kiosk Satellite:$password")}:$nonce:${md5("$method:$digestUri")}")
        return MessageDigest.isEqual(expected.toByteArray(), (fields["response"] ?: "").lowercase().toByteArray())
    }

    private fun digestUriMatches(digestUri: String, method: String, uri: String): Boolean {
        if (sameResource(digestUri, uri)) return true
        // LIVE555 signs SETUP with the presentation URL instead of the track URL.
        // Accept only the same camera base so other resources cannot share a digest.
        if (method != "SETUP" || !(uri.endsWith("/camera/trackID=0") ||
                (audioEnabled && uri.endsWith("/camera/trackID=1")))) return false
        val base = uri.substringBeforeLast('/')
        return sameResource(digestUri, base) || sameResource(digestUri, "$base/")
    }

    // SecuritySpy signs with the request path instead of the absolute URL.
    private fun sameResource(digestUri: String, url: String): Boolean {
        if (digestUri == url) return true
        val path = try { java.net.URI(url).rawPath } catch (_: Exception) { null }
        return !path.isNullOrEmpty() && digestUri == path
    }

    /** Records each client request outcome once every few minutes, so polling NVRs do not flood the log. */
    private fun note(key: String, event: String, details: String) {
        val now = System.nanoTime()
        synchronized(requestNotes) {
            val last = requestNotes[key]
            if (last != null && now - last < 300_000_000_000L) return
            if (requestNotes.size >= 256) requestNotes.entries.removeAll { now - it.value >= 300_000_000_000L }
            if (requestNotes.size >= 256) return
            requestNotes[key] = now
        }
        onDiagnostic(event, details, null)
    }

    private fun md5(text: String) = MessageDigest.getInstance("MD5").digest(text.toByteArray())
        .joinToString("") { "%02x".format(it.toInt() and 255) }

    private data class Frame(val units: List<ByteArray>, val timestamp: Long, val key: Boolean, val audio: Boolean = false)

    private inner class Client(private val socket: Socket) {
        @Volatile var http = false
            private set
        private var identified = false
        private val connectedNs = System.nanoTime()
        @Volatile private var userAgent = ""
        private var requestMethod = ""
        private var requestPath = ""
        @Volatile var playing = false
        @Volatile private var open = true
        @Volatile private var gotKey = false
        @Volatile var wantsVideo = false
        private var setup = false
        @Volatile var audioSetup = false
        private var videoSetup = false
        private var audioChannel = 2
        private var audioSequence = 0
        private var audioPackets = 0L
        private var audioOctets = 0L
        private var audioReportNs = 0L
        private val nonce = java.util.UUID.randomUUID().toString()
        private var lastReportNs = 0L
        private var packets = 0L
        private var octets = 0L
        @Volatile private var writeStartedNs = 0L
        private var sequence = 0
        private var channel = 0
        private val queue = ArrayBlockingQueue<Frame>(40)
        private lateinit var output: java.io.OutputStream
        private lateinit var input: BufferedInputStream
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
            if (frame.audio) {
                if (!audioSetup) return
            } else {
                if (!videoSetup || (!gotKey && !frame.key)) return
                gotKey = true
            }
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
            // Inside the try: a server close() between accept() and this
            // thread's first line closes the socket, and the option setters
            // throw on a closed socket. Uncaught here, that took the process.
            try {
                socket.tcpNoDelay = true
                socket.soTimeout = 15_000
                (socket as? javax.net.ssl.SSLSocket)?.startHandshake()
                output = socket.getOutputStream()
                input = BufferedInputStream(socket.getInputStream())
                while (open) {
                    val request = line() ?: break
                    if (request.isBlank()) continue
                    val parts = request.split(' ')
                    if (parts.size != 3) break
                    if (!identified && onvif == null) {
                        http = parts[2] in listOf("HTTP/1.0", "HTTP/1.1")
                        identified = true
                    } else if (!identified) {
                        synchronized(this@CameraRtspServer) {
                            http = parts[2] in listOf("HTTP/1.0", "HTTP/1.1")
                            identified = true
                            if (!http && clients.count { it.identified && !it.http } > 4) close()
                        }
                    }
                    if (!open || (parts[2] != "RTSP/1.0" && !http)) break
                    val method = parts[0]
                    val uri = parts[1]
                    requestMethod = method
                    requestPath = if (uri == "*") "*" else try { java.net.URI(uri).path ?: "" } catch (_: Exception) { "" }
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
                    check(length in 0..(if (http) 65536 else 8192))
                    if (http) {
                        if (headers.containsKey("transfer-encoding")) {
                            httpReply(CameraOnvifService.Response("400 Bad Request", "")); break
                        }
                        if (headers["expect"]?.equals("100-continue", ignoreCase = true) == true) {
                            output.write("HTTP/1.1 100 Continue\r\n\r\n".toByteArray()); output.flush()
                        }
                        val body = ByteArray(length)
                        var offset = 0
                        while (offset < length) {
                            val count = input.read(body, offset, length - offset)
                            check(count > 0)
                            offset += count
                        }
                        if (onvif != null && snapshot != null && requestPath == CameraOnvifService.SNAPSHOT_PATH) {
                            serveSnapshot(snapshot, method, uri, headers["authorization"])
                            break
                        }
                        val response = when {
                            onvif == null -> CameraOnvifService.Response("404 Not Found", "")
                            method != "POST" -> CameraOnvifService.Response("405 Method Not Allowed", "")
                            else -> onvif.respond(uri, body, socket.localAddress.hostAddress ?: "127.0.0.1", localPort)
                        }
                        httpReply(response)
                        val operation = response.operation.ifEmpty { "$method $requestPath" }
                        note("onvif ${socket.inetAddress.hostAddress} $operation ${response.status}", "onvif request",
                            "client=${socket.inetAddress.hostAddress}, operation=$operation, status=${response.status}" +
                                (response.fault?.let { ", fault=$it" } ?: "") +
                                (if (userAgent.isNotEmpty()) ", userAgent=$userAgent" else ""))
                        break
                    }
                    repeat(length) { check(input.read() >= 0) }
                    val cseq = headers["cseq"]?.takeIf { it.matches(Regex("[0-9]{1,10}")) } ?: break
                    if (method != "OPTIONS" && !authorized(headers["authorization"], method, uri, nonce)) {
                        reply(cseq, "WWW-Authenticate: Digest realm=\"Kiosk Satellite\", nonce=\"$nonce\", algorithm=MD5\r\n", code = "401 Unauthorized")
                        continue
                    }
                    val path = if (uri == "*") "*" else try { java.net.URI(uri).path.trimEnd('/') } catch (_: Exception) { "" }
                    if (method != "OPTIONS" && path != "/camera" && path != "/camera/trackID=0" &&
                        !(audioEnabled && path == "/camera/trackID=1")) {
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
                            val body = "v=0\r\no=- 0 0 IN IP4 127.0.0.1\r\ns=$sessionName\r\nt=0 0\r\n" +
                                "a=control:*\r\nm=video 0 RTP/AVP 96\r\nc=IN IP4 0.0.0.0\r\n" +
                                "a=rtpmap:96 H264/90000\r\na=fmtp:96 packetization-mode=1;profile-level-id=$profile;" +
                                "sprop-parameter-sets=${base64(a)},${base64(b)}\r\n" +
                                "a=control:trackID=0\r\n" + if (audioEnabled) {
                                    "m=audio 0 RTP/AVP 97\r\nc=IN IP4 0.0.0.0\r\n" +
                                    "a=rtpmap:97 MPEG4-GENERIC/16000/1\r\n" +
                                    "a=fmtp:97 streamtype=5;profile-level-id=1;mode=AAC-hbr;config=1408;" +
                                    "sizeLength=13;indexLength=3;indexDeltaLength=3;constantDuration=1024\r\n" +
                                    "a=control:trackID=1\r\n"
                                } else ""
                            val base = java.net.URI(uri)
                            val clean = java.net.URI(base.scheme, null, base.host, base.port, "/camera/", null, null)
                            reply(cseq, "Content-Type: application/sdp\r\nContent-Base: $clean\r\n", body)
                        }
                        "SETUP" -> {
                            val transport = headers["transport"] ?: ""
                            if (!transport.contains("RTP/AVP/TCP")) { reply(cseq, code = "461 Unsupported Transport"); continue }
                            if (!wantsVideo || playing) { reply(cseq, code = "455 Method Not Valid in This State"); continue }
                            val channels = Regex("interleaved=(\\d+)-(\\d+)").find(transport)
                            val isAudio = path == "/camera/trackID=1"
                            val selectedChannel = channels?.groupValues?.get(1)?.toIntOrNull() ?: if (isAudio) 2 else 0
                            val second = channels?.groupValues?.get(2)?.toIntOrNull() ?: selectedChannel + 1
                            if (selectedChannel !in 0..254 || second != selectedChannel + 1 ||
                                (if (isAudio) videoSetup && kotlin.math.abs(selectedChannel - channel) < 2
                                 else audioSetup && kotlin.math.abs(selectedChannel - audioChannel) < 2)) { reply(cseq, code = "461 Unsupported Transport"); continue }
                            if (isAudio) { audioSetup = true; audioChannel = selectedChannel }
                            else { videoSetup = true; channel = selectedChannel }
                            setup = true
                            reply(cseq, "Transport: RTP/AVP/TCP;unicast;interleaved=$selectedChannel-${selectedChannel + 1}\r\nSession: $session;timeout=60\r\n")
                        }
                        "PLAY" -> {
                            reply(cseq, "Session: $session;timeout=60\r\nRange: npt=0.000-\r\n")
                            if (!playing) {
                                socket.soTimeout = 120_000
                                playing = true; onKeyFrame()
                                updateDemand()
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

        private fun httpReply(response: CameraOnvifService.Response) =
            httpReply(response.status, "application/soap+xml; charset=utf-8", response.body.toByteArray(Charsets.UTF_8))

        private fun httpReply(status: String, contentType: String, bytes: ByteArray, headers: String = "", body: Boolean = true) {
            writeStartedNs = System.nanoTime()
            output.write(("HTTP/1.1 $status\r\nContent-Type: $contentType\r\n$headers" +
                "Content-Length: ${bytes.size}\r\nConnection: close\r\n\r\n").toByteArray())
            if (body) output.write(bytes)
            output.flush()
            writeStartedNs = 0L
        }

        /** GET on the ONVIF snapshot URI: one JPEG of the current frame. */
        private fun serveSnapshot(snapshot: CameraOnvifSnapshot, method: String, uri: String, authorization: String?) {
            val client = socket.inetAddress.hostAddress
            val status = when {
                method != "GET" && method != "HEAD" -> {
                    httpReply("405 Method Not Allowed", "text/plain", ByteArray(0), "Allow: GET, HEAD\r\n"); "405"
                }
                !snapshot.authorized(authorization, method, uri) -> {
                    httpReply("401 Unauthorized", "text/plain", ByteArray(0),
                        "WWW-Authenticate: ${snapshot.challenge(snapshot.stale(authorization))}\r\n"); "401"
                }
                else -> {
                    val result = snapshot.take()
                    val jpeg = result.jpeg
                    if (jpeg != null) {
                        httpReply("200 OK", "image/jpeg", jpeg, "Cache-Control: no-store\r\n", body = method == "GET")
                        "200"
                    } else {
                        httpReply("503 Service Unavailable", "text/plain; charset=utf-8",
                            (result.error ?: "No frame is available").toByteArray(), "Retry-After: 5\r\n")
                        "503, error=${result.error}"
                    }
                }
            }
            note("onvif $client snapshot $status", "onvif request",
                "client=$client, operation=$method ${CameraOnvifService.SNAPSHOT_PATH}, status=$status" +
                    (if (userAgent.isNotEmpty()) ", userAgent=$userAgent" else ""))
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
            if (code != "200 OK" || requestMethod in listOf("DESCRIBE", "SETUP", "PLAY", "TEARDOWN")) {
                val client = socket.inetAddress.hostAddress
                note("rtsp $client $requestMethod $requestPath $code", "rtsp request",
                    "client=$client, method=$requestMethod, path=$requestPath, status=$code" +
                        (if (userAgent.isNotEmpty()) ", userAgent=$userAgent" else ""))
            }
        }

        private fun sendFrames() {
            try {
                while (open) {
                    val frame = queue.poll(1, java.util.concurrent.TimeUnit.SECONDS) ?: continue
                    if (frame.audio) {
                        if (System.nanoTime() - audioReportNs >= 5_000_000_000L) {
                            senderReport(frame.timestamp, audio = true)
                            audioReportNs = System.nanoTime()
                        }
                        val unit = frame.units.single()
                        var offset = 0
                        while (offset < unit.size) {
                            val size = minOf(1196, unit.size - offset)
                            val payload = ByteArray(size + 4)
                            payload[1] = 16
                            payload[2] = (unit.size shr 5).toByte()
                            payload[3] = (unit.size shl 3).toByte()
                            unit.copyInto(payload, 4, offset, offset + size)
                            offset += size
                            packet(payload, frame.timestamp, offset == unit.size, audio = true)
                        }
                        continue
                    }
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

        private fun packet(payload: ByteArray, time: Long, marker: Boolean, audio: Boolean = false) {
            val length = payload.size + 12
            val bytes = ByteArray(length + 4)
            bytes[0] = 36; bytes[1] = (if (audio) audioChannel else channel).toByte()
            bytes[2] = (length shr 8).toByte(); bytes[3] = length.toByte()
            bytes[4] = 0x80.toByte(); bytes[5] = ((if (audio) 97 else 96) or if (marker) 128 else 0).toByte()
            val seq = if (audio) audioSequence++ else sequence++
            bytes[6] = (seq shr 8).toByte(); bytes[7] = seq.toByte()
            val source = if (audio) ssrc xor 0x13579bdf else ssrc
            for (i in 0..3) {
                bytes[8 + i] = (time shr (24 - i * 8)).toByte()
                bytes[12 + i] = (source shr (24 - i * 8)).toByte()
            }
            payload.copyInto(bytes, 16)
            synchronized(output) {
                writeStartedNs = System.nanoTime()
                output.write(bytes)
                writeStartedNs = 0L
            }
            if (audio) { audioPackets++; audioOctets += payload.size }
            else { packets++; octets += payload.size }
        }

        fun checkWriter() {
            val started = writeStartedNs
            if (started != 0L && System.nanoTime() - started > 5_000_000_000L) close()
        }

        private fun senderReport(timestamp: Long, audio: Boolean = false) {
            val source = if (audio) ssrc xor 0x13579bdf else ssrc
            val cname = "kiosk-$session".toByteArray()
            val sdesLength = (4 + 4 + 2 + cname.size + 1 + 3) / 4 * 4
            val packet = java.nio.ByteBuffer.allocate(4 + 28 + sdesLength)
            packet.put(36).put(((if (audio) audioChannel else channel) + 1).toByte()).putShort((28 + sdesLength).toShort())
            packet.put(0x80.toByte()).put(200.toByte()).putShort(6).putInt(source)
            // Map both RTP clocks to the same monotonic capture timeline.
            val rate = if (audio) 16000L else 90000L
            val now = clockMs + timestamp * 1000 / rate - clockNs / 1_000_000
            packet.putInt((now / 1000 + 2_208_988_800L).toInt())
            packet.putInt(((now % 1000) * 0x1_0000_0000L / 1000).toInt())
            packet.putInt(timestamp.toInt()).putInt((if (audio) audioPackets else packets).toInt()).putInt((if (audio) audioOctets else octets).toInt())
            packet.put(0x81.toByte()).put(202.toByte()).putShort((sdesLength / 4 - 1).toShort())
            packet.putInt(source).put(1).put(cname.size.toByte()).put(cname)
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
            if (!http) updateDemand()
        }
    }

}
