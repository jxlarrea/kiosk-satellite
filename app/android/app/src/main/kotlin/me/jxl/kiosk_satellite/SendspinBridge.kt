package me.jxl.kiosk_satellite

import android.content.Context
import android.net.ConnectivityManager
import android.net.Network
import android.os.Handler
import android.os.HandlerThread
import android.os.Looper
import android.os.Process
import android.os.SystemClock
import android.util.Log
import java.util.concurrent.atomic.AtomicInteger
import java.util.concurrent.atomic.AtomicLong
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import me.jxl.kiosk_satellite.sendspin.PlaybackState
import me.jxl.kiosk_satellite.sendspin.SendSpin
import me.jxl.kiosk_satellite.sendspin.SyncAudioPlayer
import me.jxl.kiosk_satellite.sendspin.decoder.AudioDecoder
import me.jxl.kiosk_satellite.sendspin.decoder.AudioDecoderFactory
import me.jxl.kiosk_satellite.sendspin.discovery.NsdDiscoveryManager
import me.jxl.kiosk_satellite.sendspin.network.WebSocketUrlBuilder
import me.jxl.kiosk_satellite.sendspin.protocol.SendSpinProtocol

/**
 * Headless SendSpin synchronized-audio player, exposed to Dart over the
 * `kiosk_satellite/sendspin` method channel.
 *
 * Owns the whole native pipeline: the SendSpin protocol client (WebSocket,
 * time sync, reconnect), the codec decoder, the DAC-gated SyncAudioPlayer,
 * and mDNS discovery. Server volume commands move [VolumeController]'s
 * MEDIA fader (AudioTrack gain under the master ceiling, issue #79) - the
 * Music Assistant slider is the music's, never the device's - and media
 * fader moves from any surface are reported back via client/state.
 *
 * Methods:
 * - start {serverUrl?, playerName, clientId, preferredCodec}
 * - stop
 * - discover {timeoutMs}
 * - getStatus
 *
 * Events pushed to Dart: stateChanged, metadataChanged, volumeChanged,
 * playingChanged.
 */
