package me.jxl.kiosk_satellite.btproxy

import java.io.IOException
import java.net.ServerSocket
import java.net.Socket
import java.util.concurrent.ArrayBlockingQueue
import java.util.concurrent.CopyOnWriteArrayList
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicInteger
import java.util.concurrent.atomic.AtomicLong

/**
 * The ESPHome native API server the proxy exposes to Home Assistant.
 *
 * Pure JVM on purpose: no Android imports, so the whole session lifecycle
 * runs under plain unit tests with a real aioesphomeapi client on the other
 * end of a socket. The Android layer supplies the BLE scanner through
 * [ScannerBackend] and receives scanner start/stop demands back.
 *
 * Reliability decisions baked in here, each one a documented failure of a
 * prior Android proxy:
 *
 *  - Every session writes through its own bounded queue and writer thread.
 *    A half-open peer (HA restarted, Wi-Fi roamed) stops draining its TCP
 *    buffer; a direct write would block whichever thread flushed next and
 *    silently stall every other client's traffic with it. Here the stuck
 *    session's queue fills, the session is closed, everyone else is
 *    untouched.
 *  - SO_KEEPALIVE plus an application-level ping: the server sends its own
 *    PingRequest over idle links and reaps sessions that stay silent past
 *    the timeout, so a dead HA connection is discovered in seconds, not
 *    never.
 *  - BluetoothScannerSetModeRequest acknowledges without restarting when
 *    the mode already matches. HA sends one immediately after subscribing;
 *    proxies that answered it with a scanner restart looped forever on
 *    HA 2026.6.
 *  - Advertisement forwarding dedups on payload change but still forwards
 *    unchanged payloads at a short interval so RSSI keeps flowing:
 *    room-presence integrations live on RSSI updates, and the 10-second
 *    suppression windows other proxies ship read as a dead scanner.
 *  - Unknown message types are ignored, malformed known ones are logged and
 *    ignored; only transport-level errors end a session. HA grows the
 *    schema every release.
 */
internal interface ScannerBackend {
    /** At least one client subscribed: scanning should run in [mode]. */
    fun onScanDemand(mode: ScannerMode)

    /** Last subscriber left: scanning may stop. */
    fun onScanRelease()
}

