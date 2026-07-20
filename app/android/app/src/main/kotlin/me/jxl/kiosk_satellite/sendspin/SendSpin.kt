package me.jxl.kiosk_satellite.sendspin

import android.os.Build
import android.util.Log
import me.jxl.kiosk_satellite.sendspin.decoder.AudioDecoderFactory
import me.jxl.kiosk_satellite.sendspin.protocol.GroupInfo
import me.jxl.kiosk_satellite.sendspin.protocol.SendSpinProtocol
import me.jxl.kiosk_satellite.sendspin.protocol.SendSpinProtocolHandler
import me.jxl.kiosk_satellite.sendspin.protocol.StreamConfig
import me.jxl.kiosk_satellite.sendspin.protocol.TrackMetadata
import me.jxl.kiosk_satellite.sendspin.protocol.message.MessageBuilder
import me.jxl.kiosk_satellite.sendspin.transport.OkHttpWebSocketTransport
import me.jxl.kiosk_satellite.sendspin.transport.SendSpinTransport
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicInteger
import java.util.concurrent.atomic.AtomicLong
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExecutorCoroutineDispatcher
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.asCoroutineDispatcher
import kotlinx.coroutines.cancel
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

/**
 * Native Kotlin SendSpin client for Kiosk Satellite.
 *
 * Implements the Sendspin Protocol for synchronized multi-room audio
 * streaming. Protocol spec: https://www.sendspin-audio.com/spec/
 *
 * Ported from SendspinDroid's SendSpin client, reduced to the
 * client-initiated LOCAL mode: a plain `ws://host:port/sendspin` WebSocket.
 * The reference app's PROXY/REMOTE (WebRTC) transports, auth flows, and
 * Music Assistant API surface are stripped.
 *
 * ## Protocol Overview
 * 1. Connect via WebSocket
 * 2. Send client/hello with capabilities
 * 3. Receive server/hello with active roles
 * 4. Send client/time messages continuously for clock sync
 * 5. Receive binary audio chunks (type 4) with microsecond timestamps
 * 6. Play audio at computed client time using Kalman-filtered offset
 */
