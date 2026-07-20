package me.jxl.kiosk_satellite.sendspin.protocol

import android.util.Log
import me.jxl.kiosk_satellite.sendspin.AdaptiveBufferPolicy
import me.jxl.kiosk_satellite.sendspin.SendspinTimeFilter
import me.jxl.kiosk_satellite.sendspin.protocol.message.BinaryMessageParser
import me.jxl.kiosk_satellite.sendspin.protocol.message.MessageBuilder
import me.jxl.kiosk_satellite.sendspin.protocol.message.MessageParser
import me.jxl.kiosk_satellite.sendspin.protocol.timesync.TimeSyncManager
import kotlinx.coroutines.CoroutineScope
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.contentOrNull
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive

/**
 * Abstract base class for SendSpin protocol handling.
 *
 * Contains shared protocol logic used by [SendSpin]:
 * - Message building and sending
 * - Message parsing and dispatching
 * - Time synchronization
 * - Binary message handling
 *
 * Subclasses implement transport-specific behavior and connection state
 * management.
 *
 * @param tag Log tag for debugging
 */
abstract class SendSpinProtocolHandler(
    protected val tag: String
) {
    // Protocol state
    @Volatile
    protected var handshakeComplete = false
    protected var currentVolume: Int = 100
    protected var currentMuted: Boolean = false
    // Per Sendspin spec, a client that has not yet synchronized to the
    // server timeline reports "error". Updated by [evaluateAndPublishSyncState].
    protected var currentSyncState: String = "error"

    private val syncStateLock = Any()
    private var hasEverConverged: Boolean = false
    private var lastPublishedMute: Boolean = false

    // True while the client's audio output is in use by an external system
    // (e.g. another app holds audio focus). Overrides synchronized/error
    // reporting until cleared. Per spec, the server reacts by parking this
    // client in a solo group and ending its streams.
    private var externalSourceActive: Boolean = false

    // Stream active tracking (mirrors CLI _stream_active)
    private var _streamActive = false
    private var _currentStreamConfig: StreamConfig? = null

    // Last received values for change detection (avoids unnecessary UI recomposition)
    private var lastMetadata: TrackMetadata? = null
    private var lastPlaybackState: String? = null
    private var lastGroupInfo: GroupInfo? = null

    // Merged controller (group-level) state from server/state deltas.
    private var currentControllerState: ControllerState? = null

    // Time sync manager (lazy initialized by subclass)
    protected var timeSyncManager: TimeSyncManager? = null

    // Adaptive jitter-buffer policy: reports a generous min_buffer_ms by default
    // and grows it on trouble (RTT spikes / sync loss), backing off slowly on a
    // sustained-good link. Constructed by [initTimeSyncManager] with the
    // memory-appropriate profile. Guarded by [adaptiveBufferLock] because the
    // time-sync callback can fire from either the burst-loop or the receive thread.
    private var adaptiveBuffer: AdaptiveBufferPolicy? = null
    private val adaptiveBufferLock = Any()
    private var lastReportedMinBufferMs: Int = SendSpinProtocol.PlayerTiming.MIN_BUFFER_MS

    // ========== Abstract Transport Methods ==========

    /**
     * Send a text message over the WebSocket.
     */
    protected abstract fun sendTextMessage(text: String)

    /**
     * Get the coroutine scope for async operations.
     */
    protected abstract fun getCoroutineScope(): CoroutineScope

    /**
     * Get the time filter for this connection.
     */
    abstract fun getTimeFilter(): SendspinTimeFilter

    /**
     * Whether the device is in low-memory mode (smaller buffer target).
     */
    protected abstract fun isLowMemoryMode(): Boolean

    /**
     * Get the client ID for this connection.
     */
    protected abstract fun getClientId(): String

    /**
     * Get the device name for this connection.
     */
    protected abstract fun getDeviceName(): String

    // ========== Abstract Event Callbacks ==========

    /**
     * Called when handshake completes with server.
     */
    protected abstract fun onHandshakeComplete(serverName: String, serverId: String)

    /**
     * Called when track metadata is updated.
     */
    protected abstract fun onMetadataUpdate(metadata: TrackMetadata)

    /**
     * Called when playback state changes.
     */
    protected abstract fun onPlaybackStateChanged(state: String)

    /**
     * Called when server sends a volume command.
     */
    protected abstract fun onVolumeCommand(volume: Int)

    /**
     * Called when server sends a mute command.
     */
    protected abstract fun onMuteCommand(muted: Boolean)

    /**
     * Called when group info is updated.
     */
    protected abstract fun onGroupUpdate(info: GroupInfo)

    /**
     * Called when audio stream starts.
     */
    protected abstract fun onStreamStart(config: StreamConfig)

    /**
     * Called when stream clear is requested.
     */
    protected abstract fun onStreamClear()

    /**
     * Called when stream ends (server terminates playback).
     */
    protected abstract fun onStreamEnd()

    /**
     * Called when audio chunk is received.
     */
    protected abstract fun onAudioChunk(timestampMicros: Long, audioData: ByteArray)

    /**
     * Called when artwork is received.
     */
    protected abstract fun onArtwork(channel: Int, payload: ByteArray)

    /**
     * Called when sync offset is received from GroupSync.
     */
    protected abstract fun onSyncOffsetApplied(offsetMs: Double, source: String)

    /**
     * Called when the merged controller (group-level) state changes:
     * supported_commands, group volume/mute, repeat, shuffle.
     * Default no-op for handlers that don't surface controller state.
     */
    protected open fun onControllerStateUpdate(state: ControllerState) {}

    /**
     * Called when the audio output should be silenced or unsilenced because
     * the client cannot maintain sync. Per Sendspin spec, clients in the
     * "error" state must mute their audio output and continue buffering
     * until they can resume synchronized playback.
     *
     * Fires only on transitions, not on every re-evaluation. The argument
     * is the desired mute state.
     */
    protected abstract fun onSyncMuteChanged(muted: Boolean)

    // ========== Protocol Message Sending ==========

    /**
     * Get the manufacturer name for device identification.
     */
    protected abstract fun getManufacturer(): String

    /**
     * Get the supported audio formats for the client/hello handshake.
     */
    protected abstract fun getSupportedFormats(): List<MessageBuilder.FormatEntry>

    /**
     * Get the client app version reported in device_info.software_version.
     */
    protected abstract fun getSoftwareVersion(): String

    /**
     * Send client/hello message to start handshake.
     *
     * Buffer capacity is computed from the format list and target duration
     * so the wire-byte cap scales with the highest PCM bitrate we advertise.
     */
    protected fun sendClientHello() {
        val formats = getSupportedFormats()
        val bufferDuration = if (isLowMemoryMode()) {
            SendSpinProtocol.Buffer.DURATION_LOW_MEM_SEC
        } else {
            SendSpinProtocol.Buffer.DURATION_NORMAL_SEC
        }
        val bufferCapacity = MessageBuilder.calculateBufferCapacity(formats, bufferDuration)
        val text = MessageBuilder.buildClientHello(
            clientId = getClientId(),
            deviceName = getDeviceName(),
            bufferCapacity = bufferCapacity,
            manufacturer = getManufacturer(),
            supportedFormats = formats,
            softwareVersion = getSoftwareVersion()
        )
        sendTextMessage(text)
        Log.d(tag, "Sent client/hello: ${text.take(500)}")
    }

    /**
     * Send client/time message for clock synchronization.
     */
    protected fun sendClientTime() {
        val clientTransmitted = System.nanoTime() / 1000 // Convert to microseconds
        sendTextMessage(MessageBuilder.buildClientTime(clientTransmitted))
    }

    /**
     * Send goodbye message before disconnecting.
     */
    protected fun sendGoodbye(reason: String) {
        if (!handshakeComplete) return
        sendTextMessage(MessageBuilder.buildGoodbye(reason))
    }

    /**
     * Send player state update (volume/muted/sync state).
     */
    protected fun sendPlayerStateUpdate() {
        val delayMs = getTimeFilter().staticDelayMs
        val minBufferMs = synchronized(adaptiveBufferLock) {
            val target = adaptiveBuffer?.currentTargetMs ?: SendSpinProtocol.PlayerTiming.MIN_BUFFER_MS
            lastReportedMinBufferMs = target
            target
        }
        sendTextMessage(
            MessageBuilder.buildPlayerState(
                currentVolume, currentMuted, currentSyncState, delayMs,
                minBufferMs = minBufferMs
            )
        )
    }

    /**
     * Feed one time-sync measurement into the adaptive buffer policy and, if the
     * learned `min_buffer_ms` target shifted, report it (debounced by the policy's
     * own grow/shrink cooldowns). Also re-evaluates sync state, preserving the
     * previous [onMeasurementApplied] behavior.
     */
    private fun onTimeMeasurement(rttMicros: Long) {
        val filter = getTimeFilter()
        val quality = when {
            filter.isReady && filter.isConverged -> AdaptiveBufferPolicy.SyncQuality.GOOD
            filter.isReady -> AdaptiveBufferPolicy.SyncQuality.DEGRADED
            else -> AdaptiveBufferPolicy.SyncQuality.LOST
        }
        val changed = synchronized(adaptiveBufferLock) {
            val policy = adaptiveBuffer
            if (policy != null) {
                policy.update(
                    nowMs = android.os.SystemClock.elapsedRealtime(),
                    rttMs = rttMicros / 1000.0,
                    quality = quality
                )
                policy.currentTargetMs != lastReportedMinBufferMs
            } else {
                false
            }
        }
        evaluateAndPublishSyncState()
        if (changed && handshakeComplete) {
            Log.d(tag, "Adaptive min_buffer_ms -> ${adaptiveBuffer?.currentTargetMs}")
            sendPlayerStateUpdate()
        }
    }

    /**
     * Public hook for code outside the protocol handler (e.g.
     * [OutputLatencyEstimator] via [SyncAudioPlayer]) to push a fresh
     * `client/state` to the server, for example after auto-measured
     * `static_delay_ms` converges.
     */
    fun sendClientStateSnapshot() {
        if (!handshakeComplete) return
        sendPlayerStateUpdate()
    }

    /**
     * Set sync state and notify server.
     *
     * Per spec: report "synchronized" when locked to server timeline,
     * report "error" when unable to maintain sync (buffer underrun, clock issues).
     *
     * @param syncState Either "synchronized" or "error"
     */
    fun setSyncState(syncState: String) {
        if (syncState != "synchronized" && syncState != "error") {
            Log.w(tag, "Invalid sync state: $syncState (must be 'synchronized' or 'error')")
            return
        }
        if (currentSyncState != syncState) {
            currentSyncState = syncState
            Log.d(tag, "Sync state changed to: $syncState")
            if (handshakeComplete) {
                sendPlayerStateUpdate()
            }
        }
    }

    /**
     * Report or clear the 'external_source' client state (spec: output is
     * in use by an external system, e.g. another app holds audio focus).
     *
     * While active, [evaluateAndPublishSyncState] is suspended so the
     * filter-derived synchronized/error states don't overwrite it. On
     * clear, the state is recomputed from the time filter and republished.
     *
     * Safe to call from any thread.
     */
    fun setExternalSource(active: Boolean) {
        val changed = synchronized(syncStateLock) {
            if (externalSourceActive == active) return
            externalSourceActive = active
            if (active) {
                currentSyncState = "external_source"
            } else {
                val filter = getTimeFilter()
                currentSyncState = if (filter.isReady && filter.isConverged) "synchronized" else "error"
            }
            true
        }
        if (changed) {
            Log.i(tag, "External source ${if (active) "active" else "cleared"}: state=$currentSyncState")
            if (handshakeComplete) sendPlayerStateUpdate()
        }
    }

    /**
     * Recompute the client's sync state from the time filter and publish
     * any change to the server and to the audio sink.
     *
     * Reports "synchronized" once the filter is converged for the first
     * time, "error" otherwise. Audio mute is requested only after a
     * successful sync has been established at least once and is then lost
     * — the initial pre-sync window does not silence playback.
     *
     * Idempotent: only fires server / mute notifications on transitions.
     * Safe to call from any thread.
     */
    fun evaluateAndPublishSyncState() {
        val muteChange: Boolean? = synchronized(syncStateLock) {
            // While an external source owns the output, synchronized/error
            // reporting (and its mute side effects) is suspended.
            if (externalSourceActive) return

            val filter = getTimeFilter()
            val converged = filter.isReady && filter.isConverged
            if (converged) {
                hasEverConverged = true
            }

            val desiredState = if (converged) "synchronized" else "error"
            setSyncState(desiredState)

            val desiredMute = hasEverConverged && desiredState == "error"
            if (desiredMute != lastPublishedMute) {
                lastPublishedMute = desiredMute
                desiredMute
            } else {
                null
            }
        }
        if (muteChange != null) {
            onSyncMuteChanged(muteChange)
        }
    }

    /**
     * Reset all sync-state tracking back to "before any sync has been
     * achieved on this server." Call this on a fresh connection to a new
     * server; do NOT call it during a normal reconnect cycle.
     *
     * Safe to call from any thread.
     */
    fun resetSyncStateTracking() {
        val needsUnmute = synchronized(syncStateLock) {
            hasEverConverged = false
            externalSourceActive = false
            currentSyncState = "error"
            if (lastPublishedMute) {
                lastPublishedMute = false
                true
            } else {
                false
            }
        }
        if (needsUnmute) {
            onSyncMuteChanged(false)
        }
    }

    /**
     * Request a different stream format from the server (spec
     * stream/request-format). Omitted fields keep their current value.
     * The server responds with stream/start, which flows through the
     * normal format-change reconfiguration path.
     */
    fun requestStreamFormat(
        codec: String? = null,
        sampleRate: Int? = null,
        channels: Int? = null,
        bitDepth: Int? = null
    ) {
        if (!handshakeComplete) return
        Log.i(tag, "Requesting stream format: codec=$codec, rate=$sampleRate, ch=$channels, bits=$bitDepth")
        sendTextMessage(MessageBuilder.buildStreamRequestFormat(codec, sampleRate, channels, bitDepth))
    }

    // ========== Player State Methods ==========

    /**
     * Set volume and notify server.
     *
     * @param volume Volume level from 0.0 to 1.0
     */
    fun setVolume(volume: Double) {
        val volumePercent = (volume * 100).toInt().coerceIn(0, 100)
        currentVolume = volumePercent
        Log.d(tag, "setVolume: $volumePercent%")
        sendPlayerStateUpdate()
    }

    /**
     * Set muted state and notify server.
     */
    fun setMuted(muted: Boolean) {
        currentMuted = muted
        Log.d(tag, "setMuted: $muted")
        sendPlayerStateUpdate()
    }

    /**
     * Set initial volume before handshake.
     *
     * @param volume Volume level from 0 to 100
     * @param muted Whether audio is muted
     */
    fun setInitialVolume(volume: Int, muted: Boolean = false) {
        currentVolume = volume.coerceIn(0, 100)
        currentMuted = muted
        Log.d(tag, "Initial volume set: $currentVolume, muted=$currentMuted")
    }

    // ========== Time Sync ==========

    /**
     * Start time synchronization.
     */
    protected fun startTimeSync() {
        val manager = timeSyncManager
        if (manager != null && !manager.isRunning) {
            manager.start(getCoroutineScope())
        }
    }

    /**
     * Stop time synchronization.
     */
    protected fun stopTimeSync() {
        timeSyncManager?.stop()
    }

    /**
     * Initialize time sync manager.
     */
    protected fun initTimeSyncManager(timeFilter: SendspinTimeFilter) {
        synchronized(adaptiveBufferLock) {
            val policy = AdaptiveBufferPolicy(
                if (isLowMemoryMode()) AdaptiveBufferPolicy.lowMemory() else AdaptiveBufferPolicy.generous()
            )
            adaptiveBuffer = policy
            lastReportedMinBufferMs = policy.currentTargetMs
        }
        timeSyncManager = TimeSyncManager(
            timeFilter = timeFilter,
            sendClientTime = { sendClientTime() },
            onMeasurementApplied = { rttMicros -> onTimeMeasurement(rttMicros) },
            tag = tag
        )
    }

    // ========== Message Handling ==========

    /**
     * Handle incoming text (JSON) message.
     * Dispatches to appropriate handler based on message type.
     */
    protected fun handleTextMessage(text: String) {
        Log.d(tag, "Received: ${text.take(500)}")

        try {
            val json = Json.parseToJsonElement(text).jsonObject
            val type = json["type"]?.jsonPrimitive?.contentOrNull ?: return
            val payload = json["payload"]?.jsonObject

            when (type) {
                SendSpinProtocol.MessageType.SERVER_HELLO -> handleServerHello(payload)
                SendSpinProtocol.MessageType.SERVER_TIME -> handleServerTime(payload)
                SendSpinProtocol.MessageType.SERVER_STATE -> handleServerState(payload)
                SendSpinProtocol.MessageType.SERVER_COMMAND -> handleServerCommand(payload)
                SendSpinProtocol.MessageType.GROUP_UPDATE -> handleGroupUpdate(payload)
                SendSpinProtocol.MessageType.STREAM_START -> handleStreamStart(payload)
                SendSpinProtocol.MessageType.STREAM_END -> handleStreamEnd(payload)
                SendSpinProtocol.MessageType.STREAM_CLEAR -> handleStreamClear()
                SendSpinProtocol.MessageType.CLIENT_SYNC_OFFSET -> handleClientSyncOffset(payload)
                else -> Log.d(tag, "Unhandled message type: $type")
            }
        } catch (e: Exception) {
            Log.e(tag, "Failed to parse message: ${text.take(100)}", e)
        }
    }

    protected open fun handleServerHello(payload: JsonObject?) {
        val result = MessageParser.parseServerHello(payload, "Unknown")
        if (result == null) {
            Log.e(tag, "Failed to parse server/hello")
            return
        }

        Log.i(tag, "server/hello: name=${result.serverName}, id=${result.serverId}, reason=${result.connectionReason}")
        Log.d(tag, "Active roles: ${result.activeRoles}")

        handshakeComplete = true

        // Clear cached values so the first post-handshake messages always propagate
        _streamActive = false
        _currentStreamConfig = null
        lastMetadata = null
        lastPlaybackState = null
        lastGroupInfo = null
        currentControllerState = null

        onHandshakeComplete(result.serverName, result.serverId)

        sendPlayerStateUpdate()
        startTimeSync()
    }

    protected fun handleServerTime(payload: JsonObject?) {
        val clientReceived = System.nanoTime() / 1000
        val measurement = MessageParser.parseServerTime(payload, clientReceived)

        if (measurement != null) {
            timeSyncManager?.onServerTime(measurement)
        }
    }

    protected fun handleServerState(payload: JsonObject?) {
        val (metadata, state, controllerDelta) = MessageParser.parseServerState(payload)

        if (metadata != null) {
            lastMetadata = metadata
            onMetadataUpdate(metadata)
        }

        if (state != null && state != lastPlaybackState) {
            lastPlaybackState = state
            onPlaybackStateChanged(state)
        }

        if (controllerDelta != null) {
            val merged = currentControllerState?.mergedWith(controllerDelta) ?: controllerDelta
            if (merged != currentControllerState) {
                currentControllerState = merged
                onControllerStateUpdate(merged)
            }
        }
    }

    protected fun handleServerCommand(payload: JsonObject?) {
        Log.i(tag, "[cmd-trace] T1 handleServerCommand ts=${System.nanoTime() / 1_000_000} thread=${Thread.currentThread().name}")
        when (val result = MessageParser.parseServerCommand(payload)) {
            is ServerCommandResult.Volume -> {
                Log.d(tag, "Server command: set volume to ${result.volume}%")
                currentVolume = result.volume
                onVolumeCommand(result.volume)
                sendPlayerStateUpdate()
            }
            is ServerCommandResult.Mute -> {
                Log.d(tag, "Server command: set mute to ${result.muted}")
                currentMuted = result.muted
                onMuteCommand(result.muted)
                sendPlayerStateUpdate()
            }
            is ServerCommandResult.SetStaticDelay -> {
                Log.i(tag, "Server command: set static delay to ${result.delayMs}ms")
                // Same application path as the client/sync_offset extension:
                // a server-pushed correction on top of the auto-measured
                // hardware latency.
                getTimeFilter().setServerSyncOffsetMs(result.delayMs.toDouble())
                onSyncOffsetApplied(result.delayMs.toDouble(), "server_command")
                sendPlayerStateUpdate()
            }
            is ServerCommandResult.Unknown -> {
                Log.d(tag, "Unknown player command: ${result.command}")
            }
            null -> { /* No player command in payload */ }
        }
    }

    protected fun handleGroupUpdate(payload: JsonObject?) {
        val info = MessageParser.parseGroupUpdate(payload)
        if (info != null) {
            lastGroupInfo = info
            Log.v(tag, "group/update: id=${info.groupId}, name=${info.groupName}, state=${info.playbackState}")
            onGroupUpdate(info)
        }
    }

    protected fun handleStreamStart(payload: JsonObject?) {
        val config = MessageParser.parseStreamStart(payload)
        if (config == null) return

        val formatChanged = _streamActive && config != _currentStreamConfig
        if (_streamActive) {
            if (formatChanged) {
                Log.i(tag, "Stream format changed: codec=${config.codec}, rate=${config.sampleRate}, ch=${config.channels}, bits=${config.bitDepth} - reconfiguring pipeline")
            } else {
                Log.d(tag, "Stream restart (same format): codec=${config.codec}, rate=${config.sampleRate}")
            }
        } else {
            Log.i(tag, "Stream started: codec=${config.codec}, rate=${config.sampleRate}, ch=${config.channels}, bits=${config.bitDepth}, header=${config.codecHeader?.size ?: 0} bytes")
        }

        _streamActive = true
        _currentStreamConfig = config
        onStreamStart(config)
    }

    protected fun handleStreamClear() {
        Log.i(tag, "[cmd-trace] T1 handleStreamClear ts=${System.nanoTime() / 1_000_000} thread=${Thread.currentThread().name}")
        Log.v(tag, "Stream clear - flushing audio buffers")
        onStreamClear()
    }

    protected fun handleStreamEnd(payload: JsonObject?) {
        Log.i(tag, "[cmd-trace] T1 handleStreamEnd ts=${System.nanoTime() / 1_000_000} thread=${Thread.currentThread().name}")
        val rolesArray = payload?.get("roles")?.jsonArray
        val roles = rolesArray?.map { it.jsonPrimitive.content }

        // Match on the role FAMILY, not the versioned name: the spec uses
        // unversioned names in message bodies, so Music Assistant sends
        // ["player"], not ["player@v1"]. Comparing against the versioned
        // constant made every stream/end look like someone else's, so the
        // ~30s chunk queue kept playing after a stop and poisoned the next
        // stream's timeline.
        val playerFamily = SendSpinProtocol.Roles.PLAYER.substringBefore('@')
        if (roles != null &&
            roles.none { it.substringBefore('@') == playerFamily }) {
            Log.d(tag, "Stream end for non-player roles: $roles - ignoring")
            return
        }

        Log.i(tag, "Stream end - server terminated playback (roles=${roles ?: "all"})")
        _streamActive = false
        _currentStreamConfig = null
        onStreamEnd()
    }

    protected fun handleClientSyncOffset(payload: JsonObject?) {
        val result = MessageParser.parseSyncOffset(payload)
        if (result == null) {
            Log.w(tag, "client/sync_offset: missing or invalid payload")
            return
        }

        Log.i(tag, "client/sync_offset: offset=${result.offsetMs}ms from ${result.source}")

        val clampedOffset = result.offsetMs.coerceIn(-5000.0, 5000.0)
        if (clampedOffset != result.offsetMs) {
            Log.w(tag, "client/sync_offset: clamped from ${result.offsetMs}ms to ${clampedOffset}ms")
        }

        getTimeFilter().setServerSyncOffsetMs(clampedOffset)
        Log.d(tag, "client/sync_offset: static delay set to ${clampedOffset}ms")

        onSyncOffsetApplied(clampedOffset, result.source)
    }

    // ========== Binary Message Handling ==========

    /**
     * Handle binary message from the transport.
     */
    protected fun handleBinaryMessage(bytes: ByteArray) {
        val message = BinaryMessageParser.parse(bytes)
        if (message != null) {
            dispatchBinaryMessage(message)
        }
    }

    /**
     * Dispatch parsed binary message to appropriate handler.
     */
    private fun dispatchBinaryMessage(message: BinaryMessageParser.BinaryMessage) {
        when (message) {
            is BinaryMessageParser.BinaryMessage.Audio -> {
                // Spec: binary messages should be rejected if there is no
                // active stream (e.g. chunks in flight after stream/end).
                if (!_streamActive) {
                    Log.v(tag, "Dropping audio chunk: no active stream")
                    return
                }
                onAudioChunk(message.timestampMicros, message.payload)
            }
            is BinaryMessageParser.BinaryMessage.Artwork -> {
                Log.v(tag, "Received artwork channel ${message.channel}: ${message.payload.size} bytes")
                onArtwork(message.channel, message.payload)
            }
            is BinaryMessageParser.BinaryMessage.Visualizer -> {
                // Visualization data - currently not used, no logging needed
            }
            is BinaryMessageParser.BinaryMessage.Unknown -> {
                Log.v(tag, "Unknown binary message type: ${message.type}")
            }
        }
    }
}