internal class ApiServer(
    private val identity: ProxyIdentity,
    private val bluetoothMac: String,
    private val port: Int,
    /** Null runs plaintext (only ever used by tests; production always sets a key). */
    private val psk: ByteArray?,
    private val backend: ScannerBackend,
    private val log: (String) -> Unit,
    private val clock: () -> Long = System::currentTimeMillis,
    /** False = no Bluetooth capability at all: a pure entity device. */
    private val bluetoothProxy: Boolean = true,
    /** Null = advertisement-only; the feature flags follow automatically. */
    private val gatt: GattBackend? = null,
    /**
     * Connect requests for devices last heard below this RSSI (dBm) are
     * refused so Home Assistant fails over to a closer proxy, instead of
     * this one accepting a link it cannot hold. 0 disables the gate.
     * Found the hard way: a kiosk across the house kept winning an
     * EcoFlow's connection, completing auth, then losing the link to
     * range seconds later - while its held slot blocked the closer proxy.
     */
    private val minConnectRssi: Int = 0,
    /** Latest advertisement RSSI per address, for the connect gate. */
    private val rssiOf: (Long) -> Int? = { null },
    /**
     * The kiosk's own entities (sensors, switches, ...) served over this
     * same connection; null keeps the server a pure Bluetooth proxy.
     */
    private val entities: EntityHub? = null,
) {
    private val featureFlags: Int = when {
        !bluetoothProxy -> 0
        gatt != null -> BtProxyFeature.WITH_CONNECTIONS
        else -> BtProxyFeature.V1
    }
    private companion object {
        const val MAX_SESSIONS = 8
        const val WRITE_QUEUE_FRAMES = 256
        const val HANDSHAKE_TIMEOUT_MS = 10_000
        const val PING_IDLE_MS = 20_000L
        const val SESSION_SILENCE_TIMEOUT_MS = 90_000L
        const val FLUSH_INTERVAL_MS = 100L
        // A healthy relay forwards within one flush interval of hearing
        // anything; two minutes of hearing-but-not-forwarding is a wedge.
        const val RELAY_STALL_MS = 120_000L
        const val ADVERTISEMENT_BATCH = 16
        const val MAX_BATCHES_PER_FLUSH = 4
        const val MAX_PENDING = 2048
        /** Unchanged-payload (RSSI-only) refresh cadence per address. */
        const val RSSI_REFRESH_MS = 1_500L
        /** Quiet-address horizon after which a sighting is "new" again. */
        const val REDISCOVERY_MS = 30 * 60_000L
    }

    private val running = AtomicBoolean(false)
    private var serverSocket: ServerSocket? = null
    private var acceptThread: Thread? = null
    private val scheduler = Executors.newSingleThreadScheduledExecutor { r ->
        Thread(r, "btproxy-tick").apply { isDaemon = true }
    }
    private val sessions = CopyOnWriteArrayList<Session>()
    private val sessionSeq = AtomicInteger(0)

    // Scanner state as last reported by the Android layer; replayed to every
    // new subscriber and broadcast on change.
    @Volatile private var scannerState: ScannerState = ScannerState.IDLE
    @Volatile private var scannerMode: ScannerMode = ScannerMode.PASSIVE

    // Advertisement pipeline. pending holds the latest packet per address in
    // arrival order; forwarding history lives in forwardState.
    private val advLock = Any()
    private val pending = LinkedHashMap<Long, BleAdvertisement>()
    private val forwardState = HashMap<Long, ForwardState>()

    // GATT ownership: each connection belongs to the session that asked for
    // it, and every response routes there and only there. Broadcasting GATT
    // traffic to all sessions is how a lingering half-open socket ends up
    // consuming another session's responses. Guarded by gattLock.
    private val gattLock = Any()
    private val gattOwner = HashMap<Long, Session>()
    private val gattConnected = HashSet<Long>()

    val receivedCount = AtomicLong(0)
    val forwardedCount = AtomicLong(0)
    val lastReceivedAt = AtomicLong(0)
    val lastForwardedAt = AtomicLong(0)

    private class ForwardState(
        var payloadHash: Int,
        var lastForwardedAt: Long,
    )

    fun start() {
        if (!running.compareAndSet(false, true)) return
        val socket = ServerSocket(port).apply { reuseAddress = true }
        serverSocket = socket
        acceptThread = Thread({ acceptLoop(socket) }, "btproxy-accept").apply {
            isDaemon = true
            start()
        }
        scheduler.scheduleWithFixedDelay(
            ::flushAdvertisements, FLUSH_INTERVAL_MS, FLUSH_INTERVAL_MS, TimeUnit.MILLISECONDS)
        scheduler.scheduleWithFixedDelay(::sweepSessions, 5_000, 5_000, TimeUnit.MILLISECONDS)
        entities?.onStateChanged = { entity, value ->
            EntityCodec.state(entity, value)?.let { (type, payload) ->
                for (session in sessions) {
                    if (session.wantsStates) session.enqueue(type, payload)
                }
            }
        }
        log("API server listening on :$port (${if (psk != null) "noise" else "plaintext"})")
    }

    fun stop() {
        if (!running.compareAndSet(true, false)) return
        entities?.onStateChanged = null
        runCatching { serverSocket?.close() }
        serverSocket = null
        scheduler.shutdownNow()
        for (session in sessions) session.close("server stopping")
        sessions.clear()
        gatt?.disconnectAll()
        synchronized(gattLock) {
            gattOwner.clear()
            gattConnected.clear()
        }
        synchronized(advLock) {
            pending.clear()
            forwardState.clear()
        }
    }

    val boundPort: Int get() = serverSocket?.localPort ?: port

    fun hasAdvertisementSubscribers(): Boolean = sessions.any { it.wantsAdvertisements }

    /** Fully connected addresses, raw, for the nearby-device tracker. */
    fun gattConnectedSet(): Set<Long> = synchronized(gattLock) { gattConnected.toSet() }

    /** Addresses with an owned connection slot, formatted, for diagnostics. */
    fun activeGattAddresses(): List<String> = synchronized(gattLock) {
        gattOwner.keys.map { address ->
            (5 downTo 0).joinToString(":") { "%02X".format((address shr (it * 8)) and 0xFF) } +
                if (address in gattConnected) "" else " (connecting)"
        }
    }

    /** Callable from any thread, including the BLE scan callback. Cheap: map put under one lock. */
    fun publishAdvertisement(adv: BleAdvertisement) {
        receivedCount.incrementAndGet()
        lastReceivedAt.set(clock())
        if (!hasAdvertisementSubscribers()) return
        synchronized(advLock) {
            if (pending.size >= MAX_PENDING && !pending.containsKey(adv.address)) {
                // Bounded: drop the oldest pending address rather than grow.
                val oldest = pending.keys.firstOrNull() ?: return
                pending.remove(oldest)
            }
            // Re-inserting moves the address to the tail, keeping drain order
            // roughly by recency of update.
            pending.remove(adv.address)
            pending[adv.address] = adv
        }
    }

    /**
     * The GATT engine's event stream, single-threaded and in causal order.
     * Everything routes to the owning session; connection transitions also
     * update the free-slot broadcast and the advertisement suppression set.
     */
    fun deliverGattEvent(event: GattEvent) {
        val owner = synchronized(gattLock) { gattOwner[event.address] }
        when (event) {
            is GattEvent.Connected -> {
                synchronized(gattLock) { gattConnected.add(event.address) }
                log("GATT connected ${formatGattAddress(event.address)} mtu=${event.mtu}")
                owner?.enqueue(Msg.BT_DEVICE_CONNECTION_RESPONSE,
                    GattCodec.connectionResponse(event.address, true, event.mtu, 0))
                broadcastConnectionsFree()
            }
            is GattEvent.ConnectFailed -> {
                log("GATT connect failed ${formatGattAddress(event.address)} error=${event.error}")
                releaseGattAddress(event.address)
                owner?.enqueue(Msg.BT_DEVICE_CONNECTION_RESPONSE,
                    GattCodec.connectionResponse(event.address, false, 0, event.error))
                broadcastConnectionsFree()
            }
            is GattEvent.Disconnected -> {
                log("GATT disconnected ${formatGattAddress(event.address)}" +
                    if (event.error != 0) " error=${event.error}" else "")
                releaseGattAddress(event.address)
                owner?.enqueue(Msg.BT_DEVICE_CONNECTION_RESPONSE,
                    GattCodec.connectionResponse(event.address, false, 0, event.error))
                broadcastConnectionsFree()
            }
            is GattEvent.Services -> {
                // Every batch and the done marker in one dispatch, in order:
                // a done marker that overtakes the last service leaves the
                // client with a truncated table it will trust forever.
                for (service in event.services) {
                    owner?.enqueue(Msg.GATT_GET_SERVICES_RESPONSE,
                        GattCodec.servicesResponse(event.address, service))
                }
                owner?.enqueue(Msg.GATT_GET_SERVICES_DONE_RESPONSE,
                    GattCodec.servicesDone(event.address))
            }
            is GattEvent.ReadResult ->
                owner?.enqueue(Msg.GATT_READ_RESPONSE,
                    GattCodec.readResponse(event.address, event.handle, event.data))
            is GattEvent.WriteDone ->
                owner?.enqueue(Msg.GATT_WRITE_RESPONSE,
                    GattCodec.writeResponse(event.address, event.handle))
            is GattEvent.NotifyStateDone ->
                owner?.enqueue(Msg.GATT_NOTIFY_RESPONSE,
                    GattCodec.notifyResponse(event.address, event.handle))
            is GattEvent.NotifyData ->
                owner?.enqueue(Msg.GATT_NOTIFY_DATA_RESPONSE,
                    GattCodec.notifyData(event.address, event.handle, event.data))
            is GattEvent.OperationError ->
                owner?.enqueue(Msg.GATT_ERROR_RESPONSE,
                    GattCodec.gattError(event.address, event.handle, event.error))
            is GattEvent.PairResult ->
                owner?.enqueue(Msg.BT_DEVICE_PAIRING_RESPONSE,
                    GattCodec.pairingResponse(event.address, event.paired, event.error))
            is GattEvent.UnpairResult ->
                owner?.enqueue(Msg.BT_DEVICE_UNPAIRING_RESPONSE,
                    GattCodec.unpairingResponse(event.address, event.success, event.error))
            is GattEvent.ClearCacheResult ->
                owner?.enqueue(Msg.BT_DEVICE_CLEAR_CACHE_RESPONSE,
                    GattCodec.clearCacheResponse(event.address, event.success, event.error))
        }
    }

    private fun formatGattAddress(address: Long): String =
        (5 downTo 0).joinToString(":") { "%02X".format((address shr (it * 8)) and 0xFF) }

    private fun releaseGattAddress(address: Long) {
        synchronized(gattLock) {
            gattOwner.remove(address)
            gattConnected.remove(address)
        }
    }

    private fun broadcastConnectionsFree() {
        val gattBackend = gatt ?: return
        val payload = synchronized(gattLock) {
            GattCodec.connectionsFree(
                (gattBackend.connectionLimit - gattOwner.size).coerceAtLeast(0),
                gattBackend.connectionLimit,
                gattOwner.keys.toList(),
            )
        }
        for (session in sessions) {
            if (session.wantsConnectionsFree) {
                session.enqueue(Msg.BT_CONNECTIONS_FREE_RESPONSE, payload)
            }
        }
    }

    /**
     * A fresh frame from the capture side for the camera [objectId]: chunked to every session
     * with an outstanding image request (16KB chunks stay far under the
     * Noise transport's 65535-byte frame ceiling), done flag on the last.
     */
    fun publishCameraImage(objectId: String, jpeg: ByteArray) {
        val cameraKey = entities?.cameraFor(objectId)?.key ?: return
        val waiting = sessions.filter { it.takeCameraRequest(cameraKey) }
        if (waiting.isEmpty()) return
        val chunks = ArrayList<Pair<ByteArray, Boolean>>()
        var offset = 0
        while (offset < jpeg.size) {
            val end = minOf(offset + 16_384, jpeg.size)
            chunks.add(jpeg.copyOfRange(offset, end) to (end == jpeg.size))
            offset = end
        }
        if (chunks.isEmpty()) chunks.add(ByteArray(0) to true)
        for (session in waiting) {
            for ((data, done) in chunks) {
                val w = ProtoWriter()
                w.fixed32(1, cameraKey)
                w.bytes(2, data)
                w.bool(3, done)
                session.enqueue(Msg.CAMERA_IMAGE_RESPONSE, w.toByteArray())
            }
        }
    }

    /** Android layer reports scanner lifecycle; broadcast to subscribers. */
    fun reportScannerState(state: ScannerState, mode: ScannerMode) {
        scannerState = state
        scannerMode = mode
        val payload = ApiCodec.scannerStateResponse(state, mode)
        for (session in sessions) {
            if (session.wantsAdvertisements) {
                session.enqueue(Msg.BT_SCANNER_STATE_RESPONSE, payload)
            }
        }
    }

    private fun acceptLoop(socket: ServerSocket) {
        while (running.get()) {
            val client = try {
                socket.accept()
            } catch (_: IOException) {
                if (running.get()) log("accept failed, listener closed")
                return
            }
            if (sessions.size >= MAX_SESSIONS) {
                // A port scanner or a reconnect storm; never queue unbounded
                // handshake work.
                log("rejecting connection from ${client.inetAddress.hostAddress}: session limit")
                runCatching { client.close() }
                continue
            }
            val session = Session(client, sessionSeq.incrementAndGet())
            sessions.add(session)
            session.startReader()
        }
    }

    private fun sweepSessions() {
        val now = clock()
        for (session in sessions) {
            val idle = now - session.lastInboundAt
            if (idle > SESSION_SILENCE_TIMEOUT_MS) {
                log("session #${session.id} silent ${idle / 1000}s, reaping")
                session.close("liveness timeout")
            } else if (idle > PING_IDLE_MS && session.handshaken && now - session.lastPingSentAt > PING_IDLE_MS) {
                session.lastPingSentAt = now
                session.enqueue(Msg.PING_REQUEST, ByteArray(0))
            }
        }
        checkRelayHealth(now)
    }

    // One line per episode, cleared on recovery: catches the failure shape
    // where the device's Nearby list fills happily while Home Assistant
    // receives nothing (issue #246, a LineageOS tablet), which no other
    // surface can distinguish from a working proxy.
    private var subscribedSince = 0L
    private var relayStallLogged = false

    private fun checkRelayHealth(now: Long) {
        if (!sessions.any { it.wantsAdvertisements }) {
            subscribedSince = 0L
            relayStallLogged = false
            return
        }
        if (subscribedSince == 0L) subscribedSince = now
        val received = lastReceivedAt.get()
        val forwarded = lastForwardedAt.get()
        val hearing = received != 0L && now - received < 30_000
        val stalled = hearing &&
            now - subscribedSince > RELAY_STALL_MS &&
            (forwarded == 0L || now - forwarded > RELAY_STALL_MS)
        if (stalled && !relayStallLogged) {
            relayStallLogged = true
            log("relay stalled: hearing advertisements but none forwarded to " +
                "Home Assistant for ${RELAY_STALL_MS / 60_000} minutes " +
                "(received ${receivedCount.get()}, forwarded ${forwardedCount.get()})")
        } else if (relayStallLogged && forwarded != 0L && now - forwarded < 30_000) {
            relayStallLogged = false
            log("relay recovered: advertisements forwarding to Home Assistant again")
        }
    }

    private fun flushAdvertisements() {
        val subscribers = sessions.filter { it.wantsAdvertisements }
        if (subscribers.isEmpty()) {
            synchronized(advLock) { pending.clear() }
            return
        }
        val now = clock()
        val batch = ArrayList<BleAdvertisement>(ADVERTISEMENT_BATCH)
        var batchesSent = 0
        while (batchesSent < MAX_BATCHES_PER_FLUSH) {
            batch.clear()
            synchronized(advLock) {
                val suppressed = synchronized(gattLock) {
                    if (gattConnected.isEmpty()) emptySet() else gattConnected.toSet()
                }
                val iterator = pending.entries.iterator()
                while (iterator.hasNext() && batch.size < ADVERTISEMENT_BATCH) {
                    val entry = iterator.next()
                    iterator.remove()
                    // A connected device's advertisements (mostly stray scan
                    // responses) stay off the wire: the link owner is doing
                    // GATT work and the traffic only competes with it.
                    if (entry.key in suppressed) continue
                    val adv = entry.value
                    val hash = adv.data.contentHashCode()
                    val state = forwardState[adv.address]
                    val forward = when {
                        state == null -> true
                        now - state.lastForwardedAt > REDISCOVERY_MS -> true
                        hash != state.payloadHash -> true
                        now - state.lastForwardedAt >= RSSI_REFRESH_MS -> true
                        else -> false
                    }
                    if (forward) {
                        if (state == null) {
                            forwardState[adv.address] = ForwardState(hash, now)
                        } else {
                            state.payloadHash = hash
                            state.lastForwardedAt = now
                        }
                        batch.add(adv)
                    }
                }
            }
            if (batch.isEmpty()) return
            val payload = ApiCodec.rawAdvertisementsResponse(batch)
            forwardedCount.addAndGet(batch.size.toLong())
            lastForwardedAt.set(now)
            for (session in subscribers) {
                session.enqueue(Msg.BLE_RAW_ADVERTISEMENTS_RESPONSE, payload)
            }
            batchesSent++
        }
    }

    private fun updateScanDemand() {
        if (hasAdvertisementSubscribers()) {
            backend.onScanDemand(scannerMode)
        } else {
            backend.onScanRelease()
        }
    }

    private inner class Session(private val socket: Socket, val id: Int) {
        @Volatile var wantsAdvertisements = false
            private set
        @Volatile var wantsConnectionsFree = false
        @Volatile var wantsStates = false
        /**
         * Camera keys with a CameraImageRequest outstanding. The request
         * names no camera, so one request pends every listed camera; each
         * key clears as its frame ships.
         */
        private val pendingCameraKeys = HashSet<Int>()

        fun requestCameraFrames(keys: Collection<Int>) {
            synchronized(pendingCameraKeys) { pendingCameraKeys.addAll(keys) }
        }

        /** True, once, while a frame for [key] is owed to this session. */
        fun takeCameraRequest(key: Int): Boolean =
            synchronized(pendingCameraKeys) { pendingCameraKeys.remove(key) }
        @Volatile var handshaken = false
        @Volatile var lastInboundAt = clock()
        @Volatile var lastPingSentAt = 0L
        private val closed = AtomicBoolean(false)
        private val writeQueue = ArrayBlockingQueue<Pair<Int, ByteArray>>(WRITE_QUEUE_FRAMES)
        private var transport: ApiTransport? = null
        private var writerThread: Thread? = null
        private val peer: String = socket.inetAddress?.hostAddress ?: "?"

        fun startReader() {
            Thread({ readerLoop() }, "btproxy-r-$id").apply {
                isDaemon = true
                start()
            }
        }

        fun enqueue(type: Int, payload: ByteArray) {
            if (closed.get() || !handshaken) return
            if (!writeQueue.offer(type to payload)) {
                // The peer stopped draining; treat as dead rather than block.
                log("session #$id ($peer) write queue full, closing")
                close("write queue overflow")
            }
        }

        fun close(reason: String) {
            if (!closed.compareAndSet(false, true)) return
            runCatching { socket.close() }
            writerThread?.interrupt()
            sessions.remove(this)
            if (wantsAdvertisements) {
                wantsAdvertisements = false
                updateScanDemand()
            }
            // A dying client's connections die with it: ESPHome semantics,
            // and the only behavior that cannot leak slots to a peer that
            // will never send the disconnect.
            val orphaned = synchronized(gattLock) {
                gattOwner.filterValues { it === this }.keys.toList()
            }
            for (address in orphaned) gatt?.disconnect(address)
            log("session #$id ($peer) closed: $reason")
        }

        private fun readerLoop() {
            try {
                socket.tcpNoDelay = true
                socket.keepAlive = true
                socket.soTimeout = HANDSHAKE_TIMEOUT_MS
                val t = if (psk != null) {
                    NoiseTransport(
                        socket.getInputStream(), socket.getOutputStream(),
                        psk, identity.name, identity.macAddress)
                } else {
                    PlaintextTransport(socket.getInputStream(), socket.getOutputStream())
                }
                try {
                    t.handshake()
                } catch (e: RequiresEncryptionException) {
                    // Tell the plaintext client the endpoint needs a key so
                    // HA prompts instead of timing out.
                    runCatching {
                        socket.getOutputStream().apply {
                            write(REQUIRES_ENCRYPTION_HINT)
                            flush()
                        }
                    }
                    close("plaintext client on encrypted endpoint")
                    return
                }
                transport = t
                handshaken = true
                lastInboundAt = clock()
                // Reads block indefinitely from here; the liveness sweep owns
                // dead-session detection.
                socket.soTimeout = 0
                writerThread = Thread({ writerLoop(t) }, "btproxy-w-$id").apply {
                    isDaemon = true
                    start()
                }
                log("session #$id ($peer) connected")
                while (!closed.get()) {
                    val frame = t.readFrame() ?: break
                    lastInboundAt = clock()
                    dispatch(frame)
                }
                close("peer disconnected")
            } catch (e: IOException) {
                close(e.message ?: "io error")
            } catch (e: Exception) {
                log("session #$id ($peer) reader error: $e")
                close("reader error")
            }
        }

        private fun handleDeviceRequest(payload: ByteArray) {
            val request = GattCodec.parseDeviceRequest(payload)
            val gattBackend = gatt
            if (gattBackend == null) {
                // Flags never advertised connections; a request anyway gets
                // an immediate refusal instead of silence.
                enqueue(Msg.BT_DEVICE_CONNECTION_RESPONSE,
                    GattCodec.connectionResponse(request.address, false, 0, 0x7F))
                return
            }
            when (request.requestType) {
                BtDeviceRequestType.CONNECT,
                BtDeviceRequestType.CONNECT_V3_WITH_CACHE,
                BtDeviceRequestType.CONNECT_V3_WITHOUT_CACHE -> {
                    // The signal floor, checked before a slot is claimed.
                    // Devices we already own skip it (their advertisement
                    // RSSI is stale the moment they connect), and unknown
                    // devices pass (never block a pairing flow on a gap in
                    // the tracker).
                    if (minConnectRssi != 0 &&
                        synchronized(gattLock) { !gattOwner.containsKey(request.address) }) {
                        val rssi = rssiOf(request.address)
                        if (rssi != null && rssi < minConnectRssi) {
                            log("connect refused ${formatGattAddress(request.address)}: " +
                                "RSSI $rssi below floor $minConnectRssi")
                            enqueue(Msg.BT_DEVICE_CONNECTION_RESPONSE,
                                GattCodec.connectionResponse(request.address, false, 0, 133))
                            return
                        }
                    }
                    val accepted = synchronized(gattLock) {
                        when {
                            gattOwner.containsKey(request.address) -> {
                                gattOwner[request.address] = this
                                true // reconnect attempt on an existing slot
                            }
                            gattOwner.size >= gattBackend.connectionLimit -> false
                            else -> {
                                gattOwner[request.address] = this
                                true
                            }
                        }
                    }
                    if (!accepted) {
                        // Slot budget spent: refuse now so HA can pick
                        // another proxy instead of waiting on a timeout.
                        enqueue(Msg.BT_DEVICE_CONNECTION_RESPONSE,
                            GattCodec.connectionResponse(request.address, false, 0, 0x7F))
                        return
                    }
                    broadcastConnectionsFree()
                    gattBackend.connect(
                        request.address,
                        request.addressType,
                        withCache = request.requestType !=
                            BtDeviceRequestType.CONNECT_V3_WITHOUT_CACHE,
                    )
                }
                BtDeviceRequestType.DISCONNECT -> gattBackend.disconnect(request.address)
                BtDeviceRequestType.PAIR -> gattBackend.pair(request.address)
                BtDeviceRequestType.UNPAIR -> gattBackend.unpair(request.address)
                BtDeviceRequestType.CLEAR_CACHE -> gattBackend.clearCache(request.address)
            }
        }

        private fun writerLoop(t: ApiTransport) {
            try {
                while (!closed.get()) {
                    val (type, payload) = writeQueue.poll(1, TimeUnit.SECONDS) ?: continue
                    t.writeFrame(type, payload)
                }
            } catch (_: InterruptedException) {
                // close() interrupting a blocked poll; done.
            } catch (e: Exception) {
                close("write failed: ${e.message}")
            }
        }

        private fun dispatch(frame: ApiFrame) {
            try {
                when (frame.type) {
                    Msg.HELLO_REQUEST -> {
                        val hello = ApiCodec.parseHello(frame.payload)
                        log("session #$id hello from \"${hello.clientInfo}\" api ${hello.major}.${hello.minor}")
                        enqueue(Msg.HELLO_RESPONSE, ApiCodec.helloResponse(identity))
                    }
                    Msg.CONNECT_REQUEST ->
                        enqueue(Msg.CONNECT_RESPONSE, ApiCodec.connectResponse())
                    Msg.DISCONNECT_REQUEST -> {
                        enqueue(Msg.DISCONNECT_RESPONSE, ByteArray(0))
                        // Give the writer a beat to drain the goodbye, then close.
                        scheduler.schedule({ close("peer requested disconnect") },
                            250, TimeUnit.MILLISECONDS)
                    }
                    Msg.DISCONNECT_RESPONSE -> close("disconnect acknowledged")
                    Msg.PING_REQUEST -> enqueue(Msg.PING_RESPONSE, ByteArray(0))
                    Msg.PING_RESPONSE -> Unit // lastInboundAt already refreshed
                    Msg.DEVICE_INFO_REQUEST ->
                        enqueue(Msg.DEVICE_INFO_RESPONSE,
                            ApiCodec.deviceInfoResponse(identity, bluetoothMac, featureFlags))
                    Msg.LIST_ENTITIES_REQUEST -> {
                        val hub = entities
                        if (hub != null) {
                            for (entity in hub.all) {
                                val (type, payload) =
                                    EntityCodec.describe(entity, identity.name)
                                enqueue(type, payload)
                            }
                            // Actions ride the same listing: aioesphomeapi
                            // collects entities and services from the one
                            // ListEntities exchange.
                            for (service in hub.services) {
                                enqueue(Msg.LIST_ENTITIES_SERVICES_RESPONSE,
                                    ServiceCodec.describe(service))
                            }
                        }
                        enqueue(Msg.LIST_ENTITIES_DONE_RESPONSE, ByteArray(0))
                    }
                    Msg.GET_TIME_REQUEST ->
                        enqueue(Msg.GET_TIME_RESPONSE, ApiCodec.getTimeResponse(clock() / 1000))
                    Msg.SUBSCRIBE_BLE_ADVERTISEMENTS_REQUEST -> {
                        wantsAdvertisements = true
                        // Logged because its absence is a diagnosis: a full
                        // Nearby list with an empty Home Assistant side and
                        // no subscribe line means HA never asked for the
                        // advertisements at all (issue #246).
                        log("session #$id subscribed to Bluetooth advertisements")
                        // Replay current scanner state so HA renders the
                        // scanner entity immediately.
                        enqueue(Msg.BT_SCANNER_STATE_RESPONSE,
                            ApiCodec.scannerStateResponse(scannerState, scannerMode))
                        updateScanDemand()
                    }
                    Msg.UNSUBSCRIBE_BLE_ADVERTISEMENTS_REQUEST -> {
                        wantsAdvertisements = false
                        log("session #$id unsubscribed from Bluetooth advertisements")
                        updateScanDemand()
                    }
                    Msg.SUBSCRIBE_BT_CONNECTIONS_FREE_REQUEST -> {
                        wantsConnectionsFree = true
                        val gattBackend = gatt
                        enqueue(Msg.BT_CONNECTIONS_FREE_RESPONSE,
                            if (gattBackend == null) {
                                ApiCodec.connectionsFreeResponse()
                            } else {
                                synchronized(gattLock) {
                                    GattCodec.connectionsFree(
                                        (gattBackend.connectionLimit - gattOwner.size)
                                            .coerceAtLeast(0),
                                        gattBackend.connectionLimit,
                                        gattOwner.keys.toList(),
                                    )
                                }
                            })
                    }
                    Msg.BT_DEVICE_REQUEST -> handleDeviceRequest(frame.payload)
                    Msg.GATT_GET_SERVICES_REQUEST ->
                        gatt?.getServices(GattCodec.parseAddress(frame.payload))
                    Msg.GATT_READ_REQUEST -> {
                        val request = GattCodec.parseHandleRequest(frame.payload)
                        gatt?.read(request.address, request.handle)
                    }
                    Msg.GATT_WRITE_REQUEST -> {
                        val request = GattCodec.parseWriteRequest(frame.payload)
                        gatt?.write(request.address, request.handle, request.data,
                            request.response)
                    }
                    Msg.GATT_READ_DESCRIPTOR_REQUEST -> {
                        val request = GattCodec.parseHandleRequest(frame.payload)
                        gatt?.readDescriptor(request.address, request.handle)
                    }
                    Msg.GATT_WRITE_DESCRIPTOR_REQUEST -> {
                        val request = GattCodec.parseWriteDescriptor(frame.payload)
                        gatt?.writeDescriptor(request.address, request.handle, request.data)
                    }
                    Msg.GATT_NOTIFY_REQUEST -> {
                        val request = GattCodec.parseNotifyRequest(frame.payload)
                        gatt?.setNotify(request.address, request.handle, request.enable)
                    }
                    Msg.BT_SCANNER_SET_MODE_REQUEST -> {
                        val requested = ApiCodec.parseScannerSetMode(frame.payload)
                        if (requested == scannerMode) {
                            // HA sends this right after every subscribe; a
                            // matching mode must be a pure ack. Restarting
                            // the scanner here is the exact restart-loop bug.
                            enqueue(Msg.BT_SCANNER_STATE_RESPONSE,
                                ApiCodec.scannerStateResponse(scannerState, scannerMode))
                        } else {
                            scannerMode = requested
                            if (hasAdvertisementSubscribers()) backend.onScanDemand(requested)
                        }
                    }
                    Msg.SUBSCRIBE_STATES_REQUEST -> {
                        wantsStates = true
                        // Replay everything known so HA renders current
                        // values immediately instead of "unknown" until the
                        // next change.
                        val hub = entities
                        if (hub != null) {
                            for (entity in hub.all) {
                                EntityCodec.state(entity, hub.valueOf(entity))
                                    ?.let { (type, payload) ->
                                        enqueue(type, payload)
                                    }
                            }
                        }
                    }
                    Msg.SWITCH_COMMAND_REQUEST,
                    Msg.NUMBER_COMMAND_REQUEST,
                    Msg.SELECT_COMMAND_REQUEST,
                    Msg.TEXT_COMMAND_REQUEST,
                    Msg.LIGHT_COMMAND_REQUEST,
                    Msg.UPDATE_COMMAND_REQUEST,
                    Msg.BUTTON_COMMAND_REQUEST ->
                        EntityCodec.parseCommand(frame.type, frame.payload)
                            ?.let { entities?.dispatchCommand(it) }
                    Msg.EXECUTE_SERVICE_REQUEST ->
                        entities?.dispatchService(
                            ServiceCodec.parseExecute(frame.payload)) { payload ->
                            // The answer goes back on the session that
                            // asked, whenever the Dart side is done.
                            enqueue(Msg.EXECUTE_SERVICE_RESPONSE, payload)
                        }
                    Msg.CAMERA_IMAGE_REQUEST -> {
                        // The request carries no key, so it asks every
                        // camera. Remember who asked and which frames are
                        // owed; they arrive asynchronously from the capture
                        // side, one per camera.
                        val hub = entities
                        if (hub != null && hub.cameras.isNotEmpty()) {
                            requestCameraFrames(hub.cameras.map { it.key })
                            hub.requestCameraImage()
                        }
                    }
                    // Required-ack subscriptions with nothing behind them:
                    // this device streams no logs and calls nothing back on
                    // Home Assistant (its own actions are served above, in
                    // the entity listing).
                    Msg.SUBSCRIBE_LOGS_REQUEST,
                    Msg.SUBSCRIBE_HOMEASSISTANT_SERVICES_REQUEST,
                    Msg.SUBSCRIBE_HOME_ASSISTANT_STATES_REQUEST -> Unit
                    else -> Unit // unknown type: HA is newer than us; skip
                }
            } catch (e: ProtoException) {
                // Malformed payload on a known type: log and keep the session.
                log("session #$id ($peer) malformed message type ${frame.type}: ${e.message}")
            }
        }
    }
}