class SendSpin(
    private val deviceName: String,
    private val clientId: String,
    private val preferredCodec: String,
    private val softwareVersion: String,
    private val callback: Callback
) : SendSpinProtocolHandler(TAG) {

    companion object {
        private const val TAG = "sendspin"

        // Reconnection configuration
        // Sequence: 500ms, 1s, 2s, 4s, 8s - then 30s steady-state forever.
        private const val MAX_RECONNECT_ATTEMPTS = 5
        private const val INITIAL_RECONNECT_DELAY_MS = 500L
        private const val MAX_RECONNECT_DELAY_MS = 10000L
        private const val STEADY_RECONNECT_DELAY_MS = 30_000L

        // Hard ceiling on reconnect attempts per cycle. Reset to 0 on every
        // successful handshake. On exhaustion the failure is surfaced via
        // Callback.onReconnectExhausted and no more attempts are scheduled.
        private const val MAX_TOTAL_RECONNECT_ATTEMPTS = 20

        // Stall watchdog: while connected+handshake-complete, if no bytes arrive
        // for this long, force-close the transport so the reconnect path kicks in.
        private const val STALL_TIMEOUT_MS = 7_000L
        private const val STALL_CHECK_INTERVAL_MS = 3_000L

        // Idle-mode stall threshold. Larger than the streaming threshold because
        // during idle the only regular server->client traffic is server/time
        // responses to our TimeSyncManager bursts.
        private const val IDLE_STALL_TIMEOUT_MS = 20_000L
    }

    /** Connection state exposed to the bridge. */
    enum class ConnectionState { IDLE, CONNECTING, READY, FAILED }

    /**
     * Callback interface for SendSpin events. All callbacks may fire on
     * transport or timer threads; never assume the main thread.
     */
    interface Callback {
        fun onConnectionStateChanged(state: ConnectionState)
        fun onHandshakeComplete(serverName: String)
        fun onStateChanged(state: String)
        fun onGroupUpdate(groupId: String, groupName: String, playbackState: String)
        fun onMetadataUpdate(
            title: String,
            artist: String,
            album: String,
            artworkUrl: String,
            durationMs: Long,
            positionMs: Long
        )
        fun onStreamStart(codec: String, sampleRate: Int, channels: Int, bitDepth: Int, codecHeader: ByteArray?)
        fun onStreamClear()
        fun onStreamEnd()
        fun onAudioChunk(serverTimeMicros: Long, audioData: ByteArray)
        fun onVolumeChanged(volume: Int)
        fun onMutedChanged(muted: Boolean)
        fun onSyncMuteChanged(muted: Boolean)
        fun onReconnectExhausted()
    }

    // Dedicated single-thread dispatcher for timer-dominated work: stall
    // watchdog polling, reconnect backoff delays, TimeSyncManager's
    // periodic scheduler.
    private val timerDispatcher: ExecutorCoroutineDispatcher =
        Executors.newSingleThreadExecutor { r ->
            Thread(r, "SendSpinTimer").apply { isDaemon = true }
        }.asCoroutineDispatcher()
    private val timerScope = CoroutineScope(SupervisorJob() + timerDispatcher)

    // Dispatchers.IO scope for blocking IO work.
    private val workScope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    @Volatile
    private var connectionState: ConnectionState = ConnectionState.IDLE

    private var transport: SendSpinTransport? = null

    // Connection info (stored for reconnection)
    private var serverAddress: String? = null
    private var serverPath: String? = null
    private var serverName: String? = null
    private var serverId: String? = null

    // Time synchronization (Kalman filter)
    private val timeFilter = SendspinTimeFilter()

    // Reconnection state
    private val userInitiatedDisconnect = AtomicBoolean(false)
    private val reconnectAttempts = AtomicInteger(0)
    private val reconnecting = AtomicBoolean(false)
    private var reconnectJob: Job? = null

    // Stall watchdog state. lastByteReceivedAtMs is updated on EVERY text/binary
    // message from the transport.
    private val lastByteReceivedAtMs = AtomicLong(System.currentTimeMillis())
    private val watchdogLock = Any()
    @Volatile
    private var stallWatchdogJob: Job? = null

    // True while a server-announced audio stream is active. The stall watchdog
    // uses the shorter streaming threshold only while streaming.
    private val streamActive = AtomicBoolean(false)

    val isConnected: Boolean
        get() = connectionState == ConnectionState.READY

    init {
        initTimeSyncManager(timeFilter)
    }

    private fun setConnectionState(state: ConnectionState) {
        if (connectionState != state) {
            connectionState = state
            callback.onConnectionStateChanged(state)
        }
    }

    // ========== SendSpinProtocolHandler Implementation ==========

    override fun sendTextMessage(text: String) {
        val t = transport ?: return // Silently drop if transport is gone (post-disconnect race)
        if (!t.send(text)) {
            Log.w(TAG, "Failed to send message")
        }
    }

    override fun getCoroutineScope(): CoroutineScope = timerScope

    override fun getTimeFilter(): SendspinTimeFilter = timeFilter

    override fun isLowMemoryMode(): Boolean = false

    override fun getClientId(): String = clientId

    override fun getDeviceName(): String = deviceName

    override fun getManufacturer(): String = Build.MANUFACTURER ?: "Unknown"

    override fun getSoftwareVersion(): String = softwareVersion

    override fun getSupportedFormats(): List<MessageBuilder.FormatEntry> =
        MessageBuilder.buildSupportedFormats(
            preferredCodec = preferredCodec,
            isCodecSupported = { AudioDecoderFactory.isCodecSupported(it) }
        )

    override fun onHandshakeComplete(serverName: String, serverId: String) {
        this.serverName = serverName
        this.serverId = serverId

        val wasReconnecting = timeFilter.isFrozen || reconnecting.get()

        if (timeFilter.isFrozen) {
            val thawed = timeFilter.thaw(serverName, serverId)
            if (thawed) {
                Log.i(TAG, "Time filter thawed after reconnection - re-syncing with increased covariance")
            } else {
                timeFilter.resetAndDiscard()
                resetSyncStateTracking()
                Log.i(TAG, "Server identity changed during reconnect; discarded frozen sync state")
            }
        }

        evaluateAndPublishSyncState()

        reconnecting.set(false)
        reconnectAttempts.set(0)
        setConnectionState(ConnectionState.READY)

        if (wasReconnecting) {
            Log.i(TAG, "Reconnection successful")
        }

        streamActive.set(false) // fresh handshake - wait for server to announce stream state
        startStallWatchdog()
        callback.onHandshakeComplete(serverName)
    }

    override fun onMetadataUpdate(metadata: TrackMetadata) {
        // Per spec, extrapolate the reported position from the metadata's
        // server timestamp to "now" before publishing. Requires a converged
        // clock; fall back to the raw value until then.
        val positionMs = if (timeFilter.isReady) {
            metadata.progressAtServerTime(timeFilter.clientToServer(System.nanoTime() / 1000))
        } else {
            metadata.positionMs
        }
        callback.onMetadataUpdate(
            metadata.title,
            metadata.artist,
            metadata.album,
            metadata.artworkUrl,
            metadata.durationMs,
            positionMs
        )
    }

    override fun onPlaybackStateChanged(state: String) {
        callback.onStateChanged(state)
    }

    override fun onVolumeCommand(volume: Int) {
        callback.onVolumeChanged(volume)
    }

    override fun onMuteCommand(muted: Boolean) {
        callback.onMutedChanged(muted)
    }

    override fun onGroupUpdate(info: GroupInfo) {
        callback.onGroupUpdate(info.groupId, info.groupName, info.playbackState)
    }

    override fun onStreamStart(config: StreamConfig) {
        streamActive.set(true)
        // Reset so we don't false-trip from a stale timestamp accumulated while
        // the stream was inactive.
        lastByteReceivedAtMs.set(System.currentTimeMillis())

        Log.i(TAG, "Stream started: server chose codec=${config.codec} (we preferred=$preferredCodec)")
        callback.onStreamStart(
            config.codec,
            config.sampleRate,
            config.channels,
            config.bitDepth,
            config.codecHeader
        )
    }

    override fun onStreamClear() {
        streamActive.set(false)
        callback.onStreamClear()
    }

    override fun onStreamEnd() {
        streamActive.set(false)
        callback.onStreamEnd()
    }

    override fun onAudioChunk(timestampMicros: Long, audioData: ByteArray) {
        callback.onAudioChunk(timestampMicros, audioData)
    }

    override fun onArtwork(channel: Int, payload: ByteArray) {
        // Artwork role is not advertised; nothing to do.
    }

    override fun onSyncOffsetApplied(offsetMs: Double, source: String) {
        Log.i(TAG, "Sync offset applied: ${offsetMs}ms from $source")
    }

    override fun onSyncMuteChanged(muted: Boolean) {
        callback.onSyncMuteChanged(muted)
    }

    // ========== Public API ==========

    fun getServerName(): String? = serverName

    fun getServerAddress(): String? = serverAddress

    /** True when the time filter is locked to the server timeline. */
    fun isSynchronized(): Boolean = timeFilter.isReady && timeFilter.isConverged

    fun isStreamActive(): Boolean = streamActive.get()

    /**
     * Connect to a SendSpin server on the local network.
     *
     * @param address Server address in "host:port" format
     * @param path WebSocket path (from mDNS TXT or default /sendspin)
     */
    fun connect(address: String, path: String = SendSpinProtocol.ENDPOINT_PATH) {
        if (isConnected) {
            Log.w(TAG, "Already connected, disconnecting first")
            disconnect()
        }

        val normalizedPath = normalizePath(path)

        Log.d(TAG, "Connecting locally to: $address path=$normalizedPath")
        prepareForConnection()

        serverAddress = address
        serverPath = normalizedPath

        createLocalTransport(address, normalizedPath)
    }

    /** Common preparation for a fresh connection. */
    private fun prepareForConnection() {
        setConnectionState(ConnectionState.CONNECTING)
        handshakeComplete = false
        timeFilter.reset()
        resetSyncStateTracking()

        // Cancel any pending reconnect from a previous connection attempt
        reconnectJob?.cancel()
        reconnectJob = null

        userInitiatedDisconnect.set(false)
        reconnectAttempts.set(0)
        reconnecting.set(false)

        // Clean up any existing transport. Clear the listener first to prevent
        // stale callbacks from firing on the new transport's listener.
        transport?.setListener(null)
        transport?.destroy()
        transport = null
    }

    private fun createLocalTransport(address: String, path: String) {
        val wsTransport = OkHttpWebSocketTransport(address, path)
        transport = wsTransport
        wsTransport.setListener(TransportEventListener())
        wsTransport.connect()
    }

    /** Disconnect from the current server. */
    fun disconnect() {
        stopStallWatchdog()
        Log.d(TAG, "Disconnecting (user-initiated)")
        userInitiatedDisconnect.set(true)

        // Cancel any pending reconnect coroutine to prevent races
        reconnectJob?.cancel()
        reconnectJob = null

        stopTimeSync()
        reconnecting.set(false)
        sendGoodbye("user_request")
        // Clear the transport listener BEFORE closing to prevent the async
        // onClosed callback from firing after we settle state below.
        transport?.setListener(null)
        transport?.close(1000, "User disconnect")
        transport = null
        handshakeComplete = false
        streamActive.set(false)
        setConnectionState(ConnectionState.IDLE)
    }

    /** Clean up resources. The instance cannot be reused afterwards. */
    fun destroy() {
        stopStallWatchdog()
        stopTimeSync()

        reconnectJob?.cancel()
        reconnectJob = null

        reconnecting.set(false)
        disconnect()

        timerScope.cancel()
        workScope.cancel()
        timerDispatcher.close()
    }

    // ========== Private Methods ==========

    /** Normalize and validate the WebSocket path parameter. */
    private fun normalizePath(path: String): String {
        if (path.isEmpty()) return SendSpinProtocol.ENDPOINT_PATH

        val pathWithoutQuery = path.substringBefore("?")
        if (pathWithoutQuery.isEmpty()) return SendSpinProtocol.ENDPOINT_PATH

        return if (!pathWithoutQuery.startsWith("/")) "/$pathWithoutQuery" else pathWithoutQuery
    }

    /**
     * Start the stall watchdog. Called when the connection reaches a state where
     * we expect data to be flowing. Cancels any previous instance.
     */
    private fun startStallWatchdog() {
        synchronized(watchdogLock) {
            stallWatchdogJob?.cancel()
            // Reset so we don't false-trip using a stale pre-handshake timestamp
            lastByteReceivedAtMs.set(System.currentTimeMillis())
            stallWatchdogJob = timerScope.launch {
                while (true) {
                    delay(STALL_CHECK_INTERVAL_MS)
                    checkStall()
                }
            }
        }
    }

    private fun stopStallWatchdog() {
        synchronized(watchdogLock) {
            stallWatchdogJob?.cancel()
            stallWatchdogJob = null
        }
    }

    /**
     * Check whether the transport has gone silent for too long and force-close
     * it if so. Two-tier threshold: [STALL_TIMEOUT_MS] while a stream is active
     * (audio frames should arrive continuously) and [IDLE_STALL_TIMEOUT_MS]
     * when idle (only server/time responses flow).
     */
    private fun checkStall() {
        if (userInitiatedDisconnect.get()) return
        if (reconnecting.get()) return
        if (!handshakeComplete) return
        val t = transport ?: return
        if (!t.isConnected) return

        val streaming = streamActive.get()
        val threshold = if (streaming) STALL_TIMEOUT_MS else IDLE_STALL_TIMEOUT_MS
        val sinceLastByte = System.currentTimeMillis() - lastByteReceivedAtMs.get()
        if (sinceLastByte > threshold) {
            val mode = if (streaming) "streaming" else "idle"
            Log.w(TAG, "Stall watchdog: no data received in ${sinceLastByte}ms ($mode threshold ${threshold}ms) - forcing transport close")
            // Non-1000 close so the failure path triggers reconnection
            t.close(1001, "stall watchdog ($mode)")
        }
    }

    /**
     * Attempt reconnection with exponential backoff.
     *
     * Exponential backoff for the first 5 attempts (500ms -> 8s), then 30s
     * steady-state retries, capped at [MAX_TOTAL_RECONNECT_ATTEMPTS] attempts
     * per cycle.
     */
    private fun attemptReconnect() {
        if (serverAddress == null) {
            Log.w(TAG, "Cannot reconnect: no connection info saved")
            return
        }

        if (userInitiatedDisconnect.get()) {
            Log.d(TAG, "Not reconnecting: user-initiated disconnect")
            return
        }

        val prior = reconnectAttempts.get()
        if (prior >= MAX_TOTAL_RECONNECT_ATTEMPTS) {
            Log.w(TAG, "Reconnect cap reached ($prior >= $MAX_TOTAL_RECONNECT_ATTEMPTS) - giving up")
            reconnecting.set(false)
            reconnectJob?.cancel()
            reconnectJob = null
            setConnectionState(ConnectionState.FAILED)
            callback.onReconnectExhausted()
            return
        }

        val attempts = reconnectAttempts.incrementAndGet()

        // On first reconnection attempt, freeze the time filter so a
        // successful reconnect to the same server can restore sync.
        if (attempts == 1) {
            timeFilter.freeze(serverName, serverId)
            Log.i(TAG, "Time filter frozen for reconnection (had ${timeFilter.measurementCountValue} measurements)")
        }
        stopStallWatchdog() // watchdog restarts on next successful handshake

        val delayMs = if (attempts > MAX_RECONNECT_ATTEMPTS) {
            STEADY_RECONNECT_DELAY_MS
        } else {
            (INITIAL_RECONNECT_DELAY_MS * (1 shl (attempts - 1)))
                .coerceAtMost(MAX_RECONNECT_DELAY_MS)
        }

        Log.i(TAG, "Attempting reconnection $attempts in ${delayMs}ms")
        reconnecting.set(true)
        setConnectionState(ConnectionState.CONNECTING)

        reconnectJob = timerScope.launch {
            delay(delayMs)

            if (userInitiatedDisconnect.get() || !reconnecting.get()) {
                Log.d(TAG, "Reconnection cancelled")
                return@launch
            }

            handshakeComplete = false
            stopTimeSync()

            // Clean up old transport
            transport?.destroy()
            transport = null

            // Transport creation does blocking IO - switch dispatchers
            withContext(Dispatchers.IO) {
                val address = serverAddress ?: return@withContext
                val path = serverPath ?: SendSpinProtocol.ENDPOINT_PATH
                Log.d(TAG, "Reconnecting to: $address path=$path (attempt $attempts)")
                createLocalTransport(address, path)
            }
        }
    }

    // ========== Transport Event Listener ==========

    private inner class TransportEventListener : SendSpinTransport.Listener {

        override fun onConnected() {
            Log.d(TAG, "Transport connected")
            sendClientHello()
        }

        override fun onMessage(text: String) {
            lastByteReceivedAtMs.set(System.currentTimeMillis())
            handleTextMessage(text)
        }

        override fun onMessage(bytes: ByteArray) {
            lastByteReceivedAtMs.set(System.currentTimeMillis())
            handleBinaryMessage(bytes)
        }

        override fun onClosing(code: Int, reason: String) {
            Log.d(TAG, "Transport closing: $code $reason")
        }

        override fun onClosed(code: Int, reason: String) {
            Log.d(TAG, "Transport closed: $code $reason")

            // Code 1000 = Normal Closure - server intentionally ended the
            // session; NOT an error that should trigger reconnection.
            val isNormalClosure = code == 1000

            if (!userInitiatedDisconnect.get() && !isNormalClosure && serverAddress != null) {
                Log.i(TAG, "Abnormal closure (code=$code, handshakeComplete=$handshakeComplete), attempting reconnection")
                attemptReconnect()
            } else {
                if (isNormalClosure && !userInitiatedDisconnect.get()) {
                    Log.i(TAG, "Server closed connection normally (code 1000) - session ended")
                }
                reconnecting.set(false)
                setConnectionState(ConnectionState.IDLE)
            }
        }

        override fun onFailure(error: Throwable, isRecoverable: Boolean) {
            Log.e(TAG, "Transport failure: ${error.message}")

            val shouldReconnect = !userInitiatedDisconnect.get() &&
                    serverAddress != null &&
                    isRecoverable

            if (shouldReconnect) {
                Log.i(TAG, "Recoverable error, attempting reconnection: ${error.message}")
                attemptReconnect()
            } else {
                reconnecting.set(false)
                setConnectionState(ConnectionState.FAILED)
            }
        }
    }
}
