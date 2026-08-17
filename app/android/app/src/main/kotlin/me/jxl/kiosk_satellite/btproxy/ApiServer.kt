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
) {
    private companion object {
        const val MAX_SESSIONS = 8
        const val WRITE_QUEUE_FRAMES = 256
        const val HANDSHAKE_TIMEOUT_MS = 10_000
        const val PING_IDLE_MS = 20_000L
        const val SESSION_SILENCE_TIMEOUT_MS = 90_000L
        const val FLUSH_INTERVAL_MS = 100L
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
        log("API server listening on :$port (${if (psk != null) "noise" else "plaintext"})")
    }

    fun stop() {
        if (!running.compareAndSet(true, false)) return
        runCatching { serverSocket?.close() }
        serverSocket = null
        scheduler.shutdownNow()
        for (session in sessions) session.close("server stopping")
        sessions.clear()
        synchronized(advLock) {
            pending.clear()
            forwardState.clear()
        }
    }

    val boundPort: Int get() = serverSocket?.localPort ?: port

    fun hasAdvertisementSubscribers(): Boolean = sessions.any { it.wantsAdvertisements }

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
                val iterator = pending.entries.iterator()
                while (iterator.hasNext() && batch.size < ADVERTISEMENT_BATCH) {
                    val entry = iterator.next()
                    iterator.remove()
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
                            ApiCodec.deviceInfoResponse(identity, bluetoothMac))
                    Msg.LIST_ENTITIES_REQUEST ->
                        enqueue(Msg.LIST_ENTITIES_DONE_RESPONSE, ByteArray(0))
                    Msg.GET_TIME_REQUEST ->
                        enqueue(Msg.GET_TIME_RESPONSE, ApiCodec.getTimeResponse(clock() / 1000))
                    Msg.SUBSCRIBE_BLE_ADVERTISEMENTS_REQUEST -> {
                        wantsAdvertisements = true
                        // Replay current scanner state so HA renders the
                        // scanner entity immediately.
                        enqueue(Msg.BT_SCANNER_STATE_RESPONSE,
                            ApiCodec.scannerStateResponse(scannerState, scannerMode))
                        updateScanDemand()
                    }
                    Msg.UNSUBSCRIBE_BLE_ADVERTISEMENTS_REQUEST -> {
                        wantsAdvertisements = false
                        updateScanDemand()
                    }
                    Msg.SUBSCRIBE_BT_CONNECTIONS_FREE_REQUEST ->
                        enqueue(Msg.BT_CONNECTIONS_FREE_RESPONSE, ApiCodec.connectionsFreeResponse())
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
                    // Required-ack subscriptions with nothing behind them: a
                    // proxy has no states, services, or logs to stream.
                    Msg.SUBSCRIBE_STATES_REQUEST,
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