class SendspinBridge(
    private val context: Context,
    messenger: BinaryMessenger,
) {
    companion object {
        private const val TAG = "sendspin"
        private const val DEFAULT_PORT = 8927
        private const val DEFAULT_DISCOVER_TIMEOUT_MS = 4000
        private const val DISCOVERY_RETRY_MS = 5_000L
        // Recycle a fruitless mDNS browse after this long (see discoveryRestart).
        private const val DISCOVERY_REBROWSE_MS = 600_000L  // 10 minutes
        private const val BUFFER_CAPACITY_SECONDS = 35L

        /**
         * Most chunks allowed to wait for the decode thread. Sized to hold
         * a FULL buffer-capacity burst in compressed form (~3 minutes of
         * audio at the server's 96ms cadence, a few MB of Opus): at stream
         * start the server sends the whole negotiated capacity at line
         * speed, and Opus decode cannot keep wire pace the way FLAC can —
         * with a 256 cap the overflow was shed, and playback ground
         * through the missing seconds as a garbled fast-forward. Chunks
         * waiting here are cheap (compressed bytes); the decoded queue
         * below is the memory that matters and has its own cap. Still an
         * OOM backstop against a dead decoder, just no longer one a
         * healthy stream start can hit.
         */
        private const val MAX_PENDING_DECODES = 2048
        private const val DECODE_DROP_LOG_INTERVAL = 100L

        /** Cadence of the audible-position re-emit (see positionCorrector). */
        private const val POSITION_CORRECT_INTERVAL_MS = 5_000L

        /**
         * Metadata progress below this means the track started from the top:
         * the reported progress is only the server's read-ahead (Music
         * Assistant's progress tracks its send cursor, which led the audible
         * timeline by a measured 4.7s on FLAC), so the correct stream base is
         * zero, not a pairing that bakes that lead into every lyric line.
         */
        private const val FRESH_TRACK_MAX_PROGRESS_MS = 8_000L
    }

    private val channel = MethodChannel(messenger, "kiosk_satellite/sendspin")
    private val mainHandler = Handler(Looper.getMainLooper())

    // Decoding runs on its own audio-priority thread, NOT the WebSocket
    // reader thread (issue #59): a MediaCodec decode blocks up to tens of
    // milliseconds, and doing that inline on the socket thread at default
    // priority let a slow CPU starve the reader until frames were dropped.
    // Everything that touches the decoder — chunks, stream start/clear/end —
    // is posted here in arrival order, so the decoder stays effectively
    // single-threaded and stream events never overtake in-flight audio.
    private val decodeThread =
        HandlerThread("SendSpinDecode", Process.THREAD_PRIORITY_AUDIO).also { it.start() }
    private val decodeHandler = Handler(decodeThread.looper)
    private val pendingDecodes = AtomicInteger(0)
    private val decodeQueueDrops = AtomicLong(0)

    private val versionName: String = try {
        context.packageManager.getPackageInfo(context.packageName, 0).versionName ?: "unknown"
    } catch (_: Exception) {
        "unknown"
    }

    // Session objects. pipelineLock guards player/decoder swaps and decoder
    // use, which happen on the decode thread while stop() can run on the
    // main thread.
    private val pipelineLock = Any()
    @Volatile private var client: SendSpin? = null
    @Volatile private var player: SyncAudioPlayer? = null
    @Volatile private var decoder: AudioDecoder? = null
    @Volatile private var autoDiscovery: NsdDiscoveryManager? = null

    @Volatile private var started = false
    @Volatile private var discoveryMode = false

    // Status mirrors for getStatus / event payloads
    @Volatile private var connected = false
    @Volatile private var serverName: String? = null
    @Volatile private var playbackState: String? = null
    @Volatile private var supportedCommands: List<String> = emptyList()

    // Persisted across the per-stream player rebuilds so a duck that spans
    // a track change is not lost.
    @Volatile private var duckFactor: Float = 1f
    @Volatile private var title: String? = null
    @Volatile private var artist: String? = null
    @Volatile private var album: String? = null
    @Volatile private var streamActive = false
    @Volatile private var lastPlaying = false

    @Volatile private var lastReportedVolume = -1
    @Volatile private var lastReportedMuted = false

    // Connectivity kick: when a network (re)appears, retry the connection
    // immediately instead of waiting out the reconnect ladder's current
    // delay. Without this, an outage longer than ~8 minutes leaves the
    // ladder parked at 5-minute retries, so the player stays unavailable in
    // Music Assistant for minutes after wifi is back. Registered per
    // session; the registration-time callback for the already-present
    // network is skipped so session start does not self-nudge.
    @Volatile private var networkCallback: ConnectivityManager.NetworkCallback? = null

    private fun registerNetworkCallback() {
        if (networkCallback != null) return
        val cm = context.getSystemService(Context.CONNECTIVITY_SERVICE) as? ConnectivityManager
        if (cm == null) {
            Log.w(TAG, "No ConnectivityManager; network kick disabled")
            return
        }
        val cb = object : ConnectivityManager.NetworkCallback() {
            private var sawInitialNetwork = false
            override fun onAvailable(network: Network) {
                mainHandler.post {
                    if (!sawInitialNetwork) {
                        sawInitialNetwork = true
                        return@post
                    }
                    if (!started) return@post
                    Log.i(TAG, "Network available - nudging Sendspin recovery")
                    client?.onNetworkAvailable()
                    if (discoveryMode && client?.isConnected != true) {
                        // Recycle the browse now rather than at the next
                        // 10-minute tick; a wedged NSD browse cannot see the
                        // server that just became reachable.
                        mainHandler.removeCallbacks(discoveryRestart)
                        discoveryRestart.run()
                    }
                }
            }
        }
        try {
            cm.registerDefaultNetworkCallback(cb)
            networkCallback = cb
        } catch (e: Exception) {
            Log.w(TAG, "Failed to register network callback", e)
        }
    }

    private fun unregisterNetworkCallback() {
        val cb = networkCallback ?: return
        networkCallback = null
        val cm = context.getSystemService(Context.CONNECTIVITY_SERVICE) as? ConnectivityManager
        try {
            cm?.unregisterNetworkCallback(cb)
        } catch (e: Exception) {
            Log.w(TAG, "Failed to unregister network callback", e)
        }
    }

    private val discoveryRestart: Runnable = object : Runnable {
        override fun run() {
            if (started && discoveryMode && client?.isConnected != true) {
                // Recycle any existing browse rather than trusting it:
                // Android's NSD can wedge silently after a wifi drop (no
                // callbacks, no error), and startAutoDiscovery's null guard
                // would then turn every restart into a no-op forever - a
                // dead player until app restart. A fresh browse is cheap.
                autoDiscovery?.cleanup()
                autoDiscovery = null
                startAutoDiscovery()
                // Self-arming: if this browse finds nothing either, recycle
                // it again in a while. Disarmed by the connected guard.
                mainHandler.postDelayed(this, DISCOVERY_REBROWSE_MS)
            }
        }
    }

    /**
     * Every few seconds while playing, re-emit the audible position (see
     * onMetadataUpdate): a track's metadata usually arrives before playback
     * has calibrated, so the first report carries the server's inflated
     * send-cursor position, and the next natural update could be a whole
     * track away. Also keeps the Dart side's extrapolation anchor fresh
     * across pauses. A no-op while nothing plays.
     */
    private val positionCorrector = object : Runnable {
        override fun run() {
            player?.audiblePositionInStreamMs()?.let { audible ->
                var base = currentStreamBaseMs()
                val duration = lastDurationMs
                if (streamBaseMs == null && lastMetaPosMs >= 0) {
                    // Deferred pairing: the anchor metadata arrived before
                    // audio ran (a resume's or rejoin's metadata precedes its
                    // stream). The metadata named the track position where
                    // the stream STARTS, and the audible clock counts audio
                    // played since that same point, so the base IS the
                    // metadata value. Deliberately NOT extrapolated by wall
                    // time and NOT reduced by the audible clock: the track
                    // does not advance while this device buffers (wall
                    // extrapolation baked the startup wait in, +4.7s
                    // measured), and subtracting the audible clock paid the
                    // corrector's tick latency twice (up to 5s behind after
                    // a resume). The fresh clamp matches the live pairing:
                    // a from-the-top start's progress is only send lead.
                    val anchored = if (lastMetaPosMs < FRESH_TRACK_MAX_PROGRESS_MS) {
                        0L
                    } else {
                        lastMetaPosMs
                    }
                    if (duration <= 0 || lastMetaPosMs < duration - 2_000) {
                        streamBaseMs = anchored
                        base = anchored
                    }
                }
                if (duration > 0 && audible + base > duration + 2_000) {
                    // Self-heal a poisoned anchor (a malformed metadata
                    // frame that slipped the guards): without this, a bad
                    // base pins the display past the end of the track for
                    // the whole song.
                    Log.w(TAG, "position anchor beyond the track end, dropping it")
                    streamBaseMs = null
                    lastMetaPosMs = -1L
                    base = 0L
                }
                emit("metadataChanged", mapOf("positionMs" to (audible + base)))
            }
            mainHandler.postDelayed(this, POSITION_CORRECT_INTERVAL_MS)
        }
    }

    /** The track position of the current stream's first chunk (see
     *  onMetadataUpdate). Null until the first real metadata after connect.
     *  Volatile: written on the socket callback thread, read by the
     *  main-thread corrector. */
    @Volatile private var streamBaseMs: Long? = null

    /** The configured audio sync offset, held here so a player built at
     *  the next stream start inherits it (see configurePipeline). */
    @Volatile private var syncOffsetMs = 0L

    /** The current track's duration from its last real metadata, for the
     *  corrector's sanity check on the position anchor. */
    @Volatile private var lastDurationMs = 0L

    /** The player's positionAnchorGeneration last seen here. */
    @Volatile private var seenAnchorGeneration = 0L

    /** The last sane metadata position and when it arrived, for the
     *  corrector's deferred base pairing (a rejoin's metadata arrives
     *  before its stream has an audible clock to pair against). */
    @Volatile private var lastMetaPosMs = -1L
    @Volatile private var lastMetaAtMs = 0L

    /** The stream base, invalidated first whenever the player re-anchored
     *  at an in-stream track boundary: a base paired against the previous
     *  track's timeline reads minutes ahead on the new one, and so does
     *  its stale metadata sample. */
    private fun currentStreamBaseMs(): Long {
        val generation = player?.positionAnchorGeneration ?: 0L
        if (generation != seenAnchorGeneration) {
            seenAnchorGeneration = generation
            streamBaseMs = null
            lastMetaPosMs = -1L
        }
        return streamBaseMs ?: 0L
    }

    init {
        mainHandler.postDelayed(positionCorrector, POSITION_CORRECT_INTERVAL_MS)
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "start" -> {
                    val serverUrl = call.argument<String>("serverUrl")
                    val playerName = call.argument<String>("playerName") ?: "Kiosk Satellite"
                    val clientId = call.argument<String>("clientId") ?: "kiosk-satellite"
                    val preferredCodec =
                        (call.argument<String>("preferredCodec") ?: "flac").lowercase()
                    syncOffsetMs = (call.argument<Number>("syncOffsetMs") ?: 0).toLong()
                    startSession(serverUrl, playerName, clientId, preferredCodec)
                    result.success(true)
                }
                // Applied live, no session restart: a slider being tuned by
                // ear must not interrupt the music it is tuning against.
                "setSyncOffset" -> {
                    syncOffsetMs = (call.argument<Number>("ms") ?: 0).toLong()
                    player?.setPlaybackOffsetMs(syncOffsetMs)
                    result.success(true)
                }
                "stop" -> {
                    stopSession()
                    result.success(true)
                }
                "discover" -> {
                    val timeoutMs = call.argument<Number>("timeoutMs")?.toInt()
                        ?: DEFAULT_DISCOVER_TIMEOUT_MS
                    runDiscover(timeoutMs, result)
                }
                "getStatus" -> result.success(buildStatus())
                "duck" -> {
                    val factor = call.argument<Number>("factor")?.toFloat() ?: 1f
                    duckFactor = factor.coerceIn(0f, 1f)
                    player?.duckFactor = duckFactor
                    result.success(true)
                }
                "control" -> {
                    val command = call.argument<String>("command") ?: ""
                    val allowed = supportedCommands
                    if (command.isNotEmpty() &&
                        (allowed.isEmpty() || command in allowed)
                    ) {
                        client?.sendControllerCommand(command)
                        result.success(true)
                    } else {
                        result.success(false)
                    }
                }
                else -> result.notImplemented()
            }
        }
        // Any fader move (media, fixed-volume master, a server command)
        // must reach the live AudioTrack and be reported to the server,
        // no matter which surface moved it.
        VolumeController.addListener {
            player?.setVolume(VolumeController.mediaGain)
            if (started) publishVolumeIfChanged()
        }
    }

    // ==================================================================
    // Session lifecycle
    // ==================================================================

    private fun startSession(
        serverUrl: String?,
        playerName: String,
        clientId: String,
        preferredCodec: String,
    ) {
        if (started) stopSession()
        started = true

        val newClient = SendSpin(
            deviceName = playerName,
            clientId = clientId,
            preferredCodec = preferredCodec,
            softwareVersion = versionName,
            callback = ClientCallback(),
        )
        newClient.setInitialVolume(deviceVolumePct(), deviceMuted())
        lastReportedVolume = deviceVolumePct()
        lastReportedMuted = deviceMuted()
        client = newClient

        if (serverUrl.isNullOrBlank()) {
            discoveryMode = true
            Log.i(TAG, "start: no serverUrl, using mDNS discovery")
            startAutoDiscovery()
            // Arm the browse recycler from the very first browse too.
            mainHandler.postDelayed(discoveryRestart, DISCOVERY_REBROWSE_MS)
        } else {
            discoveryMode = false
            val (address, path) = parseServerUrl(serverUrl)
            Log.i(TAG, "start: connecting to $address$path")
            newClient.connect(address, path)
        }

        registerNetworkCallback()
    }

    private fun stopSession() {
        started = false
        discoveryMode = false
        unregisterNetworkCallback()
        mainHandler.removeCallbacks(discoveryRestart)

        autoDiscovery?.cleanup()
        autoDiscovery = null

        // Goodbye + disconnect + release, in dependency order.
        client?.destroy()
        client = null

        synchronized(pipelineLock) {
            player?.release()
            player = null
            decoder?.release()
            decoder = null
        }

        connected = false
        serverName = null
        playbackState = null
        title = null
        artist = null
        album = null
        streamActive = false
        if (lastPlaying) {
            lastPlaying = false
            emit("playingChanged", mapOf("playing" to false))
        }
        emitState()
    }

    // ==================================================================
    // Discovery
    // ==================================================================

    /** Parse a user-supplied server URL/address into ("host:port", "/path"). */
    private fun parseServerUrl(raw: String): Pair<String, String> {
        var s = raw.trim()
            .removePrefix("ws://")
            .removePrefix("wss://")
            .removePrefix("http://")
            .removePrefix("https://")
        val slash = s.indexOf('/')
        val authority: String
        val path: String
        if (slash >= 0) {
            authority = s.substring(0, slash)
            path = s.substring(slash)
        } else {
            authority = s
            path = SendSpinProtocol.ENDPOINT_PATH
        }
        return WebSocketUrlBuilder.ensureDefaultPort(authority, DEFAULT_PORT) to path
    }

    /**
     * Browse for the first `_sendspin-server._tcp.` server and connect to it.
     * Keeps browsing until a server appears; if the subsequent connection
     * dies for good, [ClientCallback] schedules a fresh browse.
     */
    private fun startAutoDiscovery() {
        mainHandler.post {
            if (!started || !discoveryMode || autoDiscovery != null) return@post
            if (client?.isConnected == true) return@post

            val manager = NsdDiscoveryManager(
                context,
                object : NsdDiscoveryManager.DiscoveryListener {
                    override fun onServerDiscovered(
                        name: String,
                        host: String,
                        port: Int,
                        path: String,
                        friendlyName: String,
                    ) {
                        mainHandler.post {
                            if (!started) return@post
                            val d = autoDiscovery ?: return@post
                            autoDiscovery = null
                            d.cleanup()
                            val address =
                                if (host.contains(":")) "[$host]:$port" else "$host:$port"
                            Log.i(TAG, "Discovery: connecting to '$friendlyName' at $address$path")
                            client?.connect(address, path)
                        }
                    }

                    override fun onServerLost(name: String) {}
                    override fun onDiscoveryStarted() {}
                    override fun onDiscoveryStopped() {}

                    override fun onDiscoveryError(error: String) {
                        Log.w(TAG, "Discovery error: $error")
                        mainHandler.post {
                            autoDiscovery?.cleanup()
                            autoDiscovery = null
                            scheduleDiscoveryRestart()
                        }
                    }
                },
            )
            autoDiscovery = manager
            manager.startDiscovery()
        }
    }

    private fun scheduleDiscoveryRestart() {
        mainHandler.removeCallbacks(discoveryRestart)
        mainHandler.postDelayed(discoveryRestart, DISCOVERY_RETRY_MS)
    }

    /** One-shot bounded discovery for the "discover" method call. */
    private fun runDiscover(timeoutMs: Int, result: MethodChannel.Result) {
        val results = mutableListOf<Map<String, Any>>()
        val seen = HashSet<String>()

        val manager = NsdDiscoveryManager(
            context,
            object : NsdDiscoveryManager.DiscoveryListener {
                override fun onServerDiscovered(
                    name: String,
                    host: String,
                    port: Int,
                    path: String,
                    friendlyName: String,
                ) {
                    synchronized(results) {
                        if (seen.add("$host:$port")) {
                            results.add(
                                mapOf(
                                    "name" to friendlyName,
                                    "host" to host,
                                    "port" to port,
                                    "url" to WebSocketUrlBuilder.buildFromHostPort(host, port, path),
                                ),
                            )
                        }
                    }
                }

                override fun onServerLost(name: String) {}
                override fun onDiscoveryStarted() {}
                override fun onDiscoveryStopped() {}
                override fun onDiscoveryError(error: String) {
                    Log.w(TAG, "discover: $error")
                }
            },
        )
        manager.startDiscovery()
        mainHandler.postDelayed({
            manager.cleanup()
            result.success(synchronized(results) { results.toList() })
        }, timeoutMs.toLong().coerceIn(500L, 60_000L))
    }

    // ==================================================================
    // Device volume (STREAM_MUSIC)
    // ==================================================================

    // The server's volume is the MEDIA fader, not the device volume: the
    // Music Assistant slider is the music's. Master stays with the MQTT
    // Volume entity and the hardware buttons.
    private fun deviceVolumePct(): Int = VolumeController.mediaPercent()

    private fun deviceMuted(): Boolean = VolumeController.mediaMuted()

    private fun setDeviceVolumePct(volume: Int) {
        VolumeController.setMediaPercent(volume)
    }

    private fun setDeviceMuted(muted: Boolean) {
        VolumeController.setMediaMuted(muted)
    }

    /**
     * Detect a device-side volume/mute change (hardware buttons, other apps),
     * report it to the server via client/state, and push it to Dart.
     */
    private fun publishVolumeIfChanged() {
        val vol = deviceVolumePct()
        val muted = deviceMuted()
        if (vol == lastReportedVolume && muted == lastReportedMuted) return
        lastReportedVolume = vol
        lastReportedMuted = muted
        client?.setInitialVolume(vol, muted)
        client?.sendClientStateSnapshot()
        emit("volumeChanged", mapOf("volume" to vol, "muted" to muted))
    }

    // ==================================================================
    // Events / status
    // ==================================================================

    private fun emit(method: String, arguments: Any?) {
        mainHandler.post { channel.invokeMethod(method, arguments) }
    }

    private fun emitState() {
        emit(
            "stateChanged",
            mapOf(
                "connected" to connected,
                "serverName" to serverName,
                "playbackState" to playbackState,
                "synced" to (client?.isSynchronized() ?: false),
            ),
        )
    }

    private fun recomputePlaying() {
        val playing = streamActive && playbackState == "playing"
        if (playing != lastPlaying) {
            lastPlaying = playing
            // No volume re-apply on start anymore: the server's volume is
            // AudioTrack gain now, not the stream, so Samsung's per-output
            // stream volumes cannot strand it on the wrong device.
            emit("playingChanged", mapOf("playing" to playing))
        }
    }

    private fun buildStatus(): Map<String, Any?> = mapOf(
        "connected" to connected,
        "serverName" to serverName,
        "playbackState" to playbackState,
        "title" to title,
        "artist" to artist,
        "album" to album,
        "volume" to deviceVolumePct(),
        "muted" to deviceMuted(),
        "synced" to (client?.isSynchronized() ?: false),
        // Pipeline health, for diagnosing stutter reports (issue #59)
        // without an adb cable: every counter that marks lost audio.
        "stats" to player?.getStats()?.let { s ->
            mapOf(
                "chunksReceived" to s.chunksReceived,
                "chunksPlayed" to s.chunksPlayed,
                "chunksDropped" to s.chunksDropped,
                "gapsFilled" to s.gapsFilled,
                "gapSilenceMs" to s.gapSilenceMs,
                "overlapsTrimmed" to s.overlapsTrimmed,
                "overlapTrimmedMs" to s.overlapTrimmedMs,
                "overlapsSkipped" to s.overlapsSkipped,
                "bufferUnderruns" to s.bufferUnderrunCount,
                "reanchors" to s.reanchorCount,
                "decoderInputDropped" to (decoder?.inputFramesDropped ?: 0L),
                "decodeQueueDrops" to decodeQueueDrops.get(),
            )
        },
    )

    // ==================================================================
    // Audio pipeline
    // ==================================================================

    private fun configurePipeline(
        codec: String,
        sampleRate: Int,
        channels: Int,
        bitDepth: Int,
        codecHeader: ByteArray?,
    ) {
        synchronized(pipelineLock) {
            val c = client ?: return

            val existing = player
            if (existing != null && existing.matchesFormat(sampleRate, channels, bitDepth)) {
                // Reuse the live AudioTrack: keeps DAC timestamps warm across
                // stream/end -> stream/start cycles with the same format.
                if (existing.getPlaybackState() == PlaybackState.DRAINING) {
                    existing.exitDraining()
                }
            } else {
                existing?.release()
                player = SyncAudioPlayer(
                    timeFilter = c.getTimeFilter(),
                    sampleRate = sampleRate,
                    channels = channels,
                    bitDepth = bitDepth,
                    maxQueueSamples = BUFFER_CAPACITY_SECONDS * sampleRate,
                    requestClientStateSnapshot = { client?.sendClientStateSnapshot() },
                ).also {
                    it.duckFactor = duckFactor
                    it.setPlaybackOffsetMs(syncOffsetMs)
                    it.initialize()
                    it.setVolume(VolumeController.mediaGain)
                    it.start()
                }
            }

            decoder?.release()
            decoder = try {
                AudioDecoderFactory.create(codec).also {
                    it.configure(sampleRate, channels, bitDepth, codecHeader)
                }
            } catch (e: Exception) {
                Log.e(TAG, "Failed to configure $codec decoder", e)
                null
            }
        }
    }

    /**
     * Decode one chunk and queue its output. Decode thread only. The
     * pipeline lock covers the decode so stopSession()/configurePipeline()
     * cannot release the MediaCodec out from under it; each output span
     * carries its own timestamp (see [me.jxl.kiosk_satellite.sendspin.decoder.DecodedAudio]),
     * so output the codec delivers late is queued at its true time instead
     * of being lost or mis-stamped.
     */
    private fun decodeAndQueue(serverTimeMicros: Long, audioData: ByteArray) {
        synchronized(pipelineLock) {
            val d = decoder ?: return
            val spans = try {
                d.decode(serverTimeMicros, audioData)
            } catch (e: Exception) {
                Log.e(TAG, "Decode failed (${audioData.size} bytes)", e)
                return
            }
            for (span in spans) {
                if (span.pcm.isNotEmpty()) {
                    player?.queueChunk(span.serverTimeMicros, span.pcm)
                }
            }
        }
    }

    // ==================================================================
    // SendSpin client callback
    // ==================================================================

    private inner class ClientCallback : SendSpin.Callback {

        override fun onConnectionStateChanged(state: SendSpin.ConnectionState) {
            val wasConnected = connected
            connected = state == SendSpin.ConnectionState.READY

            if (wasConnected && !connected) {
                // Transport dropped: keep playing from buffer while the client
                // reconnects (SyncAudioPlayer no-ops unless it was playing).
                player?.enterDraining()
            }

            if (!connected &&
                (state == SendSpin.ConnectionState.IDLE || state == SendSpin.ConnectionState.FAILED) &&
                started && discoveryMode
            ) {
                // Terminal state in discovery mode: go find a server again.
                scheduleDiscoveryRestart()
            }

            emitState()
        }

        override fun onHandshakeComplete(serverName: String) {
            this@SendspinBridge.serverName = serverName
            mainHandler.removeCallbacks(discoveryRestart)
            emitState()
        }

        override fun onStateChanged(state: String) {
            playbackState = state
            recomputePlaying()
            emitState()
        }

        override fun onGroupUpdate(groupId: String, groupName: String, playbackState: String) {
            if (playbackState.isNotEmpty()) {
                this@SendspinBridge.playbackState = playbackState
                recomputePlaying()
                emitState()
            }
        }

        override fun onMetadataUpdate(
            title: String,
            artist: String,
            album: String,
            artworkUrl: String,
            durationMs: Long,
            positionMs: Long,
        ) {
            this@SendspinBridge.title = title.ifEmpty { null }
            this@SendspinBridge.artist = artist.ifEmpty { null }
            this@SendspinBridge.album = album.ifEmpty { null }
            if (durationMs > 0) lastDurationMs = durationMs
            // The base maps our stream-anchored audible clock onto TRACK
            // time: base = (reported position) - (audible position), both
            // read at this same instant, so it holds regardless of how far
            // the server has buffered ahead, in which order boundary
            // messages arrived, or whether the server's progress tracks its
            // cursor or its playback clock — all of which have varied.
            // Guarded to positions that fit inside the track and not within
            // its final seconds: placeholder frames, end-of-track boundary
            // frames, and the server's stream-end frames with progress in
            // MICROSECONDS (one anchored the display 42 hours in) must not
            // become anchors. The base may legitimately be negative.
            //
            // With no audible clock yet (metadata before the stream, the
            // rejoin case), the pairing is deferred: the position corrector
            // picks it up from lastMetaPosMs once audio runs.
            currentStreamBaseMs() // sync the anchor generation first
            val saneAnchor =
                durationMs > 2_000 && positionMs in 0 until durationMs - 2_000
            val audibleRaw = player?.audiblePositionInStreamMs()
            if (saneAnchor) {
                lastMetaPosMs = positionMs
                lastMetaAtMs = SystemClock.elapsedRealtime()
                // Live pairing only while a stream is actually running: the
                // metadata riding a pause's stream/end can carry a garbage
                // progress (observed 2985ms against a track at 44s), and the
                // audible clock is still within its staleness window at that
                // moment, so pairing there anchored the display 41s off. The
                // value still lands in lastMetaPosMs above, where the
                // deferred pairing vets it against the next stream instead.
                if (!streamActive) {
                    // No stream to pair against.
                } else if (positionMs < FRESH_TRACK_MAX_PROGRESS_MS &&
                    (audibleRaw == null || audibleRaw < FRESH_TRACK_MAX_PROGRESS_MS)
                ) {
                    // Track started from the top: the audible clock IS the
                    // track position. Pairing here instead would absorb the
                    // send-cursor lead and run the lyrics seconds ahead of
                    // the speaker for the whole song.
                    streamBaseMs = 0L
                } else if (audibleRaw != null) {
                    streamBaseMs = positionMs - audibleRaw
                }
            }
            // The audible clock beats the metadata's value: it is what the
            // speaker is saying, smooth and unaffected by the server's
            // buffering. With no audible clock yet, the metadata's own
            // value passes through only when sane against the duration;
            // otherwise the field is omitted and the Dart side keeps what
            // it had.
            val audible = audibleRaw?.plus(currentStreamBaseMs())
            val reported = audible
                ?: positionMs.takeIf {
                    it >= 0 && (durationMs <= 0 || it <= durationMs + 2_000)
                }
            emit(
                "metadataChanged",
                buildMap {
                    put("title", title)
                    put("artist", artist)
                    put("album", album)
                    put("artworkUrl", artworkUrl)
                    if (reported != null) put("positionMs", reported)
                    put("durationMs", durationMs)
                },
            )
        }

        override fun onStreamStart(
            codec: String,
            sampleRate: Int,
            channels: Int,
            bitDepth: Int,
            codecHeader: ByteArray?,
        ) {
            // On the decode thread, behind any still-queued chunks of the
            // previous stream, so the old decoder finishes its audio before
            // being replaced.
            decodeHandler.post {
                configurePipeline(codec, sampleRate, channels, bitDepth, codecHeader)
            }
            // A new stream is a new timeline: whatever base mapped the old
            // stream's audible clock onto track time is meaningless against
            // the new clock, and a survivor here anchored the display a
            // whole pause off after resume. Keep lastMetaPosMs: the pairing
            // re-derives from it (fresh clamp included) once the new
            // stream's audible clock is live.
            streamBaseMs = null
            streamActive = true
            recomputePlaying()
        }

        override fun onStreamClear() {
            // Ordered behind pending chunk decodes: clearing first and
            // decoding after would re-queue the audio the clear removed.
            decodeHandler.post {
                synchronized(pipelineLock) { decoder?.flush() }
                player?.clearBuffer()
            }
            // The cleared stream's timeline dies with it (see onStreamStart).
            streamBaseMs = null
        }

        override fun onStreamEnd() {
            streamActive = false
            decodeHandler.post {
                // Keep the AudioTrack alive writing silence so DAC timestamps
                // stay warm for the next stream.
                player?.enterIdle()
                synchronized(pipelineLock) { decoder?.flush() }
            }
            recomputePlaying()
        }

        override fun onAudioChunk(serverTimeMicros: Long, audioData: ByteArray) {
            // Deliberately NOT blocking here when the backlog is full: this
            // is the socket reader thread, and stalling it also stalls the
            // time-sync messages sharing the websocket — the sync state
            // then degrades to error and the player mutes itself (tried,
            // reverted). With buffer_capacity sized per codec the server
            // never overruns the backlog in normal play; a drop is the
            // last-resort shed it always was.
            if (pendingDecodes.get() >= MAX_PENDING_DECODES) {
                val dropped = decodeQueueDrops.incrementAndGet()
                if (dropped % DECODE_DROP_LOG_INTERVAL == 1L) {
                    Log.w(TAG, "Decode queue full, dropping chunk (total $dropped)")
                }
                return
            }
            pendingDecodes.incrementAndGet()
            decodeHandler.post {
                pendingDecodes.decrementAndGet()
                decodeAndQueue(serverTimeMicros, audioData)
            }
        }

        override fun onVolumeChanged(volume: Int) {
            setDeviceVolumePct(volume)
            publishVolumeIfChanged()
        }

        override fun onMutedChanged(muted: Boolean) {
            setDeviceMuted(muted)
            publishVolumeIfChanged()
        }

        override fun onSyncMuteChanged(muted: Boolean) {
            player?.setSyncMuted(muted)
        }

        override fun onReconnectExhausted() {
            Log.w(TAG, "Reconnect attempts exhausted")
            if (started && discoveryMode) scheduleDiscoveryRestart()
            emitState()
        }

        override fun onControllerUpdate(supportedCommands: List<String>) {
            this@SendspinBridge.supportedCommands = supportedCommands
            emit("controllerChanged",
                mapOf("supportedCommands" to supportedCommands))
        }
    }
}
